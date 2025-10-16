#!/bin/bash

# MSN-AI - Test de Detección de Modelos
# ====================================
# 🎯 Por: Alan Mac-Arthur García Díaz
# ⚖️ Licencia: GPL-3.0
# 📧 alan.mac.arthur.garcia.diaz@gmail.com
# ====================================

echo "🧪 MSN-AI - Test de Detección de Modelos"
echo "========================================"
echo "🎯 Por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "========================================"
echo ""

# Detectar IP del servidor
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
echo "🖥️ Servidor: $(hostname) ($SERVER_IP)"
echo ""

echo "🔍 Test 1: Verificar Ollama funcionando"
echo "========================================"

# Test básico de Ollama
echo -n "🤖 Ollama ejecutándose: "
if pgrep -f ollama >/dev/null 2>&1; then
    echo "✅ SÍ"
    OLLAMA_RUNNING=true
else
    echo "❌ NO"
    OLLAMA_RUNNING=false
fi

# Test API local
echo -n "📡 API Ollama local (localhost:11434): "
if curl -s --connect-timeout 3 "http://localhost:11434/api/tags" >/dev/null 2>&1; then
    echo "✅ ACCESIBLE"
    LOCAL_API=true

    # Obtener modelos
    MODELS_JSON=$(curl -s "http://localhost:11434/api/tags" 2>/dev/null)
    MODEL_COUNT=$(echo "$MODELS_JSON" | grep -o '"name"' | wc -l 2>/dev/null || echo "0")
    echo "   📦 Modelos detectados: $MODEL_COUNT"

    if [ "$MODEL_COUNT" -gt 0 ]; then
        echo "   📋 Lista de modelos:"
        echo "$MODELS_JSON" | grep '"name"' | sed 's/.*"name": *"\([^"]*\)".*/   • \1/' 2>/dev/null || echo "   • Error parseando nombres"
    fi
else
    echo "❌ NO ACCESIBLE"
    LOCAL_API=false
fi

# Test API remoto (si no es localhost)
if [ "$SERVER_IP" != "localhost" ] && [ "$SERVER_IP" != "127.0.0.1" ]; then
    echo -n "🌐 API Ollama remoto (${SERVER_IP}:11434): "
    if curl -s --connect-timeout 3 "http://${SERVER_IP}:11434/api/tags" >/dev/null 2>&1; then
        echo "✅ ACCESIBLE"
        REMOTE_API=true
    else
        echo "❌ NO ACCESIBLE"
        REMOTE_API=false
    fi
else
    REMOTE_API=false
fi

echo ""
echo "🌐 Test 2: Verificar MSN-AI Web"
echo "==============================="

# Test local web
echo -n "🏠 MSN-AI local (localhost:8000): "
if curl -s --connect-timeout 3 "http://localhost:8000/msn-ai.html" >/dev/null 2>&1; then
    echo "✅ ACCESIBLE"
    LOCAL_WEB=true
else
    echo "❌ NO ACCESIBLE"
    LOCAL_WEB=false
fi

# Test remoto web
if [ "$SERVER_IP" != "localhost" ] && [ "$SERVER_IP" != "127.0.0.1" ]; then
    echo -n "🌐 MSN-AI remoto (${SERVER_IP}:8000): "
    if curl -s --connect-timeout 3 "http://${SERVER_IP}:8000/msn-ai.html" >/dev/null 2>&1; then
        echo "✅ ACCESIBLE"
        REMOTE_WEB=true
    else
        echo "❌ NO ACCESIBLE"
        REMOTE_WEB=false
    fi
else
    REMOTE_WEB=false
fi

echo ""
echo "🔧 Test 3: Verificar Configuración JavaScript"
echo "=============================================="

# Test de configuración automática
echo "📝 Configuración esperada por tipo de acceso:"

echo "   🏠 Acceso LOCAL (localhost):"
echo "      • URL Ollama esperada: http://localhost:11434"
echo "      • Auto-detección: DESACTIVADA"

if [ "$SERVER_IP" != "localhost" ] && [ "$SERVER_IP" != "127.0.0.1" ]; then
    echo "   🌐 Acceso REMOTO (${SERVER_IP}):"
    echo "      • URL Ollama esperada: http://${SERVER_IP}:11434"
    echo "      • Auto-detección: ACTIVADA"
fi

echo ""
echo "🧪 Test 4: Simulación de Detección de Modelos"
echo "=============================================="

