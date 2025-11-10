# MSN-AI Docker - Cloud Models Installation Helper for Windows
# Version: 1.0.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Helper script to install Ollama cloud models with signin

Write-Host "[CLOUD]  MSN-AI - Instalador de Modelos Cloud" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "[EMAIL] Desarrollado por: Alan Mac-Arthur García Díaz" -ForegroundColor Green
Write-Host "[LICENSE] Licencia: GPL-3.0" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is available
try {
    docker --version | Out-Null
} catch {
    Write-Host "[ERROR] Docker no está instalado" -ForegroundColor Red
    Read-Host "Presiona Enter para salir"
    exit 1
}

# Check if msn-ai-ollama container is running
$containers = docker ps --format "{{.Names}}" 2>$null
if ($containers -notcontains "msn-ai-ollama") {
    Write-Host "[ERROR] El contenedor msn-ai-ollama no está en ejecución" -ForegroundColor Red
    Write-Host ""
    Write-Host "[INFO] Inicia MSN-AI primero:" -ForegroundColor Yellow
    Write-Host "   .\windows\start-msnai-docker.ps1" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host "[OK] Contenedor msn-ai-ollama detectado" -ForegroundColor Green
Write-Host ""

# Available cloud models
$CloudModels = @(
    "qwen3-vl:235b-cloud"
    "gpt-oss:120b-cloud"
    "qwen3-coder:480b-cloud"
    "deepseek-v3.1:671b-cloud"
    "gpt-oss:20b-cloud"
    "qwen3-vl:235b-instruct-cloud"
    "minimax-m2:cloud"
    "kimi-k2:1t-cloud"
    "kimi-k2-thinking:cloud"
    "glm-4.6:cloud"
)

Write-Host "[PACKAGE] Modelos cloud disponibles:" -ForegroundColor Cyan
for ($i = 0; $i -lt $CloudModels.Count; $i++) {
    Write-Host "   $($i+1). $($CloudModels[$i])" -ForegroundColor Gray
}
Write-Host ""

# Check signin status
Write-Host "[INFO] Verificando estado de autenticación..." -ForegroundColor Cyan
$SigninStatus = docker exec msn-ai-ollama ollama list 2>&1

# Try to verify signin with a cloud model check
Write-Host "[INFO] Verificando acceso a modelos cloud..." -ForegroundColor Cyan
$CloudTest = docker exec msn-ai-ollama ollama show qwen3-vl:235b-cloud 2>&1

$NeedsSignin = $false
if ($SigninStatus -match "You need to be signed in") {
    $NeedsSignin = $true
}
elseif ($CloudTest -match "You need to be signed in") {
    $NeedsSignin = $true
}

if ($NeedsSignin) {
    Write-Host "[WARN]  No has hecho signin con Ollama o la sesión expiró" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[MENU] PROCESO DE SIGNIN:" -ForegroundColor Cyan
    Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "1.  Este script generará un enlace de autenticación" -ForegroundColor White
    Write-Host ""
    Write-Host "2.  Abre el enlace en tu navegador" -ForegroundColor White
    Write-Host ""
    Write-Host "3.  Inicia sesión en ollama.com (crea cuenta si no tienes)" -ForegroundColor White
    Write-Host ""
    Write-Host "4.  Aprueba el acceso del contenedor" -ForegroundColor White
    Write-Host ""
    Write-Host "5.  Vuelve a esta ventana y espera la confirmación" -ForegroundColor White
    Write-Host ""
    Write-Host "[WARN]  IMPORTANTE: El signin puede expirar con el tiempo" -ForegroundColor Yellow
    Write-Host "   Si los modelos dejan de funcionar, repite este proceso" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
    Write-Host ""

    $doSignin = Read-Host "¿Deseas hacer signin ahora? (s/N)"

    if ($doSignin -notmatch '^[sS]$') {
        Write-Host ""
        Write-Host "[ERROR] Signin cancelado" -ForegroundColor Red
        Write-Host ""
        Write-Host "[INFO] Puedes hacer signin manualmente con:" -ForegroundColor Yellow
        Write-Host "   docker exec -it msn-ai-ollama ollama signin" -ForegroundColor Cyan
        Write-Host ""
        Read-Host "Presiona Enter para salir"
        exit 0
    }

    Write-Host ""
    Write-Host "[KEY] Iniciando proceso de signin..." -ForegroundColor Cyan
    Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "[WARN]  IMPORTANTE: Abre el enlace que aparecerá a continuación" -ForegroundColor Yellow
    Write-Host "   en tu navegador para completar el signin" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
    Write-Host ""
    Start-Sleep -Seconds 3

    # Run signin in interactive mode
    docker exec -it msn-ai-ollama ollama signin

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[ERROR] Error durante el signin" -ForegroundColor Red
        Write-Host ""
        Write-Host "[INFO] Intenta manualmente:" -ForegroundColor Yellow
        Write-Host "   docker exec -it msn-ai-ollama ollama signin" -ForegroundColor Cyan
        Write-Host ""
        Read-Host "Presiona Enter para salir"
        exit 1
    }

    Write-Host ""
    Write-Host "[OK] Signin completado" -ForegroundColor Green
    Write-Host ""

    # Wait a moment for signin to propagate
    Write-Host "[WAIT] Esperando propagación del signin..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2

    # Verify signin worked
    $VerifyTest = docker exec msn-ai-ollama ollama list 2>&1
    if ($VerifyTest -match "You need to be signed in") {
        Write-Host ""
        Write-Host "[WARN]  Signin no se completó correctamente" -ForegroundColor Yellow
        Write-Host "   Intenta de nuevo o verifica en el navegador" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Presiona Enter para salir"
        exit 1
    }

    Write-Host "[OK] Signin verificado correctamente" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "[OK] Signin activo - acceso a modelos cloud disponible" -ForegroundColor Green
    Write-Host ""
}

