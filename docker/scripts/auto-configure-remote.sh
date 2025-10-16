#!/bin/bash

# MSN-AI - Auto-configuración para Acceso Remoto Transparente
# ==========================================================
# 🎯 Por: Alan Mac-Arthur García Díaz
# ⚖️ Licencia: GPL-3.0
# 📧 alan.mac.arthur.garcia.diaz@gmail.com
# ==========================================================

echo "🌐 MSN-AI Auto-Remote Configuration"
echo "===================================="
echo "🎯 Configurando acceso remoto transparente..."
echo ""

# Detectar información del sistema
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "")
SERVER_NAME=$(hostname 2>/dev/null || echo "unknown")
CURRENT_USER=$(whoami)

if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[^ ]+' || echo "localhost")
fi

echo "🖥️ Sistema detectado:"
echo "   Servidor: $SERVER_NAME"
echo "   IP: $SERVER_IP"
echo "   Usuario: $CURRENT_USER"
echo ""

# Función para configurar UFW automáticamente
configure_ufw() {
    if ! command -v ufw >/dev/null 2>&1; then
        echo "⚠️ UFW no está instalado, saltando configuración firewall"
        return 1
    fi

    echo "🔥 Configurando UFW para acceso remoto..."

    # Intentar configuración silenciosa
    if [ "$EUID" -eq 0 ]; then
        # Ejecutándose como root
        ufw allow 8000 >/dev/null 2>&1
        ufw allow 11434 >/dev/null 2>&1

        # Activar UFW si está inactivo
        if ufw status 2>/dev/null | grep -q "inactive"; then
            ufw --force enable >/dev/null 2>&1
        fi

        echo "✅ UFW configurado como root"
        return 0
    elif sudo -n true 2>/dev/null; then
        # Sudo disponible sin contraseña
        sudo ufw allow 8000 >/dev/null 2>&1
        sudo ufw allow 11434 >/dev/null 2>&1

        if sudo ufw status 2>/dev/null | grep -q "inactive"; then
            sudo ufw --force enable >/dev/null 2>&1
        fi

        echo "✅ UFW configurado con sudo"
        return 0
    else
        echo "⚠️ Sin permisos sudo automáticos para UFW"
        return 1
    fi
}

# Función para verificar conectividad
test_connectivity() {
    echo "🧪 Verificando conectividad..."

    # Test localhost
    echo -n "   Localhost (8000): "
    if curl -s --connect-timeout 3 "http://localhost:8000/msn-ai.html" >/dev/null 2>&1; then
        echo "✅"
        LOCAL_8000=true
    else
        echo "❌"
        LOCAL_8000=false
    fi

    echo -n "   Localhost (11434): "
    if curl -s --connect-timeout 3 "http://localhost:11434/api/tags" >/dev/null 2>&1; then
        echo "✅"
        LOCAL_11434=true
    else
        echo "❌"
        LOCAL_11434=false
    fi

    # Test remoto si la IP no es localhost
    if [ "$SERVER_IP" != "localhost" ] && [ "$SERVER_IP" != "127.0.0.1" ]; then
        echo -n "   Remoto ${SERVER_IP} (8000): "
        if curl -s --connect-timeout 3 "http://${SERVER_IP}:8000/msn-ai.html" >/dev/null 2>&1; then
            echo "✅"
            REMOTE_8000=true
        else
            echo "❌"
            REMOTE_8000=false
        fi

        echo -n "   Remoto ${SERVER_IP} (11434): "
        if curl -s --connect-timeout 3 "http://${SERVER_IP}:11434/api/tags" >/dev/null 2>&1; then
            echo "✅"
            REMOTE_11434=true
        else
            echo "❌"
            REMOTE_11434=false
        fi
    else
        REMOTE_8000=false
        REMOTE_11434=false
    fi
}

# Función para crear archivo de configuración
create_config_file() {
    CONFIG_DIR="/app/data"
    CONFIG_FILE="${CONFIG_DIR}/remote-config.json"

    # Crear directorio si no existe
    mkdir -p "$CONFIG_DIR" 2>/dev/null

    # Crear configuración JSON
    cat > "$CONFIG_FILE" << EOF
{
  "version": "1.0.0",
  "timestamp": "$(date -Iseconds)",
  "server": {
    "hostname": "$SERVER_NAME",
    "ip": "$SERVER_IP",
    "user": "$CURRENT_USER"
  },
  "connectivity": {
    "local": {
      "web": $LOCAL_8000,
      "api": $LOCAL_11434
    },
    "remote": {
      "web": $REMOTE_8000,
      "api": $REMOTE_11434,
      "enabled": $([ "$REMOTE_8000" = true ] && [ "$REMOTE_11434" = true ] && echo true || echo false)
    }
  },
  "urls": {
    "local_web": "http://localhost:8000/msn-ai.html",
    "local_api": "http://localhost:11434",
    "remote_web": "http://$SERVER_IP:8000/msn-ai.html",
    "remote_api": "http://$SERVER_IP:11434"
  },
  "firewall": {
    "ufw_available": $(command -v ufw >/dev/null 2>&1 && echo true || echo false),
    "configured": $([ "$UFW_CONFIGURED" = true ] && echo true || echo false)
  }
}
EOF

    echo "📄 Configuración guardada en: $CONFIG_FILE"
}

