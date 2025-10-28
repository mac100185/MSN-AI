#!/bin/bash
# Docker Diagnostics and Log Collection Script
# Version: 1.0.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Comprehensive Docker diagnostics and log collection for MSN-AI

set -e

echo "🔍 MSN-AI - Diagnóstico Docker Completo"
echo "========================================"
echo "📧 Desarrollado por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "========================================"
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
    echo "   $PROJECT_ROOT/linux/docker-diagnostics.sh"
    exit 1
fi

echo "✅ Proyecto MSN-AI detectado correctamente"
echo ""

# Create diagnostics directory with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DIAG_DIR="$PROJECT_ROOT/diagnostics_${TIMESTAMP}"

echo "📁 Creando directorio de diagnóstico: $DIAG_DIR"
mkdir -p "$DIAG_DIR"

# Function to print section header
print_section() {
    echo ""
    echo "========================================" | tee -a "$DIAG_DIR/diagnostics.log"
    echo "$1" | tee -a "$DIAG_DIR/diagnostics.log"
    echo "========================================" | tee -a "$DIAG_DIR/diagnostics.log"
    echo "" | tee -a "$DIAG_DIR/diagnostics.log"
}

# Function to run command and save output
run_diagnostic() {
    local description=$1
    local command=$2
    local output_file=$3

    echo "▶ $description" | tee -a "$DIAG_DIR/diagnostics.log"
    echo "  Comando: $command" | tee -a "$DIAG_DIR/diagnostics.log"

    if eval "$command" > "$DIAG_DIR/$output_file" 2>&1; then
        echo "  ✅ Completado: $output_file" | tee -a "$DIAG_DIR/diagnostics.log"
    else
        echo "  ⚠️  Error ejecutando comando (guardado en $output_file)" | tee -a "$DIAG_DIR/diagnostics.log"
    fi
    echo "" | tee -a "$DIAG_DIR/diagnostics.log"
}

# Start diagnostics
echo "🔍 Iniciando recopilación de diagnósticos..."
echo "📅 Fecha: $(date)" | tee "$DIAG_DIR/diagnostics.log"
echo "🖥️  Host: $(hostname)" | tee -a "$DIAG_DIR/diagnostics.log"
echo "👤 Usuario: $(whoami)" | tee -a "$DIAG_DIR/diagnostics.log"
echo "" | tee -a "$DIAG_DIR/diagnostics.log"

# System Information
print_section "1. INFORMACIÓN DEL SISTEMA"
run_diagnostic "Sistema operativo" "uname -a" "system_uname.txt"
run_diagnostic "Distribución Linux" "cat /etc/os-release" "system_distribution.txt"
run_diagnostic "Información CPU" "lscpu" "system_cpu.txt"
run_diagnostic "Memoria del sistema" "free -h" "system_memory.txt"
run_diagnostic "Espacio en disco (general)" "df -h" "system_disk.txt"
run_diagnostic "Espacio en disco (Docker)" "df -h /var/lib/docker" "system_disk_docker.txt"
run_diagnostic "Procesos del sistema" "ps aux" "system_processes.txt"

# Check for low disk space
echo "  Analizando espacio en disco..." | tee -a "$DIAG_DIR/diagnostics.log"
DISK_AVAILABLE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$DISK_AVAILABLE" -lt 5 ]; then
    echo "  ⚠️  ADVERTENCIA: Espacio bajo detectado (${DISK_AVAILABLE}GB)" | tee -a "$DIAG_DIR/diagnostics.log"
    echo "ADVERTENCIA: Espacio en disco muy bajo (${DISK_AVAILABLE}GB disponible)" > "$DIAG_DIR/WARNING_LOW_DISK_SPACE.txt"
    echo "Se recomienda al menos 5GB para operaciones de Docker." >> "$DIAG_DIR/WARNING_LOW_DISK_SPACE.txt"
    echo "Libera espacio con: docker system prune -a --volumes" >> "$DIAG_DIR/WARNING_LOW_DISK_SPACE.txt"
fi

# Docker Installation
print_section "2. INSTALACIÓN DE DOCKER"
run_diagnostic "Versión de Docker" "docker --version" "docker_version.txt"
run_diagnostic "Información de Docker" "docker info" "docker_info.txt"
run_diagnostic "Docker Compose version" "docker compose version || docker-compose --version" "docker_compose_version.txt"
run_diagnostic "Plugins de Docker" "docker plugin ls" "docker_plugins.txt"

