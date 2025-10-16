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

read -p "¿Deseas instalar Ollama y el modelo recomendado ahora? (s/n): " CONFIRM
if [[ "$CONFIRM" =~ ^[sS]$ ]]; then
    if ! command -v ollama &>/dev/null; then
        echo "Instalando Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh
    fi
    echo "Descargando modelo $MODEL ..."
    ollama pull $MODEL
    echo "Listo. Puedes probarlo con: ollama run $MODEL"
else
    echo "Instalación omitida. Puedes hacerlo manualmente más tarde."
fi