# Función para mostrar URLs de acceso
show_access_urls() {
    echo ""
    echo "🔗 URLS DE ACCESO CONFIGURADAS"
    echo "=============================="

    if [ "$LOCAL_8000" = true ]; then
        echo "🏠 Acceso Local:"
        echo "   http://localhost:8000/msn-ai.html"
    fi

    if [ "$REMOTE_8000" = true ] && [ "$REMOTE_11434" = true ]; then
        echo "🌐 Acceso Remoto:"
        echo "   http://$SERVER_IP:8000/msn-ai.html"
        echo ""
        echo "✅ CONFIGURACIÓN COMPLETA"
        echo "   • Acceso transparente desde cualquier dispositivo"
        echo "   • Auto-detección de configuración en la interfaz"
        echo "   • No requiere configuración manual del usuario"
    else
        echo "⚠️ Acceso Remoto Limitado:"
        echo "   http://$SERVER_IP:8000/msn-ai.html (puede requerir configuración)"
        echo ""
        echo "💡 Para habilitar acceso remoto completo:"
        echo "   sudo ufw allow 8000"
        echo "   sudo ufw allow 11434"
    fi
}

# Función para generar instrucciones de troubleshooting
generate_troubleshooting() {
    TROUBLESHOOTING_FILE="/app/data/troubleshooting.md"

    cat > "$TROUBLESHOOTING_FILE" << EOF
# MSN-AI Troubleshooting Guide

## Información del Sistema
- **Servidor**: $SERVER_NAME ($SERVER_IP)
- **Usuario**: $CURRENT_USER
- **Fecha**: $(date)

## Estado de Conectividad
- Local Web (8000): $([ "$LOCAL_8000" = true ] && echo "✅ OK" || echo "❌ FALLO")
- Local API (11434): $([ "$LOCAL_11434" = true ] && echo "✅ OK" || echo "❌ FALLO")
- Remoto Web (8000): $([ "$REMOTE_8000" = true ] && echo "✅ OK" || echo "❌ FALLO")
- Remoto API (11434): $([ "$REMOTE_11434" = true ] && echo "✅ OK" || echo "❌ FALLO")

## Solución de Problemas Comunes

### 1. Acceso Local Funciona, Remoto No
**Causa**: Firewall bloqueando conexiones externas
**Solución**:
\`\`\`bash
sudo ufw allow 8000
sudo ufw allow 11434
sudo ufw enable
\`\`\`

### 2. Indicador de Conexión en Rojo
**Causa**: Problema de CORS o configuración de URL incorrecta
**Solución**: La interfaz detecta automáticamente la configuración
- Actualiza la página (F5)
- Verifica la consola del navegador (F12)

### 3. Modelos No Aparecen en la Lista
**Causa**: Ollama no está respondiendo o modelos no instalados
**Verificación**:
\`\`\`bash
docker logs msn-ai-ollama
curl http://localhost:11434/api/tags
\`\`\`

### 4. Contenedores No Responden
**Solución**:
\`\`\`bash
docker-compose -f docker/docker-compose.yml restart
docker logs msn-ai-app
docker logs msn-ai-ollama
\`\`\`

## URLs de Acceso
- **Local**: http://localhost:8000/msn-ai.html
- **Remoto**: http://$SERVER_IP:8000/msn-ai.html

## Comandos Útiles
\`\`\`bash
# Ver estado
docker ps | grep msn-ai

# Reiniciar servicios
docker restart msn-ai-app msn-ai-ollama

# Ver logs
docker logs msn-ai-app --tail 50
docker logs msn-ai-ollama --tail 50

# Test de conectividad
curl http://localhost:8000/msn-ai.html
curl http://localhost:11434/api/tags
curl http://$SERVER_IP:8000/msn-ai.html
curl http://$SERVER_IP:11434/api/tags
\`\`\`

## Soporte
📧 alan.mac.arthur.garcia.diaz@gmail.com
EOF

    echo "📚 Guía de troubleshooting creada en: $TROUBLESHOOTING_FILE"
}

# Ejecución principal
main() {
    # Configurar firewall automáticamente
    configure_ufw
    UFW_CONFIGURED=$?

    # Esperar un poco para que los servicios estén listos
    echo "⏳ Esperando que los servicios estén listos..."
    sleep 5

    # Test de conectividad
    test_connectivity

    # Crear archivos de configuración
    create_config_file
    generate_troubleshooting

    # Mostrar resultados
    show_access_urls

    echo ""
    echo "🎉 AUTO-CONFIGURACIÓN COMPLETADA"
    echo "================================"

    if [ "$REMOTE_8000" = true ] && [ "$REMOTE_11434" = true ]; then
        echo "✅ Acceso remoto configurado exitosamente"
        echo "   • Los usuarios pueden acceder transparentemente"
        echo "   • No se requiere configuración adicional"
        echo "   • La interfaz se configura automáticamente"
    elif [ "$LOCAL_8000" = true ] && [ "$LOCAL_11434" = true ]; then
        echo "⚠️ Solo acceso local disponible"
        echo "   • Funciona perfectamente en localhost"
        echo "   • Para acceso remoto: configurar firewall manualmente"
    else
        echo "❌ Problemas de conectividad detectados"
        echo "   • Verificar logs de contenedores"
        echo "   • Consultar guía de troubleshooting"
    fi

    echo ""
    echo "💡 La interfaz web ahora:"
    echo "   • Detecta automáticamente acceso local vs remoto"
    echo "   • Configura Ollama URL apropiada"
    echo "   • Carga modelos automáticamente"
    echo "   • Proporciona diagnósticos detallados"

    echo ""
    echo "🔧 MSN-AI Auto-Remote Configuration v1.0.0"
}

# Ejecutar configuración principal
main
