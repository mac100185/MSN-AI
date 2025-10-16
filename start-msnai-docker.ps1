# start-msnai-docker.ps1 - Docker Startup Script for MSN-AI - Windows
# Version: 1.0.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Docker-based startup for MSN-AI on Windows with intelligent setup

Write-Host "🐳 MSN-AI v1.0.0 - Docker Edition" -ForegroundColor Cyan
Write-Host "=================================="
Write-Host "📧 Desarrollado por: Alan Mac-Arthur García Díaz" -ForegroundColor Green
Write-Host "⚖️ Licencia: GPL-3.0 | 🔗 alan.mac.arthur.garcia.diaz@gmail.com" -ForegroundColor Yellow
Write-Host "🐳 Modo: Docker Container" -ForegroundColor Cyan
Write-Host "=================================="

# Check if we're in the correct directory
if (-not (Test-Path "msn-ai.html")) {
    Write-Host "❌ Error: No se encuentra msn-ai.html" -ForegroundColor Red
    Write-Host "   Asegúrate de ejecutar este script desde el directorio MSN-AI"
    exit 1
}

# Check if docker directory exists
if (-not (Test-Path "docker")) {
    Write-Host "❌ Error: Directorio docker no encontrado" -ForegroundColor Red
    Write-Host "   Asegúrate de que todos los archivos Docker estén presentes"
    exit 1
}

# Global variables
$UseGPU = $false
$DockerInstalled = $false

# Function to check Docker installation
function Test-Docker {
    Write-Host "🔍 Verificando Docker..." -ForegroundColor Cyan

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Docker no está instalado" -ForegroundColor Red
        Write-Host ""
        Write-Host "🚀 Opciones de instalación:" -ForegroundColor Yellow
        Write-Host "   1. Descargar Docker Desktop (recomendado)"
        Write-Host "   2. Instrucciones manuales"
        Write-Host "   3. Continuar sin Docker (modo local)"

        $dockerOption = Read-Host "Selecciona una opción (1-3)"

        switch ($dockerOption) {
            1 {
                Install-DockerDesktop
            }
            2 {
                Show-DockerInstructions
                exit 1
            }
            3 {
                Write-Host "🔄 Iniciando en modo local..." -ForegroundColor Yellow
                & ".\start-msnai.ps1" @args
                exit 0
            }
            default {
                Write-Host "❌ Opción no válida" -ForegroundColor Red
                exit 1
            }
        }
    }
    else {
        $dockerVersion = (docker --version).Split(' ')[2]
        Write-Host "✅ Docker instalado: $dockerVersion" -ForegroundColor Green
        $script:DockerInstalled = $true
    }

    # Check if Docker is running
    try {
        docker info | Out-Null
        Write-Host "✅ Docker está ejecutándose" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Docker no está ejecutándose" -ForegroundColor Red
        Write-Host "   Inicia Docker Desktop e intenta nuevamente"
        exit 1
    }

    # Check Docker Compose
    try {
        if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
            Write-Host "✅ Docker Compose disponible (standalone)" -ForegroundColor Green
        }
        elseif ((docker compose version) -match "version") {
            Write-Host "✅ Docker Compose disponible (plugin)" -ForegroundColor Green
        }
        else {
            throw "Docker Compose not found"
        }
    }
    catch {
        Write-Host "❌ Docker Compose no está disponible" -ForegroundColor Red
        Write-Host "   Instala Docker Desktop que incluye Docker Compose"
        exit 1
    }
}

# Function to install Docker Desktop
function Install-DockerDesktop {
    Write-Host "📦 Instalando Docker Desktop..." -ForegroundColor Green

    Write-Host "🌐 Abriendo página de descarga de Docker Desktop..."
    Start-Process "https://www.docker.com/products/docker-desktop"

    Write-Host ""
    Write-Host "📋 Instrucciones de instalación:" -ForegroundColor Yellow
    Write-Host "   1. Descarga Docker Desktop desde la página que se abrió"
    Write-Host "   2. Ejecuta el instalador como administrador"
    Write-Host "   3. Reinicia tu computadora si es necesario"
    Write-Host "   4. Inicia Docker Desktop"
    Write-Host "   5. Ejecuta este script nuevamente"
    Write-Host ""

    Read-Host "Presiona Enter para continuar después de instalar Docker Desktop"

    # Re-check Docker
    Test-Docker
}

# Function to show manual Docker installation instructions
function Show-DockerInstructions {
    Write-Host ""
    Write-Host "📖 Instrucciones de instalación manual de Docker:" -ForegroundColor Yellow
    Write-Host "================================================="
    Write-Host ""
    Write-Host "🪟 Windows 10/11 Pro, Enterprise, Education:"
    Write-Host "   1. Habilitar Hyper-V y Containers en Windows Features"
    Write-Host "   2. Descargar Docker Desktop: https://www.docker.com/products/docker-desktop"
    Write-Host "   3. Instalar como administrador"
    Write-Host "   4. Reiniciar si es necesario"
    Write-Host ""
    Write-Host "🪟 Windows 10/11 Home:"
    Write-Host "   1. Habilitar WSL 2 (Windows Subsystem for Linux)"
    Write-Host "   2. Descargar Docker Desktop: https://www.docker.com/products/docker-desktop"
    Write-Host "   3. Instalar con backend WSL 2"
    Write-Host ""
    Write-Host "💡 Después de instalar, ejecuta este script nuevamente"
}

