#!/bin/bash
# Docker Entrypoint Script for MSN-AI
# Version: 1.0.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Intelligent startup script for MSN-AI container

set -e

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
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://${OLLAMA_HOST}/api/tags" >/dev/null 2>&1; then
            echo "✅ Ollama está listo y respondiendo"
            return 0
        fi

        echo "⏳ Intento $attempt/$max_attempts - Ollama no responde aún..."
        sleep 2
        attempt=$((attempt + 1))
    done

    echo "⚠️ Ollama no responde después de $max_attempts intentos"
    echo "   Continuando sin IA (funcionalidad limitada)"
    return 1
}

# Function to setup directories
setup_directories() {
    echo "📁 Configurando directorios..."

    # Ensure data directories exist
    mkdir -p /app/data/chats
    mkdir -p /app/data/logs
    mkdir -p /app/data/config

    # Set permissions
    chmod 755 /app/data/chats
    chmod 755 /app/data/logs
    chmod 755 /app/data/config

    echo "✅ Directorios configurados"
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

    # Try Python first
    if command -v python3 >/dev/null 2>&1; then
        echo "🐍 Usando Python 3 HTTP Server"
        exec python3 -m http.server "$MSN_AI_PORT" --bind 0.0.0.0
    elif command -v python >/dev/null 2>&1; then
        echo "🐍 Usando Python HTTP Server"
        exec python -m http.server "$MSN_AI_PORT" --bind 0.0.0.0
    elif command -v http-server >/dev/null 2>&1; then
        echo "📗 Usando Node.js HTTP Server"
        exec http-server -p "$MSN_AI_PORT" -a 0.0.0.0 --cors
    else
        echo "❌ No se encontró servidor web disponible"
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
    # Setup directories
    setup_directories

    # Check assets
    check_assets

    # Wait for Ollama (optional)
    wait_for_ollama || echo "⚠️ Continuando sin Ollama"

    # Log startup information
    log_startup_info

    # Change to app directory
    cd /app

    # Start web server (this blocks)
    start_web_server
}

# Check if running as intended user
if [ "$(id -u)" = "0" ]; then
    echo "⚠️ Ejecutándose como root, esto no es recomendado"
    echo "   Cambiando a usuario msnai..."
    exec gosu msnai "$0" "$@"
fi

# Run main function
main "$@"