# Docker System Status
print_section "3. ESTADO DEL SISTEMA DOCKER"
run_diagnostic "Espacio usado por Docker" "docker system df" "docker_system_df.txt"
run_diagnostic "Eventos recientes de Docker" "docker system events --since 24h --until 1s" "docker_events.txt"

# Docker Networks
print_section "4. REDES DE DOCKER"
run_diagnostic "Lista de redes" "docker network ls" "docker_networks_list.txt"
run_diagnostic "Inspección red msn-ai-network" "docker network inspect msn-ai-network" "docker_network_msnai_inspect.txt"

# Docker Volumes
print_section "5. VOLÚMENES DE DOCKER"
run_diagnostic "Lista de volúmenes" "docker volume ls" "docker_volumes_list.txt"
run_diagnostic "Inspección volumen msn-ai-data" "docker volume inspect msn-ai-data" "docker_volume_data_inspect.txt"
run_diagnostic "Inspección volumen msn-ai-ollama-data" "docker volume inspect msn-ai-ollama-data" "docker_volume_ollama_inspect.txt"
run_diagnostic "Inspección volumen msn-ai-chats" "docker volume inspect msn-ai-chats" "docker_volume_chats_inspect.txt"
run_diagnostic "Inspección volumen msn-ai-logs" "docker volume inspect msn-ai-logs" "docker_volume_logs_inspect.txt"

# Docker Images
print_section "6. IMÁGENES DE DOCKER"
run_diagnostic "Lista de imágenes" "docker images -a" "docker_images_list.txt"
run_diagnostic "Historial imagen MSN-AI" "docker history msn-ai-app 2>/dev/null || echo 'Imagen no encontrada'" "docker_image_history_msnai.txt"
run_diagnostic "Historial imagen Ollama" "docker history ollama/ollama:latest 2>/dev/null || echo 'Imagen no encontrada'" "docker_image_history_ollama.txt"
run_diagnostic "Inspección imagen MSN-AI" "docker inspect msn-ai-app 2>/dev/null || echo 'Imagen no encontrada'" "docker_image_inspect_msnai.txt"

# Docker Containers
print_section "7. CONTENEDORES DE DOCKER"
run_diagnostic "Contenedores en ejecución" "docker ps" "docker_containers_running.txt"
run_diagnostic "Todos los contenedores" "docker ps -a" "docker_containers_all.txt"
run_diagnostic "Inspección contenedor msn-ai-app" "docker inspect msn-ai-app" "docker_container_inspect_msnai.txt"
run_diagnostic "Inspección contenedor msn-ai-ollama" "docker inspect msn-ai-ollama" "docker_container_inspect_ollama.txt"
run_diagnostic "Inspección contenedor msn-ai-setup" "docker inspect msn-ai-setup" "docker_container_inspect_setup.txt"
run_diagnostic "Stats de contenedores" "docker stats --no-stream" "docker_container_stats.txt"

# Container Logs
print_section "8. LOGS DE CONTENEDORES"
echo "📝 Extrayendo logs de contenedores..." | tee -a "$DIAG_DIR/diagnostics.log"

# MSN-AI App logs
if docker ps -a --format '{{.Names}}' | grep -q "^msn-ai-app$"; then
    echo "  Extrayendo logs de msn-ai-app..." | tee -a "$DIAG_DIR/diagnostics.log"
    docker logs msn-ai-app > "$DIAG_DIR/logs_msnai_app.txt" 2>&1 || echo "No se pudieron extraer logs" > "$DIAG_DIR/logs_msnai_app.txt"
    docker logs --tail 100 msn-ai-app > "$DIAG_DIR/logs_msnai_app_last100.txt" 2>&1 || true
    echo "  ✅ Logs de msn-ai-app guardados" | tee -a "$DIAG_DIR/diagnostics.log"
else
    echo "  ⚠️  Contenedor msn-ai-app no existe" | tee -a "$DIAG_DIR/diagnostics.log"
    echo "Contenedor no existe" > "$DIAG_DIR/logs_msnai_app.txt"
fi

