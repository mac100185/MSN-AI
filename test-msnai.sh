#!/bin/bash
# Test rápido para MSN-AI
# Verifica que todos los componentes estén en su lugar

echo "🧪 MSN-AI - Test de componentes"
echo "================================="

# Contador de errores
ERRORS=0

# Función para verificar archivo
check_file() {
    if [ -f "$1" ]; then
        echo "✅ $1"
    else
        echo "❌ $1 - NO ENCONTRADO"
        ERRORS=$((ERRORS + 1))
    fi
}

# Función para verificar directorio
check_dir() {
    if [ -d "$1" ]; then
        echo "✅ $1/"
    else
        echo "❌ $1/ - NO ENCONTRADO"
        ERRORS=$((ERRORS + 1))
    fi
}

echo ""
echo "📁 Verificando estructura de archivos:"
echo "-------------------------------------"

# Archivos principales
check_file "msn-ai.html"
check_file "start-msnai.sh"
check_file "ai_check_all.sh"
check_file "README-MSNAI.md"

# Directorios de assets
check_dir "assets"
check_dir "assets/sounds"
check_dir "assets/background"
check_dir "assets/chat-window"
check_dir "assets/contacts-window"
check_dir "assets/general"
check_dir "assets/scrollbar"
check_dir "assets/status"

echo ""
echo "🔊 Verificando archivos de sonido:"
echo "-----------------------------------"

# Sonidos requeridos
check_file "assets/sounds/login.wav"
check_file "assets/sounds/message_in.wav"
check_file "assets/sounds/message_out.wav"
check_file "assets/sounds/nudge.wav"
check_file "assets/sounds/calling.wav"

echo ""
echo "🖼️ Verificando assets críticos:"
echo "--------------------------------"

# Assets importantes
check_file "assets/general/live_logo.png"
check_file "assets/general/title_text.png"
check_file "assets/background/msgres_fullheader.png"
check_file "assets/background/frame_48.png"
check_file "assets/01CAT.jpg"

echo ""
echo "⚙️ Verificando herramientas del sistema:"
echo "----------------------------------------"

# Verificar comandos necesarios
if command -v curl &> /dev/null; then
    echo "✅ curl"
else
    echo "⚠️ curl - Recomendado para instalación de Ollama"
fi

if command -v python3 &> /dev/null; then
    echo "✅ python3"
elif command -v python &> /dev/null; then
    echo "✅ python"
else
    echo "⚠️ python - Recomendado para servidor local"
fi

# Verificar navegadores
BROWSERS=("firefox" "google-chrome" "google-chrome-stable" "chromium-browser")
BROWSER_FOUND=false

for browser in "${BROWSERS[@]}"; do
    if command -v "$browser" &> /dev/null; then
        echo "✅ $browser"
        BROWSER_FOUND=true
        break
    fi
done

if [ "$BROWSER_FOUND" = false ]; then
    echo "⚠️ Navegador - Se intentará usar el navegador por defecto"
fi

echo ""
echo "🤖 Verificando Ollama:"
echo "----------------------"

if command -v ollama &> /dev/null; then
    echo "✅ Ollama instalado"

    if pgrep -x "ollama" > /dev/null; then
        echo "✅ Ollama ejecutándose"

        # Verificar modelos
        MODELS=$(ollama list 2>/dev/null | tail -n +2 | wc -l)
        if [ "$MODELS" -gt 0 ]; then
            echo "✅ Modelos disponibles: $MODELS"
            echo "   Modelos encontrados:"
            ollama list 2>/dev/null | tail -n +2 | head -5 | sed 's/^/   - /'
        else
            echo "⚠️ Sin modelos instalados"
            echo "   Ejecuta: ollama pull mistral:7b"
        fi

        # Test de conectividad
        if curl -s http://localhost:11434/api/tags &> /dev/null; then
            echo "✅ API de Ollama accesible"
        else
            echo "⚠️ API de Ollama no responde"
        fi

    else
        echo "⚠️ Ollama no está ejecutándose"
        echo "   Ejecuta: ollama serve"
    fi
else
    echo "❌ Ollama no instalado"
    echo "   Ejecuta: ./ai_check_all.sh"
fi

echo ""
echo "🔒 Verificando permisos:"
echo "------------------------"

if [ -x "start-msnai.sh" ]; then
    echo "✅ start-msnai.sh ejecutable"
else
    echo "⚠️ start-msnai.sh no ejecutable"
    echo "   Ejecuta: chmod +x start-msnai.sh"
fi

if [ -x "ai_check_all.sh" ]; then
    echo "✅ ai_check_all.sh ejecutable"
else
    echo "⚠️ ai_check_all.sh no ejecutable"
    echo "   Ejecuta: chmod +x ai_check_all.sh"
fi

echo ""
echo "📊 Resumen del test:"
echo "==================="

if [ $ERRORS -eq 0 ]; then
    echo "🎉 ¡Perfecto! Todos los componentes están presentes"
    echo ""
    echo "🚀 Para iniciar MSN-AI:"
    echo "   ./start-msnai.sh"
    echo ""
    echo "🤖 Para configurar IA:"
    echo "   ./ai_check_all.sh"
else
    echo "⚠️ Se encontraron $ERRORS problemas"
    echo ""
    echo "🔧 Acciones recomendadas:"
    echo "   1. Verifica que todos los archivos estén presentes"
    echo "   2. Asegúrate de estar en el directorio correcto"
    echo "   3. Revisa los permisos de los archivos"
fi

echo ""
echo "📋 Información del sistema:"
echo "---------------------------"
echo "SO: $(uname -s)"
echo "Arquitectura: $(uname -m)"
echo "Usuario: $(whoami)"
echo "Directorio: $(pwd)"

if [ -f /etc/os-release ]; then
    echo "Distribución: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
fi

echo ""
echo "💡 Tips adicionales:"
echo "-------------------"
echo "• Mantén Ollama ejecutándose para mejor experiencia"
echo "• Usa Firefox o Chrome para mejor compatibilidad"
echo "• Exporta tus chats regularmente como respaldo"
echo "• Revisa README-MSNAI.md para documentación completa"

echo ""
echo "🏁 Test completado"

exit $ERRORS
