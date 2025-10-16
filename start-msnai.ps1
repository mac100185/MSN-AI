# start-msnai.ps1 - Script de inicio para MSN-AI en Windows
# Versión: 1.0.0
# Autor: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# Licencia: GNU General Public License v3.0
# Descripción: Inicia MSN-AI con verificaciones automáticas en Windows

Write-Host "🚀 MSN-AI v1.0.0 - Iniciando aplicación..." -ForegroundColor Cyan
Write-Host "============================================"
Write-Host "📧 Desarrollado por: Alan Mac-Arthur García Díaz" -ForegroundColor Green
Write-Host "⚖️ Licencia: GPL-3.0 | 🔗 alan.mac.arthur.garcia.diaz@gmail.com" -ForegroundColor Yellow
Write-Host "============================================"

# Verificar si estamos en el directorio correcto
if (-not (Test-Path "msn-ai.html")) {
    Write-Host "❌ Error: No se encuentra msn-ai.html" -ForegroundColor Red
    Write-Host "   Asegúrate de ejecutar este script desde el directorio MSN-AI"
    exit 1
}

# Variables globales para procesos
$ServerProcess = $null
$OllamaProcess = $null

# Función para verificar Ollama
function Test-Ollama {
    Write-Host "🔍 Verificando Ollama..." -ForegroundColor Cyan

    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        Write-Host "⚠️  Ollama no está instalado" -ForegroundColor Yellow
        $install = Read-Host "   ¿Deseas instalarlo automáticamente? (s/n)"

        if ($install -eq "s" -or $install -eq "S") {
            Write-Host "📦 Instalando Ollama..." -ForegroundColor Green
            try {
                $tempPath = "$env:TEMP\OllamaSetup.exe"
                Invoke-WebRequest -Uri "https://ollama.com/download/OllamaSetup.exe" -OutFile $tempPath
                Start-Process -FilePath $tempPath -Wait
                Write-Host "✅ Ollama instalado correctamente" -ForegroundColor Green
            }
            catch {
                Write-Host "❌ Error instalando Ollama: $_" -ForegroundColor Red
                return $false
            }
        }
        else {
            Write-Host "⏭️  Continuando sin Ollama (funcionalidad limitada)" -ForegroundColor Yellow
            return $false
        }
    }

    # Verificar si Ollama está ejecutándose
    $ollamaRunning = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
    if (-not $ollamaRunning) {
        Write-Host "🔄 Iniciando Ollama..." -ForegroundColor Yellow
        try {
            $script:OllamaProcess = Start-Process -FilePath "ollama" -ArgumentList "serve" -PassThru -NoNewWindow
            Start-Sleep -Seconds 3

            $ollamaRunning = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
            if ($ollamaRunning) {
                Write-Host "✅ Ollama iniciado correctamente (PID: $($ollamaRunning.Id))" -ForegroundColor Green
            }
            else {
                Write-Host "❌ Error iniciando Ollama" -ForegroundColor Red
                return $false
            }
        }
        catch {
            Write-Host "❌ Error iniciando Ollama: $_" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "✅ Ollama ya está ejecutándose" -ForegroundColor Green
    }

    # Verificar modelos disponibles
    Write-Host "🧠 Verificando modelos de IA..." -ForegroundColor Cyan
    try {
        $models = & ollama list 2>$null | Select-String -Pattern "^\w" | Measure-Object
        $modelCount = $models.Count

        if ($modelCount -eq 0) {
            Write-Host "⚠️  No hay modelos instalados" -ForegroundColor Yellow
            $installModel = Read-Host "   ¿Deseas instalar mistral:7b (recomendado)? (s/n)"

            if ($installModel -eq "s" -or $installModel -eq "S") {
                Write-Host "📥 Descargando mistral:7b..." -ForegroundColor Green
                & ollama pull mistral:7b
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Modelo instalado correctamente" -ForegroundColor Green
                }
                else {
                    Write-Host "❌ Error instalando modelo" -ForegroundColor Red
                    return $false
                }
            }
            else {
                Write-Host "⏭️  Continuando sin modelos (funcionalidad limitada)" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "✅ Modelos disponibles: $modelCount" -ForegroundColor Green
            & ollama list | Select-Object -First 10
        }
    }
    catch {
        Write-Host "⚠️ No se pudieron verificar los modelos" -ForegroundColor Yellow
    }

    return $true
}

