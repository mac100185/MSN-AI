#!/bin/bash
# start-msnai-docker-mac.sh - Docker Startup Script for MSN-AI - macOS
# Version: 1.0.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Docker-based startup for MSN-AI on macOS with intelligent setup

echo "🐳 MSN-AI v1.0.0 - Docker Edition (macOS)"
echo "=========================================="
echo "📧 Desarrollado por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0 | 🔗 alan.mac.arthur.garcia.diaz@gmail.com"
echo "🐳 Modo: Docker Container"
echo "🍎 Plataforma: macOS"
echo "🐳 Modo: Docker Container (Sin Firewall)"
echo "=================================="

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
    echo "   $PROJECT_ROOT/macos/start-msnai-docker-mac.sh"
    exit 1
fi

echo "✅ Proyecto MSN-AI detectado correctamente"
echo ""

# Check if docker directory exists
if [ ! -d "docker" ]; then
    echo "❌ Error: Directorio docker no encontrado"
    echo "   Asegúrate de que todos los archivos Docker estén presentes"
    exit 1
fi

# Function to detect macOS version and architecture
detect_mac_info() {
    echo "🍎 Detectando información del sistema..."

    MAC_VERSION=$(sw_vers -productVersion)
    MAC_ARCH=$(uname -m)

    echo "✅ macOS: $MAC_VERSION"
    echo "✅ Arquitectura: $MAC_ARCH"

    if [[ "$MAC_ARCH" == "arm64" ]]; then
        echo "🚀 Apple Silicon (M1/M2/M3) detectado - Excelente para IA!"
        USE_APPLE_SILICON=true
    else
        echo "⚡ Intel Mac detectado"
        USE_APPLE_SILICON=false
    fi
}

# Function to check disk space
check_disk_space() {
    echo "🔍 Verificando espacio en disco..."

    # Get available space in /var (where Docker Desktop stores data on macOS)
    local docker_dir="/"
    if [ -d "$HOME/Library/Containers/com.docker.docker/Data" ]; then
        docker_dir="$HOME/Library/Containers/com.docker.docker/Data"
    fi

    local available_gb=$(df -g "$docker_dir" | awk 'NR==2 {print $4}')
    local required_gb=5  # Minimum 5GB required for Ollama and MSN-AI images

    echo "   Espacio disponible: ${available_gb}GB"
    echo "   Espacio requerido: ${required_gb}GB"

    if [ "$available_gb" -lt "$required_gb" ]; then
        echo ""
        echo "❌ ERROR: Espacio en disco insuficiente"
        echo "   Disponible: ${available_gb}GB"
        echo "   Requerido: ${required_gb}GB mínimo"
        echo ""
        echo "💡 Soluciones:"
        echo "   1. Libera espacio en disco eliminando archivos innecesarios"
        echo "   2. Limpia imágenes Docker antiguas:"
        echo "      docker system prune -a --volumes"
        echo "   3. Aumenta el espacio del disco/partición"
        echo "   4. Vacía la papelera de macOS"
        echo ""
        echo "📊 Uso actual del disco:"
        df -h "$docker_dir" | head -2
        echo ""

        read -p "¿Deseas continuar de todas formas? (s/N): " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[sS]$ ]]; then
            echo "❌ Instalación cancelada por falta de espacio"
            exit 1
        fi
        echo "⚠️  Continuando con espacio limitado (puede fallar)..."
    else
        echo "✅ Espacio en disco suficiente: ${available_gb}GB disponible"
    fi
    echo ""
}

# Function to check Docker installation
check_docker() {
    echo "🔍 Verificando Docker..."

    # Check disk space first
    check_disk_space

    if ! command -v docker &> /dev/null; then
        echo "❌ Docker no está instalado"
        echo ""
        echo "🚀 Opciones de instalación:"
        echo "   1. Instalar Docker Desktop automáticamente (recomendado)"
        echo "   2. Instalar via Homebrew"
        echo "   3. Instrucciones manuales"
        echo "   4. Continuar sin Docker (modo local)"

        read -p "Selecciona una opción (1-4): " docker_option

        case $docker_option in
            1)
                install_docker_desktop
                ;;
            2)
                install_docker_homebrew
                ;;
            3)
                show_docker_instructions
                exit 1
                ;;
            4)
                echo "🔄 Iniciando en modo local..."
                exec ./start-msnai-mac.sh "$@"
                ;;
            *)
                echo "❌ Opción no válida"
                exit 1
                ;;
        esac
    else
        echo "✅ Docker instalado: $(docker --version | cut -d' ' -f3)"
    fi

    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker no está ejecutándose"
        echo "   Inicia Docker Desktop desde Applications"
        echo "   O ejecuta: open -a Docker"
        exit 1
    else
        echo "✅ Docker está ejecutándose"
    fi

    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo "❌ Docker Compose no está disponible"
        echo "   Docker Desktop incluye Docker Compose automáticamente"
        exit 1
    else
        echo "✅ Docker Compose disponible"
    fi
}

