#!/bin/bash
# MSN-AI Docker Status Script
# Version: 1.1.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Simple script to view MSN-AI Docker container status

echo "📊 MSN-AI Docker - Estado de Contenedores"
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
    echo "   Verifica tu instalación de Docker"
    exit 1
fi

# Parse command line arguments
DETAILED=false
WATCH_MODE=false
WATCH_INTERVAL=5

while [[ $# -gt 0 ]]; do
    case $1 in
        --detailed|-d)
            DETAILED=true
            shift
            ;;
        --watch|-w)
            WATCH_MODE=true
            shift
            ;;
        --interval|-i)
            WATCH_INTERVAL="$2"
            shift 2
            ;;
        --help|-h)
            echo ""
            echo "Uso: $0 [opciones]"
            echo ""
            echo "Opciones:"
            echo "  --detailed, -d    Mostrar información detallada (recursos, puertos, health)"
            echo "  --watch, -w       Modo observación continua (Ctrl+C para salir)"
            echo "  --interval, -i N  Intervalo para modo watch en segundos (default: 5)"
            echo "  --help, -h        Mostrar esta ayuda"
            echo ""
            echo "Ejemplos:"
            echo "  $0                # Estado básico"
            echo "  $0 --detailed     # Estado detallado con recursos"
            echo "  $0 --watch        # Monitoreo en tiempo real"
            echo "  $0 -w -i 2        # Watch cada 2 segundos"
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

