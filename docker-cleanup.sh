#!/bin/bash
# MSN-AI Docker Cleanup Script
# Version: 1.1.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Complete cleanup script for MSN-AI Docker installation

echo "🧹 MSN-AI Docker - Limpieza Completa del Sistema"
echo "=============================================="
echo "📧 Por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "=============================================="

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
    echo "   Continuando con limpieza manual..."
    COMPOSE_CMD=""
fi

# Parse command line arguments
REMOVE_IMAGES=false
REMOVE_VOLUMES=false
REMOVE_NETWORKS=false
FORCE_ALL=false
INTERACTIVE=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --all|-a)
            REMOVE_IMAGES=true
            REMOVE_VOLUMES=true
            REMOVE_NETWORKS=true
            shift
            ;;
        --images|-i)
            REMOVE_IMAGES=true
            shift
            ;;
        --volumes|-v)
            REMOVE_VOLUMES=true
            shift
            ;;
        --networks|-n)
            REMOVE_NETWORKS=true
            shift
            ;;
        --force|-f)
            FORCE_ALL=true
            INTERACTIVE=false
            shift
            ;;
        --yes|-y)
            INTERACTIVE=false
            shift
            ;;
        --help|-h)
            echo ""
            echo "Uso: $0 [opciones]"
            echo ""
            echo "Opciones de limpieza:"
            echo "  --all, -a         Limpieza completa (contenedores + imágenes + volúmenes + redes)"
            echo "  --images, -i      Eliminar imágenes MSN-AI"
            echo "  --volumes, -v     Eliminar volúmenes (¡ELIMINA DATOS PERMANENTEMENTE!)"
            echo "  --networks, -n    Eliminar redes Docker"
            echo ""
            echo "Opciones de control:"
            echo "  --force, -f       Forzar eliminación sin confirmación"
            echo "  --yes, -y         Responder 'sí' a todas las preguntas"
            echo "  --help, -h        Mostrar esta ayuda"
            echo ""
            echo "Ejemplos:"
            echo "  $0                # Limpieza básica (solo contenedores)"
            echo "  $0 --all          # Limpieza completa"
            echo "  $0 --volumes      # Solo eliminar datos"
            echo "  $0 --images       # Solo eliminar imágenes"
            echo "  $0 --all --force  # Limpieza completa sin confirmación"
            echo ""
            echo "⚠️  CUIDADO:"
            echo "   --volumes eliminará PERMANENTEMENTE:"
            echo "   - Todos tus chats guardados"
            echo "   - Modelos de IA descargados (varios GB)"
            echo "   - Configuraciones personalizadas"
            echo "   - Logs del sistema"
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

echo ""
echo "🔍 Analizando instalación MSN-AI Docker..."

# Check what exists
CONTAINERS_EXIST=$(docker ps -aq --filter "label=com.msnai.service" 2>/dev/null | wc -l)
IMAGES_EXIST=$(docker images --filter "label=com.msnai.service" -q 2>/dev/null | wc -l)
VOLUMES_EXIST=$(docker volume ls --filter "label=com.msnai.volume" -q 2>/dev/null | wc -l)
NETWORKS_EXIST=$(docker network ls --filter "label=com.msnai.network" -q 2>/dev/null | wc -l)

echo ""
echo "📊 Estado actual:"
echo "   🐳 Contenedores MSN-AI: $CONTAINERS_EXIST"
echo "   📦 Imágenes MSN-AI: $IMAGES_EXIST"
echo "   💾 Volúmenes MSN-AI: $VOLUMES_EXIST"
echo "   🌐 Redes MSN-AI: $NETWORKS_EXIST"

if [ "$CONTAINERS_EXIST" -eq 0 ] && [ "$IMAGES_EXIST" -eq 0 ] && [ "$VOLUMES_EXIST" -eq 0 ] && [ "$NETWORKS_EXIST" -eq 0 ]; then
    echo ""
    echo "✅ No se encontraron recursos de MSN-AI para limpiar"
    echo "   El sistema ya está limpio"
    exit 0
fi

# Show what will be cleaned
echo ""
echo "🧹 Limpieza planificada:"
echo "   🐳 Contenedores: SÍ (detendrá y eliminará)"

