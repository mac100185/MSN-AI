# start-msnai.ps1 - Script de inicio para MSN-AI en Windows
# Version: 1.0.0
# Autor: Alan Mac-Arthur Garcia Diaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# Licencia: GNU General Public License v3.0
# Descripcion: Inicia MSN-AI con verificaciones automaticas en Windows

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "     MSN-AI v1.0.0 - Iniciando aplicacion" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Desarrollado por: Alan Mac-Arthur Garcia Diaz" -ForegroundColor Green
Write-Host "Licencia: GPL-3.0" -ForegroundColor Yellow
Write-Host "Email: alan.mac.arthur.garcia.diaz@gmail.com" -ForegroundColor Yellow
Write-Host "GitHub: https://github.com/mac100185/MSN-AI" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verificar si estamos en el directorio correcto
if (-not (Test-Path "msn-ai.html")) {
    Write-Host "ERROR: No se encuentra msn-ai.html" -ForegroundColor Red
    Write-Host "Asegurate de ejecutar este script desde el directorio MSN-AI" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 1
}

# Variables globales para procesos
$script:ServerProcess = $null
$script:OllamaProcess = $null
$script:BrowserName = ""
$script:BrowserPath = ""
$script:ServerUrl = ""
$script:ServerPort = 0

# Funcion para verificar Ollama
function Test-Ollama {
    Write-Host "Verificando Ollama..." -ForegroundColor Cyan

    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        Write-Host "Ollama no esta instalado" -ForegroundColor Yellow
        $install = Read-Host "Deseas instalarlo automaticamente? (s/n)"

        if ($install -eq "s" -or $install -eq "S") {
            Write-Host "Instalando Ollama..." -ForegroundColor Green
            try {
                $tempPath = "$env:TEMP\OllamaSetup.exe"
                Invoke-WebRequest -Uri "https://ollama.com/download/OllamaSetup.exe" -OutFile $tempPath
                Start-Process -FilePath $tempPath -Wait
                Write-Host "Ollama instalado correctamente" -ForegroundColor Green
                Write-Host "Reinicia PowerShell para usar Ollama" -ForegroundColor Yellow
            }
            catch {
                Write-Host "Error instalando Ollama: $_" -ForegroundColor Red
                return $false
            }
        }
        else {
            Write-Host "Continuando sin Ollama (funcionalidad limitada)" -ForegroundColor Yellow
            return $false
        }
    }

    # Verificar si Ollama esta ejecutandose
    $ollamaRunning = Get-Process -Name "ollama*" -ErrorAction SilentlyContinue
    if (-not $ollamaRunning) {
        Write-Host "Iniciando Ollama..." -ForegroundColor Yellow
        try {
            $script:OllamaProcess = Start-Process -FilePath "ollama" -ArgumentList "serve" -PassThru -WindowStyle Hidden
            Start-Sleep -Seconds 5

            $ollamaRunning = Get-Process -Name "ollama*" -ErrorAction SilentlyContinue
            if ($ollamaRunning) {
                Write-Host "Ollama iniciado correctamente" -ForegroundColor Green
            }
            else {
                Write-Host "Ollama puede no haberse iniciado correctamente" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Error iniciando Ollama: $_" -ForegroundColor Yellow
            Write-Host "Intenta iniciarlo manualmente con: ollama serve" -ForegroundColor Yellow
            return $false
        }
    }
    else {
        Write-Host "Ollama ya esta ejecutandose" -ForegroundColor Green
    }

    # Verificar modelos disponibles
    Write-Host "Verificando modelos de IA..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    try {
        $modelsOutput = & ollama list 2>&1
        $modelLines = $modelsOutput | Select-String -Pattern "^\w" | Where-Object { $_ -notmatch "^NAME" }
        $modelCount = ($modelLines | Measure-Object).Count

        if ($modelCount -eq 0) {
            Write-Host "No hay modelos instalados" -ForegroundColor Yellow
            $installModel = Read-Host "Deseas instalar mistral:7b (recomendado)? (s/n)"

            if ($installModel -eq "s" -or $installModel -eq "S") {
                Write-Host "Descargando mistral:7b (esto puede tardar varios minutos)..." -ForegroundColor Green
                & ollama pull mistral:7b
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Modelo instalado correctamente" -ForegroundColor Green
                }
                else {
                    Write-Host "Error instalando modelo" -ForegroundColor Red
                    return $false
                }
            }
            else {
                Write-Host "Continuando sin modelos (funcionalidad limitada)" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "Modelos disponibles: $modelCount" -ForegroundColor Green
            $modelLines | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        }
    }
    catch {
        Write-Host "No se pudieron verificar los modelos: $_" -ForegroundColor Yellow
    }

    return $true
}

# Funcion para detectar navegador
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

