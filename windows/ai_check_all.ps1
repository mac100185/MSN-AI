# ai_check_all.ps1 - Script para Windows
# Version: 1.0.0
# Autor: Alan Mac-Arthur Garcia Diaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# Licencia: GNU General Public License v3.0
# GitHub: https://github.com/mac100185/MSN-AI
# Descripcion: Detecta hardware y recomienda modelos de IA para MSN-AI
#
# ============================================
# INSTRUCCIONES DE USO
# ============================================
#
# IMPORTANTE: Si descargaste este archivo de Internet, primero debes desbloquearlo:
#
#   Unblock-File -Path .\ai_check_all.ps1
#
# Luego configura la politica de ejecucion (solo la primera vez):
#
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#
# Finalmente ejecuta el script:
#
#   .\ai_check_all.ps1
#
# QUE HACE ESTE SCRIPT:
#   - Detecta CPU, RAM y GPU de tu sistema
#   - Verifica si Ollama esta instalado
#   - Recomienda modelos de IA segun tu hardware
#   - Instala automaticamente el modelo recomendado (opcional)
#
# NOTA TECNICA:
#   - La deteccion de VRAM exacta requiere nvidia-smi (incluido con drivers NVIDIA)
#   - Ollama para Windows funciona en version estable
#
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Verificando hardware del sistema" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# CPU cores
$CPU_CORES = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors

