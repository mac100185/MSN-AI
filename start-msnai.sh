#!/bin/bash
# Script de inicio rápido para MSN-AI
# Versión: 1.0
# Descripción: Inicia MSN-AI con verificaciones automáticas

echo "🚀 MSN-AI - Iniciando aplicación..."
echo "============================================"

# Verificar si estamos en el directorio correcto
if [ ! -f "msn-ai.html" ]; then
    echo "❌ Error: No se encuentra msn-ai.html"
    echo "   Asegúrate de ejecutar este script desde el directorio MSN-AI"
    exit 1
fi

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

    if [ "$MODELS" -eq 0 ]; then
        echo "⚠️  No hay modelos instalados"
        echo "   ¿Deseas instalar mistral:7b (recomendado)? (s/n)"
        read -r install_model

        if [[ "$install_model" =~ ^[sS]$ ]]; then
            echo "📥 Descargando mistral:7b..."
            ollama pull mistral:7b

            if [ $? -eq 0 ]; then
                echo "✅ Modelo instalado correctamente"
            else
                echo "❌ Error instalando modelo"
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
    echo "🌐 Detectando navegador..."

    # Detectar SO
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v firefox &> /dev/null; then
            BROWSER="firefox"
        elif command -v google-chrome &> /dev/null; then
            BROWSER="google-chrome"
        elif command -v chromium-browser &> /dev/null; then
            BROWSER="chromium-browser"
        elif command -v google-chrome-stable &> /dev/null; then
            BROWSER="google-chrome-stable"
        else
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

    echo "✅ Navegador seleccionado: $BROWSER"
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
        case $BROWSER in
            "firefox")
                firefox "$url/msn-ai.html" &
                ;;
            "google-chrome"|"google-chrome-stable")
                $BROWSER --new-window "$url/msn-ai.html" &
                ;;
            "chromium-browser")
                chromium-browser --new-window "$url/msn-ai.html" &
                ;;
            "open")
                open "$url/msn-ai.html"
                ;;
            "start")
                start "$url/msn-ai.html"
                ;;
            *)
                $BROWSER "$url/msn-ai.html" &
                ;;
        esac
    else
        # Abrir archivo directamente
        case $BROWSER in
            "firefox")
                firefox "file://$(pwd)/msn-ai.html" &
                ;;
            "google-chrome"|"google-chrome-stable")
                $BROWSER --new-window --allow-file-access-from-files "file://$(pwd)/msn-ai.html" &
                ;;
            "chromium-browser")
                chromium-browser --new-window --allow-file-access-from-files "file://$(pwd)/msn-ai.html" &
                ;;
            "open")
                open "file://$(pwd)/msn-ai.html"
                ;;
            "start")
                start "file://$(pwd)/msn-ai.html"
                ;;
            *)
                $BROWSER "file://$(pwd)/msn-ai.html" &
                ;;
        esac
    fi

    echo "✅ MSN-AI abierto en el navegador"
}

# Función de limpieza al salir
cleanup() {
    echo ""
    echo "🧹 Limpiando procesos..."

    if [ -n "$SERVER_PID" ] && kill -0 $SERVER_PID 2>/dev/null; then
        echo "🛑 Deteniendo servidor web (PID: $SERVER_PID)..."
        kill $SERVER_PID
    fi

    if [ -n "$OLLAMA_PID" ] && kill -0 $OLLAMA_PID 2>/dev/null; then
        echo "🛑 Deteniendo Ollama (PID: $OLLAMA_PID)..."
        kill $OLLAMA_PID
    fi

    echo "👋 ¡Gracias por usar MSN-AI!"
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
            echo "🎉 ¡MSN-AI está ejecutándose!"
            echo "============================================"
            echo "📱 URL: http://localhost:$PORT/msn-ai.html"
            echo "🔧 Ollama: $([ $OLLAMA_OK -eq 0 ] && echo "✅ Funcionando" || echo "⚠️ No disponible")"
            echo "🌐 Navegador: $BROWSER"
            echo ""
            echo "💡 Consejos:"
            echo "   • Mantén esta terminal abierta"
            echo "   • Presiona Ctrl+C para detener"
            echo "   • Verifica la conexión con Ollama en la app"
            echo ""
            echo "⏳ Mantendo servidor activo... Presiona Ctrl+C para salir"

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
        echo "🎉 ¡MSN-AI abierto!"
        echo "============================================"
        echo "⚠️  Modo archivo directo (funcionalidad limitada)"
        echo "🔧 Ollama: $([ $OLLAMA_OK -eq 0 ] && echo "✅ Funcionando" || echo "⚠️ No disponible")"
        echo ""
        echo "💡 Si experimentas problemas, usa el modo servidor (opción 1)"
        ;;

    3)
        echo "🔍 Solo verificación del sistema:"
        echo "============================================"
        echo "✅ MSN-AI: Archivo encontrado"
        echo "🔧 Ollama: $([ $OLLAMA_OK -eq 0 ] && echo "✅ Funcionando" || echo "❌ No disponible")"
        echo "🌐 Navegador: $BROWSER detectado"
        echo ""
        echo "💡 Para iniciar la aplicación, ejecuta:"
        echo "   $0 --auto"
        ;;

    *)
        echo "❌ Opción no válida"
        exit 1
        ;;
esac

echo ""
echo "🏁 Script completado"
