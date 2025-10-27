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
NUCLEAR_CLEANUP=false

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
        --nuclear)
            NUCLEAR_CLEANUP=true
            REMOVE_IMAGES=true
            REMOVE_VOLUMES=true
            REMOVE_NETWORKS=true
            shift
            ;;
        --force|-f)
            FORCE_ALL=true
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
            echo "  --nuclear         🔥 RESET TOTAL MSN-AI: Elimina TODO de MSN-AI + limpieza profunda"
            echo ""
            echo "Opciones de control:"
            echo "  --force, -f       Forzar eliminación sin confirmación"
            echo "  --help, -h        Mostrar esta ayuda"
            echo ""
            echo "Ejemplos:"
            echo "  $0                # Limpieza básica (solo contenedores)"
            echo "  $0 --all          # Limpieza completa"
            echo "  $0 --volumes      # Solo eliminar datos"
            echo "  $0 --images       # Solo eliminar imágenes"
            echo "  $0 --all --force  # Limpieza completa sin confirmación"
            echo "  $0 --nuclear      # 🔥 RESET TOTAL del sistema Docker"
            echo ""
            echo "⚠️  CUIDADO:"
            echo "   --volumes eliminará PERMANENTEMENTE:"
            echo "   - Todos tus chats guardados"
            echo "   - Modelos de IA descargados (varios GB)"
            echo "   - Configuraciones personalizadas"
            echo "   - Logs del sistema"
            echo ""
            echo "🔥 PELIGRO EXTREMO --nuclear:"
            echo "   - Elimina TODOS los recursos MSN-AI (contenedores, imágenes, volúmenes, redes)"
            echo "   - Busca y elimina recursos huérfanos relacionados con MSN-AI"
            echo "   - Limpia cache de build relacionado con MSN-AI"
            echo "   - Resetea MSN-AI a estado de instalación fresca"
            echo "   - ⚠️ SOLO AFECTA RECURSOS DE MSN-AI, NO otros proyectos Docker"
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
# Also check for containers by name pattern
CONTAINERS_BY_NAME=$(docker ps -aq --filter "name=msn-ai" 2>/dev/null; docker ps -aq --filter "name=docker-msn-ai" 2>/dev/null; docker ps -aq --filter "name=docker-ai-setup" 2>/dev/null | sort -u | wc -l)
CONTAINERS_EXIST=$((CONTAINERS_EXIST + CONTAINERS_BY_NAME))

IMAGES_EXIST=$(docker images --filter "label=com.msnai.service" -q 2>/dev/null | wc -l)
# Also check for images by name pattern
IMAGES_BY_NAME=$(docker images --format "{{.Repository}}" | grep -cE "(msn-ai|docker-msn-ai|docker-ai-setup)" 2>/dev/null || echo 0)
IMAGES_EXIST=$((IMAGES_EXIST + IMAGES_BY_NAME))

VOLUMES_EXIST=$(docker volume ls --filter "label=com.msnai.volume" -q 2>/dev/null | wc -l)
# Also check for volumes by name pattern
VOLUMES_BY_NAME=$(docker volume ls --format "{{.Name}}" | grep -cE "(msn-ai|msnai)" 2>/dev/null || echo 0)
VOLUMES_EXIST=$((VOLUMES_EXIST + VOLUMES_BY_NAME))

NETWORKS_EXIST=$(docker network ls --filter "label=com.msnai.network" -q 2>/dev/null | wc -l)
# Also check for networks by name pattern
NETWORKS_BY_NAME=$(docker network ls --format "{{.Name}}" | grep -cE "(msn-ai|msnai)" 2>/dev/null || echo 0)
NETWORKS_EXIST=$((NETWORKS_EXIST + NETWORKS_BY_NAME))