# Function to check GPU support
function Test-GPUSupport {
    Write-Host "🎮 Verificando soporte de GPU..." -ForegroundColor Cyan

    try {
        $gpuInfo = Get-WmiObject -Class Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" }

        if ($gpuInfo) {
            Write-Host "✅ GPU NVIDIA detectada: $($gpuInfo.Name)" -ForegroundColor Green

            # Check if nvidia-smi is available
            if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
                Write-Host "✅ NVIDIA drivers instalados" -ForegroundColor Green

                # Test Docker GPU access
                try {
                    $testResult = docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu22.04 nvidia-smi 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "✅ Docker GPU support configurado" -ForegroundColor Green
                        $script:UseGPU = $true
                    }
                    else {
                        Write-Host "⚠️ Docker GPU support no disponible" -ForegroundColor Yellow
                        Write-Host "   Para habilitar GPU: Instala NVIDIA Container Toolkit"
                        $script:UseGPU = $false
                    }
                }
                catch {
                    Write-Host "⚠️ Error probando GPU en Docker" -ForegroundColor Yellow
                    $script:UseGPU = $false
                }
            }
            else {
                Write-Host "⚠️ NVIDIA drivers no encontrados" -ForegroundColor Yellow
                $script:UseGPU = $false
            }
        }
        else {
            Write-Host "ℹ️ GPU NVIDIA no detectada, usando solo CPU" -ForegroundColor Cyan
            $script:UseGPU = $false
        }
    }
    catch {
        Write-Host "ℹ️ No se pudo detectar GPU, usando solo CPU" -ForegroundColor Cyan
        $script:UseGPU = $false
    }
}

# Function to setup environment
function Set-Environment {
    Write-Host "⚙️ Configurando entorno Docker..." -ForegroundColor Cyan

    # Create .env file for Docker Compose
    $envContent = @"
# MSN-AI Docker Environment Configuration
MSN_AI_VERSION=1.0.0
MSN_AI_PORT=8000
COMPOSE_PROJECT_NAME=msn-ai
DOCKER_BUILDKIT=1
"@

    # Add GPU configuration if available
    if ($UseGPU) {
        $envContent += "`nGPU_SUPPORT=true"
    }
    else {
        $envContent += "`nGPU_SUPPORT=false"
    }

    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-Host "✅ Archivo de entorno creado" -ForegroundColor Green
}

# Function to build and start containers
function Start-Containers {
    Write-Host "🏗️ Construyendo e iniciando contenedores..." -ForegroundColor Cyan

    # Build images
    Write-Host "📦 Construyendo imagen MSN-AI..." -ForegroundColor Yellow

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
        Write-Host "❌ Error construyendo la imagen" -ForegroundColor Red
        exit 1
    }

    # Start services
    Write-Host "🚀 Iniciando servicios..." -ForegroundColor Green

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
        Write-Host "❌ Error iniciando los servicios" -ForegroundColor Red
        exit 1
    }

    Write-Host "✅ Contenedores iniciados correctamente" -ForegroundColor Green
}

# Function to wait for services
function Wait-ForServices {
    Write-Host "⏳ Esperando que los servicios estén listos..." -ForegroundColor Yellow

    $maxAttempts = 30
    $attempt = 1

    while ($attempt -le $maxAttempts) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8000/msn-ai.html" -UseBasicParsing -TimeoutSec 2
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ MSN-AI está listo" -ForegroundColor Green
                break
            }
        }
        catch {
            # Service not ready yet
        }

        Write-Host "⏳ Intento $attempt/$maxAttempts..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        $attempt++
    }

    if ($attempt -gt $maxAttempts) {
        Write-Host "⚠️ Timeout esperando los servicios" -ForegroundColor Yellow
        Write-Host "   Verifica los logs con el comando mostrado en el estado"
    }
}

# Function to open application
function Open-Application {
    Write-Host "🌐 Abriendo MSN-AI en el navegador..." -ForegroundColor Cyan

    $url = "http://localhost:8000/msn-ai.html"

    # Try different browsers
    $browsers = @(
        "C:\Program Files\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        "C:\Program Files\Mozilla Firefox\firefox.exe",
        "C:\Program Files (x86)\Mozilla Firefox\firefox.exe",
        "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
    )

    $browserFound = $false
    foreach ($browser in $browsers) {
        if (Test-Path $browser) {
            Start-Process -FilePath $browser -ArgumentList $url
            $browserFound = $true
            break
        }
    }

    if (-not $browserFound) {
        # Try default browser
        Start-Process $url
    }
}

