# start-msnai.ps1 - Script de inicio para MSN-AI en Windows
# Version: 1.0.0
# Autor: Alan Mac-Arthur Garcia Diaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# Licencia: GNU General Public License v3.0
# GitHub: https://github.com/mac100185/MSN-AI
# Descripcion: Inicia MSN-AI con verificaciones automaticas en Windows
#
# ============================================
# INSTRUCCIONES DE USO
# ============================================
#
# IMPORTANTE: Si descargaste este archivo de Internet, primero debes desbloquearlo:
#
#   Unblock-File -Path .\start-msnai.ps1
#
# Luego puedes ejecutarlo de las siguientes formas:
#
# 1. Modo automatico (inicia directamente con servidor local):
#   .\start-msnai.ps1 --auto
#   .\start-msnai.ps1 -auto
#   .\start-msnai.ps1 auto
#
# 2. Modo interactivo (te pregunta que opcion elegir):
#   .\start-msnai.ps1
#
# OPCIONES DISPONIBLES:
#   1) Servidor local - Recomendado, requiere Python instalado
#   2) Archivo directo - Sin servidor, puede tener limitaciones CORS
#   3) Solo verificar - Verifica el sistema sin iniciar la aplicacion
#
# REQUISITOS:
#   - Python 3.x (para modo servidor)
#   - Ollama (opcional, para funcionalidad de IA)
#   - Navegador web moderno (Chrome, Edge, Firefox, etc.)
#
# DETENER EL SERVIDOR:
#   Presiona Ctrl+C en la ventana de PowerShell donde se ejecuta el script
#   NO cierres la ventana sin presionar Ctrl+C para evitar procesos huerfanos
#
# ============================================

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
        Write-Host ""
        Write-Host "IMPORTANTE: Ollama requiere instalacion manual" -ForegroundColor Yellow
        Write-Host ""
        $install = Read-Host "Deseas abrir la pagina de descarga de Ollama? (s/n)"

        if ($install -eq "s" -or $install -eq "S") {
            Write-Host ""
            Write-Host "Abriendo pagina de descarga de Ollama..." -ForegroundColor Green
            Start-Process "https://ollama.com/download"
            Write-Host ""
            Write-Host "============================================" -ForegroundColor Yellow
            Write-Host "  INSTRUCCIONES DE INSTALACION DE OLLAMA" -ForegroundColor Yellow
            Write-Host "============================================" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "1. Descarga OllamaSetup.exe desde la pagina que se abrio" -ForegroundColor White
            Write-Host "2. Ejecuta el instalador" -ForegroundColor White
            Write-Host "3. Sigue el asistente de instalacion" -ForegroundColor White
            Write-Host "4. Una vez instalado, CIERRA esta ventana de PowerShell" -ForegroundColor White
            Write-Host "5. Abre una NUEVA ventana de PowerShell" -ForegroundColor White
            Write-Host "6. Navega al directorio MSN-AI" -ForegroundColor White
            Write-Host "7. Ejecuta nuevamente: .\start-msnai.ps1 --auto" -ForegroundColor White
            Write-Host ""
            Write-Host "NOTA: Despues de instalar Ollama, este script debe ejecutarse" -ForegroundColor Yellow
            Write-Host "      en una NUEVA sesion de PowerShell para detectar Ollama." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "============================================" -ForegroundColor Yellow
            Write-Host ""

            $continue = Read-Host "Ya instalaste Ollama y abriste una nueva PowerShell? (s/n)"
            if ($continue -ne "s" -and $continue -ne "S") {
                Write-Host ""
                Write-Host "Por favor, completa la instalacion de Ollama y ejecuta este script nuevamente" -ForegroundColor Yellow
                Write-Host ""
                Read-Host "Presiona Enter para salir"
                exit 0
            }

            # Re-verificar si Ollama esta disponible ahora
            if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
                Write-Host ""
                Write-Host "Ollama aun no esta disponible en esta sesion de PowerShell" -ForegroundColor Red
                Write-Host "Debes CERRAR esta ventana y abrir una NUEVA PowerShell" -ForegroundColor Yellow
                Write-Host ""
                Read-Host "Presiona Enter para salir"
                exit 0
            }
        }
        else {
            Write-Host ""
            Write-Host "Continuando sin Ollama (funcionalidad de IA limitada)" -ForegroundColor Yellow
            Write-Host "La aplicacion funcionara pero no podras chatear con IA" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Para instalar Ollama mas tarde:" -ForegroundColor Cyan
            Write-Host "  1. Ve a: https://ollama.com/download" -ForegroundColor White
            Write-Host "  2. Descarga e instala OllamaSetup.exe" -ForegroundColor White
            Write-Host "  3. Reinicia PowerShell y ejecuta: ollama pull mistral:7b" -ForegroundColor White
            Write-Host ""
            Start-Sleep -Seconds 3
            return $false
        }
    }

    # Verificar si Ollama esta ejecutandose
    $ollamaRunning = Get-Process -Name "ollama*" -ErrorAction SilentlyContinue
    if (-not $ollamaRunning) {
        Write-Host "Iniciando servicio Ollama..." -ForegroundColor Yellow
        try {
            # Iniciar Ollama serve en segundo plano
            $script:OllamaProcess = Start-Process -FilePath "ollama" -ArgumentList "serve" -PassThru -WindowStyle Hidden
            Start-Sleep -Seconds 5

            $ollamaRunning = Get-Process -Name "ollama*" -ErrorAction SilentlyContinue
            if ($ollamaRunning) {
                Write-Host "Ollama iniciado correctamente" -ForegroundColor Green
            }
            else {
                Write-Host "Advertencia: Ollama puede no haberse iniciado correctamente" -ForegroundColor Yellow
                Write-Host "Puedes iniciarlo manualmente con: ollama serve" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Advertencia: No se pudo iniciar Ollama automaticamente" -ForegroundColor Yellow
            Write-Host "Error: $_" -ForegroundColor Yellow
            Write-Host "Intenta iniciarlo manualmente con: ollama serve" -ForegroundColor Yellow
            return $false
        }
    }
    else {
        Write-Host "Ollama ya esta ejecutandose" -ForegroundColor Green
    }

    # Verificar modelos disponibles
    Write-Host "Verificando modelos de IA instalados..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    try {
        $modelsOutput = & ollama list 2>&1
        $modelLines = $modelsOutput | Select-String -Pattern "^\w" | Where-Object { $_ -notmatch "^NAME" }
        $modelCount = ($modelLines | Measure-Object).Count

        # Modelos requeridos por defecto
        $requiredModels = @(
            "qwen3-vl:235b-cloud",
            "gpt-oss:120b-cloud",
            "qwen3-coder:480b-cloud"
        )

        if ($modelCount -eq 0) {
            Write-Host "No hay modelos de IA instalados" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Modelos requeridos por defecto:" -ForegroundColor Cyan
            foreach ($model in $requiredModels) {
                Write-Host "   - $model" -ForegroundColor White
            }
            Write-Host ""
            $installModels = Read-Host "Deseas instalar los modelos requeridos? (s/n)"

            if ($installModels -eq "s" -or $installModels -eq "S") {
                Write-Host ""
                Write-Host "Instalando modelos requeridos..." -ForegroundColor Green
                Write-Host "NOTA: Este proceso puede tardar bastante tiempo dependiendo de tu conexion" -ForegroundColor Yellow
                Write-Host ""

                $installedCount = 0
                $failedCount = 0

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

                Write-Host "==========================================" -ForegroundColor Cyan
                Write-Host "Resumen de instalacion:" -ForegroundColor Yellow
                Write-Host "   Instalados: $installedCount/$($requiredModels.Count)" -ForegroundColor Green
                Write-Host "   Fallidos: $failedCount/$($requiredModels.Count)" -ForegroundColor Red
                Write-Host "==========================================" -ForegroundColor Cyan

                if ($installedCount -eq 0) {
                    Write-Host ""
                    Write-Host "No se pudo instalar ningun modelo" -ForegroundColor Red
                    return $false
                }
            }
            else {
                Write-Host ""
                Write-Host "Continuando sin modelos de IA" -ForegroundColor Yellow
                Write-Host "Puedes instalar modelos mas tarde manualmente" -ForegroundColor Cyan
                Write-Host ""
                Start-Sleep -Seconds 2
            }
        }
        else {
            Write-Host "Modelos de IA disponibles: $modelCount" -ForegroundColor Green
            Write-Host "Modelos instalados:" -ForegroundColor Cyan
            $modelLines | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        }
    }
    catch {
        Write-Host "No se pudieron verificar los modelos: $_" -ForegroundColor Yellow
        Write-Host "El servicio de Ollama puede no estar respondiendo correctamente" -ForegroundColor Yellow
    }

    return $true
}

