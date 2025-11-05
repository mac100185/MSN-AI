# start-msnai-docker.ps1 - Docker Startup Script for MSN-AI - Windows
# Version: 1.0.0
# Author: Alan Mac-Arthur Garcia Diaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# GitHub: https://github.com/mac100185/MSN-AI
# Description: Docker-based startup for MSN-AI on Windows with intelligent setup
#
# ============================================
# INSTRUCCIONES DE USO
# ============================================
#
# IMPORTANTE: Si descargaste este archivo de Internet, primero debes desbloquearlo:
#
#   Unblock-File -Path .\start-msnai-docker.ps1
#
# Luego puedes ejecutarlo de las siguientes formas:
#
# 1. Modo automatico (inicia directamente):
#   .\start-msnai-docker.ps1 --auto
#   .\start-msnai-docker.ps1 -auto
#   .\start-msnai-docker.ps1 auto
#
# 2. Modo interactivo (te pregunta que opcion elegir):
#   .\start-msnai-docker.ps1
#
# QUE HACE ESTE SCRIPT:
#   - Verifica si Docker esta instalado (lo instala si falta)
#   - Construye las imagenes Docker necesarias
#   - Inicia los contenedores con MSN-AI y Ollama
#   - Abre automaticamente la aplicacion en el navegador
#
# REQUISITOS:
#   - Docker Desktop para Windows (se instala automaticamente si falta)
#   - 8GB+ RAM recomendado
#   - Navegador web moderno
#
# DETENER LOS CONTENEDORES:
#   Presiona Ctrl+C en la ventana de PowerShell donde se ejecuta el script
#   O ejecuta: docker-compose -f docker/docker-compose.yml down
#
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "     MSN-AI v1.0.0 - Docker Edition" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Desarrollado por: Alan Mac-Arthur Garcia Diaz" -ForegroundColor Green
Write-Host "Licencia: GPL-3.0" -ForegroundColor Yellow
Write-Host "Email: alan.mac.arthur.garcia.diaz@gmail.com" -ForegroundColor Yellow
Write-Host "GitHub: https://github.com/mac100185/MSN-AI" -ForegroundColor Cyan
Write-Host "Modo: Docker Container" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Detect and change to project root directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Host "[INFO] Detectando directorio del proyecto..." -ForegroundColor Cyan
Write-Host "   Script ubicado en: $ScriptDir" -ForegroundColor Gray
Write-Host "   Directorio raíz: $ProjectRoot" -ForegroundColor Gray

# Change to project root
Set-Location $ProjectRoot

Write-Host "   Directorio actual: $(Get-Location)" -ForegroundColor Gray

# Verify we're in the correct directory
if (-not (Test-Path "msn-ai.html")) {
    Write-Host "[ERROR] ERROR: No se encuentra msn-ai.html en $(Get-Location)" -ForegroundColor Red
    Write-Host "   Archivos encontrados:" -ForegroundColor Yellow
    Get-ChildItem | Select-Object -First 10 | Format-Table Name, Length
    Write-Host ""
    Write-Host "[INFO] Asegúrate de ejecutar este script desde:" -ForegroundColor Yellow
    Write-Host "   $ProjectRoot\windows\start-msnai-docker.ps1" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host "[OK] Proyecto MSN-AI detectado correctamente" -ForegroundColor Green
Write-Host ""

# Check if docker directory exists
if (-not (Test-Path "docker")) {
    Write-Host "ERROR: Directorio docker no encontrado" -ForegroundColor Red
    Write-Host "Asegurate de que todos los archivos Docker esten presentes" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 1
}

# Global variables
$script:UseGPU = $false
$script:DockerInstalled = $false
$script:BrowserName = ""
$script:BrowserPath = ""

# Function to check Docker installation
function Test-Docker {
    Write-Host "Verificando Docker..." -ForegroundColor Cyan

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "Docker no esta instalado" -ForegroundColor Red
        Write-Host ""
        Write-Host "Opciones de instalacion:" -ForegroundColor Yellow
        Write-Host "   1. Descargar Docker Desktop (recomendado)"
        Write-Host "   2. Instrucciones manuales"
        Write-Host "   3. Continuar sin Docker (modo local)"

        $dockerOption = Read-Host "Selecciona una opcion (1-3)"

        switch ($dockerOption) {
            1 {
                Install-DockerDesktop
            }
            2 {
                Show-DockerInstructions
                exit 1
            }
            3 {
                Write-Host "Iniciando en modo local..." -ForegroundColor Yellow
                & ".\start-msnai.ps1" @args
                exit 0
            }
            default {
                Write-Host "Opcion no valida" -ForegroundColor Red
                exit 1
            }
        }
    }
    else {
        $dockerVersion = (docker --version).Split(' ')[2]
        Write-Host "Docker instalado: $dockerVersion" -ForegroundColor Green
        $script:DockerInstalled = $true
    }

    # Check if Docker is running
    try {
        docker info | Out-Null
        Write-Host "Docker esta ejecutandose" -ForegroundColor Green
    }
    catch {
        Write-Host "Docker no esta ejecutandose" -ForegroundColor Red
        Write-Host "Inicia Docker Desktop e intenta nuevamente" -ForegroundColor Yellow
        exit 1
    }

    # Check Docker Compose
    try {
        if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
            Write-Host "Docker Compose disponible (standalone)" -ForegroundColor Green
        }
        elseif ((docker compose version) -match "version") {
            Write-Host "Docker Compose disponible (plugin)" -ForegroundColor Green
        }
        else {
            throw "Docker Compose not found"
        }
    }
    catch {
        Write-Host "Docker Compose no esta disponible" -ForegroundColor Red
        Write-Host "Instala Docker Desktop que incluye Docker Compose" -ForegroundColor Yellow
        exit 1
    }
}