# Funcion para verificar si un puerto esta disponible
function Test-PortAvailable {
    param([int]$Port)

    try {
        $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
        return $null -eq $connection
    }
    catch {
        return $true
    }
}

# Funcion para iniciar servidor web
function Start-WebServer {
    Write-Host "Iniciando servidor web local..." -ForegroundColor Cyan

    $script:ServerPort = 8000
    while (-not (Test-PortAvailable -Port $script:ServerPort)) {
        $script:ServerPort++
        if ($script:ServerPort -gt 8020) {
            Write-Host "No se encontro puerto disponible" -ForegroundColor Red
            return $false
        }
    }

    Write-Host "Puerto disponible: $script:ServerPort" -ForegroundColor Yellow

    $pythonCmd = $null
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $pythonCmd = "python"
    }
    elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
        $pythonCmd = "python3"
    }
    elseif (Get-Command py -ErrorAction SilentlyContinue) {
        $pythonCmd = "py"
    }

    if ($pythonCmd) {
        try {
            Write-Host "Usando $pythonCmd para el servidor..." -ForegroundColor Green

            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $pythonCmd
            $psi.Arguments = "-m http.server $script:ServerPort"
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true

            $script:ServerProcess = New-Object System.Diagnostics.Process
            $script:ServerProcess.StartInfo = $psi
            $script:ServerProcess.Start() | Out-Null

            Start-Sleep -Seconds 2

            if (-not $script:ServerProcess.HasExited) {
                $script:ServerUrl = "http://localhost:$script:ServerPort"
                Write-Host "Servidor iniciado correctamente" -ForegroundColor Green
                return $true
            }
            else {
                Write-Host "El servidor se detuvo inesperadamente" -ForegroundColor Red
                return $false
            }
        }
        catch {
            Write-Host "Error iniciando servidor Python: $_" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "Python no esta instalado" -ForegroundColor Yellow
        Write-Host "Instala Python desde: https://www.python.org/downloads/" -ForegroundColor Yellow
        Write-Host "O usa el modo archivo directo (opcion 2)" -ForegroundColor Yellow
        return $false
    }
}