# RAM total en GB
$RAM_GB = [Math]::Floor((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)

# Detectar GPU NVIDIA
$NVIDIA_GPUS = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" }
if ($NVIDIA_GPUS) {
    $GPU_DETECTED = $true
    Write-Host "GPU NVIDIA detectada: $($NVIDIA_GPUS[0].Name)" -ForegroundColor Green

    # Intentar obtener VRAM con nvidia-smi
    if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
        try {
            $nvidiaOutput = nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>$null
            if ($nvidiaOutput) {
                $VRAM_MB = [int]($nvidiaOutput.Trim())
                $VRAM_GB = [Math]::Floor($VRAM_MB / 1024)
                Write-Host "VRAM detectada: $VRAM_GB GB" -ForegroundColor Green
            }
            else {
                $VRAM_GB = 8
                Write-Host "VRAM: Usando valor estimado de 8 GB" -ForegroundColor Yellow
            }
        }
        catch {
            $VRAM_GB = 8
            Write-Host "VRAM: Usando valor estimado de 8 GB" -ForegroundColor Yellow
        }
    }
    else {
        $VRAM_GB = 8
        Write-Host "VRAM: Usando valor estimado de 8 GB" -ForegroundColor Yellow
        Write-Host "Para deteccion exacta, asegurate de tener nvidia-smi instalado" -ForegroundColor Gray
    }
}
else {
    $GPU_DETECTED = $false
    $VRAM_GB = 0
    Write-Host "GPU NVIDIA: No detectada (modo CPU)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Resumen del sistema:" -ForegroundColor Cyan
Write-Host "  CPU: $CPU_CORES nucleos logicos"
Write-Host "  RAM: $RAM_GB GB"
if ($GPU_DETECTED) {
    Write-Host "  GPU: NVIDIA detectada"
    Write-Host "  VRAM: $VRAM_GB GB"
}
else {
    Write-Host "  GPU: No detectada (usara CPU)"
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Analisis y recomendacion de modelo IA" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Logica de recomendacion de modelos
if ($GPU_DETECTED) {
    if ($VRAM_GB -ge 24) {
        $MODEL = "llama3:8b"
        $LEVEL = "Avanzado - Excelente para programacion y tareas complejas"
        $SIZE = "4.7 GB"
    }
    elseif ($VRAM_GB -ge 12) {
        $MODEL = "mistral:7b"
        $LEVEL = "Equilibrado - Recomendado para GPUs medias-altas"
        $SIZE = "4.1 GB"
    }
    elseif ($VRAM_GB -ge 6) {
        $MODEL = "phi3:mini"
        $LEVEL = "Ligero - Optimizado para GPUs con VRAM limitada"
        $SIZE = "2.3 GB"
    }
    else {
        $MODEL = "tinyllama"
        $LEVEL = "Ultra ligero - Para GPUs con muy poca VRAM"
        $SIZE = "637 MB"
    }
}
else {
    if ($RAM_GB -ge 32) {
        $MODEL = "mistral:7b"
        $LEVEL = "Equilibrado - Posible en CPU con RAM suficiente (lento)"
        $SIZE = "4.1 GB"
    }
    elseif ($RAM_GB -ge 16) {
        $MODEL = "phi3:mini"
        $LEVEL = "Ligero - Recomendado para modo CPU"
        $SIZE = "2.3 GB"
    }
    elseif ($RAM_GB -ge 8) {
        $MODEL = "tinyllama"
        $LEVEL = "Ultra ligero - Para sistemas con recursos limitados"
        $SIZE = "637 MB"
    }
    else {
        $MODEL = "tinyllama"
        $LEVEL = "Ultra ligero - Unica opcion viable con poca RAM"
        $SIZE = "637 MB"
        Write-Host "ADVERTENCIA: Tu sistema tiene poca RAM ($RAM_GB GB)" -ForegroundColor Red
        Write-Host "El rendimiento de IA sera muy limitado" -ForegroundColor Red
        Write-Host ""
    }
}

# Modelos requeridos por defecto
$requiredModels = @(
    "qwen3-vl:235b-cloud",
    "gpt-oss:120b-cloud",
    "qwen3-coder:480b-cloud"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Modelos requeridos por defecto:" -ForegroundColor Green
foreach ($model in $requiredModels) {
    Write-Host "   - $model" -ForegroundColor White
}
Write-Host ""
Write-Host "Modelo recomendado adicional para tu sistema:" -ForegroundColor Green
Write-Host "  Modelo: $MODEL" -ForegroundColor Cyan
Write-Host "  Tamano: $SIZE" -ForegroundColor Yellow
Write-Host "  Nivel: $LEVEL" -ForegroundColor White
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Otros modelos disponibles:" -ForegroundColor Cyan
Write-Host "  - tinyllama (637 MB) - Ultra ligero y rapido"
Write-Host "  - phi3:mini (2.3 GB) - Ligero y eficiente"
Write-Host "  - mistral:7b (4.1 GB) - Equilibrado (recomendado general)"
Write-Host "  - llama3:8b (4.7 GB) - Avanzado para tareas complejas"
Write-Host "  - codellama:7b (3.8 GB) - Especializado en programacion"
Write-Host ""

# Verificar si Ollama esta instalado
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "Ollama no esta instalado" -ForegroundColor Red
    Write-Host ""
    $installOllama = Read-Host "Deseas abrir la pagina de descarga de Ollama? (s/n)"

    if ($installOllama -eq "s" -or $installOllama -eq "S") {
        Write-Host ""
        Write-Host "Abriendo pagina de descarga de Ollama..." -ForegroundColor Green
        Start-Process "https://ollama.com/download"
        Write-Host ""
        Write-Host "============================================" -ForegroundColor Yellow
        Write-Host "  INSTRUCCIONES DE INSTALACION" -ForegroundColor Yellow
        Write-Host "============================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1. Descarga OllamaSetup.exe desde la pagina" -ForegroundColor White
        Write-Host "2. Ejecuta el instalador" -ForegroundColor White
        Write-Host "3. Completa el asistente de instalacion" -ForegroundColor White
        Write-Host "4. IMPORTANTE: Cierra esta ventana de PowerShell" -ForegroundColor Yellow
        Write-Host "5. Abre una NUEVA ventana de PowerShell" -ForegroundColor Yellow
        Write-Host "6. Ejecuta nuevamente este script: .\ai_check_all.ps1" -ForegroundColor White
        Write-Host ""
        Write-Host "NOTA: Debes usar una NUEVA sesion de PowerShell" -ForegroundColor Yellow
        Write-Host "      despues de instalar Ollama para que se detecte" -ForegroundColor Yellow
        Write-Host "============================================" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Presiona Enter para salir"
        exit 0
    }
    else {
        Write-Host ""
        Write-Host "Instalacion cancelada" -ForegroundColor Yellow
        Write-Host "Puedes instalar Ollama mas tarde desde: https://ollama.com/download" -ForegroundColor Cyan
        Write-Host ""
        Read-Host "Presiona Enter para salir"
        exit 0
    }
}

# Si Ollama esta instalado, ofrecer instalar el modelo
Write-Host "Ollama esta instalado correctamente" -ForegroundColor Green
Write-Host ""

# Verificar modelos ya instalados
Write-Host "Verificando modelos ya instalados..." -ForegroundColor Cyan
try {
    $installedModels = & ollama list 2>&1
    $modelLines = $installedModels | Select-String -Pattern "^\w" | Where-Object { $_ -notmatch "^NAME" }

    if ($modelLines) {
        Write-Host "Modelos ya instalados:" -ForegroundColor Green
        $modelLines | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        Write-Host ""
    }
}
catch {
    Write-Host "No se pudieron verificar los modelos instalados" -ForegroundColor Yellow
}

$CONFIRM = Read-Host "Deseas instalar todos los modelos requeridos? (s/n)"
if ($CONFIRM -eq "s" -or $CONFIRM -eq "S") {
    Write-Host ""
    Write-Host "Instalando modelos requeridos..." -ForegroundColor Green
    Write-Host "IMPORTANTE: Esto puede tardar bastante tiempo" -ForegroundColor Yellow
    Write-Host ""

    $installedCount = 0
    $failedCount = 0

    # Instalar modelos requeridos
    foreach ($model in $requiredModels) {
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host "Descargando: $model" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Cyan

        & ollama pull $model

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Modelo $model instalado correctamente" -ForegroundColor Green
            $installedCount++
        }
        else {
            Write-Host "Error instalando modelo $model" -ForegroundColor Red
            $failedCount++
        }
        Write-Host ""
    }

    # Instalar modelo recomendado adicional
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Descargando modelo recomendado: $MODEL" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan

    & ollama pull $MODEL

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Modelo $MODEL instalado correctamente" -ForegroundColor Green
        $installedCount++
    }
    else {
        Write-Host "Error instalando modelo $MODEL" -ForegroundColor Red
        $failedCount++
    }
    Write-Host ""

    # Resumen
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Resumen de instalacion:" -ForegroundColor Yellow
    Write-Host "   Instalados: $installedCount" -ForegroundColor Green
    Write-Host "   Fallidos: $failedCount" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    if ($installedCount -gt 0) {
        Write-Host "Instalacion completada" -ForegroundColor Green
        Write-Host ""
        Write-Host "Puedes probar los modelos con:" -ForegroundColor Cyan
        Write-Host "  ollama run <modelo>" -ForegroundColor White
        Write-Host ""
        Write-Host "O iniciar MSN-AI con:" -ForegroundColor Cyan
        Write-Host "  .\start-msnai.ps1 --auto" -ForegroundColor White
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-Host "Error al descargar los modelos" -ForegroundColor Red
        Write-Host ""
        Write-Host "Posibles causas:" -ForegroundColor Yellow
        Write-Host "  - Problema de conexion a internet" -ForegroundColor White
        Write-Host "  - Espacio en disco insuficiente" -ForegroundColor White
        Write-Host "  - Servicio Ollama no esta ejecutandose" -ForegroundColor White
        Write-Host ""
        Write-Host "Intenta manualmente:" -ForegroundColor Cyan
        Write-Host "  1. Verifica tu conexion a internet" -ForegroundColor White
        Write-Host "  2. Asegurate de tener espacio libre en disco" -ForegroundColor White
        Write-Host "  3. Ejecuta: ollama serve" -ForegroundColor White
        Write-Host "  4. En otra ventana: ollama pull <modelo>" -ForegroundColor White
        Write-Host ""
    }
}
else {
    Write-Host ""
    Write-Host "Instalacion de modelos omitida" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Puedes instalar modelos mas tarde con:" -ForegroundColor Cyan
    Write-Host "  ollama pull <modelo>" -ForegroundColor White
    Write-Host ""
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Verificacion completada" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Siguiente paso: Iniciar MSN-AI" -ForegroundColor Green
Write-Host "  .\start-msnai.ps1 --auto" -ForegroundColor White
Write-Host ""
Write-Host "Documentacion: https://github.com/mac100185/MSN-AI" -ForegroundColor Cyan
Write-Host "Soporte: alan.mac.arthur.garcia.diaz@gmail.com" -ForegroundColor Yellow
Write-Host ""
Read-Host "Presiona Enter para salir"
