#!/bin/bash

# MSN-AI - Test de Conectividad Remota
# =====================================
# 🎯 Por: Alan Mac-Arthur García Díaz
# ⚖️ Licencia: GPL-3.0
# 📧 alan.mac.arthur.garcia.diaz@gmail.com
# =====================================

echo "🌐 MSN-AI - Test de Conectividad Remota"
echo "======================================="
echo "🎯 Por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "======================================="
echo ""

# Obtener IP del servidor
SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="192.168.1.99"
    echo "⚠️ No se pudo detectar IP automáticamente, usando: $SERVER_IP"
else
    echo "🖥️ IP del servidor detectada: $SERVER_IP"
fi

echo ""
echo "🔍 Test 1: Verificando puertos abiertos"
echo "======================================="

# Test puerto 8000 (MSN-AI Web)
echo -n "🌐 Puerto 8000 (MSN-AI Web): "
if netstat -tuln | grep -q ":8000 "; then
    echo "✅ ABIERTO"
    WEB_STATUS="✅"
else
    echo "❌ CERRADO"
    WEB_STATUS="❌"
fi

# Test puerto 11434 (Ollama)
echo -n "🤖 Puerto 11434 (Ollama): "
if netstat -tuln | grep -q ":11434 "; then
    echo "✅ ABIERTO"
    OLLAMA_STATUS="✅"
else
    echo "❌ CERRADO"
    OLLAMA_STATUS="❌"
fi

echo ""
echo "🔍 Test 2: Conectividad HTTP"
echo "============================"

# Test MSN-AI Web
echo -n "🌐 MSN-AI Web (http://$SERVER_IP:8000): "
if curl -s --connect-timeout 5 "http://$SERVER_IP:8000/msn-ai.html" > /dev/null 2>&1; then
    echo "✅ ACCESIBLE"
    WEB_HTTP="✅"
else
    echo "❌ NO ACCESIBLE"
    WEB_HTTP="❌"
fi

# Test Ollama API
echo -n "🤖 Ollama API (http://$SERVER_IP:11434/api/tags): "
OLLAMA_RESPONSE=$(curl -s --connect-timeout 5 "http://$SERVER_IP:11434/api/tags" 2>/dev/null)
if [ $? -eq 0 ] && echo "$OLLAMA_RESPONSE" | grep -q "models"; then
    echo "✅ ACCESIBLE"
    OLLAMA_HTTP="✅"
    MODEL_COUNT=$(echo "$OLLAMA_RESPONSE" | grep -o '"name"' | wc -l)
    echo "   📦 Modelos disponibles: $MODEL_COUNT"
else
    echo "❌ NO ACCESIBLE"
    OLLAMA_HTTP="❌"
fi

echo ""
echo "🔍 Test 3: Configuración de red"
echo "==============================="

# Test firewall
echo -n "🔥 Estado del firewall: "
if command -v ufw >/dev/null 2>&1; then
    UFW_STATUS=$(ufw status 2>/dev/null | head -1)
    if echo "$UFW_STATUS" | grep -q "inactive"; then
        echo "✅ DESACTIVADO (permitirá conexiones)"
    else
        echo "⚠️ ACTIVO - revisar reglas"
        echo "   💡 Para permitir acceso remoto:"
        echo "   sudo ufw allow 8000"
        echo "   sudo ufw allow 11434"
    fi
else
    echo "❓ UFW no instalado"
fi

# Test conectividad desde localhost
echo -n "🏠 Conectividad localhost: "
if curl -s --connect-timeout 3 "http://localhost:11434/api/tags" > /dev/null 2>&1; then
    echo "✅ FUNCIONA"
else
    echo "❌ FALLA"
fi

echo ""
echo "🔍 Test 4: Diagnóstico de contenedores"
echo "======================================"

if command -v docker >/dev/null 2>&1; then
    echo "📦 Estado de contenedores MSN-AI:"
    docker ps --filter "name=msn-ai" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | head -10
    echo ""

    # Verificar health de contenedores
    echo "🏥 Health checks:"
    for container in msn-ai-app msn-ai-ollama; do
        if docker ps --filter "name=$container" --format "{{.Names}}" | grep -q "$container"; then
            HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "sin-health-check")
            echo "   $container: $HEALTH"
        fi
    done
else
    echo "❌ Docker no disponible"
fi

echo ""
echo "📋 RESUMEN DE CONECTIVIDAD"
echo "========================="
echo "🌐 MSN-AI Web:"
echo "   Puerto: $WEB_STATUS | HTTP: $WEB_HTTP"
echo "   URL: http://$SERVER_IP:8000/msn-ai.html"
echo ""
echo "🤖 Ollama API:"
echo "   Puerto: $OLLAMA_STATUS | HTTP: $OLLAMA_HTTP"
echo "   URL: http://$SERVER_IP:11434/api/tags"
echo ""

# URLs de acceso
echo "🔗 URLs DE ACCESO"
echo "================="
echo "📱 Desde la red local:"
echo "   http://$SERVER_IP:8000/msn-ai.html"
echo ""
echo "🖥️ Desde el servidor (localhost):"
echo "   http://localhost:8000/msn-ai.html"
echo ""

# Consejos de resolución
if [ "$WEB_HTTP" != "✅" ] || [ "$OLLAMA_HTTP" != "✅" ]; then
    echo "🛠️ PASOS PARA SOLUCIONAR PROBLEMAS"
    echo "=================================="

    if [ "$WEB_HTTP" != "✅" ]; then
        echo "❌ MSN-AI Web no accesible:"
        echo "   1. Verificar contenedores: docker ps"
        echo "   2. Ver logs: docker logs msn-ai-app"
        echo "   3. Reiniciar: docker restart msn-ai-app"
    fi

    if [ "$OLLAMA_HTTP" != "✅" ]; then
        echo "❌ Ollama API no accesible:"
        echo "   1. Verificar contenedor: docker ps | grep ollama"
        echo "   2. Ver logs: docker logs msn-ai-ollama"
        echo "   3. Test manual: curl http://$SERVER_IP:11434/api/tags"
        echo "   4. Reiniciar: docker restart msn-ai-ollama"
    fi

    echo ""
    echo "🔥 Si hay problemas de firewall:"
    echo "   sudo ufw allow 8000"
    echo "   sudo ufw allow 11434"
    echo "   # O desactivar temporalmente: sudo ufw disable"
fi

echo ""
echo "📞 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
echo "🔧 MSN-AI Remote Connection Test v1.0.0"
