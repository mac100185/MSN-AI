#!/bin/bash

# MSN-AI - Instalación Transparente con Acceso Remoto Automático
# =============================================================
# 🎯 Por: Alan Mac-Arthur García Díaz
# ⚖️ Licencia: GPL-3.0
# 📧 alan.mac.arthur.garcia.diaz@gmail.com
# =============================================================

echo "🚀 MSN-AI v2.0.0 - Instalación Remota Transparente"
echo "=================================================="
echo "📧 Desarrollado por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0 | 🔗 alan.mac.arthur.garcia.diaz@gmail.com"
echo "🌐 Modo: Docker + Acceso Remoto Automático"
echo "=================================================="
echo ""

# Detectar información del sistema
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[^ ]+' || echo "localhost")
SERVER_NAME=$(hostname 2>/dev/null || echo "unknown")

if [ "$SERVER_IP" = "localhost" ] || [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[^ ]+' || echo "127.0.0.1")
fi

echo "🖥️ Servidor: $SERVER_NAME ($SERVER_IP)"
echo ""

# Verificar directorio correcto
if [ ! -f "msn-ai.html" ]; then
    echo "❌ Error: No se encuentra msn-ai.html"
    echo "   Asegúrate de ejecutar este script desde el directorio MSN-AI"
    exit 1
fi

# Verificar Docker
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker no está instalado"
    echo "💡 Instalar Docker:"
    echo "   curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "   sudo sh get-docker.sh"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker no está ejecutándose"
    echo "💡 Iniciar Docker: sudo systemctl start docker"
    exit 1
fi

# Detectar Docker Compose
DOCKER_COMPOSE_CMD=""
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "❌ Docker Compose no está disponible"
    echo "💡 Instalar Docker Compose:"
    echo "   sudo apt update && sudo apt install docker-compose-plugin"
    exit 1
fi

echo "✅ Docker y Docker Compose disponibles"
echo ""

# Función para configurar firewall automáticamente
configure_firewall_auto() {
    echo "🔥 Configurando acceso remoto automáticamente..."

    if ! command -v ufw >/dev/null 2>&1; then
        echo "⚠️ UFW no disponible, saltando configuración firewall"
        echo "💡 Si tienes problemas de acceso remoto, consulta tu administrador de firewall"
        return 1
    fi

    # Intentar configuración automática silenciosa
    UFW_CONFIGURED=false

    if [ "$EUID" -eq 0 ]; then
        # Ejecutándose como root
        echo "🔧 Configurando como administrador..."
        ufw allow 8000 comment "MSN-AI Web Interface" >/dev/null 2>&1
        ufw allow 11434 comment "MSN-AI Ollama API" >/dev/null 2>&1

        if ufw status 2>/dev/null | grep -q "inactive"; then
            ufw --force enable >/dev/null 2>&1
        fi
        UFW_CONFIGURED=true
        echo "✅ Firewall configurado automáticamente"

    elif sudo -n true 2>/dev/null; then
        # Sudo sin contraseña disponible
        echo "🔧 Configurando con permisos elevados..."
        sudo ufw allow 8000 comment "MSN-AI Web Interface" >/dev/null 2>&1
        sudo ufw allow 11434 comment "MSN-AI Ollama API" >/dev/null 2>&1

        if sudo ufw status 2>/dev/null | grep -q "inactive"; then
            sudo ufw --force enable >/dev/null 2>&1
        fi
        UFW_CONFIGURED=true
        echo "✅ Firewall configurado automáticamente"

    else
        # Necesita contraseña sudo
        echo "🔐 Se requieren permisos de administrador para configurar acceso remoto"
        echo "💡 Puedes:"
        echo "   1. Ejecutar: sudo $0"
        echo "   2. Configurar manualmente después: sudo ufw allow 8000 && sudo ufw allow 11434"
        echo "   3. Continuar solo con acceso local"
        echo ""
        echo "¿Continuar con la instalación? (Y/n): "
        read -r CONTINUE
        if [ "$CONTINUE" = "n" ] || [ "$CONTINUE" = "N" ]; then
            echo "❌ Instalación cancelada por el usuario"
            exit 1
        fi
        UFW_CONFIGURED=false
    fi

    return 0
}

# Función para instalar MSN-AI
install_msnai() {
    echo "🐳 Iniciando instalación de MSN-AI..."
    echo "===================================="

    # Configurar variables de entorno
    export MSN_AI_VERSION=2.0.0
    export MSN_AI_PORT=8000
    export OLLAMA_HOST=0.0.0.0:11434
    export OLLAMA_ORIGINS="*"

    # Crear archivo .env si no existe
    if [ ! -f ".env" ]; then
        cat > .env << EOF
# MSN-AI Environment Configuration
MSN_AI_VERSION=2.0.0
MSN_AI_PORT=8000
OLLAMA_HOST=0.0.0.0:11434
OLLAMA_ORIGINS=*
EOF
        echo "✅ Archivo de configuración creado"
    fi

    # Limpiar instalación previa si existe
    echo "🧹 Limpiando instalación previa..."
    $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml down >/dev/null 2>&1 || true

    # Construir e iniciar contenedores
    echo "🔨 Construyendo contenedores MSN-AI..."
    if ! $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml build --quiet; then
        echo "❌ Error construyendo contenedores"
        return 1
    fi

    echo "🚀 Iniciando servicios MSN-AI..."
    if ! $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml up -d; then
        echo "❌ Error iniciando servicios"
        return 1
    fi

    echo "✅ Contenedores iniciados"
    return 0
}

# Función para esperar que los servicios estén listos
wait_for_services() {
    echo ""
    echo "⏳ Esperando que los servicios estén listos..."

    local max_attempts=60
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        echo -n "⏳ Intento $attempt/$max_attempts..."

        # Verificar que MSN-AI responda
        if curl -s --connect-timeout 3 "http://localhost:8000/msn-ai.html" >/dev/null 2>&1; then
            echo " ✅ MSN-AI listo"
            break
        fi

        if [ $attempt -eq $max_attempts ]; then
            echo " ❌ Timeout"
            echo "⚠️ Los servicios están tardando más de lo esperado"
            echo "💡 Verificar logs: docker logs msn-ai-app"
            return 1
        fi

        echo " ⏳"
        sleep 2
        ((attempt++))
    done

    # Esperar un poco más para Ollama
    echo "⏳ Esperando que Ollama esté listo..."
    sleep 5

    return 0
}

# Función para verificar conectividad completa
verify_connectivity() {
    echo ""
    echo "🧪 Verificando conectividad completa..."
    echo "====================================="

    local all_ok=true

    # Test local web
    echo -n "🏠 MSN-AI local (localhost:8000): "
    if curl -s --connect-timeout 5 "http://localhost:8000/msn-ai.html" >/dev/null 2>&1; then
        echo "✅"
        LOCAL_WEB_OK=true
    else
        echo "❌"
        LOCAL_WEB_OK=false
        all_ok=false
    fi

    # Test local API
    echo -n "🤖 Ollama local (localhost:11434): "
    if curl -s --connect-timeout 5 "http://localhost:11434/api/tags" >/dev/null 2>&1; then
        OLLAMA_RESPONSE=$(curl -s "http://localhost:11434/api/tags" 2>/dev/null)
        MODEL_COUNT=$(echo "$OLLAMA_RESPONSE" | grep -o '"name"' | wc -l 2>/dev/null || echo "0")
        echo "✅ ($MODEL_COUNT modelos)"
        LOCAL_API_OK=true
    else
        echo "❌"
        LOCAL_API_OK=false
        all_ok=false
    fi

    # Test remoto solo si la IP no es localhost
    if [ "$SERVER_IP" != "localhost" ] && [ "$SERVER_IP" != "127.0.0.1" ]; then
        # Test remoto web
        echo -n "🌐 MSN-AI remoto ($SERVER_IP:8000): "
        if curl -s --connect-timeout 5 "http://$SERVER_IP:8000/msn-ai.html" >/dev/null 2>&1; then
            echo "✅"
            REMOTE_WEB_OK=true
        else
            echo "❌"
            REMOTE_WEB_OK=false
        fi

        # Test remoto API
        echo -n "🌐 Ollama remoto ($SERVER_IP:11434): "
        if curl -s --connect-timeout 5 "http://$SERVER_IP:11434/api/tags" >/dev/null 2>&1; then
            echo "✅"
            REMOTE_API_OK=true
        else
            echo "❌"
            REMOTE_API_OK=false
        fi

        REMOTE_ACCESS_AVAILABLE=$([ "$REMOTE_WEB_OK" = true ] && [ "$REMOTE_API_OK" = true ] && echo true || echo false)
    else
        REMOTE_ACCESS_AVAILABLE=false
    fi

    return $([ "$all_ok" = true ] && echo 0 || echo 1)
}

# Función para mostrar estado final
show_final_status() {
    echo ""
    echo "🎉 INSTALACIÓN COMPLETADA"
    echo "========================="
    echo ""

    if [ "$LOCAL_WEB_OK" = true ] && [ "$LOCAL_API_OK" = true ]; then
        echo "✅ MSN-AI FUNCIONANDO CORRECTAMENTE"
        echo ""

        echo "🔗 ACCESO DISPONIBLE:"
        echo "   🏠 Local:  http://localhost:8000/msn-ai.html"

        if [ "$REMOTE_ACCESS_AVAILABLE" = true ]; then
            echo "   🌐 Remoto: http://$SERVER_IP:8000/msn-ai.html"
            echo ""
            echo "🌟 CARACTERÍSTICAS ACTIVAS:"
            echo "   ✅ Acceso local y remoto transparente"
            echo "   ✅ Auto-detección de configuración en la interfaz"
            echo "   ✅ Carga automática de modelos de IA"
            echo "   ✅ Sin configuración adicional requerida"
            echo ""
            echo "💡 Los usuarios pueden acceder desde cualquier dispositivo en la red usando:"
            echo "   http://$SERVER_IP:8000/msn-ai.html"
        else
            echo ""
            if [ "$UFW_CONFIGURED" = false ]; then
                echo "⚠️ ACCESO REMOTO LIMITADO"
                echo "   • Funciona perfectamente en modo local"
                echo "   • Para acceso remoto completo, ejecuta:"
                echo "     sudo ufw allow 8000 && sudo ufw allow 11434"
            else
                echo "⚠️ VERIFICAR ACCESO REMOTO"
                echo "   • Firewall configurado correctamente"
                echo "   • Puede haber otros firewalls (router, etc.)"
                echo "   • Probar acceso desde otro dispositivo"
            fi
        fi

    else
        echo "⚠️ INSTALACIÓN CON PROBLEMAS"
        echo ""
        echo "🛠️ DIAGNÓSTICO:"
        if [ "$LOCAL_WEB_OK" = false ]; then
            echo "   ❌ MSN-AI web no accesible localmente"
            echo "      Verificar: docker logs msn-ai-app"
        fi

        if [ "$LOCAL_API_OK" = false ]; then
            echo "   ❌ Ollama no accesible localmente"
            echo "      Verificar: docker logs msn-ai-ollama"
        fi
    fi

    echo ""
    echo "🚀 CARACTERÍSTICAS DE MSN-AI v2.0.0:"
    echo "   • 🤖 IA conversacional con Ollama"
    echo "   • 🌐 Acceso remoto transparente y automático"
    echo "   • 📱 Interfaz web responsive"
    echo "   • 💾 Persistencia de chats y configuración"
    echo "   • 🔧 Auto-configuración inteligente"
    echo "   • 🛠️ Diagnósticos integrados"

    echo ""
    echo "📋 COMANDOS ÚTILES:"
    echo "   🔍 Estado:    $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml ps"
    echo "   📋 Logs:      $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml logs -f"
    echo "   🔄 Reiniciar: $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml restart"
    echo "   ⏹️  Detener:   $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml down"

    echo ""
    echo "🧪 DIAGNÓSTICO Y PRUEBAS:"
    echo "   ./docker-test-ai.sh          # Test completo de IA"
    echo "   ./test-remote-connection.sh  # Test de conectividad remota"
    echo "   docker logs msn-ai-app       # Logs de la aplicación"
    echo "   docker logs msn-ai-ollama    # Logs de Ollama"

    echo ""
    echo "📞 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
    echo "🚀 MSN-AI Transparent Remote Installation v2.0.0"
}

# Función principal
main() {
    # Paso 1: Configurar acceso remoto
    configure_firewall_auto

    # Paso 2: Instalar MSN-AI
    echo ""
    if ! install_msnai; then
        echo "❌ Error en la instalación de MSN-AI"
        exit 1
    fi

    # Paso 3: Esperar servicios
    if ! wait_for_services; then
        echo "❌ Los servicios no están respondiendo correctamente"
        echo "💡 Verificar logs y reintentar"
    fi

    # Paso 4: Verificar conectividad
    verify_connectivity

    # Paso 5: Mostrar estado final
    show_final_status
}

# Manejo de señales para limpieza
cleanup() {
    echo ""
    echo "🧹 Limpiando y deteniendo servicios..."
    $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml down >/dev/null 2>&1 || true
    echo "✅ Limpieza completada"
    exit 1
}

trap cleanup INT TERM

# Verificar argumentos
case "${1:-}" in
    --help|-h)
        echo "📋 USO: $0 [opciones]"
        echo ""
        echo "Este script instala MSN-AI con Docker y configura"
        echo "automáticamente el acceso remoto transparente."
        echo ""
        echo "Opciones:"
        echo "  --help, -h    Mostrar esta ayuda"
        echo ""
        echo "Características:"
        echo "  🌐 Auto-configuración de firewall"
        echo "  🔧 Detección automática de IP del servidor"
        echo "  🤖 Configuración transparente de Ollama"
        echo "  📱 Interfaz que se adapta automáticamente"
        echo ""
        echo "URLs resultantes:"
        echo "  Local:  http://localhost:8000/msn-ai.html"
        echo "  Remoto: http://[IP-SERVIDOR]:8000/msn-ai.html"
        exit 0
        ;;
    --version|-v)
        echo "MSN-AI Transparent Remote Installation v2.0.0"
        echo "Por: Alan Mac-Arthur García Díaz"
        echo "Licencia: GPL-3.0"
        exit 0
        ;;
esac

# Ejecutar instalación principal
echo "🎯 Iniciando instalación transparente de MSN-AI..."
echo "🌐 Configuración automática para: $SERVER_IP"
echo ""

main

echo ""
echo "🎉 ¡Instalación completada! MSN-AI está listo para usar."
