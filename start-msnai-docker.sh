#!/bin/bash
# Docker Startup Script for MSN-AI - Linux
# Version: 1.0.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Docker-based startup for MSN-AI with intelligent setup

echo "🐳 MSN-AI v1.0.0 - Docker Edition"
echo "=================================="
echo "📧 Desarrollado por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0 | 🔗 alan.mac.arthur.garcia.diaz@gmail.com"
echo "🐳 Modo: Docker Container"
echo "=================================="

# Check if we're in the correct directory
if [ ! -f "msn-ai.html" ]; then
    echo "❌ Error: No se encuentra msn-ai.html"
    echo "   Asegúrate de ejecutar este script desde el directorio MSN-AI"
    exit 1
fi

# Check if docker directory exists
if [ ! -d "docker" ]; then
    echo "❌ Error: Directorio docker no encontrado"
    echo "   Asegúrate de que todos los archivos Docker estén presentes"
    exit 1
fi

# Function to check Docker installation
check_docker() {
    echo "🔍 Verificando Docker..."

    if ! command -v docker &> /dev/null; then
        echo "❌ Docker no está instalado"
        echo ""
        echo "🚀 Opciones de instalación:"
        echo "   1. Instalar automáticamente (recomendado)"
        echo "   2. Instrucciones manuales"
        echo "   3. Continuar sin Docker (modo local)"

        read -p "Selecciona una opción (1-3): " docker_option

        case $docker_option in
            1)
                install_docker
                ;;
            2)
                show_docker_instructions
                exit 1
                ;;
            3)
                echo "🔄 Iniciando en modo local..."
                exec ./start-msnai.sh "$@"
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
        echo "   Ejecuta: sudo systemctl start docker"
        echo "   O inicia Docker Desktop si lo usas"
        exit 1
    else
        echo "✅ Docker está ejecutándose"
    fi

    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo "❌ Docker Compose no está disponible"
        echo "   Instala Docker Compose o usa Docker Desktop"
        exit 1
    else
        echo "✅ Docker Compose disponible"
    fi
}

# Function to install Docker automatically
install_docker() {
    echo "📦 Instalando Docker automáticamente..."

    # Detect Linux distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo "❌ No se pudo detectar la distribución Linux"
        exit 1
    fi

    case $DISTRO in
        ubuntu|debian)
            echo "🐧 Detectado: $PRETTY_NAME"
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            rm get-docker.sh
            ;;
        centos|rhel|fedora)
            echo "🎩 Detectado: $PRETTY_NAME"
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            sudo systemctl start docker
            sudo systemctl enable docker
            rm get-docker.sh
            ;;
        arch)
            echo "🏹 Detectado: Arch Linux"
            sudo pacman -S docker docker-compose
            sudo usermod -aG docker $USER
            sudo systemctl start docker
            sudo systemctl enable docker
            ;;
        *)
            echo "⚠️  Distribución no soportada para instalación automática: $DISTRO"
            show_docker_instructions
            exit 1
            ;;
    esac

    echo "✅ Docker instalado correctamente"
    echo "⚠️  Es necesario reiniciar la sesión para aplicar los permisos"
    echo "   Ejecuta: newgrp docker"
    echo "   O cierra sesión e inicia sesión nuevamente"
}

# Function to show manual Docker installation instructions
show_docker_instructions() {
    echo ""
    echo "📖 Instrucciones de instalación manual de Docker:"
    echo "================================================="
    echo ""
    echo "🐧 Ubuntu/Debian:"
    echo "   curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "   sudo sh get-docker.sh"
    echo "   sudo usermod -aG docker \$USER"
    echo ""
    echo "🎩 CentOS/RHEL/Fedora:"
    echo "   sudo yum install -y docker"
    echo "   sudo systemctl start docker"
    echo "   sudo usermod -aG docker \$USER"
    echo ""
    echo "🏹 Arch Linux:"
    echo "   sudo pacman -S docker docker-compose"
    echo "   sudo systemctl start docker"
    echo "   sudo usermod -aG docker \$USER"
    echo ""
    echo "💡 Después de instalar, ejecuta este script nuevamente"
}

