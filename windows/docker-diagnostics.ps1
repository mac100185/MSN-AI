# Docker Diagnostics and Log Collection Script for Windows
# Version: 1.0.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Comprehensive Docker diagnostics and log collection for MSN-AI on Windows

Write-Host "[INFO] MSN-AI - Diagnóstico Docker Completo" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[EMAIL] Desarrollado por: Alan Mac-Arthur García Díaz" -ForegroundColor Green
Write-Host "[LICENSE] Licencia: GPL-3.0" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
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
    Write-Host "   $ProjectRoot\windows\docker-diagnostics.ps1" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host "[OK] Proyecto MSN-AI detectado correctamente" -ForegroundColor Green
Write-Host ""

# Create diagnostics directory with timestamp
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$DiagDir = Join-Path $ProjectRoot "diagnostics_$Timestamp"

Write-Host "[FOLDER] Creando directorio de diagnóstico: $DiagDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $DiagDir -Force | Out-Null

$DiagLogFile = Join-Path $DiagDir "diagnostics.log"

# Function to print section header
function Print-Section {
    param([string]$Title)

    $separator = "========================================"
    Write-Host ""
    Write-Host $separator -ForegroundColor Yellow
    Write-Host $Title -ForegroundColor White
    Write-Host $separator -ForegroundColor Yellow
    Write-Host ""

    Add-Content -Path $DiagLogFile -Value ""
    Add-Content -Path $DiagLogFile -Value $separator
    Add-Content -Path $DiagLogFile -Value $Title
    Add-Content -Path $DiagLogFile -Value $separator
    Add-Content -Path $DiagLogFile -Value ""
}

# Function to run diagnostic command
function Run-Diagnostic {
    param(
        [string]$Description,
        [scriptblock]$Command,
        [string]$OutputFile
    )

    Write-Host "▶ $Description" -ForegroundColor Cyan
    $outPath = Join-Path $DiagDir $OutputFile

    try {
        $output = & $Command 2>&1
        $output | Out-File -FilePath $outPath -Encoding UTF8
        Write-Host "  [OK] Completado: $OutputFile" -ForegroundColor Green
        Add-Content -Path $DiagLogFile -Value "▶ $Description - Completado"
    }
    catch {
        "Error: $_" | Out-File -FilePath $outPath -Encoding UTF8
        Write-Host "  [WARN]  Error ejecutando comando (guardado en $OutputFile)" -ForegroundColor Yellow
        Add-Content -Path $DiagLogFile -Value "▶ $Description - Error: $_"
    }

    Write-Host ""
}

# Start diagnostics
Write-Host "[INFO] Iniciando recopilación de diagnósticos..." -ForegroundColor Cyan
Add-Content -Path $DiagLogFile -Value "[DATE] Fecha: $(Get-Date)"
Add-Content -Path $DiagLogFile -Value "[COMPUTER]  Host: $env:COMPUTERNAME"
Add-Content -Path $DiagLogFile -Value "[USER] Usuario: $env:USERNAME"
Add-Content -Path $DiagLogFile -Value ""

# System Information
Print-Section "1. INFORMACIÓN DEL SISTEMA"
Run-Diagnostic "Sistema operativo" { Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer } "system_info.txt"
Run-Diagnostic "Información de CPU" { Get-WmiObject Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors } "system_cpu.txt"
Run-Diagnostic "Memoria del sistema" { Get-WmiObject Win32_ComputerSystem | Select-Object TotalPhysicalMemory } "system_memory.txt"
Run-Diagnostic "Espacio en disco" { Get-PSDrive -PSProvider FileSystem | Select-Object Name, Used, Free } "system_disk.txt"
Run-Diagnostic "Procesos del sistema" { Get-Process | Sort-Object CPU -Descending | Select-Object -First 50 } "system_processes.txt"

# Docker Installation
Print-Section "2. INSTALACIÓN DE DOCKER"
Run-Diagnostic "Versión de Docker" { docker --version } "docker_version.txt"
Run-Diagnostic "Información de Docker" { docker info } "docker_info.txt"
Run-Diagnostic "Docker Compose version" { docker compose version } "docker_compose_version.txt"
Run-Diagnostic "Plugins de Docker" { docker plugin ls } "docker_plugins.txt"