# Function to install Docker Desktop
install_docker_desktop() {
    echo "📦 Instalando Docker Desktop..."

    # Detect architecture for correct download
    if [[ "$USE_APPLE_SILICON" == true ]]; then
        DOCKER_URL="https://desktop.docker.com/mac/main/arm64/Docker.dmg"
        echo "📥 Descargando Docker Desktop para Apple Silicon..."
    else
        DOCKER_URL="https://desktop.docker.com/mac/main/amd64/Docker.dmg"
        echo "📥 Descargando Docker Desktop para Intel Mac..."
    fi

    # Download Docker Desktop
    echo "⏬ Descargando desde: $DOCKER_URL"
    curl -L -o /tmp/Docker.dmg "$DOCKER_URL"

    if [ $? -eq 0 ]; then
        echo "✅ Descarga completada"

        # Mount and install
        echo "📀 Montando imagen..."
        hdiutil attach /tmp/Docker.dmg -quiet

        echo "📦 Instalando Docker Desktop..."
        cp -R "/Volumes/Docker/Docker.app" "/Applications/"

        # Unmount
        hdiutil detach "/Volumes/Docker" -quiet

        # Clean up
        rm /tmp/Docker.dmg

        echo "✅ Docker Desktop instalado en /Applications/"
        echo "🚀 Iniciando Docker Desktop..."
        open -a Docker

        echo "⏳ Esperando que Docker Desktop se inicie..."
        sleep 10

        # Wait for Docker to be ready
        local max_attempts=30
        local attempt=1

        while [ $attempt -le $max_attempts ]; do
            if docker info >/dev/null 2>&1; then
                echo "✅ Docker Desktop iniciado correctamente"
                break
            fi

            echo "⏳ Esperando Docker... (intento $attempt/$max_attempts)"
            sleep 5
            attempt=$((attempt + 1))
        done

        if [ $attempt -gt $max_attempts ]; then
            echo "⚠️ Docker Desktop tarda en iniciar"
            echo "   Inicia manualmente Docker Desktop desde Applications"
            exit 1
        fi
    else
        echo "❌ Error descargando Docker Desktop"
        exit 1
    fi
}

# Function to install Docker via Homebrew
install_docker_homebrew() {
    echo "🍺 Instalando Docker via Homebrew..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "📦 Homebrew no está instalado, instalando..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for current session
        if [[ "$USE_APPLE_SILICON" == true ]]; then
            export PATH="/opt/homebrew/bin:$PATH"
        else
            export PATH="/usr/local/bin:$PATH"
        fi
    fi

    echo "📦 Instalando Docker Desktop con Homebrew..."
    brew install --cask docker

    if [ $? -eq 0 ]; then
        echo "✅ Docker Desktop instalado via Homebrew"
        echo "🚀 Iniciando Docker Desktop..."
        open -a Docker

        # Wait for Docker to be ready
        echo "⏳ Esperando que Docker Desktop se inicie..."
        sleep 15

        local max_attempts=20
        local attempt=1

        while [ $attempt -le $max_attempts ]; do
            if docker info >/dev/null 2>&1; then
                echo "✅ Docker Desktop iniciado correctamente"
                break
            fi

            echo "⏳ Esperando Docker... (intento $attempt/$max_attempts)"
            sleep 5
            attempt=$((attempt + 1))
        done
    else
        echo "❌ Error instalando Docker via Homebrew"
        exit 1
    fi
}

# Function to show manual Docker installation instructions
show_docker_instructions() {
    echo ""
    echo "📖 Instrucciones de instalación manual de Docker:"
    echo "================================================="
    echo ""
    echo "🍎 macOS (Apple Silicon M1/M2/M3):"
    echo "   1. Descarga: https://desktop.docker.com/mac/main/arm64/Docker.dmg"
    echo "   2. Arrastra Docker.app a Applications"
    echo "   3. Inicia Docker desde Applications"
    echo ""
    echo "🍎 macOS (Intel):"
    echo "   1. Descarga: https://desktop.docker.com/mac/main/amd64/Docker.dmg"
    echo "   2. Arrastra Docker.app a Applications"
    echo "   3. Inicia Docker desde Applications"
    echo ""
    echo "🍺 Alternativa con Homebrew:"
    echo "   brew install --cask docker"
    echo ""
    echo "💡 Después de instalar, ejecuta este script nuevamente"
}