# Función para detectar navegador
function Find-Browser {
    Write-Host "🌐 Detectando navegador..." -ForegroundColor Cyan

    # Lista de navegadores comunes en Windows
    $browsers = @(
        @{Name="Chrome"; Path="C:\Program Files\Google\Chrome\Application\chrome.exe"},
        @{Name="Chrome"; Path="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"},
        @{Name="Firefox"; Path="C:\Program Files\Mozilla Firefox\firefox.exe"},
        @{Name="Firefox"; Path="C:\Program Files (x86)\Mozilla Firefox\firefox.exe"},
        @{Name="Edge"; Path="C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"},
        @{Name="Edge"; Path="$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"}
    )

    foreach ($browser in $browsers) {
        if (Test-Path $browser.Path) {
            $script:BrowserName = $browser.Name
            $script:BrowserPath = $browser.Path
            Write-Host "✅ Navegador encontrado: $($browser.Name)" -ForegroundColor Green
            return $true
        }
    }

    # Fallback al navegador por defecto
    $script:BrowserName = "Default"
    $script:BrowserPath = "start"
    Write-Host "⚠️  Usando navegador por defecto" -ForegroundColor Yellow
    return $true
}

# Función para iniciar servidor web
function Start-WebServer {
    Write-Host "🌍 Iniciando servidor web local..." -ForegroundColor Cyan

    # Buscar puerto disponible
    $port = 8000
    while (Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue) {
        $port++
        if ($port -gt 8010) {
            Write-Host "❌ No se encontró puerto disponible" -ForegroundColor Red
            return $false
        }
    }

    Write-Host "📡 Servidor web en puerto: $port" -ForegroundColor Yellow

    # Intentar Python 3 primero, luego Python 2
    if (Get-Command python -ErrorAction SilentlyContinue) {
        try {
            Write-Host "🐍 Usando Python..." -ForegroundColor Green
            $script:ServerProcess = Start-Process -FilePath "python" -ArgumentList "-m", "http.server", "$port" -PassThru -NoNewWindow
            Start-Sleep -Seconds 2

            if (-not $ServerProcess.HasExited) {
                Write-Host "✅ Servidor iniciado (PID: $($ServerProcess.Id))" -ForegroundColor Green
                $script:ServerUrl = "http://localhost:$port"
                return $true
            }
        }
        catch {
            Write-Host "⚠️ Error con Python, intentando método alternativo..." -ForegroundColor Yellow
        }
    }

    # Intentar con PowerShell Web Server como alternativa
    Write-Host "🔧 Usando servidor PowerShell básico..." -ForegroundColor Yellow
    $script:ServerUrl = "file://$((Get-Location).Path)\msn-ai.html"
    Write-Host "⚠️ Modo archivo directo (funcionalidad limitada)" -ForegroundColor Yellow
    return $true
}

# Función para abrir aplicación
function Open-Application {
    param($url)

    Write-Host "🚀 Abriendo MSN-AI..." -ForegroundColor Cyan

    try {
        if ($BrowserName -eq "Default") {
            Start-Process $url
        }
        else {
            Start-Process -FilePath $BrowserPath -ArgumentList "--new-window", "$url/msn-ai.html"
        }
        Write-Host "✅ MSN-AI abierto en el navegador" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ Error abriendo navegador: $_" -ForegroundColor Yellow
        Write-Host "   Abre manualmente: $url/msn-ai.html" -ForegroundColor Yellow
    }
}

