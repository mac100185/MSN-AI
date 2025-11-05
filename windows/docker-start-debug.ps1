# Docker Debug Mode Startup Script for MSN-AI - Windows
# Version: 1.0.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Start MSN-AI Docker with full debug logging and verbose output

Write-Host "[INFO] MSN-AI v2.1.0 - Docker Debug Mode" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "[EMAIL] Desarrollado por: Alan Mac-Arthur García Díaz" -ForegroundColor Green
Write-Host "[LICENSE] Licencia: GPL-3.0" -ForegroundColor Yellow
Write-Host "[DEBUG] Modo: DEBUG COMPLETO" -ForegroundColor Red
Write-Host "====================================" -ForegroundColor Cyan
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
    Write-Host "[ERROR] Error: No se encuentra msn-ai.html en $(Get-Location)" -ForegroundColor Red
    Write-Host "   Archivos encontrados:" -ForegroundColor Yellow
    Get-ChildItem | Select-Object -First 10 | Format-Table Name, Length
    Write-Host ""
    Write-Host "[INFO] Asegúrate de ejecutar este script desde:" -ForegroundColor Yellow
    Write-Host "   $ProjectRoot\windows\docker-start-debug.ps1" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host "[OK] Proyecto MSN-AI detectado correctamente" -ForegroundColor Green
Write-Host ""

# Create debug log directory
$DebugLogDir = Join-Path $ProjectRoot "docker\logs\debug"
New-Item -ItemType Directory -Path $DebugLogDir -Force | Out-Null
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$DebugLogFile = Join-Path $DebugLogDir "debug_$Timestamp.log"

Write-Host "[NOTE] Log de debug: $DebugLogFile" -ForegroundColor Cyan
Write-Host ""

# Function to log with timestamp
function Log-Debug {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $DebugLogFile -Value $logMessage
}

# Start logging
Log-Debug "========================================="
Log-Debug "MSN-AI Docker Debug Mode Started"
Log-Debug "========================================="
Log-Debug ""

# System Information
Log-Debug "=== INFORMACIÓN DEL SISTEMA ==="
Log-Debug "Usuario: $env:USERNAME"
Log-Debug "Hostname: $env:COMPUTERNAME"
Log-Debug "OS: $((Get-CimInstance Win32_OperatingSystem).Caption)"
Log-Debug "Fecha: $(Get-Date)"
Log-Debug ""

# Memory and CPU info
Log-Debug "=== RECURSOS DEL SISTEMA ==="
$cpu = (Get-WmiObject Win32_Processor).NumberOfLogicalProcessors
$memory = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
Log-Debug "CPU cores: $cpu"
Log-Debug "Memoria total: $memory GB"

$disk = Get-PSDrive C | Select-Object Used, Free
$diskUsed = [math]::Round($disk.Used / 1GB, 2)
$diskFree = [math]::Round($disk.Free / 1GB, 2)
Log-Debug "Disco C: Usado: ${diskUsed}GB, Libre: ${diskFree}GB"
Log-Debug ""

# Docker version and info
Log-Debug "=== DOCKER INFORMATION ==="
try {
    $dockerVersion = docker --version
    Log-Debug $dockerVersion
    Log-Debug ""
    Log-Debug "Docker info:"
    docker info 2>&1 | ForEach-Object { Add-Content -Path $DebugLogFile -Value $_ }
    docker info
}
catch {
    Log-Debug "[ERROR] Error obteniendo información de Docker: $_"
    exit 1
}
Log-Debug ""

# Check docker-compose
Log-Debug "=== DOCKER COMPOSE ==="
try {
    $composeVersion = docker compose version 2>&1
    Log-Debug "Usando: docker compose (plugin)"
    Log-Debug $composeVersion
    $DockerComposeCmd = "docker compose"
}
catch {
    Log-Debug "[ERROR] Docker Compose no encontrado"
    exit 1
}
Log-Debug ""

# Clean up any existing containers
Log-Debug "=== LIMPIEZA DE CONTENEDORES PREVIOS ==="
Log-Debug "Deteniendo contenedores existentes..."
try {
    Set-Location (Join-Path $ProjectRoot "docker")
    & docker compose down 2>&1 | ForEach-Object { Add-Content -Path $DebugLogFile -Value $_ }
    & docker compose down
    Set-Location $ProjectRoot
}
catch {
    Log-Debug "[WARN]  Error limpiando contenedores: $_"
}
Log-Debug ""

# Show current containers and images
Log-Debug "=== ESTADO ACTUAL ==="
Log-Debug "Contenedores:"
docker ps -a | ForEach-Object { Add-Content -Path $DebugLogFile -Value $_ }
docker ps -a
Log-Debug ""
Log-Debug "Imágenes:"
docker images | ForEach-Object { Add-Content -Path $DebugLogFile -Value $_ }
docker images
Log-Debug ""
Log-Debug "Volúmenes MSN-AI:"
docker volume ls | Select-String "msn-ai" | ForEach-Object {
    Add-Content -Path $DebugLogFile -Value $_
    Write-Host $_
}
Log-Debug ""

