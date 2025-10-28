#!/bin/bash
# Docker Debug Mode Startup Script for MSN-AI - Linux
# Version: 1.0.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Start MSN-AI Docker with full debug logging and verbose output

echo "🔍 MSN-AI v2.1.0 - Docker Debug Mode"
echo "===================================="
echo "📧 Desarrollado por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "🐛 Modo: DEBUG COMPLETO"
echo "===================================="
echo ""

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
    echo "   $PROJECT_ROOT/linux/docker-start-debug.sh"
    exit 1
fi

echo "✅ Proyecto MSN-AI detectado correctamente"
echo ""

# Create debug log directory
DEBUG_LOG_DIR="$PROJECT_ROOT/docker/logs/debug"
mkdir -p "$DEBUG_LOG_DIR"
DEBUG_LOG_FILE="$DEBUG_LOG_DIR/debug_$(date +%Y%m%d_%H%M%S).log"

echo "📝 Log de debug: $DEBUG_LOG_FILE"
echo ""

# Function to log with timestamp
log_debug() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" | tee -a "$DEBUG_LOG_FILE"
}

# Start logging
log_debug "========================================="
log_debug "MSN-AI Docker Debug Mode Started"
log_debug "========================================="
log_debug ""

# System Information
log_debug "=== INFORMACIÓN DEL SISTEMA ==="
log_debug "Usuario: $(whoami)"
log_debug "Hostname: $(hostname)"
log_debug "OS: $(uname -a)"
log_debug "Fecha: $(date)"
log_debug ""

# Memory and CPU info
log_debug "=== RECURSOS DEL SISTEMA ==="
log_debug "CPU cores: $(nproc)"
log_debug "Memoria total: $(free -h | awk '/^Mem:/ {print $2}')"
log_debug "Memoria disponible: $(free -h | awk '/^Mem:/ {print $7}')"
log_debug "Espacio en disco:"
df -h / | tee -a "$DEBUG_LOG_FILE"
log_debug ""

# Docker version and info
log_debug "=== DOCKER INFORMATION ==="
docker --version | tee -a "$DEBUG_LOG_FILE"
log_debug ""
log_debug "Docker info:"
docker info 2>&1 | tee -a "$DEBUG_LOG_FILE"
log_debug ""

# Check docker-compose
log_debug "=== DOCKER COMPOSE ==="
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
    log_debug "Usando: docker-compose (standalone)"
    docker-compose --version | tee -a "$DEBUG_LOG_FILE"
elif docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
    log_debug "Usando: docker compose (plugin)"
    docker compose version | tee -a "$DEBUG_LOG_FILE"
else
    log_debug "❌ Docker Compose no encontrado"
    exit 1
fi
log_debug ""

# Clean up any existing containers
log_debug "=== LIMPIEZA DE CONTENEDORES PREVIOS ==="
log_debug "Deteniendo contenedores existentes..."
$DOCKER_COMPOSE_CMD -f docker/docker-compose.yml down 2>&1 | tee -a "$DEBUG_LOG_FILE"
log_debug ""

# Show current containers and images
log_debug "=== ESTADO ACTUAL ==="
log_debug "Contenedores:"
docker ps -a | tee -a "$DEBUG_LOG_FILE"
log_debug ""
log_debug "Imágenes:"
docker images | tee -a "$DEBUG_LOG_FILE"
log_debug ""
log_debug "Volúmenes MSN-AI:"
docker volume ls | grep msn-ai | tee -a "$DEBUG_LOG_FILE"
log_debug ""

# Build with full verbosity
log_debug "=== CONSTRUCCIÓN DE IMAGEN (MODO VERBOSE) ==="
log_debug "Iniciando build con --progress=plain y --no-cache..."
log_debug ""

echo "⚠️  ATENCIÓN: La construcción en modo debug es más lenta pero muestra todos los detalles"
echo "   Presiona Ctrl+C para cancelar"
echo ""
sleep 3

# Enable debug mode in container
export DEBUG=1
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain

# Build command with full output
BUILD_CMD="$DOCKER_COMPOSE_CMD -f docker/docker-compose.yml build --no-cache --progress=plain"
log_debug "Comando: $BUILD_CMD"
log_debug ""

if $BUILD_CMD 2>&1 | tee -a "$DEBUG_LOG_FILE"; then
    log_debug ""
    log_debug "✅ Build completado exitosamente"
else
    BUILD_EXIT=$?
    log_debug ""
    log_debug "❌ Build falló con código: $BUILD_EXIT"
    log_debug "📝 Log completo guardado en: $DEBUG_LOG_FILE"
    exit $BUILD_EXIT
fi
log_debug ""

# Start containers with verbose output
log_debug "=== INICIO DE CONTENEDORES (MODO VERBOSE) ==="
log_debug "Iniciando servicios con logs en tiempo real..."
log_debug ""

# Start in foreground to see all logs
COMPOSE_CMD="$DOCKER_COMPOSE_CMD -f docker/docker-compose.yml up --remove-orphans"
log_debug "Comando: $COMPOSE_CMD"
log_debug ""

echo "🚀 Iniciando contenedores en modo debug..."
echo "   Los logs se mostrarán en tiempo real"
echo "   Presiona Ctrl+C para detener (limpiará contenedores)"
echo ""
sleep 2

# Trap for cleanup
cleanup_debug() {
    echo ""
    log_debug "🛑 Deteniendo contenedores..."
    $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml down 2>&1 | tee -a "$DEBUG_LOG_FILE"
    log_debug ""
    log_debug "✅ Debug session terminada"
    log_debug "📝 Log completo: $DEBUG_LOG_FILE"
    echo ""
    echo "📊 Resumen del debug:"
    echo "   Log guardado en: $DEBUG_LOG_FILE"
    echo "   Tamaño: $(du -h "$DEBUG_LOG_FILE" | cut -f1)"
    echo ""
    exit 0
}

trap cleanup_debug SIGINT SIGTERM

# Start services (this will block and show all logs)
log_debug "========================================="
log_debug "LOGS EN TIEMPO REAL:"
log_debug "========================================="

$COMPOSE_CMD 2>&1 | tee -a "$DEBUG_LOG_FILE"

# If we get here, containers stopped on their own
COMPOSE_EXIT=$?
log_debug ""
log_debug "⚠️  Contenedores se detuvieron"
log_debug "   Código de salida: $COMPOSE_EXIT"
log_debug ""
log_debug "📝 Log completo guardado en: $DEBUG_LOG_FILE"

if [ $COMPOSE_EXIT -ne 0 ]; then
    echo ""
    echo "❌ Los contenedores se detuvieron con errores"
    echo "📝 Revisa el log completo: $DEBUG_LOG_FILE"
    echo ""
    echo "🔍 Últimos 50 errores encontrados:"
    grep -i "error\|fail\|exception\|fatal" "$DEBUG_LOG_FILE" | tail -50
    echo ""
    exit $COMPOSE_EXIT
fi

exit 0
