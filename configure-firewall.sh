#!/bin/bash

# MSN-AI - Configuración de Firewall
# ==================================
# 🎯 Por: Alan Mac-Arthur García Díaz
# ⚖️ Licencia: GPL-3.0
# 📧 alan.mac.arthur.garcia.diaz@gmail.com
# ==================================

echo "🔥 MSN-AI - Configuración de Firewall"
echo "====================================="
echo "🎯 Por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "====================================="
echo ""

# Verificar si se ejecuta como root/sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script requiere permisos de administrador"
    echo "💡 Ejecuta: sudo $0"
    exit 1
fi

echo "🔍 Verificando estado actual del firewall..."

# Verificar si UFW está instalado
if ! command -v ufw >/dev/null 2>&1; then
    echo "❌ UFW no está instalado"
    echo "💡 Instalar con: sudo apt update && sudo apt install ufw"
    exit 1
fi

# Mostrar estado actual
echo ""
echo "📊 Estado actual del firewall:"
echo "=============================="
ufw status numbered

echo ""
echo "🔧 Configurando reglas para MSN-AI..."

# Permitir puerto 8000 (MSN-AI Web)
echo -n "🌐 Abriendo puerto 8000 (MSN-AI Web): "
if ufw allow 8000 >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ ERROR"
    ERRORS=1
fi

# Permitir puerto 11434 (Ollama API)
echo -n "🤖 Abriendo puerto 11434 (Ollama API): "
if ufw allow 11434 >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ ERROR"
    ERRORS=1
fi

# Verificar si UFW está activo
UFW_STATUS=$(ufw status | head -1)
if echo "$UFW_STATUS" | grep -q "inactive"; then
    echo ""
    echo "⚠️ El firewall UFW está desactivado"
    echo "🔥 ¿Deseas activarlo? (y/N): "
    read -r ACTIVATE
    if [ "$ACTIVATE" = "y" ] || [ "$ACTIVATE" = "Y" ]; then
        echo -n "🚀 Activando UFW: "
        if ufw --force enable >/dev/null 2>&1; then
            echo "✅ OK"
        else
            echo "❌ ERROR"
            ERRORS=1
        fi
    else
        echo "⏸️ UFW permanece desactivado (las reglas se aplicarán cuando se active)"
    fi
fi

echo ""
echo "📊 Nuevo estado del firewall:"
echo "============================="
ufw status numbered

echo ""
echo "🧪 Verificando conectividad..."

# Test conectividad local
sleep 2

# Obtener IP del servidor
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "🖥️ IP del servidor: $SERVER_IP"

echo ""
echo "🔍 Test de conectividad:"

# Test puerto 8000
echo -n "🌐 Puerto 8000 desde red local: "
if timeout 5 nc -z "$SERVER_IP" 8000 2>/dev/null; then
    echo "✅ ACCESIBLE"
else
    echo "⏳ Verificando... (puede tomar unos segundos)"
    sleep 3
    if timeout 5 nc -z "$SERVER_IP" 8000 2>/dev/null; then
        echo "   ✅ ACCESIBLE"
    else
        echo "   ❌ NO ACCESIBLE (verifica que MSN-AI esté ejecutándose)"
    fi
fi

# Test puerto 11434
echo -n "🤖 Puerto 11434 desde red local: "
if timeout 5 nc -z "$SERVER_IP" 11434 2>/dev/null; then
    echo "✅ ACCESIBLE"
else
    echo "⏳ Verificando... (puede tomar unos segundos)"
    sleep 3
    if timeout 5 nc -z "$SERVER_IP" 11434 2>/dev/null; then
        echo "   ✅ ACCESIBLE"
    else
        echo "   ❌ NO ACCESIBLE (verifica que Ollama esté ejecutándose)"
    fi
fi

echo ""
if [ -z "$ERRORS" ]; then
    echo "✅ CONFIGURACIÓN COMPLETADA"
    echo "=========================="
    echo "🌐 MSN-AI ahora debería ser accesible desde:"
    echo "   http://$SERVER_IP:8000/msn-ai.html"
    echo ""
    echo "🤖 Ollama API accesible en:"
    echo "   http://$SERVER_IP:11434/api/tags"
    echo ""
    echo "💡 Consejos:"
    echo "   • Reinicia los contenedores MSN-AI si siguen sin funcionar"
    echo "   • Verifica que no haya otros firewalls (iptables, router, etc.)"
    echo "   • Usa el comando './test-remote-connection.sh' para diagnósticos"
else
    echo "❌ HUBO ERRORES EN LA CONFIGURACIÓN"
    echo "================================="
    echo "🛠️ Soluciones manuales:"
    echo "   sudo ufw allow 8000"
    echo "   sudo ufw allow 11434"
    echo "   sudo ufw enable"
fi

echo ""
echo "🔍 Comandos útiles:"
echo "=================="
echo "📊 Ver estado:        sudo ufw status numbered"
echo "🔥 Desactivar UFW:    sudo ufw disable"
echo "🚫 Eliminar regla:    sudo ufw delete <número>"
echo "🔄 Recargar reglas:   sudo ufw reload"

echo ""
echo "📞 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
echo "🔧 MSN-AI Firewall Setup v1.0.0"
