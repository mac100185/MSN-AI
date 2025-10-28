#!/bin/bash
# AI Setup Script for MSN-AI Docker Container
# Version: 2.1.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Hardware detection and AI model setup for Docker environment

# Don't exit on error - allow script to continue and report issues
set +e

echo "🤖 MSN-AI Docker - Configuración de IA"
echo "======================================"
echo "📧 Desarrollado por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "🐳 Modo: Docker Container"
echo "======================================"

# Environment variables
OLLAMA_HOST=${OLLAMA_HOST:-ollama:11434}
OLLAMA_API_KEY=${OLLAMA_API_KEY:-}
SETUP_TIMEOUT=${SETUP_TIMEOUT:-300}  # 5 minutes timeout
MAX_RETRIES=${MAX_RETRIES:-10}       # Maximum connection retries

# Check and display API Key status
check_api_key() {
    if [ -n "$OLLAMA_API_KEY" ]; then
        # Mask the key for display
        MASKED_KEY="${OLLAMA_API_KEY:0:8}***${OLLAMA_API_KEY: -4}"
        echo "🔑 API Key detectada: ${MASKED_KEY}"
        return 0
    else
        echo "⚠️  API Key no configurada"
        echo "   Los modelos cloud NO funcionarán sin OLLAMA_API_KEY"
        return 1
    fi
}

echo ""
check_api_key || echo "   Configure OLLAMA_API_KEY para usar modelos cloud"
echo ""

# Function to wait for Ollama
wait_for_ollama() {
    echo "🔄 Esperando conexión con Ollama..."
    local max_attempts=$MAX_RETRIES
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        # First check basic connectivity
        if curl -s --max-time 5 "http://${OLLAMA_HOST}/" >/dev/null 2>&1; then
            echo "✅ Conexión básica con Ollama establecida"

            # Then check if API is responding
            if curl -s --max-time 10 "http://${OLLAMA_HOST}/api/tags" >/dev/null 2>&1; then
                echo "✅ API de Ollama completamente disponible"
                return 0
            else
                echo "⏳ Ollama iniciando, API aún no lista..."
            fi
        else
            echo "⏳ Esperando que Ollama inicie..."
        fi

        echo "   Intento $attempt/$max_attempts (esperando 10s...)"
        sleep 10
        attempt=$((attempt + 1))
    done

    echo "❌ No se pudo conectar con Ollama después de $max_attempts intentos"
    echo "   Verifique que el contenedor ollama esté ejecutándose"
    return 1
}

# Function to detect hardware (adapted for container environment)
detect_hardware() {
    echo "🔍 Detectando hardware del contenedor..."

    # CPU cores
    CPU_CORES=$(nproc)
    echo "🖥️  CPU: $CPU_CORES núcleos"

    # RAM (in container context)
    if [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
        # cgroups v1
        RAM_BYTES=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
        RAM_GB=$((RAM_BYTES / 1024 / 1024 / 1024))
    elif [ -f /sys/fs/cgroup/memory.max ]; then
        # cgroups v2
        RAM_BYTES=$(cat /sys/fs/cgroup/memory.max)
        if [ "$RAM_BYTES" = "max" ]; then
            RAM_GB=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
        else
            RAM_GB=$((RAM_BYTES / 1024 / 1024 / 1024))
        fi
    else
        # Fallback to system memory
        RAM_GB=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
    fi

    echo "💾 RAM disponible: ${RAM_GB} GB"

    # GPU detection (limited in container)
    GPU_INFO=""
    VRAM_GB=0

    # Check if nvidia-smi is available (NVIDIA Container Toolkit)
    if command -v nvidia-smi >/dev/null 2>&1; then
        GPU_INFO=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null | head -1)
        VRAM_GB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 | awk '{print int($1/1024)}')
        echo "🎮 GPU: $GPU_INFO"
        echo "🎮 VRAM: ${VRAM_GB} GB"
    else
        echo "🎮 GPU: No detectada o no disponible en contenedor"
    fi
}

# Function to get default required models
get_required_models() {
    # Cloud models require signin - skip automatic installation
    # Users must signin manually: docker exec -it msn-ai-ollama ollama signin
    # Then pull models: docker exec -it msn-ai-ollama ollama pull qwen3-vl:235b-cloud
    REQUIRED_MODELS=()
}