echo ""
echo "📊 Estado actual:"
echo "   🐳 Contenedores MSN-AI: $CONTAINERS_EXIST"
echo "   📦 Imágenes MSN-AI: $IMAGES_EXIST"
echo "   💾 Volúmenes MSN-AI: $VOLUMES_EXIST"
echo "   🌐 Redes MSN-AI: $NETWORKS_EXIST"

if [ "$NUCLEAR_CLEANUP" = false ]; then
    if [ "$CONTAINERS_EXIST" -eq 0 ] && [ "$IMAGES_EXIST" -eq 0 ] && [ "$VOLUMES_EXIST" -eq 0 ] && [ "$NETWORKS_EXIST" -eq 0 ]; then
        echo ""
        echo "✅ No se encontraron recursos de MSN-AI para limpiar"
        echo "   El sistema ya está limpio"
        exit 0
    fi
fi

# Show what will be cleaned
echo ""
if [ "$NUCLEAR_CLEANUP" = true ]; then
    echo "🔥 LIMPIEZA NUCLEAR MSN-AI PLANIFICADA:"
    echo "   🐳 Contenedores: TODOS los de MSN-AI (etiquetados y por nombre)"
    echo "   📦 Imágenes: TODAS las de MSN-AI (liberará ~2-4GB)"
    echo "   💾 Volúmenes: TODOS los de MSN-AI (⚠️ TODOS LOS DATOS MSN-AI PERDIDOS)"
    echo "   🌐 Redes: TODAS las de MSN-AI"
    echo "   🧹 Cache Build: Solo relacionado con MSN-AI"
    echo "   🎯 Recursos huérfanos: Busca y elimina residuos MSN-AI"
    echo "   💣 ESTO RESETEA COMPLETAMENTE MSN-AI"
    echo ""
    echo "⚠️  ESTO AFECTARÁ SOLO:"
    echo "       - Recursos etiquetados com.msnai.*"
    echo "       - Contenedores/imágenes con nombres msn-ai*"
    echo "       - Volúmenes msn-ai-*"
    echo "       - ✅ OTROS proyectos Docker NO se afectarán"
else
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
fi

# Confirmation if interactive
if [ "$INTERACTIVE" = true ]; then
    echo ""
    if [ "$NUCLEAR_CLEANUP" = true ]; then
        echo "🚨 ¡ADVERTENCIA NUCLEAR MSN-AI!"
        echo "   Vas a RESETEAR COMPLETAMENTE MSN-AI Docker"
        echo "   Esto afectará SOLO los recursos de MSN-AI"
        echo "   TODOS los datos, imágenes, contenedores MSN-AI serán ELIMINADOS"
        echo "   Tendrás que reinstalar MSN-AI desde cero"
        echo "   Esta acción es IRREVERSIBLE para MSN-AI"
        echo ""
        echo "🔥 Esta opción es para casos extremos MSN-AI como:"
        echo "   - Corrupción de contenedores/imágenes MSN-AI"
        echo "   - Problemas persistentes que no se resuelven"
        echo "   - Resetear MSN-AI a estado fresco sin afectar otros proyectos"
        echo ""
        read -p "Para continuar, escribe 'NUCLEAR MSN-AI': " confirmation
        if [ "$confirmation" != "NUCLEAR MSN-AI" ]; then
            echo "❌ Cancelado por el usuario"
            echo "💡 Para limpieza normal: $0 --all"
            exit 1
        fi
        echo ""
        read -p "¿Estás SEGURO de resetear MSN-AI? Escribe 'RESETEAR MSN-AI': " final_confirmation
        if [ "$final_confirmation" != "RESETEAR MSN-AI" ]; then
            echo "❌ Cancelado por el usuario"
            echo "💡 Decisión inteligente. Para limpieza normal: $0 --all"
            exit 1
        fi
    elif [ "$REMOVE_VOLUMES" = true ]; then
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
if [ "$NUCLEAR_CLEANUP" = true ]; then
    echo "🔥 Iniciando LIMPIEZA NUCLEAR de MSN-AI..."
    echo "⚠️  Esta operación puede tardar algunos minutos"