# Ollama logs
if docker ps -a --format '{{.Names}}' | grep -q "^msn-ai-ollama$"; then
    echo "  Extrayendo logs de msn-ai-ollama..." | tee -a "$DIAG_DIR/diagnostics.log"
    docker logs msn-ai-ollama > "$DIAG_DIR/logs_ollama.txt" 2>&1 || echo "No se pudieron extraer logs" > "$DIAG_DIR/logs_ollama.txt"
    docker logs --tail 100 msn-ai-ollama > "$DIAG_DIR/logs_ollama_last100.txt" 2>&1 || true
    echo "  ✅ Logs de msn-ai-ollama guardados" | tee -a "$DIAG_DIR/diagnostics.log"
else
    echo "  ⚠️  Contenedor msn-ai-ollama no existe" | tee -a "$DIAG_DIR/diagnostics.log"
    echo "Contenedor no existe" > "$DIAG_DIR/logs_ollama.txt"
fi

# Setup logs
if docker ps -a --format '{{.Names}}' | grep -q "^msn-ai-setup$"; then
    echo "  Extrayendo logs de msn-ai-setup..." | tee -a "$DIAG_DIR/diagnostics.log"
    docker logs msn-ai-setup > "$DIAG_DIR/logs_setup.txt" 2>&1 || echo "No se pudieron extraer logs" > "$DIAG_DIR/logs_setup.txt"
    echo "  ✅ Logs de msn-ai-setup guardados" | tee -a "$DIAG_DIR/diagnostics.log"
else
    echo "  ⚠️  Contenedor msn-ai-setup no existe" | tee -a "$DIAG_DIR/diagnostics.log"
    echo "Contenedor no existe" > "$DIAG_DIR/logs_setup.txt"
fi

echo "" | tee -a "$DIAG_DIR/diagnostics.log"

# Docker Compose Status
print_section "9. ESTADO DE DOCKER COMPOSE"
if [ -f "docker/docker-compose.yml" ]; then
    echo "  Archivo docker-compose.yml encontrado" | tee -a "$DIAG_DIR/diagnostics.log"
    cp "docker/docker-compose.yml" "$DIAG_DIR/docker-compose.yml.bak"
    echo "  ✅ Copia de docker-compose.yml guardada" | tee -a "$DIAG_DIR/diagnostics.log"

    run_diagnostic "Estado de servicios (docker-compose)" "cd docker && docker-compose ps" "docker_compose_ps.txt"
    run_diagnostic "Configuración de Compose" "cd docker && docker-compose config" "docker_compose_config.txt"
else
    echo "  ⚠️  Archivo docker-compose.yml no encontrado" | tee -a "$DIAG_DIR/diagnostics.log"
fi

# Build logs if available
print_section "10. LOGS DE CONSTRUCCIÓN"
if [ -f "$HOME/.docker/build-cache/build.log" ]; then
    cp "$HOME/.docker/build-cache/build.log" "$DIAG_DIR/docker_build.log"
    echo "  ✅ Logs de construcción copiados" | tee -a "$DIAG_DIR/diagnostics.log"
else
    echo "  ℹ️  No se encontraron logs de construcción en ubicación por defecto" | tee -a "$DIAG_DIR/diagnostics.log"
fi

# Docker daemon logs
print_section "11. LOGS DEL DAEMON DE DOCKER"
echo "  Intentando extraer logs del daemon..." | tee -a "$DIAG_DIR/diagnostics.log"

# Try different locations for Docker daemon logs
if [ -f "/var/log/docker.log" ]; then
    sudo tail -n 500 /var/log/docker.log > "$DIAG_DIR/docker_daemon.log" 2>&1 || echo "Sin permisos para leer" > "$DIAG_DIR/docker_daemon.log"
    echo "  ✅ Logs del daemon extraídos de /var/log/docker.log" | tee -a "$DIAG_DIR/diagnostics.log"
elif command -v journalctl &> /dev/null; then
    sudo journalctl -u docker --no-pager -n 500 > "$DIAG_DIR/docker_daemon_journal.log" 2>&1 || echo "Sin permisos para leer journal" > "$DIAG_DIR/docker_daemon_journal.log"
    echo "  ✅ Logs del daemon extraídos de journalctl" | tee -a "$DIAG_DIR/diagnostics.log"
else
    echo "  ⚠️  No se pudieron extraer logs del daemon" | tee -a "$DIAG_DIR/diagnostics.log"
    echo "No disponible" > "$DIAG_DIR/docker_daemon.log"