# Build with full verbosity
Log-Debug "=== CONSTRUCCIÓN DE IMAGEN (MODO VERBOSE) ==="
Log-Debug "Iniciando build con --progress=plain y --no-cache..."
Log-Debug ""

Write-Host "[WARN]  ATENCIÓN: La construcción en modo debug es más lenta pero muestra todos los detalles" -ForegroundColor Yellow
Write-Host "   Presiona Ctrl+C para cancelar" -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Seconds 3

# Enable debug mode in container
$env:DEBUG = "1"
$env:DOCKER_BUILDKIT = "1"
$env:BUILDKIT_PROGRESS = "plain"

# Build command with full output
Set-Location (Join-Path $ProjectRoot "docker")
$buildCmd = "docker compose build --no-cache --progress=plain"
Log-Debug "Comando: $buildCmd"
Log-Debug ""

Write-Host "[BUILD]  Construyendo imagen..." -ForegroundColor Cyan
try {
    & docker compose build --no-cache --progress=plain 2>&1 | Tee-Object -FilePath $DebugLogFile -Append
    $buildSuccess = $?
    if ($buildSuccess) {
        Log-Debug ""
        Log-Debug "[OK] Build completado exitosamente"
    }
    else {
        throw "Build failed"
    }
}
catch {
    Log-Debug ""
    Log-Debug "[ERROR] Build falló: $_"
    Log-Debug "[NOTE] Log completo guardado en: $DebugLogFile"
    Set-Location $ProjectRoot
    Read-Host "Presiona Enter para salir"
    exit 1
}
Log-Debug ""

# Start containers with verbose output
Log-Debug "=== INICIO DE CONTENEDORES (MODO VERBOSE) ==="
Log-Debug "Iniciando servicios con logs en tiempo real..."
Log-Debug ""

$composeCmd = "docker compose up --remove-orphans"
Log-Debug "Comando: $composeCmd"
Log-Debug ""

Write-Host "[START] Iniciando contenedores en modo debug..." -ForegroundColor Green
Write-Host "   Los logs se mostrarán en tiempo real" -ForegroundColor Gray
Write-Host "   Presiona Ctrl+C para detener (limpiará contenedores)" -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Seconds 2

# Cleanup function
$cleanupScript = {
    Write-Host ""
    Write-Host "[STOP] Deteniendo contenedores..." -ForegroundColor Yellow
    Set-Location (Join-Path $ProjectRoot "docker")
    docker compose down 2>&1 | Out-Null
    Set-Location $ProjectRoot
    Write-Host "[OK] Debug session terminada" -ForegroundColor Green
    Write-Host "[NOTE] Log completo: $DebugLogFile" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[STATUS] Resumen del debug:" -ForegroundColor Cyan
    Write-Host "   Log guardado en: $DebugLogFile" -ForegroundColor Gray
    $logSize = [math]::Round((Get-Item $DebugLogFile).Length / 1MB, 2)
    Write-Host "   Tamaño: $logSize MB" -ForegroundColor Gray
    Write-Host ""
}

# Register cleanup on exit
Register-EngineEvent PowerShell.Exiting -Action $cleanupScript | Out-Null

# Start services (this will block and show all logs)
Log-Debug "========================================="
Log-Debug "LOGS EN TIEMPO REAL:"
Log-Debug "========================================="

try {
    & docker compose up --remove-orphans 2>&1 | Tee-Object -FilePath $DebugLogFile -Append
    $composeExit = $LASTEXITCODE
}
catch {
    $composeExit = 1
    Log-Debug "[ERROR] Error ejecutando compose up: $_"
}

Set-Location $ProjectRoot

# If we get here, containers stopped on their own
Log-Debug ""
Log-Debug "[WARN]  Contenedores se detuvieron"
Log-Debug "   Código de salida: $composeExit"
Log-Debug ""
Log-Debug "[NOTE] Log completo guardado en: $DebugLogFile"

if ($composeExit -ne 0) {
    Write-Host ""
    Write-Host "[ERROR] Los contenedores se detuvieron con errores" -ForegroundColor Red
    Write-Host "[NOTE] Revisa el log completo: $DebugLogFile" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[INFO] Últimos errores encontrados:" -ForegroundColor Cyan
    Get-Content $DebugLogFile | Select-String -Pattern "error|fail|exception|fatal" -CaseSensitive:$false | Select-Object -Last 50
    Write-Host ""
}

Read-Host "Presiona Enter para salir"
exit $composeExit