# Function to install Docker Desktop
function Install-DockerDesktop {
    Write-Host "Instalando Docker Desktop..." -ForegroundColor Green

    Write-Host "Abriendo pagina de descarga de Docker Desktop..." -ForegroundColor Yellow
    Start-Process "https://www.docker.com/products/docker-desktop"

    Write-Host ""
    Write-Host "Instrucciones de instalacion:" -ForegroundColor Yellow
    Write-Host "   1. Descarga Docker Desktop desde la pagina que se abrio"
    Write-Host "   2. Ejecuta el instalador como administrador"
    Write-Host "   3. Reinicia tu computadora si es necesario"
    Write-Host "   4. Inicia Docker Desktop"
    Write-Host "   5. Ejecuta este script nuevamente"
    Write-Host ""

    Read-Host "Presiona Enter para continuar despues de instalar Docker Desktop"

    # Re-check Docker
    Test-Docker
}

# Function to show Docker instructions
function Show-DockerInstructions {
    Write-Host ""
    Write-Host "Instrucciones de instalacion manual de Docker:" -ForegroundColor Yellow
    Write-Host "================================================="
    Write-Host ""
    Write-Host "Windows 10/11 Pro, Enterprise, Education:"
    Write-Host "   1. Habilitar Hyper-V y Containers en Windows Features"
    Write-Host "   2. Descargar Docker Desktop: https://www.docker.com/products/docker-desktop"
    Write-Host "   3. Instalar y reiniciar"
    Write-Host "   4. Reiniciar si es necesario"
    Write-Host ""
    Write-Host "Windows 10/11 Home:"
    Write-Host "   1. Habilitar WSL 2 (Windows Subsystem for Linux)"
    Write-Host "   2. Descargar Docker Desktop: https://www.docker.com/products/docker-desktop"
    Write-Host "   3. Instalar con backend WSL 2"
    Write-Host ""
    Write-Host "Despues de instalar, ejecuta este script nuevamente" -ForegroundColor Cyan
}

# Function to check GPU support
function Test-GPUSupport {
    Write-Host "Verificando soporte de GPU..." -ForegroundColor Cyan

    try {
        $nvidiagpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" }

        if ($nvidiagpu) {
            Write-Host "GPU NVIDIA detectada" -ForegroundColor Green

            if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
                Write-Host "NVIDIA drivers instalados" -ForegroundColor Green

                # Test Docker GPU access
                try {
                    $testResult = docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu22.04 nvidia-smi 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Docker GPU support configurado" -ForegroundColor Green
                        $script:UseGPU = $true
                    }
                    else {
                        Write-Host "Docker GPU support no disponible" -ForegroundColor Yellow
                        Write-Host "Para habilitar GPU: Instala NVIDIA Container Toolkit" -ForegroundColor Yellow
                        $script:UseGPU = $false
                    }
                }
                catch {
                    Write-Host "Error probando GPU en Docker" -ForegroundColor Yellow
                    $script:UseGPU = $false
                }
            }
            else {
                Write-Host "NVIDIA drivers no encontrados" -ForegroundColor Yellow
                $script:UseGPU = $false
            }
        }
        else {
            Write-Host "GPU NVIDIA no detectada, usando solo CPU" -ForegroundColor Cyan
            $script:UseGPU = $false
        }
    }
    catch {
        Write-Host "No se pudo detectar GPU, usando solo CPU" -ForegroundColor Cyan
        $script:UseGPU = $false
    }
}