# Docker System Status
Print-Section "3. ESTADO DEL SISTEMA DOCKER"
Run-Diagnostic "Espacio usado por Docker" { docker system df } "docker_system_df.txt"

# Docker Networks
Print-Section "4. REDES DE DOCKER"
Run-Diagnostic "Lista de redes" { docker network ls } "docker_networks_list.txt"
Run-Diagnostic "Inspección red msn-ai-network" { docker network inspect msn-ai-network } "docker_network_msnai_inspect.txt"

# Docker Volumes
Print-Section "5. VOLÚMENES DE DOCKER"
Run-Diagnostic "Lista de volúmenes" { docker volume ls } "docker_volumes_list.txt"
Run-Diagnostic "Inspección volumen msn-ai-data" { docker volume inspect msn-ai-data } "docker_volume_data_inspect.txt"
Run-Diagnostic "Inspección volumen msn-ai-ollama-data" { docker volume inspect msn-ai-ollama-data } "docker_volume_ollama_inspect.txt"
Run-Diagnostic "Inspección volumen msn-ai-chats" { docker volume inspect msn-ai-chats } "docker_volume_chats_inspect.txt"
Run-Diagnostic "Inspección volumen msn-ai-logs" { docker volume inspect msn-ai-logs } "docker_volume_logs_inspect.txt"

# Docker Images
Print-Section "6. IMÁGENES DE DOCKER"
Run-Diagnostic "Lista de imágenes" { docker images -a } "docker_images_list.txt"
Run-Diagnostic "Historial imagen MSN-AI" { docker history msn-ai-app 2>$null } "docker_image_history_msnai.txt"
Run-Diagnostic "Historial imagen Ollama" { docker history ollama/ollama:latest 2>$null } "docker_image_history_ollama.txt"
Run-Diagnostic "Inspección imagen MSN-AI" { docker inspect msn-ai-app 2>$null } "docker_image_inspect_msnai.txt"

# Docker Containers
Print-Section "7. CONTENEDORES DE DOCKER"
Run-Diagnostic "Contenedores en ejecución" { docker ps } "docker_containers_running.txt"
Run-Diagnostic "Todos los contenedores" { docker ps -a } "docker_containers_all.txt"
Run-Diagnostic "Inspección contenedor msn-ai-app" { docker inspect msn-ai-app } "docker_container_inspect_msnai.txt"
Run-Diagnostic "Inspección contenedor msn-ai-ollama" { docker inspect msn-ai-ollama } "docker_container_inspect_ollama.txt"
Run-Diagnostic "Inspección contenedor msn-ai-setup" { docker inspect msn-ai-setup } "docker_container_inspect_setup.txt"
Run-Diagnostic "Stats de contenedores" { docker stats --no-stream } "docker_container_stats.txt"

# Container Logs
Print-Section "8. LOGS DE CONTENEDORES"
Write-Host "[NOTE] Extrayendo logs de contenedores..." -ForegroundColor Cyan

# MSN-AI App logs
$containers = docker ps -a --format "{{.Names}}" 2>$null
if ($containers -contains "msn-ai-app") {
    Write-Host "  Extrayendo logs de msn-ai-app..." -ForegroundColor Gray
    docker logs msn-ai-app 2>&1 | Out-File -FilePath (Join-Path $DiagDir "logs_msnai_app.txt") -Encoding UTF8
    docker logs --tail 100 msn-ai-app 2>&1 | Out-File -FilePath (Join-Path $DiagDir "logs_msnai_app_last100.txt") -Encoding UTF8
    Write-Host "  [OK] Logs de msn-ai-app guardados" -ForegroundColor Green
} else {
    Write-Host "  [WARN]  Contenedor msn-ai-app no existe" -ForegroundColor Yellow
    "Contenedor no existe" | Out-File -FilePath (Join-Path $DiagDir "logs_msnai_app.txt") -Encoding UTF8
}

