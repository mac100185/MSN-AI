#!/bin/bash

# MSN-AI - Habilitar Acceso Remoto en Instalación Existente
# ========================================================
# 🎯 Por: Alan Mac-Arthur García Díaz
# ⚖️ Licencia: GPL-3.0
# 📧 alan.mac.arthur.garcia.diaz@gmail.com
# ========================================================

echo "🔧 MSN-AI - Habilitar Acceso Remoto"
echo "==================================="
echo "🎯 Por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "==================================="
echo ""

# Detectar información del sistema
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[^ ]+' || echo "localhost")
SERVER_NAME=$(hostname 2>/dev/null || echo "unknown")

if [ "$SERVER_IP" = "localhost" ] || [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[^ ]+' || echo "127.0.0.1")
fi

echo "🖥️ Servidor: $SERVER_NAME ($SERVER_IP)"
echo ""

# Verificar si MSN-AI está instalado
if [ ! -f "msn-ai.html" ]; then
    echo "❌ MSN-AI no encontrado en este directorio"
    echo "💡 Asegúrate de ejecutar este script desde el directorio MSN-AI"
    exit 1
fi

# Verificar si Docker está ejecutándose
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker no está disponible"
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
    exit 1
fi

# Función para verificar estado actual
check_current_status() {
    echo "🔍 Verificando estado actual de MSN-AI..."
    echo "========================================"

    # Verificar contenedores
    if $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml ps | grep -q "msn-ai"; then
        echo "✅ Contenedores MSN-AI encontrados"
        CONTAINERS_EXIST=true

        # Verificar si están ejecutándose
        if $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml ps | grep -q "Up"; then
            echo "✅ Contenedores ejecutándose"
            CONTAINERS_RUNNING=true
        else
            echo "⚠️ Contenedores detenidos"
            CONTAINERS_RUNNING=false
        fi
    else
        echo "❌ No se encontraron contenedores MSN-AI"
        CONTAINERS_EXIST=false
        CONTAINERS_RUNNING=false
    fi

    echo ""
    echo "🧪 Probando conectividad actual..."

    # Test local
    echo -n "   Local (localhost:8000): "
    if curl -s --connect-timeout 3 "http://localhost:8000/msn-ai.html" >/dev/null 2>&1; then
        echo "✅ Accesible"
        LOCAL_ACCESS=true
    else
        echo "❌ No accesible"
        LOCAL_ACCESS=false
    fi

    echo -n "   Local Ollama (localhost:11434): "
    if curl -s --connect-timeout 3 "http://localhost:11434/api/tags" >/dev/null 2>&1; then
        echo "✅ Accesible"
        LOCAL_OLLAMA=true
    else
        echo "❌ No accesible"
        LOCAL_OLLAMA=false
    fi

    # Test remoto
    if [ "$SERVER_IP" != "localhost" ] && [ "$SERVER_IP" != "127.0.0.1" ]; then
        echo -n "   Remoto (${SERVER_IP}:8000): "
        if curl -s --connect-timeout 3 "http://${SERVER_IP}:8000/msn-ai.html" >/dev/null 2>&1; then
            echo "✅ Accesible"
            REMOTE_ACCESS=true
        else
            echo "❌ No accesible"
            REMOTE_ACCESS=false
        fi

        echo -n "   Remoto Ollama (${SERVER_IP}:11434): "
        if curl -s --connect-timeout 3 "http://${SERVER_IP}:11434/api/tags" >/dev/null 2>&1; then
            echo "✅ Accesible"
            REMOTE_OLLAMA=true
        else
            echo "❌ No accesible"
            REMOTE_OLLAMA=false
        fi
    else
        REMOTE_ACCESS=false
        REMOTE_OLLAMA=false
    fi
}

# Función para configurar firewall
configure_firewall() {
    echo ""
    echo "🔥 Configurando firewall para acceso remoto..."
    echo "============================================="

    if ! command -v ufw >/dev/null 2>&1; then
        echo "⚠️ UFW no está disponible"
        echo "💡 Verificar manualmente que los puertos 8000 y 11434 estén abiertos"
        return 1
    fi

    echo "🔍 Estado actual del firewall:"
    ufw status

    echo ""
    echo "🚀 Configurando reglas..."

    if [ "$EUID" -eq 0 ]; then
        # Ejecutándose como root
        echo "   Abriendo puerto 8000 (MSN-AI Web)..."
        ufw allow 8000 comment "MSN-AI Web Interface"
        echo "   Abriendo puerto 11434 (Ollama API)..."
        ufw allow 11434 comment "MSN-AI Ollama API"

        if ufw status | grep -q "inactive"; then
            echo "   Activando UFW..."
            ufw --force enable
        fi
        echo "✅ Firewall configurado como administrador"

    elif sudo -n true 2>/dev/null; then
        # Sudo sin contraseña
        echo "   Abriendo puerto 8000 (MSN-AI Web)..."
        sudo ufw allow 8000 comment "MSN-AI Web Interface"
        echo "   Abriendo puerto 11434 (Ollama API)..."
        sudo ufw allow 11434 comment "MSN-AI Ollama API"

        if sudo ufw status | grep -q "inactive"; then
            echo "   Activando UFW..."
            sudo ufw --force enable
        fi
        echo "✅ Firewall configurado con sudo"

    else
        # Requiere contraseña
        echo "🔐 Se requieren permisos de administrador"
        echo "💡 Ejecutando configuración interactiva..."

        echo "   Configurando puerto 8000..."
        if sudo ufw allow 8000 comment "MSN-AI Web Interface"; then
            echo "   ✅ Puerto 8000 configurado"
        else
            echo "   ❌ Error configurando puerto 8000"
            return 1
        fi

        echo "   Configurando puerto 11434..."
        if sudo ufw allow 11434 comment "MSN-AI Ollama API"; then
            echo "   ✅ Puerto 11434 configurado"
        else
            echo "   ❌ Error configurando puerto 11434"
            return 1
        fi

        if sudo ufw status | grep -q "inactive"; then
            echo "   ¿Activar UFW? (y/N): "
            read -r ACTIVATE_UFW
            if [ "$ACTIVATE_UFW" = "y" ] || [ "$ACTIVATE_UFW" = "Y" ]; then
                sudo ufw --force enable
                echo "   ✅ UFW activado"
            else
                echo "   ⚠️ UFW permanece inactivo"
            fi
        fi

        echo "✅ Firewall configurado interactivamente"
    fi

    echo ""
    echo "📊 Estado final del firewall:"
    if command -v ufw >/dev/null 2>&1; then
        ufw status | grep -E "(8000|11434|Status)" || true
    fi

    return 0
}

# Función para verificar y actualizar configuración de contenedores
update_container_config() {
    echo ""
    echo "🐳 Verificando configuración de contenedores..."
    echo "==============================================="

    # Verificar docker-compose.yml
    if [ -f "docker/docker-compose.yml" ]; then
        echo "✅ docker-compose.yml encontrado"

        # Verificar configuración de Ollama
        if grep -q "OLLAMA_HOST=0.0.0.0:11434" docker/docker-compose.yml; then
            echo "✅ Ollama configurado para acceso externo"
        else
            echo "⚠️ Puede ser necesario actualizar configuración de Ollama"
        fi

        # Verificar mapeo de puertos
        if grep -q "8000:8000" docker/docker-compose.yml && grep -q "11434:11434" docker/docker-compose.yml; then
            echo "✅ Puertos mapeados correctamente"
        else
            echo "⚠️ Verificar mapeo de puertos en docker-compose.yml"
        fi
    else
        echo "❌ docker-compose.yml no encontrado"
        return 1
    fi

    return 0
}

# Función para reiniciar contenedores si es necesario
restart_containers() {
    echo ""
    echo "🔄 Gestionando contenedores..."
    echo "============================="

    if [ "$CONTAINERS_RUNNING" = true ]; then
        echo "⚠️ Los contenedores están ejecutándose"
        echo "💡 Para aplicar cambios de configuración, es recomendable reiniciarlos"
        echo ""
        echo "¿Reiniciar contenedores ahora? (Y/n): "
        read -r RESTART_CONTAINERS

        if [ "$RESTART_CONTAINERS" != "n" ] && [ "$RESTART_CONTAINERS" != "N" ]; then
            echo "🔄 Reiniciando contenedores..."

            if $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml restart; then
                echo "✅ Contenedores reiniciados"

                echo "⏳ Esperando que los servicios estén listos..."
                sleep 10
            else
                echo "❌ Error reiniciando contenedores"
                return 1
            fi
        else
            echo "⏭️ Manteniendo contenedores en ejecución"
        fi
    elif [ "$CONTAINERS_EXIST" = true ]; then
        echo "🚀 Iniciando contenedores..."
        if $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml up -d; then
            echo "✅ Contenedores iniciados"
            echo "⏳ Esperando que los servicios estén listos..."
            sleep 10
        else
            echo "❌ Error iniciando contenedores"
            return 1
        fi
    else
        echo "⚠️ No hay contenedores MSN-AI"
        echo "💡 Ejecutar primero: ./start-msnai-docker.sh --auto"
        return 1
    fi

    return 0
}

# Función para verificar acceso remoto final
verify_remote_access() {
    echo ""
    echo "🧪 Verificación final de acceso remoto..."
    echo "========================================"

    local success=true

    echo "⏳ Esperando que los servicios estén completamente listos..."
    sleep 5

    # Test web remoto
    echo -n "🌐 MSN-AI Web (${SERVER_IP}:8000): "
    if curl -s --connect-timeout 5 "http://${SERVER_IP}:8000/msn-ai.html" >/dev/null 2>&1; then
        echo "✅ ACCESIBLE"
        FINAL_WEB=true
    else
        echo "❌ NO ACCESIBLE"
        FINAL_WEB=false
        success=false
    fi

    # Test API remoto
    echo -n "🤖 Ollama API (${SERVER_IP}:11434): "
    if curl -s --connect-timeout 5 "http://${SERVER_IP}:11434/api/tags" >/dev/null 2>&1; then
        OLLAMA_RESPONSE=$(curl -s "http://${SERVER_IP}:11434/api/tags" 2>/dev/null)
        MODEL_COUNT=$(echo "$OLLAMA_RESPONSE" | grep -o '"name"' | wc -l 2>/dev/null || echo "0")
        echo "✅ ACCESIBLE ($MODEL_COUNT modelos)"
        FINAL_API=true
    else
        echo "❌ NO ACCESIBLE"
        FINAL_API=false
        success=false
    fi

    # Test local como referencia
    echo -n "🏠 Acceso local (localhost:8000): "
    if curl -s --connect-timeout 3 "http://localhost:8000/msn-ai.html" >/dev/null 2>&1; then
        echo "✅ OK"
    else
        echo "❌ PROBLEMA"
        success=false
    fi

    return $([ "$success" = true ] && echo 0 || echo 1)
}

# Función para mostrar resultado final
show_final_result() {
    echo ""
    echo "🎉 RESULTADO DE LA CONFIGURACIÓN"
    echo "==============================="
    echo ""

    if [ "$FINAL_WEB" = true ] && [ "$FINAL_API" = true ]; then
        echo "✅ ACCESO REMOTO HABILITADO EXITOSAMENTE"
        echo ""
        echo "🔗 URLs DE ACCESO:"
        echo "   🏠 Local:  http://localhost:8000/msn-ai.html"
        echo "   🌐 Remoto: http://$SERVER_IP:8000/msn-ai.html"
        echo ""
        echo "🌟 CARACTERÍSTICAS ACTIVAS:"
        echo "   ✅ Acceso desde cualquier dispositivo en la red"
        echo "   ✅ Auto-detección de configuración en la interfaz"
        echo "   ✅ Modelos de IA accesibles remotamente"
        echo "   ✅ Firewall configurado correctamente"
        echo ""
        echo "💡 INSTRUCCIONES PARA USUARIOS:"
        echo "   1. Desde la red local, acceder a: http://$SERVER_IP:8000/msn-ai.html"
        echo "   2. La interfaz detectará automáticamente la configuración remota"
        echo "   3. Los modelos se cargarán automáticamente"
        echo "   4. ¡Listo para usar!"

    elif [ "$LOCAL_ACCESS" = true ]; then
        echo "⚠️ ACCESO REMOTO PARCIAL"
        echo ""
        echo "✅ Funcionando localmente: http://localhost:8000/msn-ai.html"
        echo "❌ Problemas de acceso remoto detectados"
        echo ""
        echo "🛠️ POSIBLES CAUSAS:"

        if [ "$FINAL_WEB" = false ]; then
            echo "   • Puerto 8000 puede estar bloqueado"
        fi

        if [ "$FINAL_API" = false ]; then
            echo "   • Puerto 11434 puede estar bloqueado"
        fi

        echo ""
        echo "💡 SOLUCIONES:"
        echo "   1. Verificar firewall del router/gateway"
        echo "   2. Verificar otros firewalls (iptables, firewalld)"
        echo "   3. Probar desde otro dispositivo en la misma red"
        echo "   4. Verificar logs: docker logs msn-ai-app"

    else
        echo "❌ PROBLEMAS DETECTADOS"
        echo ""
        echo "🛠️ DIAGNÓSTICO:"
        echo "   • Verificar que los contenedores estén ejecutándose"
        echo "   • Revisar logs: docker logs msn-ai-app"
        echo "   • Verificar configuración de red"
        echo ""
        echo "💡 INTENTAR:"
        echo "   ./docker-start.sh    # Reiniciar servicios"
        echo "   ./docker-status.sh   # Verificar estado"
    fi

    echo ""
    echo "📋 COMANDOS ÚTILES:"
    echo "   🔍 Estado:     $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml ps"
    echo "   📋 Logs:       $DOCKER_COMPOSE_CMD -f docker/docker-compose.yml logs -f"
    echo "   🧪 Test:       ./test-remote-connection.sh"
    echo "   🔧 Diagnós.:   ./docker-test-ai.sh"

    echo ""
    echo "📞 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
    echo "🔧 Enable Remote Access v1.0.0"
}

# Función principal
main() {
    # Paso 1: Verificar estado actual
    check_current_status

    echo ""
    if [ "$REMOTE_ACCESS" = true ] && [ "$REMOTE_OLLAMA" = true ]; then
        echo "✅ EL ACCESO REMOTO YA ESTÁ FUNCIONANDO"
        echo ""
        echo "🔗 URLs disponibles:"
        echo "   🏠 Local:  http://localhost:8000/msn-ai.html"
        echo "   🌐 Remoto: http://$SERVER_IP:8000/msn-ai.html"
        echo ""
        echo "💡 No se requiere configuración adicional"
        exit 0
    fi

    echo "🎯 HABILITANDO ACCESO REMOTO..."
    echo "=============================="

    if [ "$LOCAL_ACCESS" = false ]; then
        echo "❌ MSN-AI no está funcionando localmente"
        echo "💡 Primero ejecuta: ./start-msnai-docker.sh --auto"
        exit 1
    fi

    # Paso 2: Configurar firewall
    if ! configure_firewall; then
        echo "⚠️ Problemas configurando firewall"
        echo "💡 Continúa, pero el acceso remoto puede no funcionar"
    fi

    # Paso 3: Verificar configuración de contenedores
    update_container_config

    # Paso 4: Reiniciar contenedores si es necesario
    if ! restart_containers; then
        echo "❌ Problemas con los contenedores"
        exit 1
    fi

    # Paso 5: Verificación final
    if verify_remote_access; then
        echo "🎉 ¡Acceso remoto configurado exitosamente!"
    else
        echo "⚠️ Configuración completada con advertencias"
    fi

    # Paso 6: Mostrar resultado
    show_final_result
}

# Manejo de argumentos
case "${1:-}" in
    --help|-h)
        echo "📋 USO: $0 [opciones]"
        echo ""
        echo "Este script habilita el acceso remoto en una instalación"
        echo "existente de MSN-AI con Docker."
        echo ""
        echo "Opciones:"
        echo "  --help, -h    Mostrar esta ayuda"
        echo ""
        echo "¿Qué hace este script?"
        echo "  🔥 Configura automáticamente el firewall"
        echo "  🐳 Verifica la configuración de contenedores"
        echo "  🔄 Reinicia servicios si es necesario"
        echo "  🧪 Verifica que el acceso remoto funcione"
        echo ""
        echo "Requisitos:"
        echo "  • MSN-AI ya instalado con Docker"
        echo "  • Permisos sudo (para configurar firewall)"
        echo "  • Contenedores funcionando localmente"
        echo ""
        echo "Resultado:"
        echo "  Local:  http://localhost:8000/msn-ai.html"
        echo "  Remoto: http://[IP-SERVIDOR]:8000/msn-ai.html"
        exit 0
        ;;
    --version|-v)
        echo "MSN-AI Enable Remote Access v1.0.0"
        echo "Por: Alan Mac-Arthur García Díaz"
        echo "Licencia: GPL-3.0"
        exit 0
        ;;
esac

# Ejecutar función principal
echo "🚀 Iniciando configuración de acceso remoto..."
echo "🌐 Servidor objetivo: $SERVER_IP"
echo ""

main

echo ""
echo "🎉 ¡Configuración de acceso remoto completada!"