if [ "$REMOVE_IMAGES" = true ]; then
    echo "   📦 Imágenes: SÍ (liberará ~2-4GB)"
else
    echo "   📦 Imágenes: NO"
fi

if [ "$REMOVE_VOLUMES" = true ]; then
    echo "   💾 Volúmenes: SÍ (⚠️ ELIMINARÁ DATOS PERMANENTEMENTE)"
    echo "       - Chats guardados"
    echo "       - Modelos IA (hasta 40GB+)"
    echo "       - Configuraciones"
else
    echo "   💾 Volúmenes: NO (datos preservados)"
fi

if [ "$REMOVE_NETWORKS" = true ]; then
    echo "   🌐 Redes: SÍ"
else
    echo "   🌐 Redes: NO"
fi

# Confirmation if interactive
if [ "$INTERACTIVE" = true ]; then
    echo ""
    if [ "$REMOVE_VOLUMES" = true ]; then
        echo "⚠️  ¡ADVERTENCIA CRÍTICA!"
        echo "   Vas a eliminar PERMANENTEMENTE todos los datos de MSN-AI"
        echo "   Esto incluye chats, modelos de IA y configuraciones"
        echo "   Esta acción NO SE PUEDE DESHACER"
        echo ""
        read -p "Para continuar, escribe 'ELIMINAR TODO': " confirmation
        if [ "$confirmation" != "ELIMINAR TODO" ]; then
            echo "❌ Cancelado por el usuario"
            echo "💡 Para limpieza sin eliminar datos: $0 --images"
            exit 1
        fi
    else
        read -p "¿Continuar con la limpieza? (s/N): " confirmation
        if [[ ! "$confirmation" =~ ^[sS]$ ]]; then
            echo "❌ Cancelado por el usuario"
            exit 1
        fi
    fi
fi

echo ""
echo "🚀 Iniciando limpieza de MSN-AI..."

# Step 1: Stop and remove containers
if [ "$CONTAINERS_EXIST" -gt 0 ]; then
    echo ""
    echo "🛑 Paso 1: Deteniendo y eliminando contenedores..."

    if [ -n "$COMPOSE_CMD" ]; then
        echo "   Usando $COMPOSE_CMD..."
        if [ "$REMOVE_VOLUMES" = true ]; then
            $COMPOSE_CMD -f docker/docker-compose.yml down -v --remove-orphans 2>/dev/null || true
        else
            $COMPOSE_CMD -f docker/docker-compose.yml down --remove-orphans 2>/dev/null || true
        fi
    fi

    # Manual cleanup for any remaining containers
    REMAINING_CONTAINERS=$(docker ps -aq --filter "label=com.msnai.service" 2>/dev/null)
    if [ -n "$REMAINING_CONTAINERS" ]; then
        echo "   Limpiando contenedores restantes..."
        docker stop $REMAINING_CONTAINERS >/dev/null 2>&1 || true
        docker rm -f $REMAINING_CONTAINERS >/dev/null 2>&1 || true
    fi

    echo "   ✅ Contenedores eliminados"
else
    echo ""
    echo "ℹ️  No hay contenedores MSN-AI para eliminar"
fi

# Step 2: Remove images if requested
if [ "$REMOVE_IMAGES" = true ]; then
    echo ""
    echo "📦 Paso 2: Eliminando imágenes..."

    # Remove images with MSN-AI labels
    MSNAI_IMAGES=$(docker images --filter "label=com.msnai.service" -q 2>/dev/null)
    if [ -n "$MSNAI_IMAGES" ]; then
        echo "   Eliminando imágenes MSN-AI..."
        docker rmi -f $MSNAI_IMAGES >/dev/null 2>&1 || true
    fi

    # Remove images by name pattern
    docker rmi -f msn-ai-app >/dev/null 2>&1 || true
    docker rmi -f msn-ai_msn-ai >/dev/null 2>&1 || true
    docker rmi -f msn-ai_ai-setup >/dev/null 2>&1 || true

    echo "   ✅ Imágenes eliminadas"
fi