# Function to recommend model based on hardware
recommend_model() {
    echo ""
    echo "🧠 Analizando configuración óptima..."

    local MODEL=""
    local LEVEL=""

    if [ -n "$GPU_INFO" ] && [ "$VRAM_GB" -gt 0 ]; then
        # GPU available
        if [ "$VRAM_GB" -ge 80 ]; then
            MODEL="llama3:70b"
            LEVEL="Máximo (alto rendimiento, razonamiento complejo)"
        elif [ "$VRAM_GB" -ge 24 ]; then
            MODEL="llama3:8b"
            LEVEL="Avanzado (programación y tareas generales)"
        elif [ "$VRAM_GB" -ge 8 ]; then
            MODEL="mistral:7b"
            LEVEL="Eficiente (equilibrio perfecto)"
        else
            MODEL="phi3:mini"
            LEVEL="Ligero (para GPUs con poca VRAM)"
        fi
    else
        # CPU only
        if [ "$RAM_GB" -ge 32 ]; then
            MODEL="mistral:7b"
            LEVEL="Eficiente (modo CPU, alta RAM)"
        elif [ "$RAM_GB" -ge 16 ]; then
            MODEL="phi3:mini"
            LEVEL="Ligero (modo CPU, RAM media)"
        else
            MODEL="tinyllama"
            LEVEL="Básico (modo CPU, RAM limitada)"
        fi
    fi

    echo "✨ Configuración recomendada:"
    echo "   📦 Modelo: $MODEL"
    echo "   🎯 Nivel: $LEVEL"
    echo ""

    # Export for use in other functions
    RECOMMENDED_MODEL="$MODEL"
    RECOMMENDED_LEVEL="$LEVEL"
}