fi

# Project Structure
print_section "12. ESTRUCTURA DEL PROYECTO"
run_diagnostic "Árbol del proyecto" "tree -L 3 -I 'node_modules|.git' . 2>/dev/null || find . -type d -maxdepth 3 ! -path '*/.*' | head -50" "project_structure.txt"
run_diagnostic "Archivos en directorio raíz" "ls -lah" "project_root_files.txt"
run_diagnostic "Archivos en directorio docker" "ls -lah docker/" "project_docker_files.txt"

# Environment Variables
print_section "13. VARIABLES DE ENTORNO"
echo "  Extrayendo variables de entorno relevantes..." | tee -a "$DIAG_DIR/diagnostics.log"
env | grep -i "docker\|compose\|ollama\|msn" > "$DIAG_DIR/environment_vars.txt" 2>&1 || echo "No se encontraron variables relevantes" > "$DIAG_DIR/environment_vars.txt"
echo "  ✅ Variables de entorno guardadas" | tee -a "$DIAG_DIR/diagnostics.log"

# Network Connectivity
print_section "14. CONECTIVIDAD DE RED"
run_diagnostic "Puertos en uso" "netstat -tuln 2>/dev/null || ss -tuln" "network_ports.txt"
run_diagnostic "Conexiones establecidas" "netstat -tan 2>/dev/null || ss -tan" "network_connections.txt"

# Test Docker Connectivity
echo "  Probando conectividad con Docker..." | tee -a "$DIAG_DIR/diagnostics.log"
{
    echo "=== Ping a contenedores ==="
    docker ps --format '{{.Names}}' | while read container; do
        echo "Container: $container"
        docker exec "$container" ping -c 2 localhost 2>&1 || echo "No se pudo hacer ping"
        echo ""
    done
} > "$DIAG_DIR/docker_connectivity.txt" 2>&1
echo "  ✅ Pruebas de conectividad completadas" | tee -a "$DIAG_DIR/diagnostics.log"

# Health Checks
print_section "15. VERIFICACIONES DE SALUD"
echo "  Ejecutando health checks..." | tee -a "$DIAG_DIR/diagnostics.log"
{
    echo "=== Health Status de Contenedores ==="
    docker ps --format "table {{.Names}}\t{{.Status}}"
    echo ""
    echo "=== Último health check de cada contenedor ==="
    docker ps -q | while read container_id; do
        container_name=$(docker inspect --format='{{.Name}}' "$container_id" | sed 's/\///')
        echo "Container: $container_name"
        docker inspect --format='{{json .State.Health}}' "$container_id" 2>/dev/null || echo "No health check configurado"
        echo ""
    done
} > "$DIAG_DIR/health_checks.txt" 2>&1
echo "  ✅ Health checks completados" | tee -a "$DIAG_DIR/diagnostics.log"

# Resource Usage
print_section "16. USO DE RECURSOS"
run_diagnostic "Uso de CPU y memoria por Docker" "docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}'" "docker_resource_usage.txt"

# Ollama Specific Diagnostics
print_section "17. DIAGNÓSTICOS ESPECÍFICOS DE OLLAMA"
if docker ps --format '{{.Names}}' | grep -q "^msn-ai-ollama$"; then
    echo "  Ejecutando diagnósticos de Ollama..." | tee -a "$DIAG_DIR/diagnostics.log"

    # Ollama version
    docker exec msn-ai-ollama ollama --version > "$DIAG_DIR/ollama_version.txt" 2>&1 || echo "Error obteniendo versión" > "$DIAG_DIR/ollama_version.txt"

    # Ollama models
    docker exec msn-ai-ollama ollama list > "$DIAG_DIR/ollama_models.txt" 2>&1 || echo "Error listando modelos" > "$DIAG_DIR/ollama_models.txt"

    # Ollama API test
    docker exec msn-ai-ollama curl -s http://localhost:11434/api/tags > "$DIAG_DIR/ollama_api_test.txt" 2>&1 || echo "Error probando API" > "$DIAG_DIR/ollama_api_test.txt"

    echo "  ✅ Diagnósticos de Ollama completados" | tee -a "$DIAG_DIR/diagnostics.log"
