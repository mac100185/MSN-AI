#!/bin/bash
# Configure Ollama API Key Script
# Version: 2.1.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Configure OLLAMA_API_KEY for cloud models

echo "🔑 MSN-AI - Configuración de API Key"
echo "====================================="
echo "📧 Desarrollado por: Alan Mac-Arthur García Díaz"
echo "⚖️ Licencia: GPL-3.0"
echo "====================================="
echo ""

# Detect and change to project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT" || {
    echo "❌ Error: No se pudo cambiar al directorio del proyecto"
    exit 1
}

# Verify we're in the correct directory
if [ ! -f "msn-ai.html" ]; then
    echo "❌ Error: No se encuentra msn-ai.html"
    echo "   Estructura del proyecto incorrecta"
    exit 1
fi

# Function to validate API key format (basic validation)
validate_api_key() {
    local key=$1

    if [ -z "$key" ]; then
        echo "❌ API Key vacía"
        return 1
    fi

    if [ ${#key} -lt 16 ]; then
        echo "⚠️  API Key parece muy corta (menos de 16 caracteres)"
        read -p "   ¿Continuar de todas formas? (s/N): " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[sS]$ ]]; then
            return 1
        fi
    fi

    return 0
}

# Function to configure API key in .env
configure_env_file() {
    local api_key=$1

    echo "📝 Configurando archivo .env..."

    # Check if .env exists
    if [ -f ".env" ]; then
        # Check if OLLAMA_API_KEY already exists
        if grep -q "^OLLAMA_API_KEY=" .env; then
            echo "⚠️  OLLAMA_API_KEY ya existe en .env"
            read -p "   ¿Deseas sobrescribirla? (s/N): " OVERWRITE

            if [[ "$OVERWRITE" =~ ^[sS]$ ]]; then
                # Replace existing key
                sed -i "s/^OLLAMA_API_KEY=.*/OLLAMA_API_KEY=${api_key}/" .env
                echo "✅ API Key actualizada en .env"
            else
                echo "⏭️  Manteniendo API Key existente"
                return 0
            fi
        else
            # Append API key
            echo "OLLAMA_API_KEY=${api_key}" >> .env
            echo "✅ API Key agregada a .env"
        fi
    else
        # Create new .env file
        cat > .env << EOF
# MSN-AI Environment Configuration
# Generated: $(date)

# Ollama API Key for cloud models
OLLAMA_API_KEY=${api_key}

# MSN-AI Configuration
MSN_AI_VERSION=2.1.0
MSN_AI_PORT=8000
COMPOSE_PROJECT_NAME=msn-ai
DOCKER_BUILDKIT=1
EOF
        echo "✅ Archivo .env creado con API Key"
    fi
}

# Function to configure API key in Docker environment
configure_docker() {
    echo ""
    echo "🐳 Configuración Docker"
    echo "━━━━━━━━━━━━━━━━━━━━━━"

    # Check if Docker is running
    if ! docker ps &> /dev/null; then
        echo "⚠️  Docker no está ejecutándose"
        echo "   La configuración se aplicará cuando inicies Docker"
        return 0
    fi

    # Check if MSN-AI containers are running
    if docker ps --filter "name=msn-ai" --format "{{.Names}}" | grep -q "msn-ai"; then
        echo "📦 Contenedores MSN-AI detectados"
        echo ""
        read -p "¿Deseas reiniciar los contenedores para aplicar la nueva API Key? (s/N): " RESTART

        if [[ "$RESTART" =~ ^[sS]$ ]]; then
            echo "🔄 Reiniciando contenedores..."

            if [ -f "docker/docker-compose.yml" ]; then
                docker compose -f docker/docker-compose.yml restart ollama
                docker compose -f docker/docker-compose.yml restart ai-setup
                echo "✅ Contenedores reiniciados"
            else
                docker restart msn-ai-ollama msn-ai-setup 2>/dev/null || echo "⚠️  No se pudieron reiniciar algunos contenedores"
            fi
        else
            echo "ℹ️  Recuerda reiniciar los contenedores manualmente:"
            echo "   docker compose -f docker/docker-compose.yml restart"
        fi
    else
        echo "ℹ️  No hay contenedores MSN-AI ejecutándose"
        echo "   La API Key se aplicará en el próximo inicio"
    fi
}

# Function to test API key (basic connectivity test)
test_api_key() {
    echo ""
    echo "🧪 Prueba de Conectividad"
    echo "━━━━━━━━━━━━━━━━━━━━━━━"

    # Check if Ollama is accessible
    if curl -s --max-time 5 http://localhost:11434/ &> /dev/null; then
        echo "✅ Ollama está accesible"

        # Try to list models (this will use the API key if configured)
        if curl -s --max-time 10 http://localhost:11434/api/tags &> /dev/null; then
            echo "✅ API de Ollama responde correctamente"
        else
            echo "⚠️  API de Ollama no responde (puede ser normal si no hay modelos instalados)"
        fi
    else
        echo "⚠️  Ollama no está accesible en localhost:11434"
        echo "   Si usas Docker, esto es normal"
    fi
}

