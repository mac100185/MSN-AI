#!/bin/bash
# MSN-AI Docker Start Script
# Version: 1.1.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Simple script to start MSN-AI Docker containers

# Make all Docker management scripts executable
chmod +x docker-*.sh 2>/dev/null || true

echo "🐳 MSN-AI Docker - Iniciando Contenedores"
echo "========================================"
echo "📧 Por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "========================================"

# Check if we're in the correct directory
if [ ! -f "docker/docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml no encontrado"
    echo "   Ejecuta este script desde el directorio raíz de MSN-AI"
    exit 1
fi

# Function to detect Docker Compose command
detect_compose_command() {
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    elif docker compose version &> /dev/null 2>&1; then
        echo "docker compose"
    else
        echo ""
    fi
}

# Get Docker Compose command
COMPOSE_CMD=$(detect_compose_command)

if [ -z "$COMPOSE_CMD" ]; then
    echo "❌ Docker Compose no disponible"
    echo "   Instala docker-compose o usa Docker Desktop"
    echo ""
    echo "💡 Para instalar docker-compose:"
    echo "   curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose"
    echo "   sudo chmod +x /usr/local/bin/docker-compose"
    exit 1
fi

echo "✅ Usando: $COMPOSE_CMD"

# Parse command line arguments
DETACHED=true
BUILD=false
FORCE_RECREATE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-detach)
            DETACHED=false
            shift
            ;;
        --build)
            BUILD=true
            shift
            ;;
        --recreate)
            FORCE_RECREATE=true
            shift
            ;;
        --help|-h)
            echo ""
            echo "Uso: $0 [opciones]"
            echo ""
            echo "Opciones:"
            echo "  --no-detach    No ejecutar en background (ver logs en tiempo real)"
            echo "  --build        Reconstruir imágenes antes de iniciar"
            echo "  --recreate     Forzar recreación de contenedores"
            echo "  --help, -h     Mostrar esta ayuda"
            echo ""
            echo "Ejemplos:"
            echo "  $0                    # Inicio normal"
            echo "  $0 --build           # Reconstruir e iniciar"
            echo "  $0 --no-detach       # Ver logs en tiempo real"
            echo "  $0 --recreate        # Forzar recreación"
            echo ""
            exit 0
            ;;
        *)
            echo "❌ Opción desconocida: $1"
            echo "   Usa --help para ver opciones disponibles"
            exit 1
            ;;
    esac
done

# Build compose command
COMPOSE_ARGS=()
if [ "$BUILD" = true ]; then
    COMPOSE_ARGS+=(--build)
    echo "🔨 Reconstruyendo imágenes..."
fi

if [ "$FORCE_RECREATE" = true ]; then
    COMPOSE_ARGS+=(--force-recreate)
    echo "♻️  Forzando recreación de contenedores..."
fi

if [ "$DETACHED" = true ]; then
    COMPOSE_ARGS+=(-d)
fi

echo ""
echo "🚀 Iniciando servicios MSN-AI..."

# Start services
if $COMPOSE_CMD -f docker/docker-compose.yml up "${COMPOSE_ARGS[@]}"; then
    if [ "$DETACHED" = true ]; then
        echo ""
        echo "✅ Servicios iniciados exitosamente"
        echo ""
        echo "📊 Estado actual:"
        $COMPOSE_CMD -f docker/docker-compose.yml ps
        echo ""
        echo "🌐 MSN-AI disponible en: http://localhost:8000/msn-ai.html"
        echo ""
        echo "💡 Comandos útiles:"
        echo "   Ver logs:     $COMPOSE_CMD -f docker/docker-compose.yml logs -f"
        echo "   Ver estado:   $COMPOSE_CMD -f docker/docker-compose.yml ps"
        echo "   Detener:      $COMPOSE_CMD -f docker/docker-compose.yml down"
        echo "   Reiniciar:    $COMPOSE_CMD -f docker/docker-compose.yml restart"
        echo ""
        echo "   O usa los scripts dedicados:"
        echo "   ./docker-stop.sh    # Detener servicios"
        echo "   ./docker-logs.sh    # Ver logs"
        echo "   ./docker-status.sh  # Ver estado"
    else
        echo ""
        echo "✅ Servicios iniciados en modo interactivo"
        echo "   Presiona Ctrl+C para detener todos los servicios"
    fi
else
    echo ""
    echo "❌ Error iniciando los servicios"
    echo ""
    echo "🔍 Para diagnosticar problemas:"
    echo "   $COMPOSE_CMD -f docker/docker-compose.yml logs"
    echo "   docker ps -a"
    echo "   docker images"
    exit 1
fi

# If not detached, wait for interrupt
if [ "$DETACHED" = false ]; then
    echo ""
    echo "⏳ Servicios ejecutándose... (Ctrl+C para detener)"

    # Function to cleanup on interrupt
    cleanup_on_interrupt() {
        echo ""
        echo "🛑 Deteniendo servicios..."
        $COMPOSE_CMD -f docker/docker-compose.yml down
        echo "✅ Servicios detenidos"
        exit 0
    }

    # Set trap for cleanup
    trap cleanup_on_interrupt SIGINT SIGTERM

    # Wait for interrupt
    while true; do
        sleep 1
    done
fi
