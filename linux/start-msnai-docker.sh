#!/bin/bash
# Docker Startup Script for MSN-AI - Linux
# Version: 2.1.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Docker-based startup for MSN-AI with intelligent setup

echo "🐳 MSN-AI v2.1.0 - Docker Edition"
echo "=================================="
echo "📧 Desarrollado por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0 | 🔗 alan.mac.arthur.garcia.diaz@gmail.com"
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
    echo "   $PROJECT_ROOT/linux/start-msnai-docker.sh"
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

# Function to detect and configure Docker Compose
setup_docker_compose() {
    echo "🔍 Detectando Docker Compose..."

    # Check if docker-compose (standalone binary) exists
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker-compose"
        echo "✅ Docker Compose (standalone) disponible"
        return 0
    fi

    # Check if docker compose (plugin) exists
    if docker compose version &> /dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker compose"
        echo "✅ Docker Compose (plugin) disponible"
        return 0
    fi

    # Neither available, offer installation
    echo "❌ Docker Compose no está disponible"
    echo ""
    echo "🚀 Opciones:"
    echo "   1. Instalar docker-compose standalone (recomendado para compatibilidad)"
    echo "   2. Usar docker compose plugin (requiere Docker Engine reciente)"
    echo "   3. Salir e instalar manualmente"

    read -p "Selecciona una opción (1-3): " compose_option

    case $compose_option in
        1)
            install_docker_compose_standalone
            ;;
        2)
            if docker compose version &> /dev/null 2>&1; then
                DOCKER_COMPOSE_CMD="docker compose"
                echo "✅ Usando docker compose plugin"
            else
                echo "❌ Docker compose plugin no disponible"
                echo "   Actualiza Docker Engine o instala Docker Desktop"
                exit 1
            fi
            ;;
        3)
            echo "ℹ️  Para instalar manualmente:"
            echo "   curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose"
            echo "   sudo chmod +x /usr/local/bin/docker-compose"
            exit 1
            ;;
        *)
            echo "❌ Opción no válida"
            exit 1
            ;;
    esac
}

# Function to install docker-compose standalone
install_docker_compose_standalone() {
    echo "📦 Instalando docker-compose standalone..."

    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64"
            ;;
        aarch64|arm64)
            COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-linux-aarch64"
            ;;
        *)
            echo "❌ Arquitectura $ARCH no soportada para instalación automática"
            exit 1
            ;;
    esac

    # Check if we can write to /usr/local/bin
    if [ -w "/usr/local/bin" ]; then
        INSTALL_PATH="/usr/local/bin/docker-compose"
        SUDO_CMD=""
    else
        INSTALL_PATH="/usr/local/bin/docker-compose"
        SUDO_CMD="sudo"
        echo "🔐 Se requieren permisos de administrador para instalar en /usr/local/bin"
    fi

    # Download and install
    echo "📥 Descargando desde: $COMPOSE_URL"
    if curl -SL "$COMPOSE_URL" -o "/tmp/docker-compose" 2>/dev/null; then
        $SUDO_CMD mv "/tmp/docker-compose" "$INSTALL_PATH"
        $SUDO_CMD chmod +x "$INSTALL_PATH"

        # Verify installation
        if command -v docker-compose &> /dev/null; then
            DOCKER_COMPOSE_CMD="docker-compose"
            echo "✅ Docker Compose standalone instalado correctamente"
            echo "   Versión: $(docker-compose --version)"
        else
            echo "❌ Error en la instalación"
            exit 1
        fi
    else
        echo "❌ Error descargando docker-compose"
        exit 1
    fi
}

