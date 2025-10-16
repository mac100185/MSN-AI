#!/bin/bash
# MSN-AI Docker Stop Script
# Version: 1.1.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Simple script to stop MSN-AI Docker containers

echo "🛑 MSN-AI Docker - Deteniendo Contenedores"
echo "========================================="
echo "📧 Por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "========================================="

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
    echo "   Verifica tu instalación de Docker"
    exit 1
fi

echo "✅ Usando: $COMPOSE_CMD"

# Parse command line arguments
REMOVE_VOLUMES=false
FORCE=false
TIMEOUT=10

while [[ $# -gt 0 ]]; do
    case $1 in
        --volumes|-v)
            REMOVE_VOLUMES=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --timeout|-t)
            TIMEOUT="$2"
            shift 2
            ;;
        --help|-h)
            echo ""
            echo "Uso: $0 [opciones]"
            echo ""
            echo "Opciones:"
            echo "  --volumes, -v     Remover volúmenes (¡ELIMINA DATOS PERMANENTEMENTE!)"
            echo "  --force, -f       Forzar detención inmediata (kill)"
            echo "  --timeout, -t N   Timeout en segundos para graceful shutdown (default: 10)"
            echo "  --help, -h        Mostrar esta ayuda"
            echo ""
            echo "Ejemplos:"
            echo "  $0                # Detención normal"
            echo "  $0 --timeout 30   # Detención con 30s timeout"
            echo "  $0 --force        # Detención forzada"
            echo "  $0 --volumes      # ⚠️ Detener Y eliminar datos"
            echo ""
            echo "⚠️  CUIDADO:"
            echo "   --volumes eliminará TODOS los chats, modelos y configuraciones"
            echo "   Haz backup antes de usar esta opción"
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

# Show current status first
echo ""
echo "📊 Estado actual de los contenedores:"
if $COMPOSE_CMD -f docker/docker-compose.yml ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null; then
    echo ""
else
    # Fallback for older compose versions
    $COMPOSE_CMD -f docker/docker-compose.yml ps
    echo ""
fi

# Warning for volumes
if [ "$REMOVE_VOLUMES" = true ]; then
    echo "⚠️  ¡ADVERTENCIA! Has seleccionado eliminar volúmenes"
    echo "   Esto eliminará permanentemente:"
    echo "   - 💬 Todos tus chats guardados"
    echo "   - 🤖 Modelos de IA descargados"
    echo "   - ⚙️  Configuraciones personalizadas"
    echo "   - 📊 Logs del sistema"
    echo ""
    read -p "¿Estás SEGURO de que quieres eliminar todos los datos? (escriba 'ELIMINAR' para confirmar): " confirmation
    if [ "$confirmation" != "ELIMINAR" ]; then
        echo "❌ Cancelado por el usuario"
        echo "💡 Para detener sin eliminar datos, usa: $0"
        exit 1
    fi
    echo ""
    echo "⚠️  Confirmación recibida. Procediendo con eliminación de datos..."
fi

# Build compose command
COMPOSE_ARGS=()

if [ "$FORCE" = true ]; then
    echo "⚡ Detención forzada activada"
    COMPOSE_ARGS+=(--timeout 0)
else
    COMPOSE_ARGS+=(--timeout "$TIMEOUT")
fi

if [ "$REMOVE_VOLUMES" = true ]; then
    COMPOSE_ARGS+=(-v)
fi

echo ""
echo "🛑 Deteniendo servicios MSN-AI..."

# Stop services
if $COMPOSE_CMD -f docker/docker-compose.yml down "${COMPOSE_ARGS[@]}"; then
    echo ""
    echo "✅ Servicios detenidos exitosamente"

    if [ "$REMOVE_VOLUMES" = true ]; then
        echo "🗑️  Volúmenes eliminados"
        echo ""
        echo "💾 Para futuras instalaciones, recuerda:"
        echo "   - Tus chats y configuraciones fueron eliminados"
        echo "   - Los modelos de IA deberán descargarse nuevamente"
        echo "   - La próxima instalación será como la primera vez"
    else
        echo ""
        echo "💾 Datos preservados en volúmenes Docker:"
        echo "   - 💬 Chats guardados: msn-ai-chats"
        echo "   - 🤖 Modelos IA: msn-ai-ollama-data"
        echo "   - ⚙️  Configuraciones: msn-ai-data"
        echo ""
        echo "💡 Para reiniciar los servicios:"
        echo "   ./docker-start.sh"
    fi

    # Clean up any remaining containers (safety check)
    echo ""
    echo "🧹 Verificando limpieza..."
    REMAINING=$(docker ps -q --filter "label=com.msnai.service" 2>/dev/null)
    if [ -n "$REMAINING" ]; then
        echo "🔍 Limpiando contenedores restantes..."
        docker stop $REMAINING >/dev/null 2>&1
        docker rm $REMAINING >/dev/null 2>&1
    fi
    echo "✅ Limpieza completada"

else
    echo ""
    echo "❌ Error deteniendo los servicios"
    echo ""
    echo "🔍 Para diagnóstico:"
    echo "   docker ps -a"
    echo "   $COMPOSE_CMD -f docker/docker-compose.yml logs"
    echo ""
    echo "💡 Para forzar detención:"
    echo "   $0 --force"
    echo ""
    echo "🆘 Para emergencia extrema:"
    echo "   docker stop \$(docker ps -q --filter 'label=com.msnai.service')"
    echo "   docker rm \$(docker ps -aq --filter 'label=com.msnai.service')"
    exit 1
fi

echo ""
echo "👋 ¡Gracias por usar MSN-AI v1.1.0!"
echo "📧 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
echo "🐳 Docker Edition"