# Main menu
show_menu() {
    echo "📋 Opciones:"
    echo ""
    echo "1. Ingresar nueva API Key"
    echo "2. Ver API Key actual (enmascarada)"
    echo "3. Eliminar API Key"
    echo "4. Probar conectividad"
    echo "5. Salir"
    echo ""
}

# Main execution
main() {
    while true; do
        show_menu
        read -p "Selecciona una opción (1-5): " option
        echo ""

        case $option in
            1)
                echo "🔑 Configuración de API Key"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "💡 Información sobre modelos cloud:"
                echo "   Los siguientes modelos requieren API Key:"
                echo "   - qwen3-vl:235b-cloud"
                echo "   - gpt-oss:120b-cloud"
                echo "   - qwen3-coder:480b-cloud"
                echo ""
                echo "📝 Obtén tu API Key desde el proveedor del modelo"
                echo ""
                read -p "Ingresa tu OLLAMA_API_KEY: " NEW_API_KEY

                if validate_api_key "$NEW_API_KEY"; then
                    configure_env_file "$NEW_API_KEY"
                    configure_docker
                    echo ""
                    echo "🎉 Configuración completada"
                else
                    echo "❌ API Key no válida"
                fi
                echo ""
                ;;

            2)
                if [ -f ".env" ] && grep -q "^OLLAMA_API_KEY=" .env; then
                    CURRENT_KEY=$(grep "^OLLAMA_API_KEY=" .env | cut -d'=' -f2-)
                    if [ -n "$CURRENT_KEY" ]; then
                        MASKED_KEY="${CURRENT_KEY:0:8}***${CURRENT_KEY: -4}"
                        echo "🔑 API Key actual: ${MASKED_KEY}"
                        echo "   Longitud: ${#CURRENT_KEY} caracteres"
                    else
                        echo "⚠️  API Key está vacía en .env"
                    fi
                else
                    echo "❌ No hay API Key configurada en .env"
                fi
                echo ""
                ;;

            3)
                echo "🗑️  Eliminar API Key"
                echo "━━━━━━━━━━━━━━━━━━━"
                echo ""
                read -p "¿Estás seguro de eliminar la API Key? (s/N): " CONFIRM

                if [[ "$CONFIRM" =~ ^[sS]$ ]]; then
                    if [ -f ".env" ]; then
                        sed -i '/^OLLAMA_API_KEY=/d' .env
                        echo "✅ API Key eliminada de .env"
                        configure_docker
                    else
                        echo "⚠️  No existe archivo .env"
                    fi
                else
                    echo "⏭️  Operación cancelada"
                fi
                echo ""
                ;;

            4)
                test_api_key
                echo ""
                ;;

            5)
                echo "👋 ¡Hasta luego!"
                exit 0
                ;;

            *)
                echo "❌ Opción no válida"
                echo ""
                ;;
        esac
    done
}

# Check for command line arguments
if [ "$#" -gt 0 ]; then
    case "$1" in
        --set)
            if [ -z "$2" ]; then
                echo "❌ Error: Debes proporcionar una API Key"
                echo "   Uso: $0 --set <api_key>"
                exit 1
            fi

            if validate_api_key "$2"; then
                configure_env_file "$2"
                configure_docker
                echo ""
                echo "🎉 API Key configurada exitosamente"
                exit 0
            else
                echo "❌ API Key no válida"
                exit 1
            fi
            ;;

        --show)
            if [ -f ".env" ] && grep -q "^OLLAMA_API_KEY=" .env; then
                CURRENT_KEY=$(grep "^OLLAMA_API_KEY=" .env | cut -d'=' -f2-)
                if [ -n "$CURRENT_KEY" ]; then
                    MASKED_KEY="${CURRENT_KEY:0:8}***${CURRENT_KEY: -4}"
                    echo "🔑 API Key: ${MASKED_KEY}"
                else
                    echo "⚠️  API Key vacía"
                fi
            else
                echo "❌ No hay API Key configurada"
            fi
            exit 0
            ;;

        --remove)
            if [ -f ".env" ]; then
                sed -i '/^OLLAMA_API_KEY=/d' .env
                echo "✅ API Key eliminada"
            else
                echo "⚠️  No existe archivo .env"
            fi
            exit 0
            ;;

        --test)
            test_api_key
            exit 0
            ;;

        --help|-h)
            echo "Uso: $0 [opción] [valor]"
            echo ""
            echo "Opciones:"
            echo "  (sin opciones)        Modo interactivo"
            echo "  --set <api_key>       Configurar API Key"
            echo "  --show                Mostrar API Key actual (enmascarada)"
            echo "  --remove              Eliminar API Key"
            echo "  --test                Probar conectividad"
            echo "  --help, -h            Mostrar esta ayuda"
            echo ""
            echo "Ejemplos:"
            echo "  $0                           # Modo interactivo"
            echo "  $0 --set sk-abc123xyz        # Configurar API Key"
            echo "  $0 --show                    # Ver API Key"
            echo "  $0 --test                    # Probar conectividad"
            echo ""
            exit 0
            ;;

        *)
            echo "❌ Opción no reconocida: $1"
            echo "   Usa --help para ver opciones disponibles"
            exit 1
            ;;
    esac
else
    # Interactive mode
    main
fi