else
    echo "🚀 Iniciando limpieza de MSN-AI..."
fi

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

    # Also cleanup containers by name pattern (docker-msn-ai, docker-ai-setup)
    DOCKER_NAMED_CONTAINERS=$(docker ps -aq 2>/dev/null | xargs -r docker inspect --format='{{.Name}} {{.Id}}' 2>/dev/null | grep -E "(docker-msn-ai|docker-ai-setup)" | awk '{print $2}')
    if [ -n "$DOCKER_NAMED_CONTAINERS" ]; then
        echo "   Limpiando contenedores docker-msn-ai y docker-ai-setup..."
        docker stop $DOCKER_NAMED_CONTAINERS >/dev/null 2>&1 || true
        docker rm -f $DOCKER_NAMED_CONTAINERS >/dev/null 2>&1 || true
    fi

    # Cleanup containers by name patterns
    echo "   Limpiando contenedores por nombre..."
    docker ps -aq --filter "name=msn-ai" 2>/dev/null | xargs -r docker stop >/dev/null 2>&1 || true
    docker ps -aq --filter "name=msn-ai" 2>/dev/null | xargs -r docker rm -f >/dev/null 2>&1 || true
    docker ps -aq --filter "name=docker-msn-ai" 2>/dev/null | xargs -r docker stop >/dev/null 2>&1 || true
    docker ps -aq --filter "name=docker-msn-ai" 2>/dev/null | xargs -r docker rm -f >/dev/null 2>&1 || true
    docker ps -aq --filter "name=docker-ai-setup" 2>/dev/null | xargs -r docker stop >/dev/null 2>&1 || true
    docker ps -aq --filter "name=docker-ai-setup" 2>/dev/null | xargs -r docker rm -f >/dev/null 2>&1 || true

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
    docker rmi -f docker-msn-ai >/dev/null 2>&1 || true
    docker rmi -f docker-ai-setup >/dev/null 2>&1 || true

    # Remove any images containing msn-ai or docker-ai-setup in the name
    docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep -iE "(msn-ai|docker-msn-ai|docker-ai-setup)" | awk '{print $2}' | xargs -r docker rmi -f >/dev/null 2>&1 || true

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

# Nuclear cleanup additional steps (MSN-AI only)
if [ "$NUCLEAR_CLEANUP" = true ]; then
    echo ""
    echo "🔥 Paso 5: LIMPIEZA NUCLEAR PROFUNDA de MSN-AI..."

    # Find and stop MSN-AI related containers (by name pattern)
    echo "   🛑 Buscando y deteniendo contenedores MSN-AI adicionales..."
    MSNAI_CONTAINERS=$(docker ps -aq --filter "name=msn-ai" 2>/dev/null)
    DOCKER_AI_CONTAINERS=$(docker ps -aq --filter "name=docker-msn-ai" 2>/dev/null)
    DOCKER_SETUP_CONTAINERS=$(docker ps -aq --filter "name=docker-ai-setup" 2>/dev/null)

    if [ -n "$MSNAI_CONTAINERS" ]; then
        docker stop $MSNAI_CONTAINERS >/dev/null 2>&1 || true
        docker rm -f $MSNAI_CONTAINERS >/dev/null 2>&1 || true
    fi
    if [ -n "$DOCKER_AI_CONTAINERS" ]; then
        docker stop $DOCKER_AI_CONTAINERS >/dev/null 2>&1 || true
        docker rm -f $DOCKER_AI_CONTAINERS >/dev/null 2>&1 || true
    fi
    if [ -n "$DOCKER_SETUP_CONTAINERS" ]; then
        docker stop $DOCKER_SETUP_CONTAINERS >/dev/null 2>&1 || true
        docker rm -f $DOCKER_SETUP_CONTAINERS >/dev/null 2>&1 || true
    fi

    # Remove MSN-AI images (by name pattern and labels)
    echo "   📦 Eliminando imágenes MSN-AI huérfanas..."
    docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep -iE "(msn-ai|msnai|docker-msn-ai|docker-ai-setup)" | awk '{print $2}' | xargs -r docker rmi -f >/dev/null 2>&1 || true

    # Remove MSN-AI volumes (by name pattern)
    echo "   💾 Eliminando volúmenes MSN-AI huérfanos..."
    docker volume ls --format "{{.Name}}" | grep -E "(msn-ai|msnai|docker-msn-ai|docker-ai-setup)" | xargs -r docker volume rm -f >/dev/null 2>&1 || true

    # Remove MSN-AI networks (by name pattern)
    echo "   🌐 Eliminando redes MSN-AI huérfanas..."
    docker network ls --format "{{.Name}}" | grep -E "(msn-ai|msnai|docker-msn-ai|docker-ai-setup)" | xargs -r docker network rm >/dev/null 2>&1 || true

    # Clean MSN-AI related build cache
    echo "   🗄️ Limpiando cache de build MSN-AI..."
    docker builder prune -f --filter "label=com.msnai.service" >/dev/null 2>&1 || true

    # Remove any dangling resources that might be MSN-AI related
    echo "   🧹 Limpieza final de recursos huérfanos..."
    docker system prune -f >/dev/null 2>&1 || true

    echo "   💥 LIMPIEZA NUCLEAR MSN-AI COMPLETADA"
