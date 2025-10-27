#!/bin/bash
# ai_check_all_mac.sh - Script para macOS
# Versión para macOS (Bash/Zsh)
# ¿Cómo usarlo?
# macOS:
# Abre Terminal.
# Dale permisos: chmod +x ai_check_all_mac.sh
# Ejecuta: ./ai_check_all_mac.sh

echo "=== Verificando hardware del sistema ==="

# CPU cores (lógicos)
CPU_CORES=$(sysctl -n hw.logicalcpu)

# RAM total en GB
RAM_GB=$(awk '/memtotal:/ {printf "%.0f", $2/1024/1024}' /proc/meminfo 2>/dev/null || sysctl -n hw.memsize | awk '{printf "%.0f", $1/1024/1024/1024}')

# Detectar GPU (macOS no tiene lspci; usamos system_profiler)
# Nota: macOS no expone VRAM fácilmente para GPUs dedicadas, pero en Macs con Apple Silicon, la GPU comparte RAM.
# Asumiremos que si es Apple Silicon (M1/M2/M3), tiene suficiente rendimiento para modelos medianos.
HAS_NVIDIA=false
HAS_APPLE_SILICON=false

if [[ $(sysctl -n machdep.cpu.brand_string) == *"Apple"* ]]; then
    HAS_APPLE_SILICON=true
    echo "Chip Apple Silicon detectado (GPU integrada con memoria unificada)"
    # En Apple Silicon, toda la RAM está disponible para el modelo (hasta cierto límite práctico)
    VRAM_GB=$RAM_GB
elif system_profiler SPDisplaysDataType | grep -iq nvidia; then
    HAS_NVIDIA=true
    echo "GPU NVIDIA detectada (poco común en macOS moderno)"
    # macOS moderno ya no soporta drivers NVIDIA, así que esto es raro.
    VRAM_GB=4  # valor conservador
else
    echo "GPU integrada Intel/AMD o no detectada"
    VRAM_GB=0
fi

echo "CPU: $CPU_CORES núcleos"
echo "RAM: $RAM_GB GB"

echo
echo "=== Análisis y recomendación ==="

if [[ "$HAS_APPLE_SILICON" == "true" ]]; then
    if [ "$RAM_GB" -ge 16 ]; then
        MODEL="llama3:8b"
        LEVEL="Avanzado (Apple Silicon con buena RAM)"
    else
        MODEL="mistral:7b"
        LEVEL="Eficiente (Apple Silicon con RAM limitada)"
    fi
elif [[ "$HAS_NVIDIA" == "true" ]] && [ "$VRAM_GB" -ge 8 ]; then
    MODEL="mistral:7b"
    LEVEL="Eficiente (GPU NVIDIA en macOS)"
else
    if [ "$RAM_GB" -ge 32 ]; then
        MODEL="mistral:7b"
        LEVEL="Eficiente (modo CPU)"
    else
        MODEL="phi3:mini"
        LEVEL="Ligero (equipos antiguos o con poca RAM)"
    fi
fi

echo "Modelo recomendado: $MODEL"
echo "Nivel de capacidad: $LEVEL"
echo

# Modelos requeridos por defecto
REQUIRED_MODELS=(
    "qwen3-vl:235b-cloud"
    "gpt-oss:120b-cloud"
    "qwen3-coder:480b-cloud"
)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Modelos requeridos por defecto:"
for model in "${REQUIRED_MODELS[@]}"; do
    echo "   - $model"
done
echo "📦 Modelo recomendado adicional: $MODEL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

read -p "¿Deseas instalar Ollama y todos los modelos requeridos? (s/n): " CONFIRM
if [[ "$CONFIRM" =~ ^[sS]$ ]]; then
    if ! command -v ollama &>/dev/null; then
        echo "Instalando Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh
    fi

    echo ""
    echo "📥 Instalando modelos requeridos..."
    echo "⚠️  NOTA: Este proceso puede tardar bastante tiempo"
    echo ""

    INSTALLED_COUNT=0
    FAILED_COUNT=0

    # Instalar modelos requeridos
    for model in "${REQUIRED_MODELS[@]}"; do
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📥 Descargando: $model"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        ollama pull "$model"

        if [ $? -eq 0 ]; then
            echo "✅ Modelo $model instalado correctamente"
            INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        else
            echo "❌ Error instalando modelo $model"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
        echo ""
    done

    # Instalar modelo recomendado adicional
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📥 Descargando modelo recomendado: $MODEL"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    ollama pull "$MODEL"

    if [ $? -eq 0 ]; then
        echo "✅ Modelo $MODEL instalado correctamente"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
        echo "❌ Error instalando modelo $MODEL"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Resumen de instalación:"
    echo "   ✅ Instalados: $INSTALLED_COUNT"
    echo "   ❌ Fallidos: $FAILED_COUNT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Listo. Puedes probar los modelos con: ollama run <modelo>"
else
    echo "Instalación omitida. Puedes hacerlo manualmente más tarde."
fi