if [ "$LOCAL_API" = true ]; then
    echo "✅ Simulando carga de modelos desde localhost:11434"

    # Simular el fetch que hace JavaScript
    echo "📡 Simulando: fetch('http://localhost:11434/api/tags')"

    RESPONSE=$(curl -s "http://localhost:11434/api/tags" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "✅ Respuesta recibida correctamente"
        echo "📦 Estructura de respuesta:"
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "   JSON válido pero no formateado"

        # Extraer nombres de modelos como lo haría JavaScript
        echo "🔍 Extrayendo nombres de modelos:"
        echo "$RESPONSE" | grep -o '"name":"[^"]*"' | sed 's/"name":"\([^"]*\)"/   • \1/' 2>/dev/null

    else
        echo "❌ Error en la simulación de fetch"
    fi
else
    echo "❌ No se puede simular - API local no disponible"
fi

echo ""
echo "📊 RESUMEN DEL DIAGNÓSTICO"
echo "=========================="

echo "🤖 Backend (Ollama):"
echo "   Proceso: $([ "$OLLAMA_RUNNING" = true ] && echo "✅ Ejecutándose" || echo "❌ Detenido")"
echo "   API Local: $([ "$LOCAL_API" = true ] && echo "✅ Funcionando" || echo "❌ Falla")"
echo "   API Remoto: $([ "$REMOTE_API" = true ] && echo "✅ Funcionando" || echo "❌ Falla/N/A")"
echo "   Modelos: $MODEL_COUNT encontrados"

echo ""
echo "🌐 Frontend (MSN-AI):"
echo "   Web Local: $([ "$LOCAL_WEB" = true ] && echo "✅ Funcionando" || echo "❌ Falla")"
echo "   Web Remoto: $([ "$REMOTE_WEB" = true ] && echo "✅ Funcionando" || echo "❌ Falla/N/A")"

echo ""
echo "🎯 DIAGNÓSTICO DE DETECCIÓN DE MODELOS"
echo "======================================"

if [ "$LOCAL_API" = true ] && [ "$MODEL_COUNT" -gt 0 ]; then
    echo "✅ DETECCIÓN DEBE FUNCIONAR"
    echo "   • Ollama API responde correctamente"
    echo "   • $MODEL_COUNT modelos disponibles"
    echo "   • JavaScript debería cargar la lista automáticamente"
    echo ""
    echo "💡 Si los modelos NO aparecen en MSN-AI:"
    echo "   1. Abrir consola del navegador (F12)"
    echo "   2. Buscar errores relacionados con fetch o CORS"
    echo "   3. Verificar que la URL Ollama sea correcta"
    echo "   4. Probar el botón 'Test Connection' en configuración"

elif [ "$LOCAL_API" = true ] && [ "$MODEL_COUNT" -eq 0 ]; then
    echo "⚠️ OLLAMA SIN MODELOS"
    echo "   • Ollama funciona pero no hay modelos instalados"
    echo "   • Instalar modelos:"
    echo "     ollama pull mistral:7b"
    echo "     ollama pull phi3:mini"

elif [ "$LOCAL_API" = false ] && [ "$OLLAMA_RUNNING" = true ]; then
    echo "⚠️ OLLAMA NO RESPONDE EN PUERTO 11434"
    echo "   • El proceso Ollama está ejecutándose"
    echo "   • Pero el API no responde en localhost:11434"
    echo "   • Verificar configuración de Ollama"
    echo "   • Reiniciar Ollama: sudo systemctl restart ollama"

else
    echo "❌ OLLAMA NO ESTÁ FUNCIONANDO"
    echo "   • Verificar instalación: ollama --version"
    echo "   • Iniciar Ollama: ollama serve"
    echo "   • O usar Docker: docker run -d -p 11434:11434 ollama/ollama"
fi

echo ""
echo "🔧 COMANDOS DE DIAGNÓSTICO ÚTILES"
echo "================================="
echo "# Verificar modelos instalados:"
echo "ollama list"
echo ""
echo "# Test manual de API:"
echo "curl http://localhost:11434/api/tags"
echo ""
echo "# Ver logs de Ollama:"
echo "journalctl -u ollama -f"
echo ""
echo "# Instalar modelo de prueba:"
echo "ollama pull tinyllama"

echo ""
echo "📞 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
echo "🧪 MSN-AI Model Detection Test v1.0.0"