# Check which models are already installed
Write-Host "[INFO] Verificando modelos instalados..." -ForegroundColor Cyan
$InstalledModels = docker exec msn-ai-ollama ollama list 2>&1
Write-Host ""

foreach ($model in $CloudModels) {
    if ($InstalledModels -match [regex]::Escape($model)) {
        Write-Host "   [OK] $model (ya instalado)" -ForegroundColor Green
    } else {
        Write-Host "   [SKIP]  $model (no instalado)" -ForegroundColor Yellow
    }
}
Write-Host ""

# Ask which models to install
Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
Write-Host "[DOWNLOAD] INSTALACIÓN DE MODELOS" -ForegroundColor Cyan
Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "¿Qué deseas instalar?" -ForegroundColor White
Write-Host ""
Write-Host "1) Instalar todos los modelos cloud" -ForegroundColor Cyan
Write-Host "2) Instalar modelos individuales" -ForegroundColor Cyan
Write-Host "3) Solo verificar modelos instalados" -ForegroundColor Cyan
Write-Host "4) Salir" -ForegroundColor Cyan
Write-Host ""

$installOption = Read-Host "Selecciona una opción (1-4)"

switch ($installOption) {
    "1" {
        Write-Host ""
        Write-Host "[DOWNLOAD] Instalando todos los modelos cloud..." -ForegroundColor Cyan
        Write-Host ""

        foreach ($model in $CloudModels) {
            if ($InstalledModels -match [regex]::Escape($model)) {
                Write-Host "[SKIP]  Saltando $model (ya instalado)" -ForegroundColor Yellow
                Write-Host ""
            } else {
                Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
                Write-Host "[DOWNLOAD] Instalando: $model" -ForegroundColor Cyan
                Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
                Write-Host ""

                docker exec msn-ai-ollama ollama pull $model

                if ($LASTEXITCODE -eq 0) {
                    Write-Host ""
                    Write-Host "[OK] $model instalado correctamente" -ForegroundColor Green
                    Write-Host ""
                } else {
                    Write-Host ""
                    Write-Host "[ERROR] Error instalando $model" -ForegroundColor Red
                    Write-Host ""
                }
            }
        }
    }

    "2" {
        Write-Host ""
        Write-Host "[PACKAGE] Selecciona los modelos a instalar:" -ForegroundColor Cyan
        Write-Host ""

        for ($i = 0; $i -lt $CloudModels.Count; $i++) {
            $model = $CloudModels[$i]
            $num = $i + 1

            if ($InstalledModels -match [regex]::Escape($model)) {
                Write-Host "$num. $model ([OK] ya instalado)" -ForegroundColor Green
            } else {
                Write-Host "$num. $model" -ForegroundColor Gray
            }
        }
        Write-Host ""

        $selected = Read-Host "Ingresa los números separados por espacio (ej: 1 3)"
        $selectedNums = $selected -split '\s+'

        foreach ($numStr in $selectedNums) {
            $num = [int]$numStr

            if ($num -ge 1 -and $num -le $CloudModels.Count) {
                $model = $CloudModels[$num - 1]

                if ($InstalledModels -match [regex]::Escape($model)) {
                    Write-Host "[SKIP]  Saltando $model (ya instalado)" -ForegroundColor Yellow
                    Write-Host ""
                } else {
                    Write-Host ""
                    Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
                    Write-Host "[DOWNLOAD] Instalando: $model" -ForegroundColor Cyan
                    Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
                    Write-Host ""

                    docker exec msn-ai-ollama ollama pull $model

                    if ($LASTEXITCODE -eq 0) {
                        Write-Host ""
                        Write-Host "[OK] $model instalado correctamente" -ForegroundColor Green
                        Write-Host ""
                    } else {
                        Write-Host ""
                        Write-Host "[ERROR] Error instalando $model" -ForegroundColor Red
                        Write-Host ""
                    }
                }
            }
        }
    }

    "3" {
        Write-Host ""
        Write-Host "[STATUS] Modelos instalados actualmente:" -ForegroundColor Cyan
        Write-Host ""
        docker exec msn-ai-ollama ollama list
        Write-Host ""
    }

    "4" {
        Write-Host ""
        Write-Host "[BYE] Saliendo..." -ForegroundColor Cyan
        exit 0
    }

    default {
        Write-Host ""
        Write-Host "[ERROR] Opción no válida" -ForegroundColor Red
        Read-Host "Presiona Enter para salir"
        exit 1
    }
}

