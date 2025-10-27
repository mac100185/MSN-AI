#!/bin/bash
# MSN-AI Docker Configuration Check Script
# Version: 1.1.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Check if AI configuration was saved properly and troubleshoot issues

echo "🔧 MSN-AI Docker - Verificador de Configuración"
echo "==============================================="
echo "📧 Por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "==============================================="

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
echo "🔍 Verificando configuración de MSN-AI..."

# Check if containers are running
echo ""
echo "📊 Estado de contenedores:"
$COMPOSE_CMD -f docker/docker-compose.yml ps

# Check configuration file
echo ""
echo "🔧 Verificando archivo de configuración..."

CONFIG_EXISTS=$(docker exec msn-ai-app test -f /app/data/config/ai-config.json 2>/dev/null && echo "yes" || echo "no")

if [ "$CONFIG_EXISTS" = "yes" ]; then
    echo "✅ Archivo de configuración encontrado"

    # Read and parse configuration
    CONFIG_CONTENT=$(docker exec msn-ai-app cat /app/data/config/ai-config.json 2>/dev/null)

    if [ -n "$CONFIG_CONTENT" ]; then
        echo "📋 Contenido de la configuración:"
        echo "$CONFIG_CONTENT" | jq . 2>/dev/null || echo "$CONFIG_CONTENT"

        # Extract key information
        echo ""
        echo "📝 Información extraída:"
        RECOMMENDED_MODEL=$(echo "$CONFIG_CONTENT" | grep -o '"recommended_model":"[^"]*"' | cut -d'"' -f4)
        SETUP_DATE=$(echo "$CONFIG_CONTENT" | grep -o '"setup_date":"[^"]*"' | cut -d'"' -f4)
        CPU_CORES=$(echo "$CONFIG_CONTENT" | grep -o '"cpu_cores":[0-9]*' | cut -d':' -f2)
        RAM_GB=$(echo "$CONFIG_CONTENT" | grep -o '"ram_gb":[0-9]*' | cut -d':' -f2)
        LEVEL=$(echo "$CONFIG_CONTENT" | grep -o '"level":"[^"]*"' | cut -d'"' -f4)

        echo "   🤖 Modelo recomendado: ${RECOMMENDED_MODEL:-No encontrado}"
        echo "   📅 Fecha de configuración: ${SETUP_DATE:-No encontrada}"
        echo "   🖥️  CPU Cores: ${CPU_CORES:-No detectado}"
        echo "   💾 RAM GB: ${RAM_GB:-No detectada}"
        echo "   🎯 Nivel: ${LEVEL:-No definido}"

        # Verify model matches hardware
        if [ -n "$CPU_CORES" ] && [ -n "$RAM_GB" ]; then
            echo ""
            echo "🧠 Verificando lógica de selección de modelo..."

            if [ "$RAM_GB" -lt 8 ] && [ "$RECOMMENDED_MODEL" = "tinyllama" ]; then
                echo "✅ Modelo correcto para RAM limitada ($RAM_GB GB)"
            elif [ "$RAM_GB" -ge 8 ] && [ "$RAM_GB" -lt 16 ] && [ "$RECOMMENDED_MODEL" = "phi3:mini" ]; then
                echo "✅ Modelo correcto para RAM media ($RAM_GB GB)"
            elif [ "$RAM_GB" -ge 16 ] && [ "$RECOMMENDED_MODEL" = "mistral:7b" ]; then
                echo "✅ Modelo correcto para RAM alta ($RAM_GB GB)"
            else
                echo "⚠️ Modelo puede no ser óptimo para el hardware detectado"
                echo "   Hardware: ${CPU_CORES} cores, ${RAM_GB}GB RAM"
                echo "   Modelo seleccionado: $RECOMMENDED_MODEL"
            fi
        fi
    else
        echo "❌ Archivo de configuración está vacío"
    fi
else
    echo "❌ Archivo de configuración no encontrado"
    echo "💡 Esto indica que ai-setup no completó correctamente"
fi

# Check if model is actually available in Ollama
echo ""
echo "🤖 Verificando modelo en Ollama..."