# Function to check hardware optimization
check_hardware_optimization() {
    echo "🔧 Optimizando configuración para hardware..."

    if [[ "$USE_APPLE_SILICON" == true ]]; then
        echo "🚀 Configuración Apple Silicon:"
        echo "   ✅ Rendimiento optimizado para ARM64"
        echo "   ✅ Memoria unificada disponible"
        echo "   ✅ Neural Engine para IA (si es compatible)"

        # Check memory
        TOTAL_MEMORY=$(sysctl -n hw.memsize)
        MEMORY_GB=$((TOTAL_MEMORY / 1024 / 1024 / 1024))
        echo "   💾 Memoria total: ${MEMORY_GB}GB"

        if [ "$MEMORY_GB" -ge 16 ]; then
            echo "   ✅ Memoria suficiente para modelos avanzados"
            RECOMMENDED_MODEL="mistral:7b"
        else
            echo "   ⚠️ Memoria limitada, usando modelo ligero"
            RECOMMENDED_MODEL="phi3:mini"
        fi
    else
        echo "⚡ Configuración Intel Mac:"

        # Check memory
        TOTAL_MEMORY=$(sysctl -n hw.memsize)
        MEMORY_GB=$((TOTAL_MEMORY / 1024 / 1024 / 1024))
        echo "   💾 Memoria total: ${MEMORY_GB}GB"

        if [ "$MEMORY_GB" -ge 32 ]; then
            RECOMMENDED_MODEL="mistral:7b"
            echo "   ✅ Memoria suficiente para modelo estándar"
        elif [ "$MEMORY_GB" -ge 16 ]; then
            RECOMMENDED_MODEL="phi3:mini"
            echo "   ⚠️ Memoria media, usando modelo ligero"
        else
            RECOMMENDED_MODEL="tinyllama"
            echo "   ⚠️ Memoria limitada, usando modelo básico"
        fi
    fi

    echo "   🤖 Modelo recomendado: $RECOMMENDED_MODEL"
}

# Function to setup environment
setup_environment() {
    echo "⚙️ Configurando entorno Docker..."

    # Create .env file for Docker Compose
    cat > .env << EOF
# MSN-AI Docker Environment Configuration
MSN_AI_VERSION=1.0.0
MSN_AI_PORT=8000
COMPOSE_PROJECT_NAME=msn-ai
DOCKER_BUILDKIT=1
RECOMMENDED_MODEL=$RECOMMENDED_MODEL
APPLE_SILICON=$USE_APPLE_SILICON
MEMORY_GB=$MEMORY_GB
EOF

    echo "✅ Archivo de entorno creado"
}

# Function to build and start containers
start_containers() {
    echo "🏗️ Construyendo e iniciando contenedores..."

    # Build images
    echo "📦 Construyendo imagen MSN-AI..."
    docker-compose -f docker/docker-compose.yml build --no-cache

    if [ $? -ne 0 ]; then
        echo "❌ Error construyendo la imagen"
        exit 1
    fi

    # Start services
    echo "🚀 Iniciando servicios..."
    docker-compose -f docker/docker-compose.yml up -d

    if [ $? -ne 0 ]; then
        echo "❌ Error iniciando los servicios"
        exit 1
    fi

    echo "✅ Contenedores iniciados correctamente"
}

# Function to wait for services
wait_for_services() {
    echo "⏳ Esperando que los servicios estén listos..."

    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:8000/msn-ai.html >/dev/null 2>&1; then
            echo "✅ MSN-AI está listo"
            break
        fi

        echo "⏳ Intento $attempt/$max_attempts..."
        sleep 2
        attempt=$((attempt + 1))
    done

    if [ $attempt -gt $max_attempts ]; then
        echo "⚠️ Timeout esperando los servicios"
        echo "   Verifica los logs: docker-compose -f docker/docker-compose.yml logs"
    fi
}

# Function to open application
open_application() {
    echo "🌐 Abriendo MSN-AI en el navegador..."

    # Try Safari first (native macOS), then other browsers
    if [ -d "/Applications/Safari.app" ]; then
        open -a Safari http://localhost:8000/msn-ai.html
    elif [ -d "/Applications/Google Chrome.app" ]; then
        open -a "Google Chrome" http://localhost:8000/msn-ai.html
    elif [ -d "/Applications/Firefox.app" ]; then
        open -a Firefox http://localhost:8000/msn-ai.html
    else
        # Use default browser
        open http://localhost:8000/msn-ai.html
    fi
}

