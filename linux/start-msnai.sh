#!/bin/bash
# Script de inicio rápido para MSN-AI
# Versión: 1.0.0
# Autor: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# Licencia: GNU General Public License v3.0
# Descripción: Inicia MSN-AI con verificaciones automáticas

echo "🚀 MSN-AI v1.0.0 - Iniciando aplicación..."
echo "============================================"
echo "📧 Desarrollado por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0 | 🔗 alan.mac.arthur.garcia.diaz@gmail.com"
echo "============================================"

# Detect and change to project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔍 Detectando directorio del proyecto..."
echo "   Script ubicado en: $SCRIPT_DIR"
echo "   Directorio raíz: $PROJECT_ROOT"

# Change to project root
cd "$PROJECT_ROOT" || {
    echo "❌ Error: No se pudo cambiar al directorio del proyecto"
    echo "   Ruta intentada: $PROJECT_ROOT"
    exit 1
}

echo "   Directorio actual: $(pwd)"

# Verify we're in the correct directory
if [ ! -f "msn-ai.html" ]; then
    echo "❌ Error: No se encuentra msn-ai.html en $(pwd)"
    echo "   Archivos encontrados:"
    ls -la | head -10
    echo ""
    echo "💡 Asegúrate de ejecutar este script desde:"
    echo "   $PROJECT_ROOT/linux/start-msnai.sh"
    exit 1
fi

echo "✅ Proyecto MSN-AI detectado correctamente"
echo ""

# Función para verificar Ollama
check_ollama() {
    echo "🔍 Verificando Ollama..."

    if ! command -v ollama &> /dev/null; then
        echo "⚠️  Ollama no está instalado"
        echo "   ¿Deseas instalarlo automáticamente? (s/n)"
        read -r install_ollama

        if [[ "$install_ollama" =~ ^[sS]$ ]]; then
            echo "📦 Instalando Ollama..."
            curl -fsSL https://ollama.com/install.sh | sh

            if [ $? -eq 0 ]; then
                echo "✅ Ollama instalado correctamente"
            else
                echo "❌ Error instalando Ollama"
                exit 1
            fi
        else
            echo "⏭️  Continuando sin Ollama (funcionalidad limitada)"
            return 1
        fi
    fi

    # Verificar si Ollama está ejecutándose
    if ! pgrep -x "ollama" > /dev/null; then
        echo "🔄 Iniciando Ollama..."
        ollama serve &
        OLLAMA_PID=$!
        sleep 3

        if pgrep -x "ollama" > /dev/null; then
            echo "✅ Ollama iniciado correctamente (PID: $OLLAMA_PID)"
        else
            echo "❌ Error iniciando Ollama"
            return 1
        fi
    else
        echo "✅ Ollama ya está ejecutándose"
    fi

    # Verificar modelos disponibles
    echo "🧠 Verificando modelos de IA..."
    MODELS=$(ollama list 2>/dev/null | tail -n +2 | wc -l)

    # Modelos requeridos por defecto
    REQUIRED_MODELS=(
        "qwen3-vl:235b-cloud"
        "gpt-oss:120b-cloud"
        "qwen3-coder:480b-cloud"
    )

    if [ "$MODELS" -eq 0 ]; then
        echo "⚠️  No hay modelos instalados"
        echo ""
        echo "📦 Modelos requeridos por defecto:"
        for model in "${REQUIRED_MODELS[@]}"; do
            echo "   - $model"
        done
        echo ""
        echo "   ¿Deseas instalar los modelos requeridos? (s/n)"
        read -r install_models

        if [[ "$install_models" =~ ^[sS]$ ]]; then
            echo ""
            echo "📥 Instalando modelos requeridos..."
            echo "⚠️  NOTA: Este proceso puede tardar bastante tiempo dependiendo de tu conexión"
            echo ""

            local installed_count=0
            local failed_count=0

            for model in "${REQUIRED_MODELS[@]}"; do
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "📥 Descargando: $model"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

                ollama pull "$model"

                if [ $? -eq 0 ]; then
                    echo "✅ Modelo $model instalado correctamente"
                    installed_count=$((installed_count + 1))
                else
                    echo "❌ Error instalando modelo $model"
                    failed_count=$((failed_count + 1))
                fi
                echo ""
            done

            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📊 Resumen de instalación:"
            echo "   ✅ Instalados: $installed_count/${#REQUIRED_MODELS[@]}"
            echo "   ❌ Fallidos: $failed_count/${#REQUIRED_MODELS[@]}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

            if [ $installed_count -eq 0 ]; then
                echo "❌ No se pudo instalar ningún modelo"
                return 1
            fi
        else
            echo "⏭️  Continuando sin modelos (funcionalidad limitada)"
        fi
    else
        echo "✅ Modelos disponibles: $MODELS"
        ollama list | head -n 10
    fi

    return 0
}

