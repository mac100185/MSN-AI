#!/bin/bash

# MSN-AI - Asistente de Configuración para Acceso Remoto
# =====================================================
# 🎯 Por: Alan Mac-Arthur García Díaz
# ⚖️ Licencia: GPL-3.0
# 📧 alan.mac.arthur.garcia.diaz@gmail.com
# =====================================================

echo "🚀 MSN-AI - Asistente de Configuración Remota"
echo "=============================================="
echo "🎯 Por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "=============================================="
echo ""

# Función para mostrar ayuda
show_help() {
    echo "📋 USO: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --auto      Configuración automática (sin interacción)"
    echo "  --test      Solo ejecutar tests de conectividad"
    echo "  --firewall  Solo configurar firewall"
    echo "  --help      Mostrar esta ayuda"
    echo ""
    echo "Sin opciones: Configuración interactiva completa"
}

# Procesar argumentos
AUTO_MODE=false
TEST_ONLY=false
FIREWALL_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --auto)
            AUTO_MODE=true
            shift
            ;;
        --test)
            TEST_ONLY=true
            shift
            ;;
        --firewall)
            FIREWALL_ONLY=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Detectar IP del servidor
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null)
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[^ ]+' || echo "192.168.1.100")
fi

echo "🖥️ Servidor detectado: $(hostname) ($SERVER_IP)"
echo ""

# Función de test de conectividad
run_connectivity_test() {
    echo "🔍 Ejecutando test de conectividad completo..."
    echo "============================================="

    # Test puertos locales
    echo "📡 Verificando puertos locales:"

    echo -n "   Puerto 8000 (MSN-AI): "
    if netstat -tuln 2>/dev/null | grep -q ":8000 " || ss -tuln 2>/dev/null | grep -q ":8000 "; then
        echo "✅ ACTIVO"
        PORT_8000_LOCAL="✅"
    else
        echo "❌ INACTIVO"
        PORT_8000_LOCAL="❌"
    fi

    echo -n "   Puerto 11434 (Ollama): "
    if netstat -tuln 2>/dev/null | grep -q ":11434 " || ss -tuln 2>/dev/null | grep -q ":11434 "; then
        echo "✅ ACTIVO"
        PORT_11434_LOCAL="✅"
    else
        echo "❌ INACTIVO"
        PORT_11434_LOCAL="❌"
    fi

    echo ""
    echo "🌐 Verificando acceso HTTP:"

    # Test HTTP local
    echo -n "   MSN-AI Web (localhost:8000): "
    if curl -s --connect-timeout 3 "http://localhost:8000/msn-ai.html" >/dev/null 2>&1; then
        echo "✅ ACCESIBLE"
        WEB_LOCAL="✅"
    else
        echo "❌ NO ACCESIBLE"
        WEB_LOCAL="❌"
    fi

    echo -n "   Ollama API (localhost:11434): "
    if curl -s --connect-timeout 3 "http://localhost:11434/api/tags" >/dev/null 2>&1; then
        echo "✅ ACCESIBLE"
        OLLAMA_LOCAL="✅"
        # Contar modelos
        MODELS=$(curl -s "http://localhost:11434/api/tags" 2>/dev/null | grep -o '"name"' | wc -l 2>/dev/null || echo "0")
        echo "      📦 Modelos instalados: $MODELS"
    else
        echo "❌ NO ACCESIBLE"
        OLLAMA_LOCAL="❌"
    fi

    # Test acceso remoto
    echo ""
    echo -n "   MSN-AI Web (${SERVER_IP}:8000): "
    if curl -s --connect-timeout 3 "http://${SERVER_IP}:8000/msn-ai.html" >/dev/null 2>&1; then
        echo "✅ ACCESIBLE"
        WEB_REMOTE="✅"
    else
        echo "❌ NO ACCESIBLE"
        WEB_REMOTE="❌"
    fi

    echo -n "   Ollama API (${SERVER_IP}:11434): "
    if curl -s --connect-timeout 3 "http://${SERVER_IP}:11434/api/tags" >/dev/null 2>&1; then
        echo "✅ ACCESIBLE"
        OLLAMA_REMOTE="✅"
    else
        echo "❌ NO ACCESIBLE"
        OLLAMA_REMOTE="❌"
    fi

    echo ""
    echo "🔥 Estado del firewall:"
    if command -v ufw >/dev/null 2>&1; then
        UFW_STATUS=$(ufw status 2>/dev/null | head -1)
        if echo "$UFW_STATUS" | grep -q "inactive"; then
            echo "   UFW: ⚪ DESACTIVADO"
            FIREWALL_STATUS="DISABLED"
        else
            echo "   UFW: 🔥 ACTIVO"
            FIREWALL_STATUS="ACTIVE"
            # Verificar reglas específicas
            if ufw status 2>/dev/null | grep -q "8000"; then
                echo "   Puerto 8000: ✅ PERMITIDO"
            else
                echo "   Puerto 8000: ❌ BLOQUEADO"
            fi
            if ufw status 2>/dev/null | grep -q "11434"; then
                echo "   Puerto 11434: ✅ PERMITIDO"
            else
                echo "   Puerto 11434: ❌ BLOQUEADO"
            fi
        fi
    else
        echo "   UFW: ❓ NO INSTALADO"
        FIREWALL_STATUS="NOT_INSTALLED"
    fi

    echo ""
    echo "📦 Estado de contenedores Docker:"
    if command -v docker >/dev/null 2>&1; then
        if docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | grep -q "msn-ai"; then
            docker ps --filter "name=msn-ai" --format "   {{.Names}}: {{.Status}}" 2>/dev/null
            DOCKER_STATUS="✅"
        else
            echo "   ❌ No se encontraron contenedores MSN-AI ejecutándose"
            DOCKER_STATUS="❌"
        fi
    else
        echo "   ❓ Docker no disponible en este contexto"
        DOCKER_STATUS="❓"
    fi
}