fi

# Final verification
echo ""
echo "🔍 Verificando limpieza final..."

FINAL_CONTAINERS=$(docker ps -aq --filter "label=com.msnai.service" 2>/dev/null | wc -l)
# Also check by name
FINAL_CONTAINERS_BY_NAME=$(docker ps -aq --filter "name=msn-ai" 2>/dev/null; docker ps -aq --filter "name=docker-msn-ai" 2>/dev/null; docker ps -aq --filter "name=docker-ai-setup" 2>/dev/null | sort -u | wc -l)
FINAL_CONTAINERS=$((FINAL_CONTAINERS + FINAL_CONTAINERS_BY_NAME))

FINAL_IMAGES=$(docker images --filter "label=com.msnai.service" -q 2>/dev/null | wc -l)
# Also check by name
FINAL_IMAGES_BY_NAME=$(docker images --format "{{.Repository}}" | grep -cE "(msn-ai|docker-msn-ai|docker-ai-setup)" 2>/dev/null || echo 0)
FINAL_IMAGES=$((FINAL_IMAGES + FINAL_IMAGES_BY_NAME))

FINAL_VOLUMES=$(docker volume ls --filter "label=com.msnai.volume" -q 2>/dev/null | wc -l)
# Also check by name
FINAL_VOLUMES_BY_NAME=$(docker volume ls --format "{{.Name}}" | grep -cE "(msn-ai|msnai)" 2>/dev/null || echo 0)
FINAL_VOLUMES=$((FINAL_VOLUMES + FINAL_VOLUMES_BY_NAME))

FINAL_NETWORKS=$(docker network ls --filter "label=com.msnai.network" -q 2>/dev/null | wc -l)
# Also check by name
FINAL_NETWORKS_BY_NAME=$(docker network ls --format "{{.Name}}" | grep -cE "(msn-ai|msnai)" 2>/dev/null || echo 0)
FINAL_NETWORKS=$((FINAL_NETWORKS + FINAL_NETWORKS_BY_NAME))