# Función para detectar navegador
detect_browser() {
    echo "🌐 Detectando navegador por defecto del sistema..."

    # Detectar SO
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux - Contar navegadores disponibles
        FOUND_BROWSERS=0

        if command -v firefox &> /dev/null; then
            FOUND_BROWSERS=$((FOUND_BROWSERS + 1))
            FIRST_BROWSER="firefox"
        fi

        if command -v microsoft-edge &> /dev/null; then
            FOUND_BROWSERS=$((FOUND_BROWSERS + 1))
            [ -z "$FIRST_BROWSER" ] && FIRST_BROWSER="microsoft-edge"
        fi

        if command -v microsoft-edge-stable &> /dev/null; then
            FOUND_BROWSERS=$((FOUND_BROWSERS + 1))
            [ -z "$FIRST_BROWSER" ] && FIRST_BROWSER="microsoft-edge-stable"
        fi

        if command -v google-chrome &> /dev/null; then
            FOUND_BROWSERS=$((FOUND_BROWSERS + 1))
            [ -z "$FIRST_BROWSER" ] && FIRST_BROWSER="google-chrome"
        fi

        if command -v chromium-browser &> /dev/null; then
            FOUND_BROWSERS=$((FOUND_BROWSERS + 1))
            [ -z "$FIRST_BROWSER" ] && FIRST_BROWSER="chromium-browser"
        fi

        if command -v google-chrome-stable &> /dev/null; then
            FOUND_BROWSERS=$((FOUND_BROWSERS + 1))
            [ -z "$FIRST_BROWSER" ] && FIRST_BROWSER="google-chrome-stable"
        fi

        # Si hay múltiples navegadores, usar el navegador por defecto
        if [ $FOUND_BROWSERS -gt 1 ]; then
            echo "✅ Múltiples navegadores detectados. Usando navegador por defecto del sistema"
            BROWSER="xdg-open"
        elif [ $FOUND_BROWSERS -eq 1 ]; then
            echo "✅ Navegador detectado: $FIRST_BROWSER"
            BROWSER="$FIRST_BROWSER"
        else
            echo "✅ Usando navegador por defecto del sistema"
            BROWSER="xdg-open"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        BROWSER="open"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        # Windows
        BROWSER="start"
    else
        echo "⚠️  Sistema operativo no detectado"
        BROWSER="xdg-open"
    fi
}

# Función para iniciar servidor web local
start_server() {
    echo "🌍 Iniciando servidor web local..."

    # Buscar puerto disponible
    PORT=8000
    while netstat -an 2>/dev/null | grep -q ":$PORT "; do
        PORT=$((PORT + 1))
        if [ $PORT -gt 8010 ]; then
            echo "❌ No se encontró puerto disponible"
            return 1
        fi
    done

    echo "📡 Servidor web en puerto: $PORT"

    # Intentar Python 3 primero, luego Python 2, luego Node.js
    if command -v python3 &> /dev/null; then
        echo "🐍 Usando Python 3..."
        python3 -m http.server $PORT &
        SERVER_PID=$!
        SERVER_CMD="python3"
    elif command -v python &> /dev/null; then
        echo "🐍 Usando Python 2..."
        python -m SimpleHTTPServer $PORT &
        SERVER_PID=$!
        SERVER_CMD="python"
    elif command -v node &> /dev/null && command -v npx &> /dev/null; then
        echo "📗 Usando Node.js..."
        npx http-server -p $PORT &
        SERVER_PID=$!
        SERVER_CMD="node"
    else
        echo "⚠️  No se encontró servidor web disponible"
        echo "   Instalando python3-http-server simple..."

        # Crear servidor simple en bash (último recurso)
        echo "🔧 Modo directo (sin servidor)"
        return 2
    fi

    if [ $? -eq 0 ]; then
        echo "✅ Servidor iniciado (PID: $SERVER_PID)"
        echo "🔗 URL: http://localhost:$PORT"

        # Esperar a que el servidor esté listo
        sleep 2

        return 0
    else
        echo "❌ Error iniciando servidor"
        return 1
    fi
}