# Funcion para detectar navegador por defecto del sistema
function Find-Browser {
    Write-Host "Detectando navegador por defecto del sistema..." -ForegroundColor Cyan

    # Intentar obtener el navegador por defecto desde el registro
    try {
        $defaultBrowser = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" -ErrorAction SilentlyContinue
        if ($defaultBrowser) {
            Write-Host "Usando navegador por defecto del sistema" -ForegroundColor Green
            $script:BrowserName = "Default"
            $script:BrowserPath = ""
            return $true
        }
    }
    catch {
        # Si falla, continuar con la detección manual
    }

    # Lista de navegadores comunes para verificar si existen
    $browsers = @(
        @{Name="Edge"; Path="C:\Program Files\Microsoft\Edge\Application\msedge.exe"},
        @{Name="Edge"; Path="C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"},
        @{Name="Chrome"; Path="C:\Program Files\Google\Chrome\Application\chrome.exe"},
        @{Name="Chrome"; Path="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"},
        @{Name="Firefox"; Path="C:\Program Files\Mozilla Firefox\firefox.exe"},
        @{Name="Firefox"; Path="C:\Program Files (x86)\Mozilla Firefox\firefox.exe"},
        @{Name="Brave"; Path="C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"},
        @{Name="Opera"; Path="C:\Program Files\Opera\launcher.exe"}
    )

    $foundBrowsers = @()
    foreach ($browser in $browsers) {
        if (Test-Path $browser.Path) {
            $foundBrowsers += $browser
        }
    }

    # Si se encontró más de un navegador, usar el navegador por defecto del sistema
    if ($foundBrowsers.Count -gt 1) {
        Write-Host "Multiples navegadores detectados. Usando navegador por defecto del sistema" -ForegroundColor Yellow
        $script:BrowserName = "Default"
        $script:BrowserPath = ""
        return $true
    }
    # Si solo hay uno, usarlo
    elseif ($foundBrowsers.Count -eq 1) {
        $script:BrowserName = $foundBrowsers[0].Name
        $script:BrowserPath = $foundBrowsers[0].Path
        Write-Host "Navegador encontrado: $($foundBrowsers[0].Name)" -ForegroundColor Green
        return $true
    }
    # Si no se encontró ninguno, usar el por defecto
    else {
        $script:BrowserName = "Default"
        $script:BrowserPath = ""
        Write-Host "Usando navegador por defecto del sistema" -ForegroundColor Yellow
        return $true
    }
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
            Write-Host "No se encontro puerto disponible (8000-8020 todos ocupados)" -ForegroundColor Red
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
            Write-Host "Usando $pythonCmd para el servidor HTTP..." -ForegroundColor Green

            # Iniciar servidor Python sin capturar salidas (para evitar bloqueos)
            $script:ServerProcess = Start-Process -FilePath $pythonCmd -ArgumentList "-m","http.server","$script:ServerPort" -PassThru -WindowStyle Hidden

            # Esperar mas tiempo para que el servidor se inicie completamente
            Write-Host "Esperando a que el servidor se inicie..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5

            # Verificar que el servidor no se haya detenido
            if ($null -ne $script:ServerProcess -and -not $script:ServerProcess.HasExited) {
                # Intentar hacer una conexion de prueba al servidor
                try {
                    $testUrl = "http://localhost:$script:ServerPort"
                    $response = Invoke-WebRequest -Uri $testUrl -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop

                    if ($response.StatusCode -eq 200) {
                        $script:ServerUrl = $testUrl
                        Write-Host "Servidor HTTP verificado y funcionando correctamente" -ForegroundColor Green
                        return $true
                    }
                }
                catch {
                    Write-Host "Advertencia: El servidor puede no estar respondiendo correctamente" -ForegroundColor Yellow
                    Write-Host "Error: $_" -ForegroundColor Gray
                    # Aun asi, intentamos continuar
                    $script:ServerUrl = "http://localhost:$script:ServerPort"
                    return $true
                }
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
        Write-Host ""
        Write-Host "Python no esta instalado" -ForegroundColor Red
        Write-Host ""
        Write-Host "Necesitas Python para usar el modo servidor (recomendado)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Opciones:" -ForegroundColor Cyan
        Write-Host "  1. Instala Python desde: https://www.python.org/downloads/" -ForegroundColor White
        Write-Host "     Durante la instalacion, marca: 'Add Python to PATH'" -ForegroundColor White
        Write-Host "  2. O usa el modo archivo directo (opcion 2 del menu)" -ForegroundColor White
        Write-Host ""
        return $false
    }
}

