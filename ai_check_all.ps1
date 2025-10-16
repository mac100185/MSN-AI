# ai_check_all.ps1 - Script para Windows
# Nota para Windows: 
# La detección de VRAM exacta requiere nvidia-smi, que sí está disponible si tienes los drivers de NVIDIA.
# Si quieres mayor precisión, podríamos invocar nvidia-smi desde PowerShell.
# Ollama para Windows está en versión preview, pero funciona bien.

# ¿Cómo usarlo?
# Windows:
# Abre PowerShell como usuario normal.
# Ejecuta: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser (una sola vez).
# Luego: .\ai_check_all.ps1

Write-Host "=== Verificando hardware del sistema ===" -ForegroundColor Cyan

# CPU cores
$CPU_CORES = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors

# RAM total en GB
$RAM_GB = [Math]::Floor((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)

# Detectar GPU NVIDIA
$NVIDIA_GPUS = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" }
if ($NVIDIA_GPUS) {
    $GPU_DETECTED = $true
    # Nota: PowerShell no puede leer VRAM directamente sin herramientas externas.
    # Asumiremos 8 GB si hay GPU NVIDIA (valor típico en laptops), o preguntaremos.
    Write-Host "GPU NVIDIA detectada (no se puede leer VRAM automáticamente en PowerShell)" -ForegroundColor Yellow
    $VRAM_GB = 8  # Valor por defecto conservador; podrías pedir al usuario que lo ingrese
} else {
    $GPU_DETECTED = $false
    $VRAM_GB = 0
}

Write-Host "CPU: $CPU_CORES núcleos"
Write-Host "RAM: $RAM_GB GB"
if ($GPU_DETECTED) {
    Write-Host "GPU NVIDIA detectada"
    Write-Host "VRAM estimada: ${VRAM_GB} GB (valor por defecto; ajusta si es necesario)"
} else {
    Write-Host "No se detectó GPU NVIDIA"
}

Write-Host ""
Write-Host "=== Análisis y recomendación ===" -ForegroundColor Cyan

if ($GPU_DETECTED) {
    if ($VRAM_GB -ge 24) {
        $MODEL = "llama3:8b"
        $LEVEL = "Avanzado (programación y tareas generales)"
    } else {
        $MODEL = "mistral:7b"
        $LEVEL = "Eficiente (recomendado para laptops con GPU media)"
    }
} else {
    if ($RAM_GB -ge 32) {
        $MODEL = "mistral:7b"
        $LEVEL = "Eficiente (modo CPU posible)"
    } else {
        $MODEL = "phi3:mini"
        $LEVEL = "Ligero (para equipos sin GPU y poca RAM)"
    }
}

Write-Host "Modelo recomendado: $MODEL"
Write-Host "Nivel de capacidad: $LEVEL"
Write-Host ""

$CONFIRM = Read-Host "¿Deseas instalar Ollama y el modelo recomendado ahora? (s/n)"
if ($CONFIRM -eq "s" -or $CONFIRM -eq "S") {
    if (!(Get-Command ollama -ErrorAction SilentlyContinue)) {
        Write-Host "Instalando Ollama..." -ForegroundColor Green
        # Descargar e instalar Ollama para Windows (versión preview)
        Invoke-WebRequest -Uri "https://ollama.com/download/OllamaSetup.exe" -OutFile "$env:TEMP\OllamaSetup.exe"
        Start-Process -FilePath "$env:TEMP\OllamaSetup.exe" -Wait
    }
    Write-Host "Descargando modelo $MODEL ..." -ForegroundColor Green
    ollama pull $MODEL
    Write-Host "Listo. Puedes probarlo con: ollama run $MODEL" -ForegroundColor Green
} else {
    Write-Host "Instalación omitida. Puedes hacerlo manualmente más tarde."
}