# Función para abrir la aplicación
open_app() {
    local url=$1
    local file_path=$2

    echo "🚀 Abriendo MSN-AI..."

    if [ -n "$url" ]; then
        # Abrir URL del servidor
        if [ "$BROWSER" = "xdg-open" ] || [ "$BROWSER" = "open" ] || [ "$BROWSER" = "start" ]; then
            # Usar navegador por defecto del sistema
            $BROWSER "$url/msn-ai.html" &
        else
            # Usar navegador específico detectado
            case $BROWSER in
                "firefox")
                    firefox "$url/msn-ai.html" &
                    ;;
                "microsoft-edge"|"microsoft-edge-stable")
                    $BROWSER --new-window "$url/msn-ai.html" &
                    ;;
                "google-chrome"|"google-chrome-stable")
                    $BROWSER --new-window "$url/msn-ai.html" &
                    ;;
                "chromium-browser")
                    chromium-browser --new-window "$url/msn-ai.html" &
                    ;;
                *)
                    $BROWSER "$url/msn-ai.html" &
                    ;;
            esac
        fi
    else
        # Abrir archivo directamente
        if [ "$BROWSER" = "xdg-open" ] || [ "$BROWSER" = "open" ] || [ "$BROWSER" = "start" ]; then
            # Usar navegador por defecto del sistema
            $BROWSER "file://$(pwd)/msn-ai.html" &
        else
            # Usar navegador específico detectado
            case $BROWSER in
                "firefox")
                    firefox "file://$(pwd)/msn-ai.html" &
                    ;;
                "microsoft-edge"|"microsoft-edge-stable")
                    $BROWSER --new-window --allow-file-access-from-files "file://$(pwd)/msn-ai.html" &
                    ;;
                "google-chrome"|"google-chrome-stable")
                    $BROWSER --new-window --allow-file-access-from-files "file://$(pwd)/msn-ai.html" &
                    ;;
                "chromium-browser")
                    chromium-browser --new-window --allow-file-access-from-files "file://$(pwd)/msn-ai.html" &
                    ;;
                *)
                    $BROWSER "file://$(pwd)/msn-ai.html" &
                    ;;
            esac
        fi
    fi

    echo "✅ MSN-AI abierto en el navegador"
}

# Función de limpieza al salir
cleanup() {
    echo ""
    echo "🧹 Limpiando procesos MSN-AI..."
    echo "⚠️ IMPORTANTE: No fuerces el cierre, espera la limpieza completa"

    # Detener servidor web
    if [ -n "$SERVER_PID" ] && kill -0 $SERVER_PID 2>/dev/null; then
        echo "🛑 Deteniendo servidor web (PID: $SERVER_PID)..."
        kill $SERVER_PID 2>/dev/null
        sleep 1
        if kill -0 $SERVER_PID 2>/dev/null; then
            echo "⚠️ Forzando cierre del servidor..."
            kill -9 $SERVER_PID 2>/dev/null
        fi
    fi

    # Detener Ollama solo si fue iniciado por este script
    if [ -n "$OLLAMA_PID" ] && kill -0 $OLLAMA_PID 2>/dev/null; then
        echo "🛑 Deteniendo Ollama (PID: $OLLAMA_PID)..."
        kill $OLLAMA_PID 2>/dev/null
        sleep 2
        if kill -0 $OLLAMA_PID 2>/dev/null; then
            echo "⚠️ Forzando cierre de Ollama..."
            kill -9 $OLLAMA_PID 2>/dev/null
        fi
    fi

    # Verificar que todo esté limpio
    echo "🔍 Verificando limpieza..."
    if pgrep -f "python.*http.server" >/dev/null 2>&1; then
        echo "⚠️ Limpiando servidores Python restantes..."
        pkill -f "python.*http.server" 2>/dev/null
    fi

    echo "✅ Limpieza completada exitosamente"
    echo "👋 ¡Gracias por usar MSN-AI v1.0.0!"
    echo "📧 Reporta problemas a: alan.mac.arthur.garcia.diaz@gmail.com"
    exit 0
}

# Capturar señales para limpieza
trap cleanup SIGINT SIGTERM

# ===================
# FLUJO PRINCIPAL
# ===================

echo "📋 Iniciando verificaciones..."

# 1. Verificar Ollama (opcional pero recomendado)
check_ollama
OLLAMA_OK=$?