# Funcion para abrir aplicacion
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

# Funcion de limpieza
function Stop-Services {
    Write-Host ""
    Write-Host "Deteniendo servicios MSN-AI..." -ForegroundColor Cyan

    if ($null -ne $script:ServerProcess -and -not $script:ServerProcess.HasExited) {
        Write-Host "Deteniendo servidor web..." -ForegroundColor Yellow
        try {
            $script:ServerProcess.Kill()
            $script:ServerProcess.WaitForExit(5000)
            Write-Host "Servidor web detenido" -ForegroundColor Green
        }
        catch {
            Write-Host "Advertencia al detener servidor web: $_" -ForegroundColor Yellow
        }
    }

    if ($null -ne $script:OllamaProcess -and -not $script:OllamaProcess.HasExited) {
        Write-Host "Deteniendo servicio Ollama (iniciado por este script)..." -ForegroundColor Yellow
        try {
            $script:OllamaProcess.Kill()
            $script:OllamaProcess.WaitForExit(5000)
            Write-Host "Ollama detenido" -ForegroundColor Green
        }
        catch {
            Write-Host "Advertencia al detener Ollama: $_" -ForegroundColor Yellow
        }
    }

    Write-Host "Limpieza completada" -ForegroundColor Green
    Write-Host ""
    Write-Host "Gracias por usar MSN-AI v1.0.0!" -ForegroundColor Cyan
    Write-Host "Reporta problemas en: https://github.com/mac100185/MSN-AI/issues" -ForegroundColor Yellow
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
    Write-Host "  1) Servidor local (recomendado, requiere Python)"
    Write-Host "  2) Archivo directo (puede tener limitaciones CORS)"
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
        Write-Host ""
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
                Write-Host "Ollama: No disponible (funcionalidad limitada)" -ForegroundColor Yellow
            }
            Write-Host "Navegador: $script:BrowserName" -ForegroundColor Green
            Write-Host "Puerto: $script:ServerPort" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "IMPORTANTE:" -ForegroundColor Yellow
            Write-Host "  - Manten esta ventana de PowerShell abierta" -ForegroundColor White
            Write-Host "  - Para detener correctamente: presiona Ctrl+C" -ForegroundColor White
            Write-Host "  - NO cierres esta ventana sin presionar Ctrl+C" -ForegroundColor White
            Write-Host ""
            Write-Host "Servidor activo... Esperando (Ctrl+C para detener)" -ForegroundColor Green
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
            Write-Host ""
            Write-Host "Soluciones:" -ForegroundColor Yellow
            Write-Host "  1. Instala Python: https://www.python.org/downloads/" -ForegroundColor White
            Write-Host "  2. Ejecuta de nuevo este script y elige opcion 2 (archivo directo)" -ForegroundColor White
            Write-Host ""
            Read-Host "Presiona Enter para salir"
        }
    }

    "2" {
        Write-Host "Iniciando en modo archivo directo..." -ForegroundColor Cyan
        $currentPath = (Get-Location).Path
        $directUrl = "file:///$($currentPath.Replace('\', '/'))/msn-ai.html"

        Write-Host "Ruta: $currentPath\msn-ai.html" -ForegroundColor Gray
        Write-Host ""

        $opened = Open-Application $directUrl

        if (-not $opened) {
            Write-Host ""
            Write-Host "No se pudo abrir automaticamente" -ForegroundColor Yellow
            Write-Host "Abre manualmente el archivo:" -ForegroundColor Cyan
            Write-Host "  $currentPath\msn-ai.html" -ForegroundColor White
            Write-Host ""
        }

        Write-Host ""
        Write-Host "============================================" -ForegroundColor Cyan
        Write-Host "     MSN-AI v1.0.0 - Modo archivo directo" -ForegroundColor Green
        Write-Host "============================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "ADVERTENCIA: Modo archivo directo" -ForegroundColor Yellow
        Write-Host "Algunas funciones pueden estar limitadas por politicas CORS" -ForegroundColor Yellow
        Write-Host ""
        if ($ollamaOk) {
            Write-Host "Ollama: Funcionando" -ForegroundColor Green
        }
        else {
            Write-Host "Ollama: No disponible" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "Si tienes problemas, usa el modo servidor (opcion 1)" -ForegroundColor Cyan
        Write-Host "Requiere tener Python instalado" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Puedes cerrar esta ventana de forma segura" -ForegroundColor Green
        Write-Host ""
        Read-Host "Presiona Enter para salir"
    }

    "3" {
        Write-Host "Verificacion del sistema completada:" -ForegroundColor Cyan
        Write-Host "============================================"
        Write-Host ""
        Write-Host "MSN-AI: Archivo principal encontrado" -ForegroundColor Green

        if ($ollamaOk) {
            Write-Host "Ollama: Instalado y funcionando" -ForegroundColor Green
        }
        else {
            Write-Host "Ollama: No disponible" -ForegroundColor Red
            Write-Host "  Instala desde: https://ollama.com/download" -ForegroundColor Yellow
        }

        if (Get-Command python -ErrorAction SilentlyContinue) {
            $pythonVersion = python --version 2>&1
            Write-Host "Python: $pythonVersion" -ForegroundColor Green
        }
        else {
            Write-Host "Python: No instalado" -ForegroundColor Yellow
            Write-Host "  Instala desde: https://www.python.org/downloads/" -ForegroundColor Yellow
        }

        Write-Host "Navegador: $script:BrowserName detectado" -ForegroundColor Green
        Write-Host ""
        Write-Host "Para iniciar MSN-AI:" -ForegroundColor Cyan
        Write-Host "  .\start-msnai.ps1 --auto" -ForegroundColor White
        Write-Host ""
        Write-Host "O en modo interactivo:" -ForegroundColor Cyan
        Write-Host "  .\start-msnai.ps1" -ForegroundColor White
        Write-Host ""

        if (-not $ollamaOk) {
            Write-Host "NOTA: Sin Ollama, MSN-AI tendra funcionalidad limitada" -ForegroundColor Yellow
            Write-Host "      No podras usar las funciones de chat con IA" -ForegroundColor Yellow
            Write-Host ""
        }

        Read-Host "Presiona Enter para salir"
    }

    default {
        Write-Host "Opcion no valida: '$method'" -ForegroundColor Red
        Write-Host "Por favor, elige 1, 2 o 3" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Presiona Enter para salir"
        exit 1
    }
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "     Script finalizado" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
