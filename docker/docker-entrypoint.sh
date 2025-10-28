#!/bin/bash
# Docker Entrypoint Script for MSN-AI
# Version: 1.0.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Intelligent startup script for MSN-AI container

set -eo pipefail

# Enable verbose mode if DEBUG is set
if [ "${DEBUG:-0}" = "1" ]; then
    set -x
fi

echo "🐳 MSN-AI v1.0.0 - Docker Container Starting..."
echo "============================================="
echo "📧 Desarrollado por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "🐳 Modo: Docker Container"
echo "============================================="

# Environment variables with defaults
MSN_AI_PORT=${MSN_AI_PORT:-8000}
OLLAMA_HOST=${OLLAMA_HOST:-ollama:11434}
MSN_AI_VERSION=${MSN_AI_VERSION:-1.0.0}

# Function to wait for Ollama service
wait_for_ollama() {
    echo "🔄 Esperando a que Ollama esté listo..."
    echo "   Host: ${OLLAMA_HOST}"
    local max_attempts=60
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        # First check basic connectivity
        if curl -s --connect-timeout 5 --max-time 10 "http://${OLLAMA_HOST}/" >/dev/null 2>&1; then
            # Then check API
            if curl -s --connect-timeout 5 --max-time 10 "http://${OLLAMA_HOST}/api/tags" >/dev/null 2>&1; then
                echo "✅ Ollama está listo y respondiendo (intento $attempt)"
                return 0
            else
                if [ $((attempt % 10)) -eq 0 ]; then
                    echo "⏳ Intento $attempt/$max_attempts - API de Ollama iniciándose..."
                fi
            fi
        else
            if [ $((attempt % 10)) -eq 0 ]; then
                echo "⏳ Intento $attempt/$max_attempts - Esperando conexión con Ollama..."
            fi
        fi

        sleep 3
        attempt=$((attempt + 1))
    done

    echo "⚠️ Ollama no responde después de $((max_attempts * 3)) segundos"
    echo "   Continuando sin IA (funcionalidad limitada)"
    echo "   Verifica que el contenedor ollama esté ejecutándose"
    return 1
}

# Function to setup directories
setup_directories() {
    echo "📁 Configurando directorios..."

    # Ensure data directories exist
    mkdir -p /app/data/chats || {
        echo "⚠️ No se pudo crear /app/data/chats"
        return 1
    }
    mkdir -p /app/data/logs || {
        echo "⚠️ No se pudo crear /app/data/logs"
        return 1
    }
    mkdir -p /app/data/config || {
        echo "⚠️ No se pudo crear /app/data/config"
        return 1
    }

    # Set permissions
    chmod 755 /app/data/chats || echo "⚠️ No se pudieron establecer permisos en chats"
    chmod 755 /app/data/logs || echo "⚠️ No se pudieron establecer permisos en logs"
    chmod 755 /app/data/config || echo "⚠️ No se pudieron establecer permisos en config"

    echo "✅ Directorios configurados correctamente"
    ls -la /app/data/
    return 0
}

# Function to check assets
check_assets() {
    echo "🎨 Verificando assets..."

    local missing_assets=0

    # Check critical files
    if [ ! -f "/app/msn-ai.html" ]; then
        echo "❌ Archivo principal msn-ai.html no encontrado"
        missing_assets=$((missing_assets + 1))
    fi

    # Check sounds directory
    if [ ! -d "/app/assets/sounds" ]; then
        echo "❌ Directorio de sonidos no encontrado"
        missing_assets=$((missing_assets + 1))
    else
        # Check sound files
        local sounds=("login.wav" "message_in.wav" "message_out.wav" "nudge.wav" "calling.wav")
        for sound in "${sounds[@]}"; do
            if [ ! -f "/app/assets/sounds/$sound" ]; then
                echo "⚠️ Sonido faltante: $sound"
            fi
        done
    fi

    if [ $missing_assets -eq 0 ]; then
        echo "✅ Todos los assets están presentes"
    else
        echo "⚠️ Se encontraron $missing_assets assets faltantes"
    fi

    return $missing_assets
}

