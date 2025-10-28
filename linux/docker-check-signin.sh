#!/bin/bash
# MSN-AI Docker - Cloud Models Signin Status Checker
# Version: 1.0.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Check if Ollama signin is active for cloud models

echo "🔍 MSN-AI - Verificador de Signin de Modelos Cloud"
echo "===================================================="
echo "📧 Desarrollado por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "===================================================="
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

echo "✅ Contenedor msn-ai-ollama encontrado"
echo ""

# Check basic signin status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 VERIFICACIÓN DE SIGNIN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SIGNIN_CHECK=$(docker exec msn-ai-ollama ollama list 2>&1)

if echo "$SIGNIN_CHECK" | grep -q "You need to be signed in"; then
    echo "❌ NO has hecho signin con Ollama"
    echo ""
    SIGNIN_REQUIRED=true
else
    echo "✅ Signin básico detectado"
    echo ""
    SIGNIN_REQUIRED=false
fi

# Check cloud models status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "☁️  ESTADO DE MODELOS CLOUD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CLOUD_MODELS=(
    "qwen3-vl:235b-cloud"
    "gpt-oss:120b-cloud"
    "qwen3-coder:480b-cloud"
)

INSTALLED_MODELS=$(docker exec msn-ai-ollama ollama list 2>&1)

CLOUD_MODELS_INSTALLED=false
ALL_CLOUD_WORKING=true

for model in "${CLOUD_MODELS[@]}"; do
    if echo "$INSTALLED_MODELS" | grep -q "$model"; then
        CLOUD_MODELS_INSTALLED=true
        echo -n "📦 $model - "

        # Test if model is accessible
        TEST_RESULT=$(docker exec msn-ai-ollama ollama show "$model" 2>&1)

        if echo "$TEST_RESULT" | grep -q "You need to be signed in"; then
            echo "❌ Signin requerido (no funcional)"
            ALL_CLOUD_WORKING=false
        elif echo "$TEST_RESULT" | grep -q "error"; then
            echo "⚠️  Error al verificar"
            ALL_CLOUD_WORKING=false
        else
            echo "✅ Funcional"
        fi
    else
        echo "⏭️  $model - No instalado"
    fi
done

echo ""

# Final status and recommendations
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 DIAGNÓSTICO FINAL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$SIGNIN_REQUIRED" = true ]; then
    echo "🔴 ESTADO: Signin requerido"
    echo ""
    echo "🔧 SOLUCIÓN:"
    echo "   1. Ejecuta el signin interactivo:"
    echo "      docker exec -it msn-ai-ollama ollama signin"
    echo ""
    echo "   2. Abre el enlace generado en tu navegador"
    echo ""
    echo "   3. Aprueba el acceso a tu cuenta de Ollama"
    echo ""
    echo "   4. Vuelve a ejecutar este script para verificar"
    echo ""
elif [ "$CLOUD_MODELS_INSTALLED" = false ]; then
    echo "🟡 ESTADO: Sin modelos cloud instalados"
    echo ""
    echo "💡 Para instalar modelos cloud:"
    echo "   bash linux/docker-install-cloud-models.sh"
    echo ""
elif [ "$ALL_CLOUD_WORKING" = false ]; then
    echo "🟠 ESTADO: Modelos instalados pero signin inactivo"
    echo ""
    echo "⚠️  Los modelos cloud están instalados pero no funcionan"
    echo "   porque el signin expiró o no está activo"
    echo ""
    echo "🔧 SOLUCIÓN:"
    echo "   docker exec -it msn-ai-ollama ollama signin"
    echo ""
    echo "   (Abre el enlace generado y aprueba el acceso)"
    echo ""
else
    echo "🟢 ESTADO: Todo funcionando correctamente"
    echo ""
    echo "✅ Signin activo"
    echo "✅ Modelos cloud instalados"
    echo "✅ Todos los modelos accesibles"
    echo ""
    echo "💡 Si encuentras problemas usando los modelos:"
    echo "   1. Verifica la conexión a internet"
    echo "   2. Revisa los logs: docker logs msn-ai-ollama"
    echo "   3. Reinicia Ollama: docker restart msn-ai-ollama"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 COMANDOS ÚTILES:"
echo ""
echo "   Ver todos los modelos instalados:"
echo "   docker exec msn-ai-ollama ollama list"
echo ""
echo "   Hacer signin:"
echo "   docker exec -it msn-ai-ollama ollama signin"
echo ""
echo "   Instalar modelos cloud:"
echo "   bash linux/docker-install-cloud-models.sh"
echo ""
echo "   Verificar modelo específico:"
echo "   docker exec msn-ai-ollama ollama show qwen3-vl:235b-cloud"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Exit with appropriate code
if [ "$SIGNIN_REQUIRED" = true ] || [ "$ALL_CLOUD_WORKING" = false ]; then
    exit 1
else
    exit 0
fi