# Función de configuración de firewall
configure_firewall() {
    echo "🔥 Configurando firewall para acceso remoto..."
    echo "============================================="

    if [ "$EUID" -ne 0 ]; then
        echo "❌ Se requieren permisos de administrador para configurar firewall"
        echo "💡 Ejecuta: sudo $0 --firewall"
        return 1
    fi

    # Verificar UFW
    if ! command -v ufw >/dev/null 2>&1; then
        echo "❌ UFW no está instalado"
        echo "💡 Instalar con: sudo apt update && sudo apt install ufw"
        return 1
    fi

    echo "🚀 Aplicando reglas de firewall..."

    # Permitir puertos
    echo -n "   Abriendo puerto 8000 (MSN-AI): "
    if ufw allow 8000 >/dev/null 2>&1; then
        echo "✅"
    else
        echo "❌"
        return 1
    fi

    echo -n "   Abriendo puerto 11434 (Ollama): "
    if ufw allow 11434 >/dev/null 2>&1; then
        echo "✅"
    else
        echo "❌"
        return 1
    fi

    # Verificar si UFW está activo
    if ufw status | grep -q "inactive"; then
        if [ "$AUTO_MODE" = true ]; then
            echo "🚀 Activando UFW automáticamente..."
            ufw --force enable >/dev/null 2>&1
        else
            echo ""
            echo "⚠️ UFW está desactivado. ¿Activar ahora? (y/N): "
            read -r ACTIVATE
            if [ "$ACTIVATE" = "y" ] || [ "$ACTIVATE" = "Y" ]; then
                ufw --force enable >/dev/null 2>&1
                echo "✅ UFW activado"
            fi
        fi
    fi

    echo "✅ Configuración de firewall completada"
    return 0
}

