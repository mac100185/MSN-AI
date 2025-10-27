#!/bin/bash
# Script: ai_check_all.sh para distros basadas en Debian, Ubuntu
# Objetivo: Detectar hardware y recomendar modelo de IA local compatible con Ollama.

echo "=== Verificando hardware del sistema ==="
CPU_CORES=$(nproc)
RAM_GB=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
GPU_INFO=$(lspci | grep -i 'vga\|3d' | grep -i nvidia)
VRAM_GB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | awk '{sum += $1} END {print int(sum/1024)}')

echo "CPU: $CPU_CORES núcleos"
echo "RAM: $RAM_GB GB"
if [ -n "$GPU_INFO" ]; then
  echo "GPU NVIDIA detectada"
  echo "VRAM total: ${VRAM_GB:-0} GB"
else
  echo "No se detectó GPU NVIDIA compatible"
fi

echo
echo "=== Análisis y recomendación ==="

if [ -n "$GPU_INFO" ]; then
  if [ "$VRAM_GB" -ge 80 ]; then
    MODEL="llama3:70b"
    LEVEL="Máximo (alto rendimiento, razonamiento complejo)"
  elif [ "$VRAM_GB" -ge 24 ]; then
    MODEL="llama3:8b"
    LEVEL="Avanzado (programación y tareas generales)"
  else
    MODEL="mistral:7b"
    LEVEL="Eficiente (recomendado para laptops con GPU media)"
  fi
else
  if [ "$RAM_GB" -ge 32 ]; then
    MODEL="mistral:7b"
    LEVEL="Eficiente (modo CPU posible)"
  else
    MODEL="phi3:mini"
    LEVEL="Ligero (para equipos sin GPU y poca RAM)"
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