# Función de limpieza
function Stop-Services {
    Write-Host ""
    Write-Host "🧹 Limpiando procesos MSN-AI..." -ForegroundColor Cyan
    Write-Host "⚠️ IMPORTANTE: No fuerces el cierre, espera la limpieza completa" -ForegroundColor Yellow

    # Detener servidor web
    if ($ServerProcess -and -not $ServerProcess.HasExited) {
        Write-Host "🛑 Deteniendo servidor web (PID: $($ServerProcess.Id))..." -ForegroundColor Yellow
        try {
            $ServerProcess.Kill()
            $ServerProcess.WaitForExit(5000)
            Write-Host "✅ Servidor web detenido" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️ Error deteniendo servidor web" -ForegroundColor Yellow
        }
    }

    # Detener Ollama solo si fue iniciado por este script
    if ($OllamaProcess -and -not $OllamaProcess.HasExited) {
        Write-Host "🛑 Deteniendo Ollama (PID: $($OllamaProcess.Id))..." -ForegroundColor Yellow
        try {
            $OllamaProcess.Kill()
            $OllamaProcess.WaitForExit(5000)
            Write-Host "✅ Ollama detenido" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️ Error deteniendo Ollama" -ForegroundColor Yellow
        }
    }

    # Verificar procesos restantes
    Write-Host "🔍 Verificando limpieza..." -ForegroundColor Cyan
    $remainingPython = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*http.server*" }
    if ($remainingPython) {
        Write-Host "⚠️ Limpiando servidores Python restantes..." -ForegroundColor Yellow
        $remainingPython | Stop-Process -Force -ErrorAction SilentlyContinue
    }

    Write-Host "✅ Limpieza completada exitosamente" -ForegroundColor Green
    Write-Host "👋 ¡Gracias por usar MSN-AI v1.0.0!" -ForegroundColor Cyan
    Write-Host "📧 Reporta problemas a: alan.mac.arthur.garcia.diaz@gmail.com" -ForegroundColor Yellow
}

# Capturar Ctrl+C para limpieza
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Stop-Services }

# ===================
# FLUJO PRINCIPAL
# ===================

Write-Host "📋 Iniciando verificaciones..." -ForegroundColor Cyan

# 1. Verificar Ollama (opcional pero recomendado)
$ollamaOk = Test-Ollama

# 2. Detectar navegador
$browserFound = Find-Browser

# 3. Decidir método de apertura
Write-Host "🤔 Seleccionando método de inicio..." -ForegroundColor Cyan

if ($args.Count -gt 0 -and $args[0] -eq "--auto") {
    Write-Host "🔄 Modo automático seleccionado" -ForegroundColor Green
    $method = 1
}
else {
    Write-Host "   1) Servidor local (recomendado)"
    Write-Host "   2) Archivo directo (puede tener limitaciones)"
    Write-Host "   3) Solo verificar sistema"
    Write-Host ""
    $method = Read-Host "Selecciona una opción (1-3) o presiona Enter para automático"
    if ([string]::IsNullOrWhiteSpace($method)) {
        $method = 1
    }
}