# Function to check disk space
check_disk_space() {
    echo "🔍 Verificando espacio en disco..."

    # Get available space in /var/lib/docker (where Docker stores images)
    local docker_dir="/var/lib/docker"
    if [ ! -d "$docker_dir" ]; then
        docker_dir="/"
    fi

    local available_gb=$(df -BG "$docker_dir" | awk 'NR==2 {print $4}' | sed 's/G//')
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

    # Setup Docker Compose
    setup_docker_compose
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
            sudo pacman -S docker
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
    echo "   sudo pacman -S docker"
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

# Function to check port conflicts
check_port_conflicts() {
    echo "🔍 Verificando conflictos de puerto..."

    local conflicts_found=false

    # Check port 8000
    if netstat -tuln 2>/dev/null | grep -q ":8000 " || ss -tuln 2>/dev/null | grep -q ":8000 "; then
        echo "⚠️  Puerto 8000 ya está en uso:"
        netstat -tulnp 2>/dev/null | grep ":8000 " || ss -tulnp 2>/dev/null | grep ":8000 " || true
        conflicts_found=true
    fi

    # Check port 11434
    if netstat -tuln 2>/dev/null | grep -q ":11434 " || ss -tuln 2>/dev/null | grep -q ":11434 "; then
        echo "⚠️  Puerto 11434 ya está en uso (posiblemente Ollama local):"
        netstat -tulnp 2>/dev/null | grep ":11434 " || ss -tulnp 2>/dev/null | grep ":11434 " || true
        echo "💡 Para servidor dedicado, detén Ollama local:"
        echo "   sudo systemctl stop ollama"
        echo "   sudo pkill -f ollama"
        conflicts_found=true
    fi

    if [ "$conflicts_found" = true ]; then
        echo ""
        echo "❓ ¿Continuar con la instalación? Los contenedores pueden fallar si los puertos están ocupados. (y/N):"
        if [ "${AUTO_MODE}" != "true" ]; then
            read -r CONTINUE
            if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
                echo "❌ Instalación cancelada por el usuario"
                exit 1
            fi
        else
            echo "⚠️  Modo automático: Intentando continuar..."
        fi
    else
        echo "✅ Puertos 8000 y 11434 disponibles"
    fi
}

# Function to setup Docker environment
setup_environment() {
    echo "⚙️  Configurando entorno Docker..."

    # Check for existing OLLAMA_API_KEY
    OLLAMA_API_KEY_VALUE=""

    # Check if .env file exists and has API key
    if [ -f ".env" ]; then
        OLLAMA_API_KEY_VALUE=$(grep "^OLLAMA_API_KEY=" .env 2>/dev/null | cut -d'=' -f2-)
    fi

    # If not in .env, check environment
    if [ -z "$OLLAMA_API_KEY_VALUE" ] && [ -n "$OLLAMA_API_KEY" ]; then
        OLLAMA_API_KEY_VALUE="$OLLAMA_API_KEY"
    fi

    # If still not found, prompt user
    if [ -z "$OLLAMA_API_KEY_VALUE" ]; then
        echo ""
        echo "🔑 Configuración de API Key para modelos cloud"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "⚠️  Los modelos cloud requieren una API Key:"
        echo "   - qwen3-vl:235b-cloud"
        echo "   - gpt-oss:120b-cloud"
        echo "   - qwen3-coder:480b-cloud"
        echo ""
        echo "💡 Si no tienes una API Key, estos modelos no funcionarán"
        echo "   (puedes configurarla después)"
        echo ""
        read -p "¿Deseas configurar la API Key ahora? (s/N): " CONFIGURE_API_KEY

        if [[ "$CONFIGURE_API_KEY" =~ ^[sS]$ ]]; then
            echo ""
            read -p "Ingresa tu OLLAMA_API_KEY: " OLLAMA_API_KEY_VALUE

            if [ -n "$OLLAMA_API_KEY_VALUE" ]; then
                echo "✅ API Key configurada"
            else
                echo "⚠️  No se ingresó API Key, continuando sin ella"
            fi
        else
            echo "⏭️  Continuando sin API Key"
            echo "   Para configurarla después, ejecuta:"
            echo "   echo 'OLLAMA_API_KEY=tu_clave_aqui' >> .env"
        fi
        echo ""
    else
        # Mask the key for display
        MASKED_KEY="${OLLAMA_API_KEY_VALUE:0:8}***${OLLAMA_API_KEY_VALUE: -4}"
        echo "✅ API Key encontrada: ${MASKED_KEY}"
    fi

    # Create .env file for Docker Compose
    cat > .env << EOF
# MSN-AI Docker Environment Configuration
MSN_AI_VERSION=1.0.0
MSN_AI_PORT=8000
COMPOSE_PROJECT_NAME=msn-ai
DOCKER_BUILDKIT=1
EOF

    # Add API Key if configured
    if [ -n "$OLLAMA_API_KEY_VALUE" ]; then
        echo "OLLAMA_API_KEY=${OLLAMA_API_KEY_VALUE}" >> .env
        echo "✅ API Key agregada al archivo .env"
    else
        echo "# OLLAMA_API_KEY=your_api_key_here" >> .env
    fi

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
    echo ""

    # Create build log directory
    BUILD_LOG_DIR="$PROJECT_ROOT/docker/logs"
    mkdir -p "$BUILD_LOG_DIR"
    BUILD_LOG="$BUILD_LOG_DIR/build_$(date +%Y%m%d_%H%M%S).log"

    echo "📝 Los logs se guardarán en: $BUILD_LOG"
    echo ""

    # Check disk space before build
    echo "🔍 Verificando espacio antes de construir..."
    local available_gb=$(df -BG /var/lib/docker 2>/dev/null || df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    echo "   Espacio disponible: ${available_gb}GB"

    if [ "$available_gb" -lt 3 ]; then
        echo ""
        echo "⚠️  ADVERTENCIA: Espacio muy limitado (${available_gb}GB)"
        echo "   La construcción puede fallar por falta de espacio"
        echo ""
        read -p "¿Continuar de todas formas? (s/N): " continue_build
        if [[ ! "$continue_build" =~ ^[sS]$ ]]; then
            echo "❌ Construcción cancelada"
            exit 1
        fi
    fi
    echo ""

    # Build images with verbose output
    echo "📦 Construyendo imagen MSN-AI..."
    echo "   Esto puede tardar varios minutos en la primera ejecución..."
    echo "   Comando: $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml build --no-cache"
    echo ""

    # Run build with full output
    if $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml build --no-cache --progress=plain 2>&1 | tee "$BUILD_LOG"; then
        echo ""
        echo "✅ Imagen construida exitosamente"
    else
        BUILD_EXIT_CODE=$?
        echo ""
        echo "❌ Error construyendo la imagen (código de salida: $BUILD_EXIT_CODE)"
        echo "📝 Revisa los logs en: $BUILD_LOG"
        echo ""
        echo "💡 Diagnóstico rápido:"
        echo ""
        echo "📊 Espacio en disco:"
        df -h /var/lib/docker 2>/dev/null || df -h /
        echo ""
        echo "💾 Memoria disponible:"
        free -h
        echo ""
        echo "📝 Últimos errores del log:"
        tail -30 "$BUILD_LOG"
        echo ""
        echo "🔍 Para diagnóstico completo, ejecuta:"
        echo "   bash linux/docker-diagnostics.sh"
        exit 1
    fi

    echo ""

    # Start services with verbose output
    echo "🚀 Iniciando servicios..."
    echo "   Comando: $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml up -d"
    echo ""

    # Create startup log
    STARTUP_LOG="$BUILD_LOG_DIR/startup_$(date +%Y%m%d_%H%M%S).log"

    if $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml up -d 2>&1 | tee "$STARTUP_LOG"; then
        echo ""
        echo "✅ Servicios iniciados"
        echo ""

        # Show container status
        echo "📊 Estado de los contenedores:"
        $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml ps
        echo ""

        # Check if ai-setup failed (non-critical)
        if docker ps -a --format '{{.Names}} {{.Status}}' | grep -q "msn-ai-setup.*Exited"; then
            echo "ℹ️  NOTA: El servicio ai-setup finalizó (esto es normal)"
            echo "   Este servicio configura modelos de IA automáticamente"
            echo "   Los modelos pueden instalarse manualmente desde la interfaz"
            echo ""
        fi
    else
        STARTUP_EXIT_CODE=$?
        echo ""
        echo "❌ Error iniciando los servicios (código de salida: $STARTUP_EXIT_CODE)"
        echo "📝 Revisa los logs en: $STARTUP_LOG"
        echo ""
        echo "📊 Diagnóstico del sistema:"
        echo "Espacio en disco:"
        df -h /var/lib/docker 2>/dev/null || df -h /
        echo ""
        echo "💡 Mostrando logs recientes de los contenedores:"
        echo ""
        echo "--- Logs de msn-ai-app ---"
        docker logs msn-ai-app 2>&1 | tail -20 || echo "Contenedor no disponible"
        echo ""
        echo "--- Logs de msn-ai-ollama ---"
        docker logs msn-ai-ollama 2>&1 | tail -20 || echo "Contenedor no disponible"
        echo ""
        echo "--- Logs de msn-ai-setup ---"
        docker logs msn-ai-setup 2>&1 | tail -20 || echo "Contenedor no disponible"
        echo ""
        echo "🔍 Para diagnóstico completo, ejecuta:"
        echo "   bash linux/docker-diagnostics.sh"
        exit 1
    fi

    echo "✅ Contenedores Docker iniciados"
    echo ""

    # Show friendly message about ai-setup
    if docker ps -a --format '{{.Names}} {{.State.ExitCode}}' | grep -q "msn-ai-setup"; then
        SETUP_EXIT_CODE=$(docker inspect msn-ai-setup --format='{{.State.ExitCode}}' 2>/dev/null || echo "unknown")
        if [ "$SETUP_EXIT_CODE" = "0" ]; then
            echo "ℹ️  Configuración de IA: Completada exitosamente"
        else
            echo "ℹ️  Configuración de IA: Finalizada con advertencias (no crítico)"
            echo "   Los modelos de IA pueden instalarse manualmente"
        fi
        echo ""
    fi
}

# Function to wait for services
wait_for_services() {
    echo "⏳ Esperando que los servicios estén listos..."
    echo ""

    local max_attempts=60
    local attempt=1
    local ollama_ready=false
    local webapp_ready=false

    # First wait for Ollama
    echo "🔄 Verificando servicio Ollama..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s --max-time 2 http://localhost:11434/api/tags >/dev/null 2>&1; then
            echo "✅ Ollama está listo (intento $attempt/$max_attempts)"
            ollama_ready=true
            break
        fi

        if [ $((attempt % 5)) -eq 0 ]; then
            echo "⏳ Esperando Ollama... intento $attempt/$max_attempts"
            # Show container status
            docker ps --filter name=msn-ai-ollama --format "   Estado: {{.Status}}"
        fi

        sleep 2
        attempt=$((attempt + 1))
    done

    if [ "$ollama_ready" = false ]; then
        echo "⚠️  Ollama no respondió después de $((max_attempts * 2)) segundos"
        echo "   Logs de Ollama:"
        docker logs --tail 30 msn-ai-ollama
        echo ""
    fi

    # Then wait for web app
    echo "🔄 Verificando aplicación web MSN-AI..."
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -s --max-time 2 http://localhost:8000/msn-ai.html >/dev/null 2>&1; then
            echo "✅ MSN-AI está listo (intento $attempt/$max_attempts)"
            webapp_ready=true
            break
        fi

        if [ $((attempt % 5)) -eq 0 ]; then
            echo "⏳ Esperando MSN-AI Web... intento $attempt/$max_attempts"
            # Show container status
            docker ps --filter name=msn-ai-app --format "   Estado: {{.Status}}"
        fi

        sleep 2
        attempt=$((attempt + 1))
    done

    echo ""

    if [ "$webapp_ready" = false ]; then
        echo "⚠️  MSN-AI Web no respondió después de $((max_attempts * 2)) segundos"
        echo ""
        echo "📋 Estado de contenedores:"
        $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml ps
        echo ""
        echo "📝 Logs recientes de MSN-AI App:"
        docker logs --tail 30 msn-ai-app 2>&1 || echo "El contenedor msn-ai-app no se inició correctamente"
        echo ""
        echo "💡 Posibles causas:"
        echo "   1. El contenedor aún está iniciando (espera 1-2 minutos más)"
        echo "   2. Falta de recursos del sistema (RAM/CPU)"
        echo "   3. Error en la construcción de la imagen"
        echo ""
        echo "🔍 Para ver todos los logs:"
        echo "   $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml logs"
        echo ""
        echo "🔍 Para diagnóstico completo:"
        echo "   bash linux/docker-diagnostics.sh"
        echo ""
        return 1
    fi

    return 0
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

    # Detect server IP for information only
    SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")

    # Test connectivity
    echo "🧪 Verificando conectividad..."
    sleep 3

    echo -n "   🌐 MSN-AI Web (localhost:8000): "
    if curl -s --connect-timeout 5 "http://localhost:8000/msn-ai.html" >/dev/null 2>&1; then
        echo "✅ OK"
        WEB_OK=true
    else
        echo "❌ FALLA"
        WEB_OK=false
    fi

    echo -n "   🤖 Ollama API (localhost:11434): "
    if curl -s --connect-timeout 5 "http://localhost:11434/api/tags" >/dev/null 2>&1; then
        MODELS_RESPONSE=$(curl -s "http://localhost:11434/api/tags" 2>/dev/null)
        MODEL_COUNT=$(echo "$MODELS_RESPONSE" | grep -o '"name"' | wc -l 2>/dev/null || echo "0")
        echo "✅ OK ($MODEL_COUNT modelos)"
        API_OK=true
    else
        echo "❌ FALLA"
        API_OK=false
    fi

    echo ""
    echo "🔗 URLs DE ACCESO:"
    if [ "$WEB_OK" = true ]; then
        echo "   🏠 Local:  http://localhost:8000/msn-ai.html"
        if [ "$SERVER_IP" != "localhost" ]; then
            echo "   🌐 Remoto: http://$SERVER_IP:8000/msn-ai.html"
        fi
    fi

    if [ "$WEB_OK" = true ] && [ "$API_OK" = true ]; then
        echo ""
        echo "✅ MSN-AI COMPLETAMENTE FUNCIONAL"
        echo "   • Interfaz web accesible"
        echo "   • API Ollama respondiendo"
        echo "   • $MODEL_COUNT modelos disponibles"
        echo "   • Auto-detección de configuración habilitada"
        echo "   • Sin configuración de firewall requerida"
    elif [ "$WEB_OK" = true ]; then
        echo ""
        echo "⚠️  MSN-AI PARCIALMENTE FUNCIONAL"
        echo "   • Interfaz web: ✅ Accesible"
        echo "   • API Ollama: ❌ No responde"
        echo "   💡 Ver logs: docker logs msn-ai-ollama"
    else
        echo ""
        echo "❌ MSN-AI CON PROBLEMAS"
        echo "   • Interfaz web: ❌ No accesible"
        echo "   • API Ollama: ❌ No responde"
        echo "   💡 Ver logs: docker logs msn-ai-app"
    fi

    echo ""
    echo "🐳 Contenedores:"
    $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml ps
    echo ""
    echo "📊 Estado de servicios:"
    $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml ps
    echo ""
    echo "💡 Comandos útiles:"
    echo "   🔍 Ver logs:        $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml logs -f"
    echo "   ⏹️  Detener:         $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml down"
    echo "   🔄 Reiniciar:       $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml restart"
    echo "   📊 Estado:          $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml ps"
    echo ""
    echo "⚠️  DETENCIÓN CORRECTA:"
    echo "   $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml down"
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
    echo "1️⃣  Accede al contenedor:"
    echo "   docker exec -it msn-ai-ollama /bin/bash"
    echo ""
    echo "2️⃣  Haz signin (abre el enlace generado en tu navegador):"
    echo "   ollama signin"
    echo ""
    echo "3️⃣  Instala los modelos que necesites:"
    echo "   ollama pull qwen3-vl:235b-cloud"
    echo "   ollama pull gpt-oss:120b-cloud"
    echo "   ollama pull qwen3-coder:480b-cloud"
    echo ""
    echo "4️⃣  Verifica la instalación:"
    echo "   ollama list"
    echo ""
    echo "5️⃣  Sal del contenedor:"
    echo "   exit"
    echo ""
    echo "💡 Los modelos locales ya están instalados y funcionando"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Function for cleanup
cleanup() {
    echo ""
    echo "🧹 Deteniendo contenedores MSN-AI..."
    if [ -n "$DOCKER_COMPOSE_CMD" ]; then
        $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml down
    else
        # Fallback si no se pudo determinar el comando
        if command -v docker-compose &> /dev/null; then
            docker-compose -f docker/docker-compose.yml down
        elif docker compose version &> /dev/null 2>&1; then
            docker compose -f docker/docker-compose.yml down
        fi
    fi
    echo "✅ Contenedores detenidos correctamente"
    echo "👋 ¡Gracias por usar MSN-AI v2.1.0!"
    exit 0
}

# Trap signals for cleanup
trap cleanup SIGINT SIGTERM

# Main execution flow
main() {
    echo "🚀 Iniciando MSN-AI en modo Docker..."

    # Check Docker installation
    check_docker

    # Check port conflicts
    check_port_conflicts

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
        echo "   Para detenerlos: $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml down"
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