# Function to check existing models
check_existing_models() {
    echo "🔍 Verificando modelos existentes..."

    # Use curl to call Ollama API
    MODELS_JSON=$(curl -s "http://${OLLAMA_HOST}/api/tags" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$MODELS_JSON" ]; then
        # Parse JSON response to count models
        MODEL_COUNT=$(echo "$MODELS_JSON" | grep -o '"name"' | wc -l)

        if [ "$MODEL_COUNT" -gt 0 ]; then
            echo "✅ Modelos ya instalados: $MODEL_COUNT"
            echo "   Modelos encontrados:"
            # Extract model names from JSON
            echo "$MODELS_JSON" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | head -5 | sed 's/^/   📦 /'
            return 0
        else
            echo "⚠️  No se encontraron modelos instalados"
            return 1
        fi
    else
        echo "⚠️  Error verificando modelos existentes"
        return 1
    fi
}

# Function to install recommended model
install_model() {
    local model=$1

    echo "📥 Instalando modelo: $model"
    echo "⏰ Esto puede tomar varios minutos dependiendo del modelo y conexión..."

    # Check if model is a cloud model - these require signin
    if [[ "$model" == *"-cloud"* ]] || [[ "$model" == *":cloud"* ]]; then
        echo ""
        echo "⚠️  Modelo cloud detectado: $model"
        echo "ℹ️  Los modelos cloud requieren autenticación con Ollama"
        echo ""
        echo "📋 IMPORTANTE: Los modelos cloud NO se instalan automáticamente"
        echo "   Debes hacer signin manualmente después de la instalación"
        echo ""
        echo "💡 Para instalar modelos cloud después:"
        echo "   1. Accede al contenedor:"
        echo "      docker exec -it msn-ai-ollama /bin/bash"
        echo ""
        echo "   2. Haz signin con Ollama:"
        echo "      ollama signin"
        echo "      (Abre el enlace generado en tu navegador y aprueba el acceso)"
        echo ""
        echo "   3. Instala el modelo:"
        echo "      ollama pull $model"
        echo ""
        echo "   4. Sal del contenedor:"
        echo "      exit"
        echo ""
        return 1
    fi

    # Use curl to pull the model via Ollama API with streaming
    echo "🔄 Iniciando descarga con progreso..."

    # Start the pull operation with streaming to show progress
    local pull_success=false
    local temp_file="/tmp/ollama_pull_$$.json"

    # Prepare headers
    local headers=(-H "Content-Type: application/json")

    # Add API key header if available
    if [ -n "$OLLAMA_API_KEY" ]; then
        headers+=(-H "Authorization: Bearer ${OLLAMA_API_KEY}")
    fi

    # Make the pull request and capture the response
    if curl -s -X POST "http://${OLLAMA_HOST}/api/pull" \
        "${headers[@]}" \
        -d "{\"name\":\"$model\"}" \
        --max-time 1800 > "$temp_file" 2>/dev/null; then

        echo "✅ Descarga iniciada para $model"
        pull_success=true
    else
        echo "❌ Error iniciando la descarga del modelo"
        rm -f "$temp_file"
        return 1
    fi

    if [ "$pull_success" = true ]; then
        # Wait for the model to be available with better error handling
        echo "⏳ Verificando instalación del modelo..."
        local attempts=0
        local max_attempts=90  # 15 minutes with 10s intervals

        while [ $attempts -lt $max_attempts ]; do
            local tags_response
            tags_response=$(curl -s --max-time 10 "http://${OLLAMA_HOST}/api/tags" 2>/dev/null)

            if [ $? -eq 0 ] && echo "$tags_response" | grep -q "\"name\":\"$model"; then
                echo "✅ Modelo $model instalado y disponible"
                rm -f "$temp_file"
                return 0
            fi

            # Show progress every 5 attempts
            if [ $((attempts % 5)) -eq 0 ]; then
                echo "⏳ Descargando modelo... ($(( (attempts * 10) / 60 )) min transcurridos)"
            fi

            sleep 10
            attempts=$((attempts + 1))
        done

        echo "⚠️  Timeout esperando la instalación del modelo después de 15 minutos"
        echo "   El modelo puede seguir descargándose en segundo plano"
        rm -f "$temp_file"
        return 1
    fi
}

# Function to install required models
install_required_models() {
    echo ""
    echo "📦 Verificando modelos requeridos por defecto..."
    echo "=============================================="

    get_required_models

    # Check if any cloud models were requested
    local has_cloud_models=false
    local cloud_models=("qwen3-vl:235b-cloud" "gpt-oss:120b-cloud" "qwen3-coder:480b-cloud")

    for model in "${cloud_models[@]}"; do
        has_cloud_models=true
        break
    done

    if [ "$has_cloud_models" = true ]; then
        echo ""
        echo "ℹ️  MODELOS CLOUD DISPONIBLES"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Los siguientes modelos cloud están disponibles:"
        for model in "${cloud_models[@]}"; do
            echo "  📦 $model"
        done
        echo ""
        echo "⚠️  Los modelos cloud requieren autenticación y NO se instalan"
        echo "   automáticamente durante el setup de Docker."
        echo ""
        echo "📋 PARA INSTALAR MODELOS CLOUD:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "1️⃣  Accede al contenedor de Ollama:"
        echo "   docker exec -it msn-ai-ollama /bin/bash"
        echo ""
        echo "2️⃣  Haz signin con tu cuenta de Ollama:"
        echo "   ollama signin"
        echo ""
        echo "3️⃣  Abre el enlace generado en tu navegador"
        echo "   (aparecerá algo como: https://ollama.com/connect?name=...)"
        echo ""
        echo "4️⃣  Aprueba el acceso en el navegador"
        echo ""
        echo "5️⃣  Instala los modelos cloud que necesites:"
        echo "   ollama pull qwen3-vl:235b-cloud"
        echo "   ollama pull gpt-oss:120b-cloud"
        echo "   ollama pull qwen3-coder:480b-cloud"
        echo ""
        echo "6️⃣  Verifica que se instalaron:"
        echo "   ollama list"
        echo ""
        echo "7️⃣  Sal del contenedor:"
        echo "   exit"
        echo ""
        echo "💡 Los modelos cloud solo funcionan con signin activo"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi

    local installed_count=0
    local failed_count=0
    local skipped_count=0

    for model in "${REQUIRED_MODELS[@]}"; do
        echo ""
        echo "🔄 Procesando modelo: $model"

        # Check if model is cloud and we don't have API key
        if [[ "$model" == *"-cloud"* ]] || [[ "$model" == *":cloud"* ]]; then
            if [ -z "$OLLAMA_API_KEY" ]; then
                echo "⏭️  Saltando modelo cloud (sin API Key): $model"
                skipped_count=$((skipped_count + 1))
                continue
            fi
        fi

        # Check if model already exists
        if curl -s "http://${OLLAMA_HOST}/api/tags" 2>/dev/null | grep -q "\"name\":\"$model"; then
            echo "✅ Modelo $model ya está instalado"
            installed_count=$((installed_count + 1))
        else
            echo "📥 Instalando modelo: $model"

            if install_model "$model"; then
                echo "✅ Modelo $model instalado exitosamente"
                installed_count=$((installed_count + 1))
            else
                echo "⚠️  Error instalando modelo $model"
                failed_count=$((failed_count + 1))
            fi
        fi
    done

    echo ""
    echo "📊 Resumen de instalación de modelos requeridos:"
    echo "   ✅ Instalados correctamente: $installed_count/${#REQUIRED_MODELS[@]}"
    echo "   ⚠️  Fallidos: $failed_count/${#REQUIRED_MODELS[@]}"
    if [ $skipped_count -gt 0 ]; then
        echo "   ⏭️  Saltados (sin API Key): $skipped_count/${#REQUIRED_MODELS[@]}"
    fi
    echo ""

    # Always return success - MSN-AI can work without pre-installed models
    if [ $installed_count -gt 0 ]; then
        echo "✅ Setup completado con modelos instalados"
        return 0
    elif [ $skipped_count -gt 0 ]; then
        echo "ℹ️  Modelos cloud saltados por falta de API Key (normal)"
        echo "   MSN-AI funcionará y podrás instalar modelos manualmente"
        return 0
    elif [ $failed_count -gt 0 ]; then
        echo "⚠️  Algunos modelos fallaron, pero MSN-AI puede continuar"
        echo "   Los modelos pueden instalarse manualmente desde la interfaz"
        return 0
    else
        echo "⚠️  No se instalaron modelos automáticamente"
        echo "   Esto no afecta el funcionamiento de MSN-AI"
        return 0
    fi
}

# Function to test model
test_model() {
    local model=$1

    echo "🧪 Probando modelo: $model"

    # Test the model with a simple prompt
    TEST_RESPONSE=$(curl -s -X POST "http://${OLLAMA_HOST}/api/generate" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"$model\",\"prompt\":\"Hola, ¿funcionas correctamente?\",\"stream\":false}" 2>/dev/null)

    if [ $? -eq 0 ] && echo "$TEST_RESPONSE" | grep -q '"response"'; then
        echo "✅ Modelo $model funciona correctamente"

        # Extract response for display
        RESPONSE_TEXT=$(echo "$TEST_RESPONSE" | grep -o '"response":"[^"]*"' | cut -d'"' -f4 | head -c 100)
        echo "🤖 Respuesta de prueba: $RESPONSE_TEXT..."

        return 0
    else
        echo "⚠️  Error probando el modelo $model"
        return 1
    fi
}

# Function to save configuration
save_config() {
    local model=$1
    local config_file="/app/data/config/ai-config.json"

    echo "💾 Guardando configuración..."

    mkdir -p "$(dirname "$config_file")"

    cat > "$config_file" << EOF
{
  "version": "1.0.0",
  "setup_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "setup_mode": "docker",
  "hardware": {
    "cpu_cores": $CPU_CORES,
    "ram_gb": $RAM_GB,
    "gpu_info": "$GPU_INFO",
    "vram_gb": $VRAM_GB
  },
  "ai_config": {
    "recommended_model": "$model",
    "level": "$RECOMMENDED_LEVEL",
    "ollama_host": "$OLLAMA_HOST"
  },
  "container_info": {
    "hostname": "$(hostname)",
    "user": "$(whoami)"
  }
}
EOF

    echo "✅ Configuración guardada en: $config_file"
}

# Main setup function
main() {
    echo "🚀 Iniciando configuración de IA para MSN-AI..."
    echo "⏰ Timeout configurado: ${SETUP_TIMEOUT}s"

    # Set timeout for entire process
    local start_time=$(date +%s)

    # Wait for Ollama service with retries
    echo "📡 Estableciendo conexión con Ollama..."
    local ollama_attempts=0
    while [ $ollama_attempts -lt 3 ]; do
        if wait_for_ollama; then
            break
        fi

        ollama_attempts=$((ollama_attempts + 1))
        if [ $ollama_attempts -lt 3 ]; then
            echo "🔄 Reintentando conexión con Ollama (intento $((ollama_attempts + 1))/3)..."
            sleep 15
        fi
    done

    if [ $ollama_attempts -eq 3 ]; then
        echo "❌ No se pudo establecer conexión con Ollama después de 3 intentos"
        echo "   Posibles causas:"
        echo "   - Ollama container aún iniciándose"
        echo "   - Recursos del sistema insuficientes"
        echo "   - Problemas de red entre contenedores"
        echo ""
        echo "💡 El contenedor MSN-AI funcionará sin IA hasta que Ollama esté disponible"
        echo "⚠️  Setup de IA cancelado - MSN-AI continuará sin modelos preinstalados"
        exit 0
    fi

    # Check timeout
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    if [ $elapsed -ge $SETUP_TIMEOUT ]; then
        echo "⏰ Timeout alcanzado durante la conexión inicial"
        echo "⚠️  Setup de IA cancelado por timeout - MSN-AI continuará sin modelos preinstalados"
        exit 0
    fi

    # Detect hardware
    detect_hardware

    # Recommend optimal model
    recommend_model

    # Install required default models
    echo "📦 Instalando modelos requeridos por defecto..."
    if ! install_required_models; then
        echo "⚠️  Error instalando modelos requeridos, pero continuando setup..."
    fi

    # Check timeout after installing required models
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))

    if [ $elapsed -lt $((SETUP_TIMEOUT - 60)) ]; then
        # Check if models already exist beyond required ones
        if check_existing_models; then
            echo "ℹ️  Modelos adicionales encontrados"
            echo "   Configuración automática: Usando modelos existentes"
            echo "   Modelo recomendado para este hardware: $RECOMMENDED_MODEL"
        else
            echo "📦 Instalando modelo recomendado adicional: $RECOMMENDED_MODEL"

            # Check timeout before starting model installation
            current_time=$(date +%s)
            elapsed=$((current_time - start_time))
            if [ $elapsed -ge $((SETUP_TIMEOUT - 60)) ]; then
                echo "⏰ Tiempo insuficiente para instalar modelo adicional"
            else
                if install_model "$RECOMMENDED_MODEL"; then
                    echo "✅ Instalación exitosa del modelo recomendado"

                    # Test the model if we have time
                    current_time=$(date +%s)
                    elapsed=$((current_time - start_time))
                    if [ $elapsed -lt $((SETUP_TIMEOUT - 30)) ]; then
                        if test_model "$RECOMMENDED_MODEL"; then
                            echo "🎉 Configuración de IA completada exitosamente"
                        else
                            echo "⚠️  Modelo instalado pero falló la prueba (puede ser normal al inicio)"
                        fi
                    else
                        echo "⏰ Saltando test del modelo por tiempo"
                    fi
                else
                    echo "⚠️  Error en la instalación del modelo recomendado"
                    echo "   Continuando con los modelos requeridos ya instalados"
                fi
            fi
        fi
    else
        echo "⏰ Tiempo insuficiente para modelos adicionales"
        echo "   Los modelos requeridos ya fueron instalados"
    fi

    # Save configuration (allow to fail gracefully)
    if ! save_config "$RECOMMENDED_MODEL"; then
        echo "⚠️  No se pudo guardar la configuración, pero continuando..."
    fi

    echo ""
    echo "🎉 Configuración de MSN-AI Docker completada"
    echo "============================================="
    echo ""
    echo "📊 RESUMEN DE MODELOS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Show installed local models
    echo ""
    echo "✅ Modelos locales instalados:"
    if curl -s "http://${OLLAMA_HOST}/api/tags" 2>/dev/null | grep -q "\"name\""; then
        curl -s "http://${OLLAMA_HOST}/api/tags" 2>/dev/null | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | while read model; do
            if [[ ! "$model" == *"-cloud"* ]]; then
                echo "   📦 $model"
            fi
        done
    else
        echo "   (ninguno aún)"
    fi

    # Show cloud models information
    echo ""
    echo "☁️  Modelos cloud (requieren signin):"
    local cloud_models=("qwen3-vl:235b-cloud" "gpt-oss:120b-cloud" "qwen3-coder:480b-cloud")
    for model in "${cloud_models[@]}"; do
        if curl -s "http://${OLLAMA_HOST}/api/tags" 2>/dev/null | grep -q "\"name\":\"$model"; then
            echo "   ✅ $model (instalado)"
        else
            echo "   ⏭️  $model (pendiente - requiere signin manual)"
        fi
    done

    echo ""
    echo "🤖 Modelo adicional recomendado: $RECOMMENDED_MODEL"
    echo "🎯 Nivel: $RECOMMENDED_LEVEL"
    echo "⚖️ Licencia: GPL-3.0"
    echo "🐳 Host Ollama: $OLLAMA_HOST"
    echo "💾 Configuración: /app/data/config/ai-config.json"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 PARA USAR MODELOS CLOUD:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   docker exec -it msn-ai-ollama ollama signin"
    echo "   (Abre el enlace en tu navegador y aprueba)"
    echo "   docker exec -it msn-ai-ollama ollama pull qwen3-vl:235b-cloud"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⏱️  Tiempo total: $(($(date +%s) - start_time))s"
    echo ""
    echo "✅ MSN-AI está listo para usar (setup completado)"
    echo "   Los modelos pueden continuar descargándose en segundo plano"
    echo "============================================="
}

# Run main function with error handling
if main "$@"; then
    echo "✅ Setup finalizado exitosamente"
    exit 0
else
    echo "⚠️  Setup completado con advertencias, pero MSN-AI puede continuar"
    exit 0
fi