# Función principal de diagnóstico y recomendaciones
show_diagnosis() {
    echo "📊 DIAGNÓSTICO Y RECOMENDACIONES"
    echo "==============================="

    ISSUES_FOUND=false

    # Verificar servicios locales
    if [ "$PORT_8000_LOCAL" != "✅" ] || [ "$PORT_11434_LOCAL" != "✅" ]; then
        ISSUES_FOUND=true
        echo "❌ PROBLEMA: Servicios no están ejecutándose localmente"
        echo "   🛠️ Solución:"
        echo "      docker-compose -f docker/docker-compose.yml up -d"
        echo "      # O usar el script de inicio:"
        echo "      ./start-msnai-docker.sh --auto"
        echo ""
    fi

    # Verificar acceso remoto
    if [ "$WEB_REMOTE" != "✅" ] || [ "$OLLAMA_REMOTE" != "✅" ]; then
        if [ "$WEB_LOCAL" = "✅" ] && [ "$OLLAMA_LOCAL" = "✅" ]; then
            ISSUES_FOUND=true
            echo "❌ PROBLEMA: Servicios funcionan localmente pero no remotamente"
            echo "   🔥 Causa probable: Firewall bloqueando conexiones externas"
            echo "   🛠️ Solución:"
            if [ "$EUID" -eq 0 ]; then
                echo "      Ejecutando configuración de firewall ahora..."
                configure_firewall
            else
                echo "      sudo $0 --firewall"
                echo "      # O configurar manualmente:"
                echo "      sudo ufw allow 8000"
                echo "      sudo ufw allow 11434"
            fi
            echo ""
        fi
    fi

    # Verificar Docker
    if [ "$DOCKER_STATUS" = "❌" ]; then
        ISSUES_FOUND=true
        echo "❌ PROBLEMA: Contenedores MSN-AI no están ejecutándose"
        echo "   🛠️ Solución:"
        echo "      cd /ruta/a/MSN-AI"
        echo "      ./start-msnai-docker.sh --auto"
        echo ""
    fi

    # Todo OK
    if [ "$ISSUES_FOUND" = false ]; then
        echo "✅ TODO FUNCIONANDO CORRECTAMENTE"
        echo ""
        echo "🌐 Acceder a MSN-AI desde la red local:"
        echo "   http://${SERVER_IP}:8000/msn-ai.html"
        echo ""
        echo "🏠 Acceder desde el servidor:"
        echo "   http://localhost:8000/msn-ai.html"
        echo ""
        echo "💡 La interfaz detectará automáticamente la IP correcta"
        echo "   y configurará Ollama en: http://${SERVER_IP}:11434"
    fi
}

# Función principal
main() {
    # Solo test
    if [ "$TEST_ONLY" = true ]; then
        run_connectivity_test
        echo ""
        show_diagnosis
        exit 0
    fi

    # Solo firewall
    if [ "$FIREWALL_ONLY" = true ]; then
        configure_firewall
        exit $?
    fi

    # Configuración completa
    echo "🔍 Paso 1: Diagnóstico inicial"
    echo "=============================="
    run_connectivity_test

    echo ""
    echo "📊 Paso 2: Análisis de problemas"
    echo "================================="
    show_diagnosis

    if [ "$AUTO_MODE" = false ]; then
        echo ""
        echo "🛠️ ¿Deseas que configure automáticamente el acceso remoto? (y/N): "
        read -r CONFIGURE
        if [ "$CONFIGURE" != "y" ] && [ "$CONFIGURE" != "Y" ]; then
            echo "ℹ️ Configuración cancelada por el usuario"
            echo "💡 Puedes ejecutar manualmente:"
            echo "   sudo $0 --firewall    # Solo firewall"
            echo "   $0 --test            # Solo tests"
            exit 0
        fi
    fi

    echo ""
    echo "🔧 Paso 3: Aplicando configuración"
    echo "=================================="

    # Configurar firewall si es necesario
    if [ "$FIREWALL_STATUS" = "ACTIVE" ] && ([ "$WEB_REMOTE" != "✅" ] || [ "$OLLAMA_REMOTE" != "✅" ]); then
        if [ "$EUID" -eq 0 ]; then
            configure_firewall
        else
            echo "⚠️ Se requieren permisos sudo para configurar firewall"
            echo "🔄 Reejecutar con: sudo $0"
        fi
    fi

    echo ""
    echo "✅ Paso 4: Verificación final"
    echo "============================="
    sleep 3
    run_connectivity_test

    echo ""
    echo "🎉 CONFIGURACIÓN COMPLETADA"
    echo "============================"

    if [ "$WEB_REMOTE" = "✅" ] && [ "$OLLAMA_REMOTE" = "✅" ]; then
        echo "✅ MSN-AI está accesible remotamente"
        echo ""
        echo "🔗 URLS DE ACCESO:"
        echo "   🌐 Red local: http://${SERVER_IP}:8000/msn-ai.html"
        echo "   🏠 Local: http://localhost:8000/msn-ai.html"
        echo ""
        echo "🤖 La interfaz web configurará automáticamente:"
        echo "   Servidor Ollama: http://${SERVER_IP}:11434"
        echo ""
        echo "💡 CONSEJOS DE USO:"
        echo "   • La detección de IP es automática"
        echo "   • Los modelos se cargarán automáticamente"
        echo "   • Si hay problemas, usa el botón 'Test Connection'"
    else
        echo "⚠️ Aún hay problemas de conectividad"
        echo "📞 Para soporte detallado, contacta:"
        echo "   alan.mac.arthur.garcia.diaz@gmail.com"
    fi
}

# Verificar si se pide ayuda
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# Ejecutar función principal
main

echo ""
echo "📞 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
echo "🚀 MSN-AI Remote Access Setup v1.0.0"