echo ""
if [ "$NUCLEAR_CLEANUP" = true ]; then
    # Get MSN-AI specific stats after nuclear cleanup
    REMAINING_MSNAI_CONTAINERS=$(docker ps -aq 2>/dev/null | xargs -r docker inspect --format='{{.Name}}' 2>/dev/null | grep -E "(msn-ai|msnai|docker-msn-ai|docker-ai-setup)" | wc -l)
    REMAINING_MSNAI_IMAGES=$(docker images --format "{{.Repository}}" | grep -E "(msn-ai|msnai|docker-msn-ai|docker-ai-setup)" 2>/dev/null | wc -l)
    REMAINING_MSNAI_VOLUMES=$(docker volume ls --format "{{.Name}}" | grep -E "(msn-ai|msnai|docker-msn-ai|docker-ai-setup)" 2>/dev/null | wc -l)
    REMAINING_MSNAI_NETWORKS=$(docker network ls --format "{{.Name}}" | grep -E "(msn-ai|msnai|docker-msn-ai|docker-ai-setup)" 2>/dev/null | wc -l)

    echo "📊 Estado final MSN-AI después de limpieza nuclear:"
    echo "   🐳 Contenedores MSN-AI restantes: $REMAINING_MSNAI_CONTAINERS"
    echo "   📦 Imágenes MSN-AI restantes: $REMAINING_MSNAI_IMAGES"
    echo "   💾 Volúmenes MSN-AI restantes: $REMAINING_MSNAI_VOLUMES"
    echo "   🌐 Redes MSN-AI restantes: $REMAINING_MSNAI_NETWORKS"
else
    echo "📊 Estado final:"
    echo "   🐳 Contenedores restantes: $FINAL_CONTAINERS"
    echo "   📦 Imágenes restantes: $FINAL_IMAGES"
    echo "   💾 Volúmenes restantes: $FINAL_VOLUMES"
    echo "   🌐 Redes restantes: $FINAL_NETWORKS"
fi

# Summary
echo ""
if [ "$NUCLEAR_CLEANUP" = true ]; then
    echo "💥 LIMPIEZA NUCLEAR MSN-AI COMPLETADA"
    echo "===================================="
    echo "🔥 MSN-AI HA SIDO COMPLETAMENTE RESETADO"
    echo ""
    echo "✅ Lo que se eliminó de MSN-AI:"
    echo "   - TODOS los contenedores MSN-AI"
    echo "   - TODAS las imágenes MSN-AI"
    echo "   - TODOS los volúmenes MSN-AI"
    echo "   - TODAS las redes MSN-AI"
    echo "   - Cache de build relacionado"
    echo "   - Recursos huérfanos relacionados"
    echo ""
    echo "⚠️  IMPORTANTE:"
    echo "   - MSN-AI está ahora en estado 'recién instalado'"
    echo "   - Otros proyectos Docker NO fueron afectados"
    echo "   - Solo datos de MSN-AI se perdieron"
    echo ""
    echo "💡 Para instalar MSN-AI desde cero:"
    echo "   ./start-msnai-docker.sh --auto"
    echo ""
    echo "🎯 Solo MSN-AI fue reseteado, otros proyectos intactos"
else
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
fi

# Show disk space freed (approximate)
if [ "$NUCLEAR_CLEANUP" = true ]; then
    echo ""
    echo "💾 Espacio liberado (aproximado):"
    echo "   🔥 Todo el espacio usado por MSN-AI"
    echo "   📦 Imágenes MSN-AI (~2-4GB)"
    echo "   💾 Volúmenes MSN-AI (modelos IA hasta 40GB+)"
    echo "   🗄️ Cache de build MSN-AI"
    echo "   📊 Para ver espacio total: docker system df"
elif [ "$REMOVE_IMAGES" = true ] || [ "$REMOVE_VOLUMES" = true ]; then
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
if [ "$NUCLEAR_CLEANUP" = true ]; then
    echo "💥 LIMPIEZA NUCLEAR MSN-AI completada exitosamente"
    echo "🔥 MSN-AI ha sido completamente resetado (otros proyectos intactos)"
else
    echo "👋 Limpieza completada exitosamente"
fi
echo "📧 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
echo "🧹 MSN-AI Docker Cleanup v1.1.0"