# Function to setup environment
function Set-Environment {
    Write-Host "Configurando entorno Docker..." -ForegroundColor Cyan

    # Create .env file for Docker Compose
    $envContent = @"
# MSN-AI Docker Environment Configuration
MSN_AI_VERSION=1.0.0
MSN_AI_PORT=8000
COMPOSE_PROJECT_NAME=msn-ai
DOCKER_BUILDKIT=1
"@

    # Add GPU configuration if available
    if ($script:UseGPU) {
        $envContent += "`nGPU_SUPPORT=true"
    }
    else {
        $envContent += "`nGPU_SUPPORT=false"
    }

    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-Host "Archivo de entorno creado" -ForegroundColor Green
}

# Function to build and start containers
function Start-Containers {
    Write-Host "Construyendo e iniciando contenedores..." -ForegroundColor Cyan

    # Build images
    Write-Host "Construyendo imagen MSN-AI..." -ForegroundColor Yellow

    try {
        if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
            docker-compose -f docker/docker-compose.yml build --no-cache
        }
        else {
            docker compose -f docker/docker-compose.yml build --no-cache
        }

        if ($LASTEXITCODE -ne 0) {
            throw "Build failed"
        }
    }
    catch {
        Write-Host "Error construyendo la imagen" -ForegroundColor Red
        exit 1
    }

    # Start services
    Write-Host "Iniciando servicios..." -ForegroundColor Green

    try {
        if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
            docker-compose -f docker/docker-compose.yml up -d
        }
        else {
            docker compose -f docker/docker-compose.yml up -d
        }

        if ($LASTEXITCODE -ne 0) {
            throw "Service start failed"
        }
    }
    catch {
        Write-Host "Error iniciando servicios" -ForegroundColor Red
        exit 1
    }

    Write-Host "Contenedores iniciados correctamente" -ForegroundColor Green

    # Wait for services to be ready
    Write-Host "Esperando a que los servicios esten listos..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5

    # Check if services are running
    $runningContainers = docker ps --filter "name=msn-ai" --format "{{.Names}}"
    if ($runningContainers) {
        Write-Host "Servicios activos:" -ForegroundColor Green
        $runningContainers | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    }
    else {
        Write-Host "No se detectaron contenedores activos" -ForegroundColor Yellow
    }
}

# Function to detect browser
function Find-Browser {
    Write-Host "Detectando navegador..." -ForegroundColor Cyan

    $browsers = @(
        @{Name="Chrome"; Path="C:\Program Files\Google\Chrome\Application\chrome.exe"},
        @{Name="Chrome"; Path="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"},
        @{Name="Edge"; Path="C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"},
        @{Name="Edge"; Path="C:\Program Files\Microsoft\Edge\Application\msedge.exe"},
        @{Name="Firefox"; Path="C:\Program Files\Mozilla Firefox\firefox.exe"},
        @{Name="Firefox"; Path="C:\Program Files (x86)\Mozilla Firefox\firefox.exe"},
        @{Name="Brave"; Path="C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"},
        @{Name="Opera"; Path="C:\Program Files\Opera\launcher.exe"}
    )

    foreach ($browser in $browsers) {
        if (Test-Path $browser.Path) {
            $script:BrowserName = $browser.Name
            $script:BrowserPath = $browser.Path
            Write-Host "Navegador encontrado: $($browser.Name)" -ForegroundColor Green
            return $true
        }
    }

    $script:BrowserName = "Default"
    $script:BrowserPath = ""
    Write-Host "Usando navegador por defecto del sistema" -ForegroundColor Yellow
    return $true
}

# Function to open application
function Open-Application {
    param([string]$url)

    Write-Host "Abriendo MSN-AI en el navegador..." -ForegroundColor Cyan

    try {
        if ([string]::IsNullOrEmpty($script:BrowserPath) -or $script:BrowserName -eq "Default") {
            Start-Process $url
        }
        else {
            Start-Process -FilePath $script:BrowserPath -ArgumentList $url
        }
        Start-Sleep -Seconds 2
        Write-Host "MSN-AI abierto en el navegador" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error abriendo navegador: $_" -ForegroundColor Yellow
        Write-Host "Abre manualmente: $url" -ForegroundColor Yellow
        return $false
    }
}

# Function to stop containers
function Stop-Containers {
    Write-Host ""
    Write-Host "Deteniendo contenedores MSN-AI..." -ForegroundColor Cyan

    try {
        if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
            docker-compose -f docker/docker-compose.yml down
        }
        else {
            docker compose -f docker/docker-compose.yml down
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Contenedores detenidos correctamente" -ForegroundColor Green
        }
        else {
            Write-Host "Error deteniendo contenedores" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error deteniendo contenedores: $_" -ForegroundColor Yellow
    }

    Write-Host "Limpieza completada" -ForegroundColor Green
    Write-Host "Gracias por usar MSN-AI v1.0.0!" -ForegroundColor Cyan
}

# Register exit handler
try {
    $null = Register-EngineEvent PowerShell.Exiting -Action {
        Stop-Containers
    }
}
catch {
    # If registration fails, it's not critical
}