# Function to show status and logs
show_status() {
    echo ""
    echo "🎉 ¡MSN-AI Docker está ejecutándose en macOS!"
    echo "============================================="
    echo "📱 URL: http://localhost:8000/msn-ai.html"
    echo "🍎 Sistema: macOS $MAC_VERSION ($MAC_ARCH)"
    echo "💾 Memoria: ${MEMORY_GB}GB"
    echo "🤖 Modelo recomendado: $RECOMMENDED_MODEL"
    echo ""
    echo "🐳 Contenedores:"
    docker-compose -f docker/docker-compose.yml ps
    echo ""
    echo "💡 Comandos útiles:"
    echo "   🔍 Ver logs:        docker-compose -f docker/docker-compose.yml logs -f"
    echo "   ⏹️ Detener:         docker-compose -f docker/docker-compose.yml down"
    echo "   🔄 Reiniciar:       docker-compose -f docker/docker-compose.yml restart"
    echo "   📊 Estado:          docker-compose -f docker/docker-compose.yml ps"
    echo ""
    echo "⚠️ DETENCIÓN CORRECTA:"
    echo "   docker-compose -f docker/docker-compose.yml down"
    echo ""
    echo "💡 Optimizaciones macOS:"
    if [[ "$USE_APPLE_SILICON" == true ]]; then
        echo "   🚀 Ejecutándose con optimización Apple Silicon"
        echo "   ⚡ Rendimiento mejorado para ARM64"
    else
        echo "   ⚡ Ejecutándose en Intel Mac"
    fi
    echo ""
    echo "🔧 Datos persistentes en volumes de Docker"
    echo "📧 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "☁️  MODELOS CLOUD DISPONIBLES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Los siguientes modelos cloud requieren autenticación:"
    echo "  📦 qwen3-vl:235b-cloud"
    echo "  📦 gpt-oss:120b-cloud"
    echo "  📦 qwen3-coder:480b-cloud"
    echo ""
    echo "⚠️  Los modelos cloud NO se instalan automáticamente"
    echo ""
    echo "📋 Para instalar modelos cloud:"
    echo ""
    echo "1️⃣  Usa el script helper:"
    echo "   bash macos/docker-install-cloud-models-mac.sh"
    echo ""
    echo "O manualmente:"
    echo "   docker exec -it msn-ai-ollama /bin/bash"
    echo "   ollama signin"
    echo "   ollama pull qwen3-vl:235b-cloud"
    echo "   exit"
    echo ""
    echo "💡 Los modelos locales ya están instalados y funcionando"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Function for cleanup
cleanup() {
    echo ""
    echo "🧹 Deteniendo contenedores MSN-AI..."
    docker-compose -f docker/docker-compose.yml down
    echo "✅ Contenedores detenidos correctamente"
    echo "👋 ¡Gracias por usar MSN-AI v1.0.0 en macOS!"
    exit 0
}

# Trap signals for cleanup
trap cleanup SIGINT SIGTERM

# Main execution flow
main() {
    echo "🚀 Iniciando MSN-AI en modo Docker para macOS..."

    # Detect macOS information
    detect_mac_info

    # Check Docker installation
    check_docker

    # Check hardware optimization
    check_hardware_optimization

    # Setup environment
    setup_environment

    # Start containers
    start_containers

    # Wait for services
    wait_for_services

    # Open application (if not --no-browser flag)
    if [ "$1" != "--no-browser" ]; then
        open_application
    fi

    # Show status
    show_status

    # Keep script running for signal handling
    if [ "$1" = "--daemon" ]; then
        echo "🔄 Modo daemon activado. Presiona Ctrl+C para detener."
        while true; do
            sleep 1
        done
    else
        echo "💡 Script completado. Los contenedores continúan ejecutándose."
        echo "   Para detenerlos: docker-compose -f docker/docker-compose.yml down"
    fi
}

# Parse command line arguments
case "$1" in
    --help|-h)
        echo "MSN-AI Docker macOS - Opciones de uso:"
        echo ""
        echo "  $0                    Iniciar con navegador automático"
        echo "  $0 --no-browser      Iniciar sin abrir navegador"
        echo "  $0 --daemon          Mantener script activo"
        echo "  $0 --help            Mostrar esta ayuda"
        echo ""
        echo "🍎 Optimizado para macOS (Intel y Apple Silicon)"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
