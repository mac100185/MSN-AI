#!/bin/bash
# MSN-AI - Universal Docker Start Script Wrapper
# Version: 2.1.0
# Author: Alan Mac-Arthur García Díaz
# License: GNU General Public License v3.0
# Description: Detects OS and redirects to appropriate docker start script

echo "🐳 MSN-AI v2.1.0 - Docker Universal Launcher"
echo "=============================================="
echo "📧 Desarrollado por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "=============================================="
echo ""

# Detect operating system
OS_TYPE=$(uname -s)

case "$OS_TYPE" in
    Linux*)
        echo "🐧 Sistema operativo: Linux"
        echo "📂 Redirigiendo a: linux/start-msnai-docker.sh"
        echo ""

        if [ -f "linux/start-msnai-docker.sh" ]; then
            chmod +x linux/start-msnai-docker.sh
            exec bash linux/start-msnai-docker.sh "$@"
        else
            echo "❌ Error: No se encuentra linux/start-msnai-docker.sh"
            exit 1
        fi
        ;;

    Darwin*)
        echo "🍎 Sistema operativo: macOS"
        echo "📂 Redirigiendo a: macos/start-msnai-docker-mac.sh"
        echo ""

        if [ -f "macos/start-msnai-docker-mac.sh" ]; then
            chmod +x macos/start-msnai-docker-mac.sh
            exec bash macos/start-msnai-docker-mac.sh "$@"
        else
            echo "❌ Error: No se encuentra macos/start-msnai-docker-mac.sh"
            exit 1
        fi
        ;;

    CYGWIN*|MINGW*|MSYS*)
        echo "🪟 Sistema operativo: Windows (Git Bash/MSYS)"
        echo "⚠️  Para Windows, use PowerShell y ejecute:"
        echo "   windows\\start-msnai-docker.ps1"
        echo ""
        echo "💡 O abra PowerShell y ejecute:"
        echo "   .\\windows\\start-msnai-docker.ps1"
        exit 1
        ;;

    *)
        echo "❌ Sistema operativo no soportado: $OS_TYPE"
        echo ""
        echo "💡 Sistemas soportados:"
        echo "   - Linux: bash linux/start-msnai-docker.sh"
        echo "   - macOS: bash macos/start-msnai-docker-mac.sh"
        echo "   - Windows: powershell windows/start-msnai-docker.ps1"
        exit 1
        ;;
esac