# 2. Detectar navegador
detect_browser

# 3. Decidir método de apertura
echo "🤔 Seleccionando método de inicio..."
echo "   1) Servidor local (recomendado)"
echo "   2) Archivo directo (puede tener limitaciones)"
echo "   3) Solo verificar sistema"
echo ""

# Auto-seleccionar o pedir al usuario
if [ "$1" = "--auto" ] || [ "$1" = "-a" ]; then
    echo "🔄 Modo automático seleccionado"
    METHOD=1
else
    echo "Selecciona una opción (1-3) o presiona Enter para automático: "
    read -r METHOD

    if [ -z "$METHOD" ]; then
        METHOD=1
    fi
fi

case $METHOD in
    1)
        echo "📡 Iniciando con servidor local..."
        start_server
        SERVER_STATUS=$?

        if [ $SERVER_STATUS -eq 0 ]; then
            open_app "http://localhost:$PORT" ""

            echo ""
            echo "🎉 ¡MSN-AI v1.0.0 está ejecutándose!"
            echo "============================================"
            echo "📱 URL: http://localhost:$PORT/msn-ai.html"
            echo "🔧 Ollama: $([ $OLLAMA_OK -eq 0 ] && echo "✅ Funcionando" || echo "⚠️ No disponible")"
            echo "🌐 Navegador: $BROWSER"
            echo "📧 Desarrollador: Alan Mac-Arthur García Díaz"
            echo ""
            echo "💡 Consejos importantes:"
            echo "   • Mantén esta terminal abierta mientras usas MSN-AI"
            echo "   • Presiona Ctrl+C para detener CORRECTAMENTE"
            echo "   • NUNCA cierres la terminal sin Ctrl+C"
            echo "   • NUNCA uses kill -9 directamente"
            echo "   • Verifica la conexión con Ollama en la app"
            echo ""
            echo "⚠️ DETENCIÓN SEGURA:"
            echo "   1. Presiona Ctrl+C en esta terminal"
            echo "   2. Espera el mensaje de limpieza completa"
            echo "   3. No fuerces el cierre hasta ver: '✅ Limpieza completada'"
            echo ""
            echo "⏳ Servidor activo... Ctrl+C para detener correctamente"

            # Mantener servidor activo
            while true; do
                sleep 1
                if ! kill -0 $SERVER_PID 2>/dev/null; then
                    echo "⚠️ Servidor web se detuvo inesperadamente"
                    break
                fi
            done
        else
            echo "⚠️ Error con servidor, intentando modo directo..."
            open_app "" "$(pwd)/msn-ai.html"
        fi
        ;;

    2)
        echo "📁 Abriendo archivo directo..."
        open_app "" "$(pwd)/msn-ai.html"

        echo ""
        echo "🎉 ¡MSN-AI v1.0.0 abierto!"
        echo "============================================"
        echo "⚠️  Modo archivo directo (funcionalidad limitada)"
        echo "🔧 Ollama: $([ $OLLAMA_OK -eq 0 ] && echo "✅ Funcionando" || echo "⚠️ No disponible")"
        echo "📧 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
        echo ""
        echo "💡 Si experimentas problemas, usa el modo servidor (opción 1)"
        echo "⚠️ En este modo no hay procesos que detener manualmente"
        ;;

    3)
        echo "🔍 Solo verificación del sistema:"
        echo "============================================"
        echo "✅ MSN-AI: Archivo encontrado"
        echo "🔧 Ollama: $([ $OLLAMA_OK -eq 0 ] && echo "✅ Funcionando" || echo "❌ No disponible")"
        echo "🌐 Navegador: $BROWSER detectado"
        echo "📧 Desarrollador: Alan Mac-Arthur García Díaz"
        echo "⚖️ Licencia: GPL-3.0"
        echo ""
        echo "💡 Para iniciar la aplicación:"
        echo "   $0 --auto"
        echo ""
        echo "💡 Para detener correctamente (cuando esté ejecutándose):"
        echo "   Ctrl+C en la terminal del servidor"
        ;;

    *)
        echo "❌ Opción no válida"
        exit 1
        ;;
esac

echo ""
echo "🏁 MSN-AI v1.0.0 - Script completado"
echo "📧 ¿Problemas? Contacta: alan.mac.arthur.garcia.diaz@gmail.com"
echo "⚖️ Software libre bajo GPL-3.0"