# Show final status
Write-Host ""
Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
Write-Host "[STATUS] ESTADO FINAL" -ForegroundColor Cyan
Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Modelos instalados:" -ForegroundColor White
docker exec msn-ai-ollama ollama list
Write-Host ""

# Verify cloud models can actually be accessed
Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
Write-Host "[INFO] VERIFICACIÓN DE ACCESO A MODELOS CLOUD" -ForegroundColor Cyan
Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
Write-Host ""

$CloudAccessOK = $true
foreach ($model in $CloudModels) {
    # Check if model is installed
    $InstalledCheck = docker exec msn-ai-ollama ollama list 2>&1
    if ($InstalledCheck -match [regex]::Escape($model)) {
        # Verify signin is active for this model
        $TestResult = docker exec msn-ai-ollama ollama show $model 2>&1
        if ($TestResult -match "You need to be signed in") {
            Write-Host "[ERROR] $model - Signin requerido (no funcional)" -ForegroundColor Red
            $CloudAccessOK = $false
        } else {
            Write-Host "[OK] $model - Accesible y funcional" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray

if ($CloudAccessOK) {
    Write-Host "[OK] Proceso completado - Todos los modelos funcionando" -ForegroundColor Green
} else {
    Write-Host "[WARN]  Proceso completado - Signin adicional requerido" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Los modelos están instalados pero necesitas signin activo:" -ForegroundColor Yellow
    Write-Host "   docker exec -it msn-ai-ollama ollama signin" -ForegroundColor Cyan
}

Write-Host "=========================================================================================================================================================━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "[INFO] Los modelos cloud ahora están disponibles en MSN-AI" -ForegroundColor Yellow
Write-Host ""
Write-Host "[WARN]  IMPORTANTE: Si los modelos dejan de funcionar:" -ForegroundColor Yellow
Write-Host "   1. Verifica signin: docker exec msn-ai-ollama ollama list" -ForegroundColor White
Write-Host "   2. Si dice 'You need to be signed in', ejecuta:" -ForegroundColor White
Write-Host "      docker exec -it msn-ai-ollama ollama signin" -ForegroundColor Cyan
Write-Host ""
Write-Host "[WEB] Accede a MSN-AI en: http://localhost:8000/msn-ai.html" -ForegroundColor Cyan
Write-Host ""
Read-Host "Presiona Enter para salir"
