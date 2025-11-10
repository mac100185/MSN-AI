#!/bin/bash
# MSN-AI Docker - Cloud Models Installation Helper
# Version: 1.0.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Helper script to install Ollama cloud models with signin

echo "☁️  MSN-AI - Instalador de Modelos Cloud"
echo "=========================================="
echo "📧 Desarrollado por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "=========================================="
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado"
    exit 1
fi

# Check if msn-ai-ollama container is running
if ! docker ps --format '{{.Names}}' | grep -q "^msn-ai-ollama$"; then
    echo "❌ El contenedor msn-ai-ollama no está en ejecución"
    echo ""
    echo "💡 Inicia MSN-AI primero:"
    echo "   bash linux/start-msnai-docker.sh"
    exit 1
fi

echo "✅ Contenedor msn-ai-ollama detectado"
echo ""

# Available cloud models
CLOUD_MODELS=(
    "qwen3-vl:235b-cloud"
    "gpt-oss:120b-cloud"
    "qwen3-coder:480b-cloud"
    "deepseek-v3.1:671b-cloud"
    "gpt-oss:20b-cloud"
    "qwen3-vl:235b-instruct-cloud"
    "minimax-m2:cloud"
    "kimi-k2:1t-cloud"
    "kimi-k2-thinking:cloud"
)

echo "📦 Modelos cloud disponibles:"
for i in "${!CLOUD_MODELS[@]}"; do
    echo "   $((i+1)). ${CLOUD_MODELS[$i]}"
done
echo ""

# Check signin status
echo "🔍 Verificando estado de autenticación..."
SIGNIN_STATUS=$(docker exec msn-ai-ollama ollama list 2>&1)

# Try to verify signin with a cloud model check
echo "🔍 Verificando acceso a modelos cloud..."
CLOUD_TEST=$(docker exec msn-ai-ollama ollama show qwen3-vl:235b-cloud 2>&1)

NEEDS_SIGNIN=false
if echo "$SIGNIN_STATUS" | grep -q "You need to be signed in"; then
    NEEDS_SIGNIN=true
elif echo "$CLOUD_TEST" | grep -q "You need to be signed in"; then
    NEEDS_SIGNIN=true
fi

if [ "$NEEDS_SIGNIN" = true ]; then
    echo "⚠️  No has hecho signin con Ollama o la sesión expiró"
    echo ""
    echo "📋 PROCESO DE SIGNIN:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1️⃣  Este script generará un enlace de autenticación"
    echo ""
    echo "2️⃣  Abre el enlace en tu navegador"
    echo ""
    echo "3️⃣  Inicia sesión en ollama.com (crea cuenta si no tienes)"
    echo ""
    echo "4️⃣  Aprueba el acceso del contenedor"
    echo ""
    echo "5️⃣  Vuelve a esta ventana y espera la confirmación"
    echo ""
    echo "⚠️  IMPORTANTE: El signin puede expirar con el tiempo"
    echo "   Si los modelos dejan de funcionar, repite este proceso"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    read -p "¿Deseas hacer signin ahora? (s/N): " do_signin

    if [[ ! "$do_signin" =~ ^[sS]$ ]]; then
        echo "❌ Signin cancelado"
        echo ""
        echo "💡 Puedes hacer signin manualmente con:"
        echo "   docker exec -it msn-ai-ollama ollama signin"
        exit 0
    fi

    echo ""
    echo "🔑 Iniciando proceso de signin..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "⚠️  IMPORTANTE: Abre el enlace que aparecerá a continuación"
    echo "   en tu navegador para completar el signin"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    sleep 3

    # Run signin in interactive mode
    docker exec -it msn-ai-ollama ollama signin

    if [ $? -ne 0 ]; then
        echo ""
        echo "❌ Error durante el signin"
        echo ""
        echo "💡 Intenta manualmente:"
        echo "   docker exec -it msn-ai-ollama /bin/bash"
        echo "   ollama signin"
        exit 1
    fi

    echo ""
    echo "✅ Signin completado"
    echo ""

    # Wait a moment for signin to propagate
    echo "⏳ Esperando propagación del signin..."
    sleep 2

    # Verify signin worked
    VERIFY_TEST=$(docker exec msn-ai-ollama ollama list 2>&1)
    if echo "$VERIFY_TEST" | grep -q "You need to be signed in"; then
        echo ""
        echo "⚠️  Signin no se completó correctamente"
        echo "   Intenta de nuevo o verifica en el navegador"
        exit 1
    fi

    echo "✅ Signin verificado correctamente"
    echo ""
else
    echo "✅ Signin activo - acceso a modelos cloud disponible"
    echo ""
fi

