#!/bin/bash
# AI Setup Script for MSN-AI Docker Container
# Version: 2.1.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Hardware detection and AI model setup for Docker environment

set -e

echo "🤖 MSN-AI Docker - Configuración de IA"
echo "======================================"
echo "📧 Desarrollado por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "🐳 Modo: Docker Container"
echo "======================================"

# Environment variables
OLLAMA_HOST=${OLLAMA_HOST:-ollama:11434}
SETUP_TIMEOUT=${SETUP_TIMEOUT:-300}  # 5 minutes timeout
MAX_RETRIES=${MAX_RETRIES:-10}       # Maximum connection retries

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

    # Use curl to pull the model via Ollama API with streaming
    echo "🔄 Iniciando descarga con progreso..."

    # Start the pull operation with streaming to show progress
    local pull_success=false
    local temp_file="/tmp/ollama_pull_$$.json"

    # Make the pull request and capture the response
    if curl -s -X POST "http://${OLLAMA_HOST}/api/pull" \
        -H "Content-Type: application/json" \
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
        exit 1
    fi

    # Check timeout
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    if [ $elapsed -ge $SETUP_TIMEOUT ]; then
        echo "⏰ Timeout alcanzado durante la conexión inicial"
        exit 1
    fi

    # Detect hardware
    detect_hardware

    # Recommend optimal model
    recommend_model

    # Check if models already exist
    if check_existing_models; then
        echo "ℹ️  Modelos existentes encontrados"
        echo "   Configuración automática: Usando modelo existente"
        echo "   Modelo recomendado para este hardware: $RECOMMENDED_MODEL"
    else
        echo "📦 No se encontraron modelos, instalando: $RECOMMENDED_MODEL"

        # Check timeout before starting model installation
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        if [ $elapsed -ge $((SETUP_TIMEOUT - 60)) ]; then
            echo "⏰ Tiempo insuficiente para instalar modelo, usando modelo básico"
            RECOMMENDED_MODEL="phi3:mini"
        fi

        if install_model "$RECOMMENDED_MODEL"; then
            echo "✅ Instalación exitosa"

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
            echo "❌ Error en la instalación del modelo principal"
            echo "   Intentando con modelo de respaldo: phi3:mini"

            if install_model "phi3:mini"; then
                RECOMMENDED_MODEL="phi3:mini"
                RECOMMENDED_LEVEL="Básico (modelo de respaldo)"
                echo "✅ Modelo de respaldo instalado correctamente"
            else
                echo "❌ Error instalando modelo de respaldo"
                echo "   MSN-AI funcionará sin modelo preinstalado"
                echo "   Puedes instalar modelos manualmente desde la interfaz"
            fi
        fi
    fi

    # Save configuration
    save_config "$RECOMMENDED_MODEL"

    echo ""
    echo "🎉 Configuración de MSN-AI Docker completada"
    echo "============================================="
    echo "🤖 Modelo configurado: $RECOMMENDED_MODEL"
    echo "🎯 Nivel: $RECOMMENDED_LEVEL"
    echo "🐳 Host Ollama: $OLLAMA_HOST"
    echo "💾 Configuración: /app/data/config/ai-config.json"
    echo "⏱️  Tiempo total: $(($(date +%s) - start_time))s"
    echo ""
    echo "💡 MSN-AI está listo para usar"
    echo "============================================="
}

# Run main function
main "$@"