# Function to show status and logs
function Show-Status {
    Write-Host ""
    Write-Host "🎉 ¡MSN-AI Docker está ejecutándose!" -ForegroundColor Green
    Write-Host "===================================="
    Write-Host "📱 URL: http://localhost:8000/msn-ai.html" -ForegroundColor Yellow
    Write-Host "🐳 Contenedores:" -ForegroundColor Cyan

    if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
        docker-compose -f docker/docker-compose.yml ps
    }
    else {
        docker compose -f docker/docker-compose.yml ps
    }

    Write-Host ""
    Write-Host "💡 Comandos útiles:" -ForegroundColor Yellow

    if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
        Write-Host "   🔍 Ver logs:        docker-compose -f docker/docker-compose.yml logs -f"
        Write-Host "   ⏹️ Detener:         docker-compose -f docker/docker-compose.yml down"
        Write-Host "   🔄 Reiniciar:       docker-compose -f docker/docker-compose.yml restart"
        Write-Host "   📊 Estado:          docker-compose -f docker/docker-compose.yml ps"
    }
    else {
        Write-Host "   🔍 Ver logs:        docker compose -f docker/docker-compose.yml logs -f"
        Write-Host "   ⏹️ Detener:         docker compose -f docker/docker-compose.yml down"
        Write-Host "   🔄 Reiniciar:       docker compose -f docker/docker-compose.yml restart"
        Write-Host "   📊 Estado:          docker compose -f docker/docker-compose.yml ps"
    }

    Write-Host ""
    Write-Host "⚠️ DETENCIÓN CORRECTA:" -ForegroundColor Red
    if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
        Write-Host "   docker-compose -f docker/docker-compose.yml down"
    }
    else {
        Write-Host "   docker compose -f docker/docker-compose.yml down"
    }

    Write-Host ""
    Write-Host "🔧 Datos persistentes en volumes de Docker" -ForegroundColor Cyan
    Write-Host "📧 Soporte: alan.mac.arthur.garcia.diaz@gmail.com" -ForegroundColor Yellow
}

# Function for cleanup
function Stop-Services {
    Write-Host ""
    Write-Host "🧹 Deteniendo contenedores MSN-AI..." -ForegroundColor Cyan

    try {
        if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
            docker-compose -f docker/docker-compose.yml down
        }
        else {
            docker compose -f docker/docker-compose.yml down
        }

        Write-Host "✅ Contenedores detenidos correctamente" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ Error deteniendo contenedores" -ForegroundColor Yellow
    }

    Write-Host "👋 ¡Gracias por usar MSN-AI v1.0.0!" -ForegroundColor Cyan
}

# Register cleanup function for Ctrl+C
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Stop-Services }

# Main execution function
function Main {
    param($Arguments)

    Write-Host "🚀 Iniciando MSN-AI en modo Docker..." -ForegroundColor Cyan

    # Check Docker installation
    Test-Docker

    # Check GPU support
    Test-GPUSupport

    # Setup environment
    Set-Environment

    # Start containers
    Start-Containers

    # Wait for services
    Wait-ForServices

    # Open application (if not --no-browser flag)
    if ($Arguments -notcontains "--no-browser") {
        Open-Application
    }

    # Show status
    Show-Status

    # Keep script running for signal handling
    if ($Arguments -contains "--daemon") {
        Write-Host "🔄 Modo daemon activado. Presiona Ctrl+C para detener." -ForegroundColor Green
        try {
            while ($true) {
                Start-Sleep -Seconds 1
            }
        }
        catch {
            # User pressed Ctrl+C
        }
    }
    else {
        Write-Host "💡 Script completado. Los contenedores continúan ejecutándose." -ForegroundColor Green
        if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
            Write-Host "   Para detenerlos: docker-compose -f docker/docker-compose.yml down"
        }
        else {
            Write-Host "   Para detenerlos: docker compose -f docker/docker-compose.yml down"
        }
    }
}

# Parse command line arguments and show help
if ($args.Count -gt 0 -and ($args[0] -eq "--help" -or $args[0] -eq "-h")) {
    Write-Host "MSN-AI Docker - Opciones de uso:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  .\start-msnai-docker.ps1                    Iniciar con navegador automático"
    Write-Host "  .\start-msnai-docker.ps1 --no-browser      Iniciar sin abrir navegador"
    Write-Host "  .\start-msnai-docker.ps1 --daemon          Mantener script activo"
    Write-Host "  .\start-msnai-docker.ps1 --help            Mostrar esta ayuda"
    Write-Host ""
    exit 0
}

# Run main function
Main $args

Write-Host ""
Write-Host "🏁 MSN-AI v1.0.0 Docker - Script completado" -ForegroundColor Cyan
Write-Host "📧 ¿Problemas? Contacta: alan.mac.arthur.garcia.diaz@gmail.com" -ForegroundColor Yellow
Write-Host "⚖️ Software libre bajo GPL-3.0" -ForegroundColor Green
