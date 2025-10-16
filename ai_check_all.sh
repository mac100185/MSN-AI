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