# Check which models are already installed
echo "🔍 Verificando modelos instalados..."
INSTALLED_MODELS=$(docker exec msn-ai-ollama ollama list 2>&1)
echo ""

for model in "${CLOUD_MODELS[@]}"; do
    if echo "$INSTALLED_MODELS" | grep -q "$model"; then
        echo "   ✅ $model (ya instalado)"
    else
        echo "   ⏭️  $model (no instalado)"
    fi
done
echo ""

# Ask which models to install
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📥 INSTALACIÓN DE MODELOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "¿Qué deseas instalar?"
echo ""
echo "1) Instalar todos los modelos cloud"
echo "2) Instalar modelos individuales"
echo "3) Solo verificar modelos instalados"
echo "4) Salir"
echo ""
read -p "Selecciona una opción (1-4): " install_option

case $install_option in
    1)
        echo ""
        echo "📥 Instalando todos los modelos cloud..."
        echo ""

        for model in "${CLOUD_MODELS[@]}"; do
            if echo "$INSTALLED_MODELS" | grep -q "$model"; then
                echo "⏭️  Saltando $model (ya instalado)"
                echo ""
            else
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "📥 Instalando: $model"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                docker exec msn-ai-ollama ollama pull "$model"

                if [ $? -eq 0 ]; then
                    echo ""
                    echo "✅ $model instalado correctamente"
                    echo ""
                else
                    echo ""
                    echo "❌ Error instalando $model"
                    echo ""
                fi
            fi
        done
        ;;

    2)
        echo ""
        echo "📦 Selecciona los modelos a instalar:"
        echo ""

        for i in "${!CLOUD_MODELS[@]}"; do
            model="${CLOUD_MODELS[$i]}"

            if echo "$INSTALLED_MODELS" | grep -q "$model"; then
                echo "$((i+1)). $model (✅ ya instalado)"
            else
                echo "$((i+1)). $model"
            fi
        done
        echo ""

        read -p "Ingresa los números separados por espacio (ej: 1 3): " selected

        for num in $selected; do
            if [ "$num" -ge 1 ] && [ "$num" -le "${#CLOUD_MODELS[@]}" ]; then
                model="${CLOUD_MODELS[$((num-1))]}"

                if echo "$INSTALLED_MODELS" | grep -q "$model"; then
                    echo "⏭️  Saltando $model (ya instalado)"
                    echo ""
                else
                    echo ""
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo "📥 Instalando: $model"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo ""
                    docker exec msn-ai-ollama ollama pull "$model"

                    if [ $? -eq 0 ]; then
                        echo ""
                        echo "✅ $model instalado correctamente"
                        echo ""
                    else
                        echo ""
                        echo "❌ Error instalando $model"
                        echo ""
                    fi
                fi
            fi
        done
        ;;

    3)
        echo ""
        echo "📊 Modelos instalados actualmente:"
        echo ""
        docker exec msn-ai-ollama ollama list
        echo ""
        ;;

    4)
        echo ""
        echo "👋 Saliendo..."
        exit 0
        ;;

    *)
        echo ""
        echo "❌ Opción no válida"
        exit 1
        ;;
esac

# Show final status
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 ESTADO FINAL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Modelos instalados:"
docker exec msn-ai-ollama ollama list
echo ""

# Verify cloud models can actually be accessed
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 VERIFICACIÓN DE ACCESO A MODELOS CLOUD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CLOUD_ACCESS_OK=true
for model in "${CLOUD_MODELS[@]}"; do
    # Check if model is installed
    if docker exec msn-ai-ollama ollama list 2>&1 | grep -q "$model"; then
        # Verify signin is active for this model
        TEST_RESULT=$(docker exec msn-ai-ollama ollama show "$model" 2>&1)
        if echo "$TEST_RESULT" | grep -q "You need to be signed in"; then
            echo "❌ $model - Signin requerido (no funcional)"
            CLOUD_ACCESS_OK=false
        else
            echo "✅ $model - Accesible y funcional"
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$CLOUD_ACCESS_OK" = true ]; then
    echo "✅ Proceso completado - Todos los modelos funcionando"
else
    echo "⚠️  Proceso completado - Signin adicional requerido"
    echo ""
    echo "Los modelos están instalados pero necesitas signin activo:"
    echo "   docker exec -it msn-ai-ollama ollama signin"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Los modelos cloud ahora están disponibles en MSN-AI"
echo ""
echo "⚠️  IMPORTANTE: Si los modelos dejan de funcionar:"
echo "   1. Verifica signin: docker exec msn-ai-ollama ollama list"
echo "   2. Si dice 'You need to be signed in', ejecuta:"
echo "      docker exec -it msn-ai-ollama ollama signin"
echo ""
echo "🌐 Accede a MSN-AI en: http://localhost:8000/msn-ai.html"
echo ""