# ===================
# MAIN FLOW
# ===================

Write-Host "Iniciando verificaciones del sistema..." -ForegroundColor Cyan
Write-Host ""

# 1. Check Docker
Test-Docker
Write-Host ""

# 2. Check GPU support
Test-GPUSupport
Write-Host ""

# 3. Detect browser
Find-Browser
Write-Host ""

# 4. Check if user wants auto mode
$autoMode = $false
if ($args.Count -gt 0) {
    if ($args[0] -eq "--auto" -or $args[0] -eq "-auto" -or $args[0] -eq "auto") {
        $autoMode = $true
    }
}

if ($autoMode) {
    Write-Host "Modo automatico activado" -ForegroundColor Green
    $continue = "s"
}
else {
    Write-Host "Listo para iniciar MSN-AI en Docker" -ForegroundColor Cyan
    $continue = Read-Host "Continuar? (s/n)"
}

if ($continue -eq "s" -or $continue -eq "S") {
    Write-Host ""

    # Setup environment
    Set-Environment
    Write-Host ""

    # Start containers
    Start-Containers
    Write-Host ""

    # Open application
    $url = "http://localhost:8000/msn-ai.html"
    Open-Application $url

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "     MSN-AI v1.0.0 Docker - Ejecutandose!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "URL: $url" -ForegroundColor Yellow
    Write-Host "GPU: $(if($script:UseGPU){'Habilitada'}else{'Deshabilitada (solo CPU)'})" -ForegroundColor $(if($script:UseGPU){'Green'}else{'Yellow'})
    Write-Host "Navegador: $script:BrowserName" -ForegroundColor Green
    Write-Host ""
    Write-Host "Comandos utiles:" -ForegroundColor Yellow
    Write-Host "  Ver logs: docker-compose -f docker/docker-compose.yml logs -f" -ForegroundColor White
    Write-Host "  Detener: docker-compose -f docker/docker-compose.yml down" -ForegroundColor White
    Write-Host "  Reiniciar: docker-compose -f docker/docker-compose.yml restart" -ForegroundColor White
    Write-Host ""
    Write-Host "Los contenedores seguiran ejecutandose en segundo plano" -ForegroundColor Green
    Write-Host "Para detener: Presiona Ctrl+C o usa el comando 'Detener' de arriba" -ForegroundColor Green
    Write-Host ""

    # Wait for user interrupt
    Write-Host "Presiona Ctrl+C para detener los contenedores..." -ForegroundColor Yellow
    try {
        while ($true) {
            Start-Sleep -Seconds 1
        }
    }
    catch {
        Write-Host ""
    }
    finally {
        Stop-Containers
    }
}
else {
    Write-Host "Instalacion cancelada" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "     Script completado" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Problemas? alan.mac.arthur.garcia.diaz@gmail.com" -ForegroundColor Yellow
Write-Host ""
Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
Write-Host "[CLOUD]  MODELOS CLOUD DISPONIBLES" -ForegroundColor Cyan
Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Los siguientes modelos cloud requieren autenticación:" -ForegroundColor White
Write-Host "  [PACKAGE] qwen3-vl:235b-cloud" -ForegroundColor Gray
Write-Host "  [PACKAGE] gpt-oss:120b-cloud" -ForegroundColor Gray
Write-Host "  [PACKAGE] qwen3-coder:480b-cloud" -ForegroundColor Gray
Write-Host ""
Write-Host "[WARN]  Los modelos cloud NO se instalan automáticamente" -ForegroundColor Yellow
Write-Host ""
Write-Host "[MENU] Para instalar modelos cloud:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1.  Usa el script helper:" -ForegroundColor White
Write-Host "   .\windows\docker-install-cloud-models.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "O manualmente:" -ForegroundColor White
Write-Host "   docker exec -it msn-ai-ollama ollama signin" -ForegroundColor Cyan
Write-Host "   (Abre el enlace en tu navegador y aprueba)" -ForegroundColor Gray
Write-Host "   docker exec -it msn-ai-ollama ollama pull qwen3-vl:235b-cloud" -ForegroundColor Cyan
Write-Host ""
Write-Host "[WARN]  IMPORTANTE: El signin puede expirar con el tiempo" -ForegroundColor Yellow
Write-Host "   Si los modelos dejan de funcionar, repite el signin:" -ForegroundColor Yellow
Write-Host "   docker exec -it msn-ai-ollama ollama signin" -ForegroundColor Cyan
Write-Host ""
Write-Host "[INFO] Los modelos locales ya están instalados y funcionando" -ForegroundColor Yellow
Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
Write-Host "Licencia: GPL-3.0" -ForegroundColor Green
Write-Host "GitHub: https://github.com/mac100185/MSN-AI" -ForegroundColor Cyan
Write-Host ""