# Step 3: Remove volumes if requested
if [ "$REMOVE_VOLUMES" = true ]; then
    echo ""
    echo "💾 Paso 3: Eliminando volúmenes (DATOS PERMANENTEMENTE)..."

    # Remove labeled volumes
    MSNAI_VOLUMES=$(docker volume ls --filter "label=com.msnai.volume" -q 2>/dev/null)
    if [ -n "$MSNAI_VOLUMES" ]; then
        echo "   Eliminando volúmenes etiquetados..."
        docker volume rm -f $MSNAI_VOLUMES >/dev/null 2>&1 || true
    fi

    # Remove volumes by name pattern
    docker volume rm -f msn-ai-data >/dev/null 2>&1 || true
    docker volume rm -f msn-ai-chats >/dev/null 2>&1 || true
    docker volume rm -f msn-ai-logs >/dev/null 2>&1 || true
    docker volume rm -f msn-ai-ollama-data >/dev/null 2>&1 || true

    echo "   ✅ Volúmenes eliminados (datos perdidos permanentemente)"
fi

# Step 4: Remove networks if requested
if [ "$REMOVE_NETWORKS" = true ]; then
    echo ""
    echo "🌐 Paso 4: Eliminando redes..."

    # Remove labeled networks
    MSNAI_NETWORKS=$(docker network ls --filter "label=com.msnai.network" -q 2>/dev/null)
    if [ -n "$MSNAI_NETWORKS" ]; then
        echo "   Eliminando redes etiquetadas..."
        docker network rm $MSNAI_NETWORKS >/dev/null 2>&1 || true
    fi

    # Remove networks by name pattern
    docker network rm msn-ai-network >/dev/null 2>&1 || true

    echo "   ✅ Redes eliminadas"
fi

# Final verification
echo ""
echo "🔍 Verificando limpieza final..."

FINAL_CONTAINERS=$(docker ps -aq --filter "label=com.msnai.service" 2>/dev/null | wc -l)
FINAL_IMAGES=$(docker images --filter "label=com.msnai.service" -q 2>/dev/null | wc -l)
FINAL_VOLUMES=$(docker volume ls --filter "label=com.msnai.volume" -q 2>/dev/null | wc -l)
FINAL_NETWORKS=$(docker network ls --filter "label=com.msnai.network" -q 2>/dev/null | wc -l)

echo ""
echo "📊 Estado final:"
echo "   🐳 Contenedores restantes: $FINAL_CONTAINERS"
echo "   📦 Imágenes restantes: $FINAL_IMAGES"
echo "   💾 Volúmenes restantes: $FINAL_VOLUMES"
echo "   🌐 Redes restantes: $FINAL_NETWORKS"

# Summary
echo ""
echo "🎉 Limpieza de MSN-AI completada"
echo "================================"

if [ "$REMOVE_VOLUMES" = true ]; then
    echo "⚠️  DATOS ELIMINADOS PERMANENTEMENTE"
    echo "   - Chats, modelos IA, y configuraciones fueron eliminados"
    echo "   - La próxima instalación será completamente nueva"
    echo ""
    echo "💡 Para reinstalar MSN-AI:"
    echo "   ./start-msnai-docker.sh --auto"
else
    echo "✅ Limpieza conservadora completada"
    echo "   - Contenedores eliminados"
    if [ "$REMOVE_IMAGES" = true ]; then
        echo "   - Imágenes eliminadas (se reconstruirán en próximo inicio)"
    fi
    echo "   - Datos preservados en volúmenes"
    echo ""
    echo "💡 Para reiniciar MSN-AI:"
    echo "   ./docker-start.sh"
fi

# Show disk space freed (approximate)
if [ "$REMOVE_IMAGES" = true ] || [ "$REMOVE_VOLUMES" = true ]; then
    echo ""
    echo "💾 Espacio aproximado liberado:"
    if [ "$REMOVE_IMAGES" = true ] && [ "$REMOVE_VOLUMES" = true ]; then
        echo "   ~2-44GB+ (imágenes + modelos IA + datos)"
    elif [ "$REMOVE_IMAGES" = true ]; then
        echo "   ~2-4GB (solo imágenes Docker)"
    elif [ "$REMOVE_VOLUMES" = true ]; then
        echo "   ~500MB-40GB+ (dependiendo de modelos IA instalados)"
    fi
fi

echo ""
echo "👋 Limpieza completada exitosamente"
echo "📧 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
echo "🧹 MSN-AI Docker Cleanup v1.1.0"