# Function to check hardware for GPU support
check_gpu_support() {
    echo "🎮 Verificando soporte de GPU..."

    if command -v nvidia-smi &> /dev/null; then
        echo "✅ NVIDIA GPU detectada"

        # Check NVIDIA Container Toolkit
        if docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu22.04 nvidia-smi &> /dev/null; then
            echo "✅ NVIDIA Container Toolkit configurado"
            USE_GPU=true
        else
            echo "⚠️  NVIDIA Container Toolkit no disponible"
            echo "   Para habilitar GPU en Docker, instala:"
            echo "   https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
            USE_GPU=false
        fi
    else
        echo "ℹ️  GPU NVIDIA no detectada, usando solo CPU"
        USE_GPU=false
    fi
}

# Function to setup environment
setup_environment() {
    echo "⚙️  Configurando entorno Docker..."

    # Create .env file for Docker Compose
    cat > .env << EOF
# MSN-AI Docker Environment Configuration
MSN_AI_VERSION=1.0.0
MSN_AI_PORT=8000
COMPOSE_PROJECT_NAME=msn-ai
DOCKER_BUILDKIT=1
EOF

    # Add GPU configuration if available
    if [ "$USE_GPU" = true ]; then
        echo "GPU_SUPPORT=true" >> .env
    else
        echo "GPU_SUPPORT=false" >> .env
    fi

    echo "✅ Archivo de entorno creado"
}

# Function to build and start containers
start_containers() {
    echo "🏗️  Construyendo e iniciando contenedores..."

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
        echo "⚠️  Timeout esperando los servicios"
        echo "   Verifica los logs: docker-compose -f docker/docker-compose.yml logs"
    fi
}

# Function to open application
open_application() {
    echo "🌐 Abriendo MSN-AI en el navegador..."

    # Try different browsers
    if command -v firefox >/dev/null 2>&1; then
        firefox http://localhost:8000/msn-ai.html &
    elif command -v google-chrome >/dev/null 2>&1; then
        google-chrome http://localhost:8000/msn-ai.html &
    elif command -v chromium-browser >/dev/null 2>&1; then
        chromium-browser http://localhost:8000/msn-ai.html &
    else
        echo "🌐 Abre manualmente: http://localhost:8000/msn-ai.html"
    fi
}

# Function to show status and logs
show_status() {
    echo ""
    echo "🎉 ¡MSN-AI Docker está ejecutándose!"
    echo "===================================="
    echo "📱 URL: http://localhost:8000/msn-ai.html"
    echo "🐳 Contenedores:"
    docker-compose -f docker/docker-compose.yml ps
    echo ""
    echo "📊 Estado de servicios:"
    docker-compose -f docker/docker-compose.yml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "💡 Comandos útiles:"
    echo "   🔍 Ver logs:        docker-compose -f docker/docker-compose.yml logs -f"
    echo "   ⏹️  Detener:         docker-compose -f docker/docker-compose.yml down"
    echo "   🔄 Reiniciar:       docker-compose -f docker/docker-compose.yml restart"
    echo "   📊 Estado:          docker-compose -f docker/docker-compose.yml ps"
    echo ""
    echo "⚠️  DETENCIÓN CORRECTA:"
    echo "   docker-compose -f docker/docker-compose.yml down"
    echo ""
    echo "🔧 Datos persistentes en volumes de Docker"
    echo "📧 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
}

# Function for cleanup
cleanup() {
    echo ""
    echo "🧹 Deteniendo contenedores MSN-AI..."
    docker-compose -f docker/docker-compose.yml down
    echo "✅ Contenedores detenidos correctamente"
    echo "👋 ¡Gracias por usar MSN-AI v1.0.0!"
    exit 0
}

# Trap signals for cleanup
trap cleanup SIGINT SIGTERM

# Main execution flow
main() {
    echo "🚀 Iniciando MSN-AI en modo Docker..."

    # Check Docker installation
    check_docker

    # Check GPU support
    check_gpu_support

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
        echo "MSN-AI Docker - Opciones de uso:"
        echo ""
        echo "  $0                    Iniciar con navegador automático"
        echo "  $0 --no-browser      Iniciar sin abrir navegador"
        echo "  $0 --daemon          Mantener script activo"
        echo "  $0 --help            Mostrar esta ayuda"
        echo ""
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