switch ($method) {
    1 {
        Write-Host "📡 Iniciando con servidor local..." -ForegroundColor Cyan
        $serverStarted = Start-WebServer

        if ($serverStarted -and $ServerProcess) {
            Open-Application $ServerUrl

            Write-Host ""
            Write-Host "🎉 ¡MSN-AI v1.0.0 está ejecutándose!" -ForegroundColor Green
            Write-Host "============================================"
            Write-Host "📱 URL: $ServerUrl/msn-ai.html" -ForegroundColor Yellow
            Write-Host "🔧 Ollama: $(if($ollamaOk){'✅ Funcionando'}else{'⚠️ No disponible'})"
            Write-Host "🌐 Navegador: $BrowserName"
            Write-Host "📧 Desarrollador: Alan Mac-Arthur García Díaz"
            Write-Host ""
            Write-Host "💡 Consejos importantes:" -ForegroundColor Yellow
            Write-Host "   • Mantén esta ventana PowerShell abierta mientras usas MSN-AI"
            Write-Host "   • Presiona Ctrl+C para detener CORRECTAMENTE"
            Write-Host "   • NUNCA cierres PowerShell sin Ctrl+C"
            Write-Host "   • Verifica la conexión con Ollama en la app"
            Write-Host ""
            Write-Host "⚠️ DETENCIÓN SEGURA:" -ForegroundColor Red
            Write-Host "   1. Presiona Ctrl+C en esta ventana PowerShell"
            Write-Host "   2. Espera el mensaje de limpieza completa"
            Write-Host "   3. No fuerces el cierre hasta ver: '✅ Limpieza completada'"
            Write-Host ""
            Write-Host "⏳ Servidor activo... Ctrl+C para detener correctamente" -ForegroundColor Green

            # Mantener servidor activo
            try {
                while (-not $ServerProcess.HasExited) {
                    Start-Sleep -Seconds 1
                }
                Write-Host "⚠️ Servidor web se detuvo inesperadamente" -ForegroundColor Yellow
            }
            catch {
                # Usuario presionó Ctrl+C
            }
        }
        else {
            Write-Host "⚠️ Error con servidor, intentando modo directo..." -ForegroundColor Yellow
            Open-Application "file://$((Get-Location).Path)"
        }
    }

    2 {
        Write-Host "📁 Abriendo archivo directo..." -ForegroundColor Cyan
        $directUrl = "file://$((Get-Location).Path)/msn-ai.html"

        try {
            Start-Process $directUrl
        }
        catch {
            Write-Host "⚠️ Error abriendo archivo. Intenta abrir manualmente:" -ForegroundColor Yellow
            Write-Host "   $directUrl" -ForegroundColor White
        }

        Write-Host ""
        Write-Host "🎉 ¡MSN-AI v1.0.0 abierto!" -ForegroundColor Green
        Write-Host "============================================"
        Write-Host "⚠️  Modo archivo directo (funcionalidad limitada)" -ForegroundColor Yellow
        Write-Host "🔧 Ollama: $(if($ollamaOk){'✅ Funcionando'}else{'⚠️ No disponible'})"
        Write-Host "📧 Soporte: alan.mac.arthur.garcia.diaz@gmail.com"
        Write-Host ""
        Write-Host "💡 Si experimentas problemas, usa el modo servidor (opción 1)" -ForegroundColor Yellow
        Write-Host "⚠️ En este modo no hay procesos que detener manualmente" -ForegroundColor Green
    }

    3 {
        Write-Host "🔍 Solo verificación del sistema:" -ForegroundColor Cyan
        Write-Host "============================================"
        Write-Host "✅ MSN-AI: Archivo encontrado"
        Write-Host "🔧 Ollama: $(if($ollamaOk){'✅ Funcionando'}else{'❌ No disponible'})"
        Write-Host "🌐 Navegador: $BrowserName detectado"
        Write-Host "📧 Desarrollador: Alan Mac-Arthur García Díaz"
        Write-Host "⚖️ Licencia: GPL-3.0"
        Write-Host ""
        Write-Host "💡 Para iniciar la aplicación:" -ForegroundColor Yellow
        Write-Host "   .\start-msnai.ps1 -auto"
        Write-Host ""
        Write-Host "💡 Para detener correctamente (cuando esté ejecutándose):" -ForegroundColor Yellow
        Write-Host "   Ctrl+C en la ventana PowerShell del servidor"
    }

    default {
        Write-Host "❌ Opción no válida" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "🏁 MSN-AI v1.0.0 - Script completado" -ForegroundColor Cyan
Write-Host "📧 ¿Problemas? Contacta: alan.mac.arthur.garcia.diaz@gmail.com" -ForegroundColor Yellow
Write-Host "⚖️ Software libre bajo GPL-3.0" -ForegroundColor Green