# Ollama logs
if ($containers -contains "msn-ai-ollama") {
    Write-Host "  Extrayendo logs de msn-ai-ollama..." -ForegroundColor Gray
    docker logs msn-ai-ollama 2>&1 | Out-File -FilePath (Join-Path $DiagDir "logs_ollama.txt") -Encoding UTF8
    docker logs --tail 100 msn-ai-ollama 2>&1 | Out-File -FilePath (Join-Path $DiagDir "logs_ollama_last100.txt") -Encoding UTF8
    Write-Host "  [OK] Logs de msn-ai-ollama guardados" -ForegroundColor Green
} else {
    Write-Host "  [WARN]  Contenedor msn-ai-ollama no existe" -ForegroundColor Yellow
    "Contenedor no existe" | Out-File -FilePath (Join-Path $DiagDir "logs_ollama.txt") -Encoding UTF8
}

# Setup logs
if ($containers -contains "msn-ai-setup") {
    Write-Host "  Extrayendo logs de msn-ai-setup..." -ForegroundColor Gray
    docker logs msn-ai-setup 2>&1 | Out-File -FilePath (Join-Path $DiagDir "logs_setup.txt") -Encoding UTF8
    Write-Host "  [OK] Logs de msn-ai-setup guardados" -ForegroundColor Green
} else {
    Write-Host "  [WARN]  Contenedor msn-ai-setup no existe" -ForegroundColor Yellow
    "Contenedor no existe" | Out-File -FilePath (Join-Path $DiagDir "logs_setup.txt") -Encoding UTF8
}

Write-Host ""

# Docker Compose Status
Print-Section "9. ESTADO DE DOCKER COMPOSE"
if (Test-Path "docker\docker-compose.yml") {
    Write-Host "  Archivo docker-compose.yml encontrado" -ForegroundColor Gray
    Copy-Item "docker\docker-compose.yml" -Destination (Join-Path $DiagDir "docker-compose.yml.bak")
    Write-Host "  [OK] Copia de docker-compose.yml guardada" -ForegroundColor Green

    Run-Diagnostic "Estado de servicios (docker-compose)" { Set-Location docker; docker compose ps } "docker_compose_ps.txt"
    Run-Diagnostic "Configuración de Compose" { Set-Location docker; docker compose config } "docker_compose_config.txt"
    Set-Location $ProjectRoot
} else {
    Write-Host "  [WARN]  Archivo docker-compose.yml no encontrado" -ForegroundColor Yellow
}

# Project Structure
Print-Section "10. ESTRUCTURA DEL PROYECTO"
Run-Diagnostic "Archivos en directorio raíz" { Get-ChildItem -Force } "project_root_files.txt"
Run-Diagnostic "Archivos en directorio docker" { Get-ChildItem docker\ -Force } "project_docker_files.txt"

# Environment Variables
Print-Section "11. VARIABLES DE ENTORNO"
Write-Host "  Extrayendo variables de entorno relevantes..." -ForegroundColor Gray
Get-ChildItem Env: | Where-Object { $_.Name -match "docker|compose|ollama|msn" } | Out-File -FilePath (Join-Path $DiagDir "environment_vars.txt") -Encoding UTF8
Write-Host "  [OK] Variables de entorno guardadas" -ForegroundColor Green

# Network Connectivity
Print-Section "12. CONECTIVIDAD DE RED"
Run-Diagnostic "Puertos en uso" { netstat -ano | Select-String "LISTENING" } "network_ports.txt"
Run-Diagnostic "Conexiones establecidas" { netstat -ano | Select-String "ESTABLISHED" } "network_connections.txt"

# Test Docker Connectivity
Write-Host "  Probando conectividad con Docker..." -ForegroundColor Gray
$connectivityOutput = Join-Path $DiagDir "docker_connectivity.txt"
"=== Pruebas de conectividad ===" | Out-File -FilePath $connectivityOutput -Encoding UTF8

try {
    $testPort8000 = Test-NetConnection -ComputerName localhost -Port 8000 -WarningAction SilentlyContinue
    "Puerto 8000 (MSN-AI): $($testPort8000.TcpTestSucceeded)" | Out-File -FilePath $connectivityOutput -Append -Encoding UTF8

    $testPort11434 = Test-NetConnection -ComputerName localhost -Port 11434 -WarningAction SilentlyContinue
    "Puerto 11434 (Ollama): $($testPort11434.TcpTestSucceeded)" | Out-File -FilePath $connectivityOutput -Append -Encoding UTF8
}
catch {
    "Error probando conectividad: $_" | Out-File -FilePath $connectivityOutput -Append -Encoding UTF8
}