OLLAMA_MODELS=$(curl -s --connect-timeout 10 http://localhost:11434/api/tags 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$OLLAMA_MODELS" ]; then
    MODELS_COUNT=$(echo "$OLLAMA_MODELS" | grep -o '"name"' | wc -l)
    echo "✅ Ollama responde, $MODELS_COUNT modelos disponibles:"

    if [ "$MODELS_COUNT" -gt 0 ]; then
        echo "$OLLAMA_MODELS" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | sed 's/^/   📦 /'

        # Check if configured model matches available models
        if [ -n "$RECOMMENDED_MODEL" ]; then
            if echo "$OLLAMA_MODELS" | grep -q "\"$RECOMMENDED_MODEL\""; then
                echo "✅ Modelo configurado '$RECOMMENDED_MODEL' está disponible en Ollama"
            else
                echo "❌ Modelo configurado '$RECOMMENDED_MODEL' NO está en Ollama"
                echo "💡 Posibles causas:"
                echo "   - La instalación del modelo falló"
                echo "   - El modelo se eliminó accidentalmente"
                echo "   - Hay un error de configuración"
            fi
        fi
    else
        echo "❌ No hay modelos en Ollama"
    fi
else
    echo "❌ No se puede conectar con Ollama"
fi

# Check ai-setup container logs for errors
echo ""
echo "📋 Verificando logs de ai-setup..."

AI_SETUP_LOGS=$(docker logs msn-ai-setup 2>/dev/null | tail -20)
if [ -n "$AI_SETUP_LOGS" ]; then
    echo "📄 Últimas líneas de ai-setup:"
    echo "$AI_SETUP_LOGS" | sed 's/^/   /'

    # Check for common error patterns
    if echo "$AI_SETUP_LOGS" | grep -q "ERROR\|Error\|error\|FAILED\|Failed\|failed"; then
        echo "⚠️ Se encontraron errores en los logs de ai-setup"
    elif echo "$AI_SETUP_LOGS" | grep -q "completada\|exitosa\|listo"; then
        echo "✅ ai-setup completó exitosamente según los logs"
    fi
else
    echo "⚠️ No se pudieron obtener logs de ai-setup"
fi

# Summary and recommendations
echo ""
echo "📊 RESUMEN DE VERIFICACIÓN"
echo "========================="

# Count issues
ISSUES=0

[ "$CONFIG_EXISTS" != "yes" ] && ISSUES=$((ISSUES + 1))
[ -z "$RECOMMENDED_MODEL" ] && ISSUES=$((ISSUES + 1))
[ "$MODELS_COUNT" -eq 0 ] && ISSUES=$((ISSUES + 1))

if [ $ISSUES -eq 0 ]; then
    echo "✅ La configuración parece estar correcta"
    echo ""
    echo "🎉 MSN-AI debería estar funcionando correctamente"
    echo "💡 Si tienes problemas en la interfaz web:"
    echo "   1. Verifica que puedes acceder: http://localhost:8000/msn-ai.html"
    echo "   2. Abre las herramientas de desarrollador (F12)"
    echo "   3. Revisa la consola en busca de errores JavaScript"
    echo "   4. Intenta crear un nuevo chat y enviar un mensaje"
elif [ $ISSUES -eq 1 ]; then
    echo "⚠️ Se encontró 1 problema menor"
    echo "💡 La aplicación puede funcionar con limitaciones"
else
    echo "❌ Se encontraron $ISSUES problemas"
    echo "💡 Soluciones recomendadas:"
fi

# Provide specific solutions
if [ "$CONFIG_EXISTS" != "yes" ] || [ -z "$RECOMMENDED_MODEL" ]; then
    echo ""
    echo "🔧 Problema de configuración detectado:"
    echo "   ./docker-logs.sh --service ai-setup  # Ver qué falló"
    echo "   docker exec -it msn-ai-setup /app/docker/scripts/ai-setup-docker.sh  # Reejecutar setup"
fi

if [ "$MODELS_COUNT" -eq 0 ]; then
    echo ""
    echo "🤖 Problema con modelos de IA:"
    echo "   docker exec -it msn-ai-ollama ollama pull tinyllama  # Instalar modelo básico"
    echo "   # O el modelo que prefieras según tu hardware"
fi

echo ""
echo "🛠️ Comandos de diagnóstico adicionales:"
echo "   ./docker-test-ai.sh           # Test completo de IA"
echo "   ./docker-status.sh --detailed # Estado detallado"
echo "   ./docker-logs.sh --follow     # Logs en tiempo real"

echo ""
echo "🔧 MSN-AI Docker Config Check v1.1.0"
echo "📧 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
