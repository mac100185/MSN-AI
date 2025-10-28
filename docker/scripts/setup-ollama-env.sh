#!/bin/bash
# Setup Ollama Environment Script
# Version: 2.1.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Configure Ollama API Key for cloud models

set -e

echo "🔑 MSN-AI - Configuración de API Key para Ollama"
echo "================================================"

# Check if API key is provided
if [ -z "$OLLAMA_API_KEY" ]; then
    echo "⚠️  OLLAMA_API_KEY no está configurada"
    echo ""
    echo "💡 Para usar modelos cloud, necesitas configurar tu API Key:"
    echo "   export OLLAMA_API_KEY=your_api_key_here"
    echo ""
    echo "   O crear un archivo .env en la raíz del proyecto:"
    echo "   echo 'OLLAMA_API_KEY=your_api_key_here' > .env"
    echo ""
    echo "⚠️  Los modelos cloud NO funcionarán sin esta configuración"
    echo ""
    exit 0
fi

# Configure API key in Ollama config
OLLAMA_CONFIG_DIR="/root/.ollama"
OLLAMA_ENV_FILE="${OLLAMA_CONFIG_DIR}/config.env"

echo "📁 Creando directorio de configuración..."
mkdir -p "${OLLAMA_CONFIG_DIR}"

echo "🔧 Configurando API Key..."

# Create environment file with API key
cat > "${OLLAMA_ENV_FILE}" << EOF
# Ollama Configuration
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

# API Key for cloud models
export OLLAMA_API_KEY="${OLLAMA_API_KEY}"

# Other configurations
export OLLAMA_HOST="${OLLAMA_HOST:-0.0.0.0:11434}"
export OLLAMA_KEEP_ALIVE="${OLLAMA_KEEP_ALIVE:-24h}"
export OLLAMA_ORIGINS="${OLLAMA_ORIGINS:-*}"
EOF

# Set proper permissions
chmod 600 "${OLLAMA_ENV_FILE}"

echo "✅ API Key configurada correctamente"
echo ""
echo "📄 Archivo de configuración: ${OLLAMA_ENV_FILE}"
echo ""

# Create systemd override if systemd is available
if command -v systemctl >/dev/null 2>&1; then
    SYSTEMD_DIR="/etc/systemd/system/ollama.service.d"

    echo "🔧 Configurando systemd override..."
    mkdir -p "${SYSTEMD_DIR}"

    cat > "${SYSTEMD_DIR}/environment.conf" << EOF
[Service]
Environment="OLLAMA_API_KEY=${OLLAMA_API_KEY}"
Environment="OLLAMA_HOST=${OLLAMA_HOST:-0.0.0.0:11434}"
Environment="OLLAMA_KEEP_ALIVE=${OLLAMA_KEEP_ALIVE:-24h}"
Environment="OLLAMA_ORIGINS=${OLLAMA_ORIGINS:-*}"
EOF

    echo "✅ Systemd override configurado"
    echo ""
fi

# Create profile.d script for system-wide availability
PROFILE_SCRIPT="/etc/profile.d/ollama-env.sh"

if [ -w "/etc/profile.d" ]; then
    echo "🔧 Configurando variables de entorno del sistema..."

    cat > "${PROFILE_SCRIPT}" << EOF
#!/bin/bash
# Ollama Environment Variables
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

export OLLAMA_API_KEY="${OLLAMA_API_KEY}"
export OLLAMA_HOST="${OLLAMA_HOST:-0.0.0.0:11434}"
export OLLAMA_KEEP_ALIVE="${OLLAMA_KEEP_ALIVE:-24h}"
export OLLAMA_ORIGINS="${OLLAMA_ORIGINS:-*}"
EOF

    chmod 644 "${PROFILE_SCRIPT}"

    echo "✅ Variables de entorno del sistema configuradas"
    echo ""
fi

# Verify API key is accessible
if [ -f "${OLLAMA_ENV_FILE}" ]; then
    echo "🔍 Verificando configuración..."

    # Source the config file
    source "${OLLAMA_ENV_FILE}"

    if [ -n "$OLLAMA_API_KEY" ]; then
        # Mask API key for display
        MASKED_KEY="${OLLAMA_API_KEY:0:8}***${OLLAMA_API_KEY: -4}"
        echo "✅ API Key detectada: ${MASKED_KEY}"
    else
        echo "⚠️  API Key no pudo ser verificada"
    fi

    echo ""
fi

echo "🎉 Configuración completada"
echo ""
echo "💡 Modelos cloud compatibles:"
echo "   - qwen3-vl:235b-cloud"
echo "   - gpt-oss:120b-cloud"
echo "   - qwen3-coder:480b-cloud"
echo ""
echo "⚠️  IMPORTANTE: Reinicia el servicio Ollama para aplicar cambios"
echo "   docker compose -f docker/docker-compose.yml restart ollama"
echo ""