# Function to show status
show_status() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [ "$WATCH_MODE" = true ]; then
        clear
        echo "📊 MSN-AI Docker Status - $timestamp"
        echo "====================================="
    fi

    echo ""
    echo "🐳 Estado de Contenedores MSN-AI:"

    # Basic status using docker-compose
    if $COMPOSE_CMD -f docker/docker-compose.yml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null; then
        echo ""
    else
        # Fallback for older compose versions
        $COMPOSE_CMD -f docker/docker-compose.yml ps
        echo ""
    fi

    # Count containers by status
    local running_count=$(docker ps --filter "label=com.msnai.service" --format "{{.Status}}" 2>/dev/null | grep -c "Up" || echo "0")
    local stopped_count=$(docker ps -a --filter "label=com.msnai.service" --format "{{.Status}}" 2>/dev/null | grep -c -v "Up" || echo "0")
    local total_count=$((running_count + stopped_count))

    echo "📈 Resumen:"
    echo "   🟢 Ejecutándose: $running_count"
    echo "   🔴 Detenidos: $stopped_count"
    echo "   📦 Total: $total_count"

    # Check if MSN-AI is accessible
    echo ""
    echo "🌐 Conectividad:"
    if curl -s --connect-timeout 3 http://localhost:8000 >/dev/null 2>&1; then
        echo "   ✅ MSN-AI Web: http://localhost:8000/msn-ai.html"
    else
        echo "   ❌ MSN-AI Web: No accesible en puerto 8000"
    fi

    if curl -s --connect-timeout 3 http://localhost:11434 >/dev/null 2>&1; then
        echo "   ✅ Ollama API: http://localhost:11434"
    else
        echo "   ❌ Ollama API: No accesible en puerto 11434"
    fi

    # Detailed information if requested
    if [ "$DETAILED" = true ]; then
        echo ""
        echo "🔍 Información Detallada:"
        echo ""

        # Container details
        local containers=$(docker ps -a --filter "label=com.msnai.service" --format "{{.Names}}" 2>/dev/null)

        if [ -n "$containers" ]; then
            while read -r container; do
                if [ -n "$container" ]; then
                    echo "📦 Contenedor: $container"

                    # Status
                    local status=$(docker inspect "$container" --format "{{.State.Status}}" 2>/dev/null)
                    local health=$(docker inspect "$container" --format "{{.State.Health.Status}}" 2>/dev/null)

                    case $status in
                        running)
                            echo "   🟢 Estado: Ejecutándose"
                            ;;
                        exited)
                            echo "   🔴 Estado: Detenido"
                            ;;
                        restarting)
                            echo "   🟡 Estado: Reiniciando"
                            ;;
                        *)
                            echo "   ⚪ Estado: $status"
                            ;;
                    esac

                    # Health check
                    if [ "$health" != "<no value>" ] && [ -n "$health" ]; then
                        case $health in
                            healthy)
                                echo "   💚 Salud: Saludable"
                                ;;
                            unhealthy)
                                echo "   💔 Salud: No saludable"
                                ;;
                            starting)
                                echo "   💛 Salud: Iniciando"
                                ;;
                            *)
                                echo "   ❓ Salud: $health"
                                ;;
                        esac
                    fi

                    # Ports
                    local ports=$(docker port "$container" 2>/dev/null | tr '\n' ' ')
                    if [ -n "$ports" ]; then
                        echo "   🌐 Puertos: $ports"
                    fi

                    # Resource usage (if running)
                    if [ "$status" = "running" ]; then
                        local stats=$(docker stats "$container" --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | tail -n +2)
                        if [ -n "$stats" ]; then
                            local cpu=$(echo "$stats" | awk '{print $1}')
                            local memory=$(echo "$stats" | awk '{print $2}')
                            echo "   🖥️  CPU: $cpu"
                            echo "   💾 Memoria: $memory"
                        fi
                    fi

                    echo ""
                fi
            done <<< "$containers"
        fi

        # Volume information
        echo "💾 Volúmenes MSN-AI:"
        local volumes=$(docker volume ls --filter "label=com.msnai.volume" --format "{{.Name}}" 2>/dev/null)
        if [ -n "$volumes" ]; then
            while read -r volume; do
                if [ -n "$volume" ]; then
                    local size=$(docker system df -v | grep "$volume" | awk '{print $3}' || echo "N/A")
                    echo "   📁 $volume ($size)"
                fi
            done <<< "$volumes"
        else
            echo "   ❌ No se encontraron volúmenes MSN-AI"
        fi

        # Network information
        echo ""
        echo "🌐 Redes MSN-AI:"
        local networks=$(docker network ls --filter "label=com.msnai.network" --format "{{.Name}}" 2>/dev/null)
        if [ -n "$networks" ]; then
            while read -r network; do
                if [ -n "$network" ]; then
                    echo "   🔗 $network"
                fi
            done <<< "$networks"
        else
            echo "   ❌ No se encontraron redes MSN-AI"
        fi
    fi

    # Show useful commands
    echo ""
    echo "💡 Comandos útiles:"
    echo "   🚀 Iniciar:     ./docker-start.sh"
    echo "   🛑 Detener:     ./docker-stop.sh"
    echo "   📋 Ver logs:    ./docker-logs.sh"
    echo "   🧹 Limpiar:     ./docker-cleanup.sh"
    echo ""
    echo "   📊 Estado:      $COMPOSE_CMD -f docker/docker-compose.yml ps"
    echo "   🔄 Reiniciar:   $COMPOSE_CMD -f docker/docker-compose.yml restart"
    echo "   📋 Logs live:   $COMPOSE_CMD -f docker/docker-compose.yml logs -f"
}

# Main execution
if [ "$WATCH_MODE" = true ]; then
    echo "👁️  Iniciando modo observación (cada ${WATCH_INTERVAL}s)..."
    echo "   Presiona Ctrl+C para salir"
    echo ""

    # Function to cleanup on interrupt
    cleanup_watch() {
        echo ""
        echo "👋 Modo observación finalizado"
        exit 0
    }

    # Set trap for cleanup
    trap cleanup_watch SIGINT SIGTERM

    # Watch loop
    while true; do
        show_status
        echo "🔄 Actualizando en ${WATCH_INTERVAL}s... (Ctrl+C para salir)"
        sleep "$WATCH_INTERVAL"
    done
else
    # Single run
    show_status
    echo "📊 MSN-AI Docker Status v1.1.0"
    echo "📧 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
fi