else
    echo "  ⚠️  Contenedor de Ollama no está en ejecución" | tee -a "$DIAG_DIR/diagnostics.log"
    echo "Contenedor no en ejecución" > "$DIAG_DIR/ollama_diagnostics.txt"
fi

# Recent Docker Events
print_section "18. EVENTOS RECIENTES"
echo "  Extrayendo eventos recientes..." | tee -a "$DIAG_DIR/diagnostics.log"
docker events --since 1h --until 1s > "$DIAG_DIR/docker_events_1h.txt" 2>&1 || echo "No se pudieron extraer eventos" > "$DIAG_DIR/docker_events_1h.txt"
echo "  ✅ Eventos guardados" | tee -a "$DIAG_DIR/diagnostics.log"

# Error Analysis
print_section "19. ANÁLISIS DE ERRORES"
echo "  Buscando errores comunes..." | tee -a "$DIAG_DIR/diagnostics.log"
{
    echo "=== Análisis de errores en logs ==="
    echo ""
    echo "--- Errores en logs de MSN-AI App ---"
    grep -i "error\|fail\|exception\|fatal" "$DIAG_DIR/logs_msnai_app.txt" 2>/dev/null | tail -20 || echo "No se encontraron errores"
    echo ""
    echo "--- Errores en logs de Ollama ---"
    grep -i "error\|fail\|exception\|fatal" "$DIAG_DIR/logs_ollama.txt" 2>/dev/null | tail -20 || echo "No se encontraron errores"
    echo ""
    echo "--- Errores en logs de Setup ---"
    grep -i "error\|fail\|exception\|fatal" "$DIAG_DIR/logs_setup.txt" 2>/dev/null | tail -20 || echo "No se encontraron errores"
    echo ""
    echo "--- Errores de espacio en disco ---"
    grep -i "no space left on device" "$DIAG_DIR"/*.txt 2>/dev/null | head -5 || echo "No se encontraron errores de espacio"
} > "$DIAG_DIR/error_analysis.txt" 2>&1
echo "  ✅ Análisis de errores completado" | tee -a "$DIAG_DIR/diagnostics.log"

# Summary Report
print_section "20. RESUMEN EJECUTIVO"
{
    echo "=== RESUMEN DE DIAGNÓSTICO MSN-AI ==="
    echo "Fecha: $(date)"
    echo "Usuario: $(whoami)"
    echo "Host: $(hostname)"
    echo ""

    echo "--- Estado de Docker ---"
    if docker info > /dev/null 2>&1; then
        echo "✅ Docker daemon en ejecución"
        echo "   Versión: $(docker --version)"
    else
        echo "❌ Docker daemon no está en ejecución"
    fi
    echo ""

    echo "--- Estado de Contenedores ---"
    if docker ps --format '{{.Names}}' | grep -q "^msn-ai-app$"; then
        echo "✅ msn-ai-app: $(docker ps --filter name=msn-ai-app --format '{{.Status}}')"
    else
        echo "❌ msn-ai-app: No encontrado"
    fi

    if docker ps --format '{{.Names}}' | grep -q "^msn-ai-ollama$"; then
        echo "✅ msn-ai-ollama: $(docker ps --filter name=msn-ai-ollama --format '{{.Status}}')"
    else
        echo "❌ msn-ai-ollama: No encontrado"
    fi
    echo ""

    echo "--- Conectividad ---"
    if curl -s http://localhost:8000 > /dev/null 2>&1; then
        echo "✅ MSN-AI Web (puerto 8000): Accesible"
    else
        echo "❌ MSN-AI Web (puerto 8000): No accesible"
    fi

    if curl -s http://localhost:11434 > /dev/null 2>&1; then
        echo "✅ Ollama API (puerto 11434): Accesible"
    else
        echo "❌ Ollama API (puerto 11434): No accesible"
    fi
    echo ""

    echo "--- Recursos del Sistema ---"
    echo "CPU: $(nproc) núcleos"
    echo "RAM Total: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "RAM Usada: $(free -h | awk '/^Mem:/ {print $3}')"

    # Check disk space and warn if low
    DISK_AVAILABLE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    echo "Disco Raíz: ${DISK_AVAILABLE}GB disponible"

    if [ "$DISK_AVAILABLE" -lt 5 ]; then
        echo "⚠️  ADVERTENCIA: Espacio en disco muy bajo (${DISK_AVAILABLE}GB)"
        echo "   Se recomienda al menos 5GB para Docker + Ollama"
    fi

    # Check Docker directory space
    if [ -d /var/lib/docker ]; then
        DOCKER_DISK_AVAILABLE=$(df -BG /var/lib/docker | awk 'NR==2 {print $4}' | sed 's/G//')
        echo "Disco Docker (/var/lib/docker): ${DOCKER_DISK_AVAILABLE}GB disponible"

        if [ "$DOCKER_DISK_AVAILABLE" -lt 3 ]; then
            echo "❌ CRÍTICO: Espacio Docker muy bajo (${DOCKER_DISK_AVAILABLE}GB)"
            echo "   Docker puede fallar con 'no space left on device'"
        fi
    fi
    echo ""

    echo "--- Volúmenes ---"
    docker volume ls --filter name=msn-ai | grep -v DRIVER || echo "No se encontraron volúmenes"
    echo ""

    echo "=== FIN DEL RESUMEN ==="
} > "$DIAG_DIR/RESUMEN.txt" 2>&1

cat "$DIAG_DIR/RESUMEN.txt" | tee -a "$DIAG_DIR/diagnostics.log"

# Create tarball
print_section "21. EMPAQUETADO FINAL"
echo "📦 Creando archivo comprimido..." | tee -a "$DIAG_DIR/diagnostics.log"

TARBALL="$PROJECT_ROOT/msn-ai-diagnostics-${TIMESTAMP}.tar.gz"
tar -czf "$TARBALL" -C "$(dirname "$DIAG_DIR")" "$(basename "$DIAG_DIR")" 2>&1 | tee -a "$DIAG_DIR/diagnostics.log"

if [ -f "$TARBALL" ]; then
    TARBALL_SIZE=$(du -h "$TARBALL" | cut -f1)
    echo "✅ Archivo de diagnóstico creado: $TARBALL" | tee -a "$DIAG_DIR/diagnostics.log"
    echo "   Tamaño: $TARBALL_SIZE" | tee -a "$DIAG_DIR/diagnostics.log"
else
    echo "❌ Error creando archivo comprimido" | tee -a "$DIAG_DIR/diagnostics.log"
fi

# Final Summary
echo ""
echo "========================================" | tee -a "$DIAG_DIR/diagnostics.log"
echo "✅ DIAGNÓSTICO COMPLETADO" | tee -a "$DIAG_DIR/diagnostics.log"
echo "========================================" | tee -a "$DIAG_DIR/diagnostics.log"
echo "" | tee -a "$DIAG_DIR/diagnostics.log"
echo "📂 Directorio de diagnóstico: $DIAG_DIR" | tee -a "$DIAG_DIR/diagnostics.log"
echo "📦 Archivo comprimido: $TARBALL" | tee -a "$DIAG_DIR/diagnostics.log"
echo "" | tee -a "$DIAG_DIR/diagnostics.log"
echo "📊 Archivos generados:" | tee -a "$DIAG_DIR/diagnostics.log"
ls -lh "$DIAG_DIR" | wc -l | xargs -I {} echo "   Total: {} archivos" | tee -a "$DIAG_DIR/diagnostics.log"
echo "" | tee -a "$DIAG_DIR/diagnostics.log"
echo "💡 Para revisar el resumen ejecutivo:" | tee -a "$DIAG_DIR/diagnostics.log"
echo "   cat $DIAG_DIR/RESUMEN.txt" | tee -a "$DIAG_DIR/diagnostics.log"
echo "" | tee -a "$DIAG_DIR/diagnostics.log"
echo "💡 Para ver los logs completos:" | tee -a "$DIAG_DIR/diagnostics.log"
echo "   cat $DIAG_DIR/diagnostics.log" | tee -a "$DIAG_DIR/diagnostics.log"
echo "" | tee -a "$DIAG_DIR/diagnostics.log"
echo "📧 Si necesitas soporte, envía el archivo:" | tee -a "$DIAG_DIR/diagnostics.log"
echo "   $TARBALL" | tee -a "$DIAG_DIR/diagnostics.log"
echo "" | tee -a "$DIAG_DIR/diagnostics.log"
echo "🎉 ¡Diagnóstico completado exitosamente!" | tee -a "$DIAG_DIR/diagnostics.log"
echo "" | tee -a "$DIAG_DIR/diagnostics.log"
