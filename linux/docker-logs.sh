#!/bin/bash
# MSN-AI Docker Logs Script
# Version: 1.1.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Simple script to view MSN-AI Docker container logs

echo "📋 MSN-AI Docker - Visualizador de Logs"
echo "======================================"
echo "📧 Por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "======================================"

# Detect and change to project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT" || {
    echo "❌ Error: No se pudo cambiar al directorio del proyecto"
    exit 1
}

# Verify we're in the correct directory
if [ ! -f "docker/docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml no encontrado"
    echo "   Estructura del proyecto incorrecta"
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
    echo "   Verifica tu instalación de Docker"
    exit 1
fi

# Parse command line arguments
FOLLOW=false
SERVICE=""
TAIL="all"
TIMESTAMPS=false
SINCE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --follow|-f)
            FOLLOW=true
            shift
            ;;
        --service|-s)
            SERVICE="$2"
            shift 2
            ;;
        --tail|-t)
            TAIL="$2"
            shift 2
            ;;
        --timestamps|--ts)
            TIMESTAMPS=true
            shift
            ;;
        --since)
            SINCE="$2"
            shift 2
            ;;
        --help|-h)
            echo ""
            echo "Uso: $0 [opciones]"
            echo ""
            echo "Opciones:"
            echo "  --follow, -f        Seguir logs en tiempo real (Ctrl+C para salir)"
            echo "  --service, -s NAME  Ver logs de servicio específico (msn-ai, ollama, ai-setup)"
            echo "  --tail, -t N        Mostrar últimas N líneas (default: todas)"
            echo "  --timestamps, --ts  Mostrar timestamps"
            echo "  --since TIME        Mostrar logs desde tiempo específico"
            echo "  --help, -h          Mostrar esta ayuda"
            echo ""
            echo "Servicios disponibles:"
            echo "  msn-ai     Aplicación web principal"
            echo "  ollama     Servicio de IA local"
            echo "  ai-setup   Configuración inicial de modelos"
            echo ""
            echo "Ejemplos:"
            echo "  $0                    # Ver todos los logs"
            echo "  $0 --follow           # Seguir logs en tiempo real"
            echo "  $0 --service ollama   # Solo logs de Ollama"
            echo "  $0 --tail 50          # Últimas 50 líneas"
            echo "  $0 --since '1h'       # Logs de la última hora"
            echo "  $0 --timestamps -f    # Tiempo real con timestamps"
            echo ""
            echo "Formatos de tiempo para --since:"
            echo "  '1h'      Una hora atrás"
            echo "  '30m'     30 minutos atrás"
            echo "  '1d'      Un día atrás"
            echo "  '2025-01-15'          Fecha específica"
            echo "  '2025-01-15T10:30'    Fecha y hora específica"
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

# Check if containers are running
RUNNING_CONTAINERS=$($COMPOSE_CMD -f docker/docker-compose.yml ps --format "{{.Service}}" 2>/dev/null | wc -l)

if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
    echo ""
    echo "⚠️  No hay contenedores MSN-AI ejecutándose"
    echo ""
    echo "💡 Para iniciar los servicios:"
    echo "   ./docker-start.sh"
    echo ""
    echo "🔍 Para ver logs de contenedores detenidos:"
    echo "   docker logs msn-ai-app"
    echo "   docker logs msn-ai-ollama"
    echo "   docker logs msn-ai-setup"
    exit 1
fi

# Show current container status
echo ""
echo "📊 Estado actual de contenedores:"
if $COMPOSE_CMD -f docker/docker-compose.yml ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null; then
    echo ""
else
    # Fallback for older compose versions
    $COMPOSE_CMD -f docker/docker-compose.yml ps
    echo ""
fi

# Build compose logs command
COMPOSE_ARGS=()

if [ "$FOLLOW" = true ]; then
    COMPOSE_ARGS+=(-f)
fi

if [ "$TIMESTAMPS" = true ]; then
    COMPOSE_ARGS+=(--timestamps)
fi

if [ "$TAIL" != "all" ]; then
    COMPOSE_ARGS+=(--tail "$TAIL")
fi

if [ -n "$SINCE" ]; then
    COMPOSE_ARGS+=(--since "$SINCE")
fi

# Add service if specified
if [ -n "$SERVICE" ]; then
    # Validate service name
    case $SERVICE in
        msn-ai|ollama|ai-setup)
            COMPOSE_ARGS+=("$SERVICE")
            echo "🔍 Mostrando logs del servicio: $SERVICE"
            ;;
        *)
            echo "❌ Servicio desconocido: $SERVICE"
            echo "   Servicios válidos: msn-ai, ollama, ai-setup"
            exit 1
            ;;
    esac
else
    echo "🔍 Mostrando logs de todos los servicios"
fi

if [ "$FOLLOW" = true ]; then
    echo "📡 Siguiendo logs en tiempo real... (Ctrl+C para salir)"
    echo ""
    echo "💡 Códigos de color por servicio:"
    echo "   🟦 Azul:     msn-ai (aplicación web)"
    echo "   🟩 Verde:    ollama (servicio IA)"
    echo "   🟨 Amarillo: ai-setup (configuración)"
else
    if [ -n "$SINCE" ]; then
        echo "📅 Mostrando logs desde: $SINCE"
    fi
    if [ "$TAIL" != "all" ]; then
        echo "📄 Mostrando últimas $TAIL líneas"
    else
        echo "📄 Mostrando todos los logs disponibles"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Execute logs command
if $COMPOSE_CMD -f docker/docker-compose.yml logs "${COMPOSE_ARGS[@]}"; then
    if [ "$FOLLOW" = false ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "✅ Logs mostrados exitosamente"
        echo ""
        echo "💡 Comandos útiles:"
        echo "   $0 --follow              # Ver logs en tiempo real"
        echo "   $0 --service ollama      # Solo logs de Ollama"
        echo "   $0 --tail 100            # Últimas 100 líneas"
        echo "   $0 --since '30m'         # Últimos 30 minutos"
    fi
else
    echo ""
    echo "❌ Error mostrando logs"
    echo ""
    echo "🔍 Verificaciones:"
    echo "   • ¿Están los contenedores ejecutándose?"
    echo "     $COMPOSE_CMD -f docker/docker-compose.yml ps"
    echo ""
    echo "   • ¿Hay logs disponibles?"
    echo "     docker logs msn-ai-app"
    echo "     docker logs msn-ai-ollama"
    echo ""
    echo "💡 Para reiniciar los servicios:"
    echo "   ./docker-start.sh"
    exit 1
fi

# If follow mode was interrupted
if [ "$FOLLOW" = true ]; then
    echo ""
    echo "📋 Seguimiento de logs finalizado"
    echo ""
    echo "💡 Para continuar viendo logs:"
    echo "   $0 --follow"
fi

echo ""
echo "📋 MSN-AI Docker Logs v1.1.0"
echo "📧 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
