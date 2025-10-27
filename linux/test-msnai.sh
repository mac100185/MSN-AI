#!/bin/bash
# Test rápido para MSN-AI
# Versión: 1.0.0
# Autor: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# Licencia: GNU General Public License v3.0
# Verifica que todos los componentes estén en su lugar

# Detectar plataforma
OS_TYPE="Unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macOS"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS_TYPE="Windows"
fi

echo "🧪 MSN-AI v1.0.0 - Test de componentes"
echo "======================================="
echo "📧 Desarrollado por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0 | 🔗 alan.mac.arthur.garcia.diaz@gmail.com"
echo "🖥️  Sistema: $OS_TYPE"
echo "======================================="

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
check_file "README.md"
check_file "README-MSNAI.md"
check_file "CHANGELOG.md"
check_file "LICENSE"

# Scripts por plataforma
echo ""
echo "📁 Verificando scripts por plataforma:"
echo "--------------------------------------"
check_file "start-msnai.sh"         # Linux
check_file "ai_check_all.sh"        # Linux
check_file "start-msnai.ps1"        # Windows
check_file "ai_check_all.ps1"       # Windows
check_file "start-msnai-mac.sh"     # macOS
check_file "ai_check_all_mac.sh"    # macOS

# Directorios de assets
check_dir "assets"
check_dir "assets/sounds"
check_dir "assets/background"
check_dir "assets/chat-window"
check_dir "assets/contacts-window"
check_dir "assets/general"
check_dir "assets/scrollbar"
check_dir "assets/status"
check_dir "assets/images"

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
check_file "assets/images/profile.jpeg"

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
    case $OS_TYPE in
        "Linux")
            echo "   ./start-msnai.sh --auto"
            echo ""
            echo "🤖 Para configurar IA:"
            echo "   ./ai_check_all.sh"
            ;;
        "macOS")
            echo "   ./start-msnai-mac.sh --auto"
            echo ""
            echo "🤖 Para configurar IA:"
            echo "   ./ai_check_all_mac.sh"
            ;;
        "Windows")
            echo "   .\\start-msnai.ps1 --auto"
            echo ""
            echo "🤖 Para configurar IA:"
            echo "   .\\ai_check_all.ps1"
            echo ""
            echo "⚠️ Windows: Habilita scripts primero:"
            echo "   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
            ;;
        *)
            echo "   Usar el script apropiado para tu plataforma:"
            echo "   Linux:   ./start-msnai.sh --auto"
            echo "   macOS:   ./start-msnai-mac.sh --auto"
            echo "   Windows: .\\start-msnai.ps1 --auto"
            ;;
    esac
    echo ""
    echo "⏹️ Para detener correctamente:"
    echo "   Ctrl+C en la terminal/PowerShell del servidor"
else
    echo "⚠️ Se encontraron $ERRORS problemas"
    echo ""
    echo "🔧 Acciones recomendadas:"
    echo "   1. Verifica que todos los archivos estén presentes"
    echo "   2. Asegúrate de estar en el directorio correcto"
    echo "   3. Revisa los permisos de los archivos"
    echo "   4. Contacta al desarrollador si persisten los problemas"
fi

echo ""
echo "📋 Información del sistema:"
echo "---------------------------"
echo "Plataforma: $OS_TYPE"
if [ "$OS_TYPE" != "Windows" ]; then
    echo "SO: $(uname -s 2>/dev/null || echo 'No disponible')"
    echo "Arquitectura: $(uname -m 2>/dev/null || echo 'No disponible')"
fi
echo "Usuario: $(whoami)"
echo "Directorio: $(pwd)"
echo "Versión MSN-AI: 1.0.0"
echo "Licencia: GPL-3.0"

if [ -f /etc/os-release ]; then
    echo "Distribución: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
fi

echo ""
echo "💡 Tips adicionales:"
echo "-------------------"
case $OS_TYPE in
    "Linux")
        echo "• Para Linux: Usa Firefox o Chrome para mejor compatibilidad"
        echo "• Instala Python 3 si no tienes servidor web: apt install python3"
        ;;
    "macOS")
        echo "• Para macOS: Safari, Chrome o Firefox funcionan perfectamente"
        echo "• Instala Homebrew si no lo tienes: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        ;;
    "Windows")
        echo "• Para Windows: Chrome o Edge recomendados"
        echo "• Instala Python desde Microsoft Store si no tienes servidor web"
        echo "• Habilita ejecución de scripts PowerShell la primera vez"
        ;;
esac
echo "• Mantén Ollama ejecutándose para mejor experiencia"
echo "• Exporta tus chats regularmente como respaldo"
echo "• Revisa README.md para guía principal"
echo "• Revisa README-MSNAI.md para documentación técnica completa"
echo "• SIEMPRE detén con Ctrl+C, nunca fuerces el cierre"

echo ""
echo "🏁 MSN-AI v1.0.0 - Test completado"
echo "📧 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
echo "⚖️ Software libre bajo GPL-3.0"

exit $ERRORS