# Funcion para abrir aplicacion
function Open-Application {
    param([string]$url)

    Write-Host "Abriendo MSN-AI..." -ForegroundColor Cyan

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

# Funcion de limpieza
function Stop-Services {
    Write-Host ""
    Write-Host "Limpiando procesos MSN-AI..." -ForegroundColor Cyan

    if ($null -ne $script:ServerProcess -and -not $script:ServerProcess.HasExited) {
        Write-Host "Deteniendo servidor web..." -ForegroundColor Yellow
        try {
            $script:ServerProcess.Kill()
            $script:ServerProcess.WaitForExit(5000)
            Write-Host "Servidor web detenido" -ForegroundColor Green
        }
        catch {
            Write-Host "Error deteniendo servidor web: $_" -ForegroundColor Yellow
        }
    }

    if ($null -ne $script:OllamaProcess -and -not $script:OllamaProcess.HasExited) {
        Write-Host "Deteniendo Ollama..." -ForegroundColor Yellow
        try {
            $script:OllamaProcess.Kill()
            $script:OllamaProcess.WaitForExit(5000)
            Write-Host "Ollama detenido" -ForegroundColor Green
        }
        catch {
            Write-Host "Error deteniendo Ollama: $_" -ForegroundColor Yellow
        }
    }

    Write-Host "Limpieza completada" -ForegroundColor Green
    Write-Host "Gracias por usar MSN-AI v1.0.0!" -ForegroundColor Cyan
}

# Registrar manejador de salida
try {
    $null = Register-EngineEvent PowerShell.Exiting -Action {
        Stop-Services
    }
}
catch {
    # Si falla el registro, no es critico
}

# ===================
# FLUJO PRINCIPAL
# ===================

Write-Host "Iniciando verificaciones del sistema..." -ForegroundColor Cyan
Write-Host ""

$ollamaOk = Test-Ollama
Write-Host ""

$browserFound = Find-Browser
Write-Host ""

Write-Host "Selecciona metodo de inicio:" -ForegroundColor Cyan
Write-Host ""

$autoMode = $false
if ($args.Count -gt 0) {
    if ($args[0] -eq "--auto" -or $args[0] -eq "-auto" -or $args[0] -eq "auto") {
        $autoMode = $true
    }
}

if ($autoMode) {
    Write-Host "Modo automatico activado" -ForegroundColor Green
    $method = "1"
}
else {
    Write-Host "  1) Servidor local (recomendado)"
    Write-Host "  2) Archivo directo (puede tener limitaciones)"
    Write-Host "  3) Solo verificar sistema"
    Write-Host ""
    $method = Read-Host "Selecciona una opcion (1-3)"

    if ([string]::IsNullOrWhiteSpace($method)) {
        $method = "1"
    }
}

Write-Host ""

switch ($method) {
    "1" {
        Write-Host "Iniciando con servidor local..." -ForegroundColor Cyan
        $serverStarted = Start-WebServer

        if ($serverStarted -and $null -ne $script:ServerProcess) {
            Write-Host ""
            $fullUrl = "$script:ServerUrl/msn-ai.html"
            Open-Application $fullUrl

            Write-Host ""
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host "     MSN-AI v1.0.0 esta ejecutandose!" -ForegroundColor Green
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "URL: $fullUrl" -ForegroundColor Yellow
            if ($ollamaOk) {
                Write-Host "Ollama: Funcionando" -ForegroundColor Green
            }
            else {
                Write-Host "Ollama: No disponible" -ForegroundColor Yellow
            }
            Write-Host "Navegador: $script:BrowserName" -ForegroundColor Green
            Write-Host ""
            Write-Host "Instrucciones:" -ForegroundColor Yellow
            Write-Host "  - Manten esta ventana abierta" -ForegroundColor White
            Write-Host "  - Para detener: presiona Ctrl+C" -ForegroundColor White
            Write-Host ""
            Write-Host "Servidor activo en puerto $script:ServerPort" -ForegroundColor Green
            Write-Host "Presiona Ctrl+C para detener" -ForegroundColor Green
            Write-Host ""

            try {
                while ($true) {
                    if ($script:ServerProcess.HasExited) {
                        Write-Host ""
                        Write-Host "El servidor se detuvo inesperadamente" -ForegroundColor Yellow
                        break
                    }
                    Start-Sleep -Seconds 1
                }
            }
            catch {
                Write-Host ""
            }
            finally {
                Stop-Services
            }
        }
        else {
            Write-Host ""
            Write-Host "No se pudo iniciar el servidor web" -ForegroundColor Red
            Write-Host "Instala Python desde: https://www.python.org/downloads/" -ForegroundColor Yellow
            Write-Host "O ejecuta de nuevo y elige opcion 2" -ForegroundColor Yellow
            Write-Host ""
        }
    }

    "2" {
        Write-Host "Iniciando en modo archivo directo..." -ForegroundColor Cyan
        $currentPath = (Get-Location).Path
        $directUrl = "file:///$($currentPath.Replace('\', '/'))/msn-ai.html"

        Write-Host "URL: $directUrl" -ForegroundColor Gray
        Write-Host ""

        $opened = Open-Application $directUrl

        if (-not $opened) {
            Write-Host ""
            Write-Host "Intenta abrir manualmente:" -ForegroundColor Yellow
            Write-Host "  $currentPath\msn-ai.html" -ForegroundColor White
        }

        Write-Host ""
        Write-Host "============================================" -ForegroundColor Cyan
        Write-Host "     MSN-AI v1.0.0 - Modo archivo" -ForegroundColor Green
        Write-Host "============================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Advertencia: Algunas funciones pueden estar limitadas" -ForegroundColor Yellow
        Write-Host ""
        if ($ollamaOk) {
            Write-Host "Ollama: Funcionando" -ForegroundColor Green
        }
        else {
            Write-Host "Ollama: No disponible" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "Si tienes problemas, usa el modo servidor (opcion 1)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Puedes cerrar esta ventana de forma segura" -ForegroundColor Green
        Write-Host ""
    }

    "3" {
        Write-Host "Verificacion del sistema:" -ForegroundColor Cyan
        Write-Host "============================================"
        Write-Host ""
        Write-Host "MSN-AI: Archivo principal encontrado" -ForegroundColor Green
        if ($ollamaOk) {
            Write-Host "Ollama: Funcionando correctamente" -ForegroundColor Green
        }
        else {
            Write-Host "Ollama: No disponible" -ForegroundColor Red
        }
        Write-Host "Navegador: $script:BrowserName detectado" -ForegroundColor Green
        Write-Host ""
        Write-Host "Para iniciar MSN-AI:" -ForegroundColor Yellow
        Write-Host "  .\start-msnai.ps1" -ForegroundColor White
        Write-Host "  O en modo automatico:" -ForegroundColor White
        Write-Host "  .\start-msnai.ps1 --auto" -ForegroundColor White
        Write-Host ""

        if (-not $ollamaOk) {
            Write-Host "Advertencia: Ollama no esta disponible" -ForegroundColor Yellow
            Write-Host "Instala Ollama desde: https://ollama.com/download" -ForegroundColor White
            Write-Host ""
        }
    }

    default {
        Write-Host "Opcion no valida: '$method'" -ForegroundColor Red
        Write-Host "Por favor, elige 1, 2 o 3" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "     Script completado" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Problemas? alan.mac.arthur.garcia.diaz@gmail.com" -ForegroundColor Yellow
Write-Host "Licencia: GPL-3.0" -ForegroundColor Green
Write-Host "GitHub: https://github.com/mac100185/MSN-AI" -ForegroundColor Cyan
Write-Host ""
