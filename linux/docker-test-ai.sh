#!/bin/bash
# MSN-AI Docker AI Test Script
# Version: 1.1.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Test script to verify AI functionality is working correctly

echo "🤖 MSN-AI Docker - Test de IA"
echo "============================="
echo "📧 Por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "============================="

# Detect and change to project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT" || {
    echo "❌ Error: No se pudo cambiar al directorio del proyecto"
    exit 1
}

# Verify we're in the correct directory
if [ ! -f "docker/docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml no encontrado"
    echo "   Estructura del proyecto incorrecta"
    exit 1
fi

# Function to detect Docker Compose command
detect_compose_command() {
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    elif docker compose version &> /dev/null 2>&1; then
        echo "docker compose"
    else
        echo ""
    fi
}

# Get Docker Compose command
COMPOSE_CMD=$(detect_compose_command)

if [ -z "$COMPOSE_CMD" ]; then
    echo "❌ Docker Compose no disponible"
    echo "   Verifica tu instalación de Docker"
    exit 1
fi

echo ""
echo "🔍 Verificando estado de contenedores..."

# Check container status
CONTAINERS_STATUS=$($COMPOSE_CMD -f docker/docker-compose.yml ps --format "json" 2>/dev/null)
if [ $? -ne 0 ]; then
    # Fallback for older compose versions
    echo "📊 Estado de contenedores:"
    $COMPOSE_CMD -f docker/docker-compose.yml ps
else
    echo "📊 Estado de contenedores MSN-AI:"
    $COMPOSE_CMD -f docker/docker-compose.yml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
fi

echo ""

# Test 1: Check if Ollama is responding
echo "🧪 Test 1: Conectividad básica con Ollama"
echo "========================================="

if curl -s --connect-timeout 5 http://localhost:11434/ >/dev/null 2>&1; then
    echo "✅ Ollama responde en puerto 11434"
else
    echo "❌ Ollama no responde en puerto 11434"
    echo "💡 Solución:"
    echo "   1. Verifica que el contenedor ollama esté ejecutándose"
    echo "   2. Ejecuta: ./docker-logs.sh --service ollama"
    echo "   3. Reinicia servicios: ./docker-start.sh --build"
    exit 1
fi

# Test 2: Check API availability
echo ""
echo "🧪 Test 2: API de Ollama disponible"
echo "==================================="

API_RESPONSE=$(curl -s --connect-timeout 10 http://localhost:11434/api/tags 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$API_RESPONSE" ]; then
    echo "✅ API de Ollama responde correctamente"

    # Parse and show models
    MODELS_COUNT=$(echo "$API_RESPONSE" | grep -o '"name"' | wc -l 2>/dev/null || echo "0")
    echo "📦 Modelos detectados: $MODELS_COUNT"

    if [ "$MODELS_COUNT" -gt 0 ]; then
        echo "📋 Modelos disponibles:"
        echo "$API_RESPONSE" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | sed 's/^/   📦 /' || echo "   (No se pudieron listar)"
    fi
else
    echo "❌ API de Ollama no responde"
    echo "💡 El contenedor puede estar iniciando. Espera 1-2 minutos y vuelve a intentar."
    exit 1
fi

# Test 3: Test model functionality
echo ""
echo "🧪 Test 3: Funcionalidad del modelo de IA"
echo "========================================="

if [ "$MODELS_COUNT" -gt 0 ]; then
    # Get the first available model
    FIRST_MODEL=$(echo "$API_RESPONSE" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)

    if [ -n "$FIRST_MODEL" ]; then
        echo "🤖 Probando modelo: $FIRST_MODEL"
        echo "⏳ Enviando pregunta de prueba..."

        # Test the model with a simple Spanish prompt
        TEST_RESPONSE=$(curl -s --connect-timeout 30 -X POST \
            http://localhost:11434/api/generate \
            -H "Content-Type: application/json" \
            -d "{\"model\":\"$FIRST_MODEL\",\"prompt\":\"Hola, responde solo con: Funciono correctamente\",\"stream\":false}" 2>/dev/null)

        if [ $? -eq 0 ] && echo "$TEST_RESPONSE" | grep -q '"response"'; then
            echo "✅ El modelo responde correctamente"

            # Extract and show response
            AI_RESPONSE=$(echo "$TEST_RESPONSE" | grep -o '"response":"[^"]*"' | cut -d'"' -f4 | head -c 200)
            if [ -n "$AI_RESPONSE" ]; then
                echo "🤖 Respuesta de prueba:"
                echo "   \"$AI_RESPONSE\""
            fi

            # Show performance metrics if available
            EVAL_COUNT=$(echo "$TEST_RESPONSE" | grep -o '"eval_count":[0-9]*' | cut -d':' -f2)
            EVAL_DURATION=$(echo "$TEST_RESPONSE" | grep -o '"eval_duration":[0-9]*' | cut -d':' -f2)

            if [ -n "$EVAL_COUNT" ] && [ -n "$EVAL_DURATION" ]; then
                TOKENS_PER_SEC=$(echo "scale=2; $EVAL_COUNT * 1000000000 / $EVAL_DURATION" | bc 2>/dev/null || echo "N/A")
                echo "📊 Rendimiento:"
                echo "   🔢 Tokens generados: $EVAL_COUNT"
                echo "   ⚡ Velocidad: $TOKENS_PER_SEC tokens/segundo"
            fi
        else
            echo "⚠️ El modelo no responde correctamente"
            echo "💡 Esto puede ser normal si:"
            echo "   - El modelo se está cargando por primera vez"
            echo "   - El sistema tiene poca RAM/CPU"
            echo "   - El modelo está siendo descargado aún"
        fi
    fi
else
    echo "❌ No hay modelos disponibles para probar"
    echo "💡 El contenedor ai-setup puede estar aún configurando."
    echo "   Ejecuta: ./docker-logs.sh --service ai-setup"
fi

# Test 4: Check MSN-AI web application
echo ""
echo "🧪 Test 4: Aplicación web MSN-AI"
echo "================================"

if curl -s --connect-timeout 5 http://localhost:8000/msn-ai.html >/dev/null 2>&1; then
    echo "✅ MSN-AI web accesible en http://localhost:8000/msn-ai.html"
else
    echo "❌ MSN-AI web no accesible"
    echo "💡 Verifica que el contenedor msn-ai esté ejecutándose"
fi

# Test 5: Check configuration files
echo ""
echo "🧪 Test 5: Archivos de configuración"
echo "==================================="

CONFIG_EXISTS=$(docker exec msn-ai-app test -f /app/data/config/ai-config.json && echo "yes" || echo "no")
if [ "$CONFIG_EXISTS" = "yes" ]; then
    echo "✅ Archivo de configuración existe"

    # Try to read configuration
    CONFIG_CONTENT=$(docker exec msn-ai-app cat /app/data/config/ai-config.json 2>/dev/null)
    if [ -n "$CONFIG_CONTENT" ]; then
        CONFIGURED_MODEL=$(echo "$CONFIG_CONTENT" | grep -o '"recommended_model":"[^"]*"' | cut -d'"' -f4)
        SETUP_DATE=$(echo "$CONFIG_CONTENT" | grep -o '"setup_date":"[^"]*"' | cut -d'"' -f4)

        echo "📋 Configuración detectada:"
        echo "   🤖 Modelo configurado: ${CONFIGURED_MODEL:-N/A}"
        echo "   📅 Fecha de setup: ${SETUP_DATE:-N/A}"
    fi
else
    echo "⚠️ Archivo de configuración no encontrado"
    echo "💡 El contenedor ai-setup puede no haber completado la configuración"
fi

# Summary and recommendations
echo ""
echo "📊 RESUMEN DEL TEST"
echo "=================="

# Count successful tests
TESTS_PASSED=0

curl -s --connect-timeout 5 http://localhost:11434/ >/dev/null 2>&1 && TESTS_PASSED=$((TESTS_PASSED + 1))
curl -s --connect-timeout 10 http://localhost:11434/api/tags >/dev/null 2>&1 && [ "$MODELS_COUNT" -gt 0 ] && TESTS_PASSED=$((TESTS_PASSED + 1))
curl -s --connect-timeout 5 http://localhost:8000/msn-ai.html >/dev/null 2>&1 && TESTS_PASSED=$((TESTS_PASSED + 1))

echo "✅ Tests exitosos: $TESTS_PASSED/3"

if [ $TESTS_PASSED -eq 3 ]; then
    echo ""
    echo "🎉 ¡MSN-AI está funcionando correctamente!"
    echo "========================================="
    echo "✅ Todos los componentes están operativos"
    echo "✅ La IA está disponible y responde"
    echo "✅ La aplicación web está accesible"
    echo ""
    echo "🌐 Accede a MSN-AI:"
    echo "   http://localhost:8000/msn-ai.html"
    echo ""
    echo "💡 Consejos de uso:"
    echo "   1. Crea un nuevo chat con el botón '+'"
    echo "   2. Escribe tu mensaje y presiona Enter"
    echo "   3. La IA responderá usando el modelo: ${FIRST_MODEL:-configurado}"
    echo "   4. Tus chats se guardan automáticamente"
elif [ $TESTS_PASSED -eq 2 ]; then
    echo ""
    echo "⚠️ MSN-AI está parcialmente funcionando"
    echo "======================================"
    echo "💡 La mayoría de componentes están bien, pero hay algunos problemas menores"
    echo "   Revisa los errores anteriores para más detalles"
elif [ $TESTS_PASSED -eq 1 ]; then
    echo ""
    echo "❌ MSN-AI tiene problemas significativos"
    echo "======================================"
    echo "💡 Soluciones recomendadas:"
    echo "   ./docker-logs.sh --follow     # Ver qué está pasando"
    echo "   ./docker-start.sh --build     # Reconstruir servicios"
else
    echo ""
    echo "🚨 MSN-AI no está funcionando"
    echo "============================"
    echo "💡 Soluciones de emergencia:"
    echo "   ./docker-stop.sh              # Detener todo"
    echo "   ./docker-cleanup.sh --all     # Limpiar completamente"
    echo "   ./docker-start.sh --build     # Reinstalar desde cero"
fi

echo ""
echo "🔧 Comandos útiles:"
echo "   ./docker-status.sh --detailed  # Estado detallado"
echo "   ./docker-logs.sh --service ollama    # Logs de IA"
echo "   ./docker-logs.sh --service msn-ai    # Logs de aplicación"
echo ""
echo "📧 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
echo "🤖 MSN-AI Docker AI Test v1.1.0"