# Function to start web server
start_web_server() {
    echo "🌍 Iniciando servidor web en puerto $MSN_AI_PORT..."

    # Change to app directory to serve files
    cd /app || {
        echo "❌ Error: No se puede acceder al directorio /app"
        echo "   Contenido del directorio actual:"
        ls -la
        exit 1
    }

    # Verify critical files exist
    if [ ! -f "msn-ai.html" ]; then
        echo "❌ Error: No se encuentra msn-ai.html en /app"
        echo "   Contenido de /app:"
        ls -la /app/
        exit 1
    fi

    echo "✅ Archivo principal encontrado: msn-ai.html"

    # Try Python first
    if command -v python3 >/dev/null 2>&1; then
        echo "🐍 Usando Python 3 HTTP Server"
        echo "   Comando: python3 -m http.server $MSN_AI_PORT --bind 0.0.0.0"
        exec python3 -m http.server "$MSN_AI_PORT" --bind 0.0.0.0
    elif command -v python >/dev/null 2>&1; then
        echo "🐍 Usando Python HTTP Server"
        echo "   Comando: python -m http.server $MSN_AI_PORT --bind 0.0.0.0"
        exec python -m http.server "$MSN_AI_PORT" --bind 0.0.0.0
    elif command -v http-server >/dev/null 2>&1; then
        echo "📗 Usando Node.js HTTP Server"
        echo "   Comando: http-server -p $MSN_AI_PORT -a 0.0.0.0 --cors"
        exec http-server -p "$MSN_AI_PORT" -a 0.0.0.0 --cors
    else
        echo "❌ No se encontró servidor web disponible"
        echo "   Servidores buscados: python3, python, http-server"
        exit 1
    fi
}

# Function to log startup info
log_startup_info() {
    echo ""
    echo "🎉 MSN-AI Container iniciado exitosamente!"
    echo "=========================================="
    echo "📱 Puerto: $MSN_AI_PORT"
    echo "🤖 Ollama: $OLLAMA_HOST"
    echo "📁 Datos: /app/data"
    echo "🐳 Container: $(hostname)"
    echo "👤 Usuario: $(whoami)"
    echo "⏰ Inicio: $(date)"
    echo ""
    echo "🌐 Accede a MSN-AI desde tu navegador:"
    echo "   http://localhost:$MSN_AI_PORT/msn-ai.html"
    echo ""
    echo "💡 Para detener el contenedor:"
    echo "   docker-compose down"
    echo ""
    echo "⚠️ IMPORTANTE: Los chats se guardan en volumes persistentes"
    echo "=============================================="
}

# Trap to handle container shutdown
cleanup() {
    echo ""
    echo "🛑 Deteniendo MSN-AI Container..."
    echo "✅ Limpieza completada"
    echo "👋 ¡Gracias por usar MSN-AI v$MSN_AI_VERSION!"
    exit 0
}

trap cleanup SIGTERM SIGINT

# Main execution flow
main() {
    echo "🔧 Iniciando secuencia de arranque..."
    echo "   PID: $$"
    echo "   Usuario: $(whoami)"
    echo "   Directorio actual: $(pwd)"
    echo ""

    # Setup directories
    if ! setup_directories; then
        echo "❌ Error configurando directorios"
        exit 1
    fi
    echo ""

    # Check assets
    if check_assets; then
        echo "✅ Verificación de assets completada"
    else
        echo "⚠️ Algunos assets faltan, pero continuando..."
    fi
    echo ""

    # Wait for Ollama (optional but important)
    if wait_for_ollama; then
        echo "✅ Sistema de IA disponible"
    else
        echo "⚠️ Continuando sin sistema de IA"
    fi
    echo ""

    # Log startup information
    log_startup_info

    # Start web server (this blocks)
    echo "🚀 Iniciando servidor web..."
    start_web_server
}

# Check if running as intended user
if [ "$(id -u)" = "0" ]; then
    echo "⚠️ Ejecutándose como root, esto no es recomendado"
    if command -v gosu >/dev/null 2>&1; then
        echo "   Cambiando a usuario msnai..."
        exec gosu msnai "$0" "$@"
    else
        echo "   gosu no disponible, continuando como root (no recomendado)"
    fi
fi

echo ""
echo "🚀 Ejecutando función principal..."

# Run main function with error handling
if ! main "$@"; then
    echo ""
    echo "❌ Error en la función principal"
    echo "   Código de salida: $?"
    exit 1
fi