Write-Host "  [OK] Pruebas de conectividad completadas" -ForegroundColor Green

# Health Checks
Print-Section "13. VERIFICACIONES DE SALUD"
Write-Host "  Ejecutando health checks..." -ForegroundColor Gray
$healthOutput = Join-Path $DiagDir "health_checks.txt"
"=== Health Status de Contenedores ===" | Out-File -FilePath $healthOutput -Encoding UTF8
docker ps --format "table {{.Names}}\t{{.Status}}" | Out-File -FilePath $healthOutput -Append -Encoding UTF8
Write-Host "  [OK] Health checks completados" -ForegroundColor Green

# Resource Usage
Print-Section "14. USO DE RECURSOS"
Run-Diagnostic "Uso de CPU y memoria por Docker" { docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" } "docker_resource_usage.txt"

# Ollama Specific Diagnostics
Print-Section "15. DIAGNÓSTICOS ESPECÍFICOS DE OLLAMA"
if ($containers -contains "msn-ai-ollama") {
    Write-Host "  Ejecutando diagnósticos de Ollama..." -ForegroundColor Gray

    # Ollama version
    docker exec msn-ai-ollama ollama --version 2>&1 | Out-File -FilePath (Join-Path $DiagDir "ollama_version.txt") -Encoding UTF8

    # Ollama models
    docker exec msn-ai-ollama ollama list 2>&1 | Out-File -FilePath (Join-Path $DiagDir "ollama_models.txt") -Encoding UTF8

    # Ollama API test
    docker exec msn-ai-ollama curl -s http://localhost:11434/api/tags 2>&1 | Out-File -FilePath (Join-Path $DiagDir "ollama_api_test.txt") -Encoding UTF8

    Write-Host "  [OK] Diagnósticos de Ollama completados" -ForegroundColor Green
} else {
    Write-Host "  [WARN]  Contenedor de Ollama no está en ejecución" -ForegroundColor Yellow
    "Contenedor no en ejecución" | Out-File -FilePath (Join-Path $DiagDir "ollama_diagnostics.txt") -Encoding UTF8
}

# Error Analysis
Print-Section "16. ANÁLISIS DE ERRORES"
Write-Host "  Buscando errores comunes..." -ForegroundColor Gray
$errorOutput = Join-Path $DiagDir "error_analysis.txt"
"=== Análisis de errores en logs ===" | Out-File -FilePath $errorOutput -Encoding UTF8

if (Test-Path (Join-Path $DiagDir "logs_msnai_app.txt")) {
    "`n--- Errores en logs de MSN-AI App ---" | Out-File -FilePath $errorOutput -Append -Encoding UTF8
    Get-Content (Join-Path $DiagDir "logs_msnai_app.txt") | Select-String -Pattern "error|fail|exception|fatal" -CaseSensitive:$false | Select-Object -Last 20 | Out-File -FilePath $errorOutput -Append -Encoding UTF8
}

if (Test-Path (Join-Path $DiagDir "logs_ollama.txt")) {
    "`n--- Errores en logs de Ollama ---" | Out-File -FilePath $errorOutput -Append -Encoding UTF8
    Get-Content (Join-Path $DiagDir "logs_ollama.txt") | Select-String -Pattern "error|fail|exception|fatal" -CaseSensitive:$false | Select-Object -Last 20 | Out-File -FilePath $errorOutput -Append -Encoding UTF8
}

Write-Host "  [OK] Análisis de errores completado" -ForegroundColor Green

# Summary Report
Print-Section "17. RESUMEN EJECUTIVO"
$summaryOutput = Join-Path $DiagDir "RESUMEN.txt"

$summary = @"
=== RESUMEN DE DIAGNÓSTICO MSN-AI ===
Fecha: $(Get-Date)
Usuario: $env:USERNAME
Host: $env:COMPUTERNAME

--- Estado de Docker ---
"@

try {
    docker info | Out-Null 2>&1
    $dockerVersion = docker --version
    $summary += "`n[OK] Docker daemon en ejecución`n   Versión: $dockerVersion`n"
}
catch {
    $summary += "`n[ERROR] Docker daemon no está en ejecución`n"
}

$summary += "`n--- Estado de Contenedores ---`n"

if ($containers -contains "msn-ai-app") {
    $status = docker ps --filter name=msn-ai-app --format "{{.Status}}"
    $summary += "[OK] msn-ai-app: $status`n"
} else {
    $summary += "[ERROR] msn-ai-app: No encontrado`n"
}

if ($containers -contains "msn-ai-ollama") {
    $status = docker ps --filter name=msn-ai-ollama --format "{{.Status}}"
    $summary += "[OK] msn-ai-ollama: $status`n"
} else {
    $summary += "[ERROR] msn-ai-ollama: No encontrado`n"
}

$summary += "`n--- Conectividad ---`n"

try {
    $test8000 = Test-NetConnection -ComputerName localhost -Port 8000 -WarningAction SilentlyContinue
    if ($test8000.TcpTestSucceeded) {
        $summary += "[OK] MSN-AI Web (puerto 8000): Accesible`n"
    } else {
        $summary += "[ERROR] MSN-AI Web (puerto 8000): No accesible`n"
    }

    $test11434 = Test-NetConnection -ComputerName localhost -Port 11434 -WarningAction SilentlyContinue
    if ($test11434.TcpTestSucceeded) {
        $summary += "[OK] Ollama API (puerto 11434): Accesible`n"
    } else {
        $summary += "[ERROR] Ollama API (puerto 11434): No accesible`n"
    }
}
catch {
    $summary += "[WARN]  Error probando conectividad`n"
}

$summary += "`n--- Recursos del Sistema ---`n"
$cpu = (Get-WmiObject Win32_Processor).NumberOfLogicalProcessors
$memory = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
$summary += "CPU: $cpu núcleos`n"
$summary += "RAM Total: $memory GB`n"

$summary += "`n--- Volúmenes ---`n"
$volumes = docker volume ls --filter name=msn-ai 2>$null
if ($volumes) {
    $summary += $volumes
} else {
    $summary += "No se encontraron volúmenes`n"
}

$summary += "`n=== FIN DEL RESUMEN ===`n"

$summary | Out-File -FilePath $summaryOutput -Encoding UTF8

Write-Host $summary -ForegroundColor Cyan
Add-Content -Path $DiagLogFile -Value $summary

# Create ZIP archive
Print-Section "18. EMPAQUETADO FINAL"
Write-Host "[PACKAGE] Creando archivo comprimido..." -ForegroundColor Cyan

$zipFile = Join-Path $ProjectRoot "msn-ai-diagnostics-$Timestamp.zip"
try {
    Compress-Archive -Path $DiagDir -DestinationPath $zipFile -Force
    $zipSize = [math]::Round((Get-Item $zipFile).Length / 1MB, 2)
    Write-Host "[OK] Archivo de diagnóstico creado: $zipFile" -ForegroundColor Green
    Write-Host "   Tamaño: $zipSize MB" -ForegroundColor Gray
}
catch {
    Write-Host "[ERROR] Error creando archivo comprimido: $_" -ForegroundColor Red
}

# Final Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "[OK] DIAGNÓSTICO COMPLETADO" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "[FOLDER] Directorio de diagnóstico: $DiagDir" -ForegroundColor Cyan
Write-Host "[PACKAGE] Archivo comprimido: $zipFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "[STATUS] Archivos generados:" -ForegroundColor Yellow
$fileCount = (Get-ChildItem $DiagDir).Count
Write-Host "   Total: $fileCount archivos" -ForegroundColor Gray
Write-Host ""
Write-Host "[INFO] Para revisar el resumen ejecutivo:" -ForegroundColor Yellow
Write-Host "   Get-Content $summaryOutput" -ForegroundColor Gray
Write-Host ""
Write-Host "[INFO] Para ver los logs completos:" -ForegroundColor Yellow
Write-Host "   Get-Content $DiagLogFile" -ForegroundColor Gray
Write-Host ""
Write-Host "[EMAIL] Si necesitas soporte, envía el archivo:" -ForegroundColor Yellow
Write-Host "   $zipFile" -ForegroundColor Gray
Write-Host ""
Write-Host "[SUCCESS] ¡Diagnóstico completado exitosamente!" -ForegroundColor Green
Write-Host ""
Read-Host "Presiona Enter para salir"
