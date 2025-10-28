# Configure Ollama API Key Script for Windows
# Version: 2.1.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Configure OLLAMA_API_KEY for cloud models

Write-Host "🔑 MSN-AI - Configuración de API Key" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "📧 Desarrollado por: Alan Mac-Arthur García Díaz" -ForegroundColor White
Write-Host "⚖️ Licencia: GPL-3.0" -ForegroundColor White
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Detect and change to project root directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Host "🔍 Detectando directorio del proyecto..." -ForegroundColor Cyan
Write-Host "   Script ubicado en: $ScriptDir" -ForegroundColor Gray
Write-Host "   Directorio raíz: $ProjectRoot" -ForegroundColor Gray

# Change to project root
Set-Location $ProjectRoot

Write-Host "   Directorio actual: $(Get-Location)" -ForegroundColor Gray

# Verify we're in the correct directory
if (-not (Test-Path "msn-ai.html")) {
    Write-Host "❌ Error: No se encuentra msn-ai.html en $(Get-Location)" -ForegroundColor Red
    Write-Host "   Archivos encontrados:" -ForegroundColor Yellow
    Get-ChildItem | Select-Object -First 10 | Format-Table Name, Length
    Write-Host ""
    Write-Host "💡 Asegúrate de ejecutar este script desde:" -ForegroundColor Yellow
    Write-Host "   $ProjectRoot\windows\configure-api-key.ps1" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host "✅ Proyecto MSN-AI detectado correctamente" -ForegroundColor Green
Write-Host ""

# Function to validate API key format (basic validation)
function Validate-ApiKey {
    param([string]$Key)

    if ([string]::IsNullOrWhiteSpace($Key)) {
        Write-Host "❌ API Key vacía" -ForegroundColor Red
        return $false
    }

    if ($Key.Length -lt 16) {
        Write-Host "⚠️  API Key parece muy corta (menos de 16 caracteres)" -ForegroundColor Yellow
        $continue = Read-Host "   ¿Continuar de todas formas? (s/N)"
        if ($continue -ne "s" -and $continue -ne "S") {
            return $false
        }
    }

    return $true
}

# Function to configure API key in .env
function Configure-EnvFile {
    param([string]$ApiKey)

    Write-Host "📝 Configurando archivo .env..." -ForegroundColor Yellow

    # Check if .env exists
    if (Test-Path ".env") {
        # Check if OLLAMA_API_KEY already exists
        $envContent = Get-Content ".env"
        $hasApiKey = $envContent | Where-Object { $_ -match "^OLLAMA_API_KEY=" }

        if ($hasApiKey) {
            Write-Host "⚠️  OLLAMA_API_KEY ya existe en .env" -ForegroundColor Yellow
            $overwrite = Read-Host "   ¿Deseas sobrescribirla? (s/N)"

            if ($overwrite -eq "s" -or $overwrite -eq "S") {
                # Replace existing key
                $newContent = $envContent | ForEach-Object {
                    if ($_ -match "^OLLAMA_API_KEY=") {
                        "OLLAMA_API_KEY=$ApiKey"
                    } else {
                        $_
                    }
                }
                $newContent | Set-Content ".env"
                Write-Host "✅ API Key actualizada en .env" -ForegroundColor Green
            } else {
                Write-Host "⏭️  Manteniendo API Key existente" -ForegroundColor Cyan
                return
            }
        } else {
            # Append API key
            Add-Content ".env" "OLLAMA_API_KEY=$ApiKey"
            Write-Host "✅ API Key agregada a .env" -ForegroundColor Green
        }
    } else {
        # Create new .env file
        $envContent = @"
# MSN-AI Environment Configuration
# Generated: $(Get-Date)

# Ollama API Key for cloud models
OLLAMA_API_KEY=$ApiKey

# MSN-AI Configuration
MSN_AI_VERSION=2.1.0
MSN_AI_PORT=8000
COMPOSE_PROJECT_NAME=msn-ai
DOCKER_BUILDKIT=1
"@
        $envContent | Set-Content ".env"
        Write-Host "✅ Archivo .env creado con API Key" -ForegroundColor Green
    }
}

# Function to configure API key in Docker environment
function Configure-Docker {
    Write-Host ""
    Write-Host "🐳 Configuración Docker" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

    # Check if Docker is running
    try {
        docker ps 2>&1 | Out-Null
        $dockerRunning = $true
    } catch {
        $dockerRunning = $false
    }

    if (-not $dockerRunning) {
        Write-Host "⚠️  Docker no está ejecutándose" -ForegroundColor Yellow
        Write-Host "   La configuración se aplicará cuando inicies Docker" -ForegroundColor White
        return
    }

    # Check if MSN-AI containers are running
    $containers = docker ps --filter "name=msn-ai" --format "{{.Names}}" 2>$null

    if ($containers) {
        Write-Host "📦 Contenedores MSN-AI detectados" -ForegroundColor Green
        Write-Host ""
        $restart = Read-Host "¿Deseas reiniciar los contenedores para aplicar la nueva API Key? (s/N)"

        if ($restart -eq "s" -or $restart -eq "S") {
            Write-Host "🔄 Reiniciando contenedores..." -ForegroundColor Yellow

            if (Test-Path "docker/docker-compose.yml") {
                docker compose -f docker/docker-compose.yml restart ollama
                docker compose -f docker/docker-compose.yml restart ai-setup
                Write-Host "✅ Contenedores reiniciados" -ForegroundColor Green
            } else {
                docker restart msn-ai-ollama msn-ai-setup 2>$null
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "⚠️  No se pudieron reiniciar algunos contenedores" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "ℹ️  Recuerda reiniciar los contenedores manualmente:" -ForegroundColor Cyan
            Write-Host "   docker compose -f docker/docker-compose.yml restart" -ForegroundColor White
        }
    } else {
        Write-Host "ℹ️  No hay contenedores MSN-AI ejecutándose" -ForegroundColor Cyan
        Write-Host "   La API Key se aplicará en el próximo inicio" -ForegroundColor White
    }
}

# Function to test API key (basic connectivity test)
function Test-ApiKey {
    Write-Host ""
    Write-Host "🧪 Prueba de Conectividad" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

    # Check if Ollama is accessible
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/" -TimeoutSec 5 -UseBasicParsing 2>$null
        Write-Host "✅ Ollama está accesible" -ForegroundColor Green

        # Try to list models
        try {
            $apiResponse = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -TimeoutSec 10 -UseBasicParsing 2>$null
            Write-Host "✅ API de Ollama responde correctamente" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  API de Ollama no responde (puede ser normal si no hay modelos instalados)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Ollama no está accesible en localhost:11434" -ForegroundColor Yellow
        Write-Host "   Si usas Docker, esto es normal" -ForegroundColor White
    }
}

# Main menu
function Show-Menu {
    Write-Host "📋 Opciones:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Ingresar nueva API Key" -ForegroundColor White
    Write-Host "2. Ver API Key actual (enmascarada)" -ForegroundColor White
    Write-Host "3. Eliminar API Key" -ForegroundColor White
    Write-Host "4. Probar conectividad" -ForegroundColor White
    Write-Host "5. Salir" -ForegroundColor White
    Write-Host ""
}

# Main execution
function Main {
    while ($true) {
        Show-Menu
        $option = Read-Host "Selecciona una opción (1-5)"
        Write-Host ""

        switch ($option) {
            "1" {
                Write-Host "🔑 Configuración de API Key" -ForegroundColor Cyan
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "💡 Información sobre modelos cloud:" -ForegroundColor Yellow
                Write-Host "   Los siguientes modelos requieren API Key:" -ForegroundColor White
                Write-Host "   - qwen3-vl:235b-cloud" -ForegroundColor Gray
                Write-Host "   - gpt-oss:120b-cloud" -ForegroundColor Gray
                Write-Host "   - qwen3-coder:480b-cloud" -ForegroundColor Gray
                Write-Host ""
                Write-Host "📝 Obtén tu API Key desde el proveedor del modelo" -ForegroundColor Yellow
                Write-Host ""
                $newApiKey = Read-Host "Ingresa tu OLLAMA_API_KEY"

                if (Validate-ApiKey $newApiKey) {
                    Configure-EnvFile $newApiKey
                    Configure-Docker
                    Write-Host ""
                    Write-Host "🎉 Configuración completada" -ForegroundColor Green
                } else {
                    Write-Host "❌ API Key no válida" -ForegroundColor Red
                }
                Write-Host ""
            }

            "2" {
                if (Test-Path ".env") {
                    $envContent = Get-Content ".env"
                    $apiKeyLine = $envContent | Where-Object { $_ -match "^OLLAMA_API_KEY=(.+)$" }

                    if ($apiKeyLine) {
                        $currentKey = ($apiKeyLine -split "=", 2)[1]
                        if ($currentKey) {
                            $maskedKey = $currentKey.Substring(0, [Math]::Min(8, $currentKey.Length)) + "***" + $currentKey.Substring([Math]::Max(0, $currentKey.Length - 4))
                            Write-Host "🔑 API Key actual: $maskedKey" -ForegroundColor Green
                            Write-Host "   Longitud: $($currentKey.Length) caracteres" -ForegroundColor White
                        } else {
                            Write-Host "⚠️  API Key está vacía en .env" -ForegroundColor Yellow
                        }
                    } else {
                        Write-Host "❌ No hay API Key configurada en .env" -ForegroundColor Red
                    }
                } else {
                    Write-Host "❌ No existe archivo .env" -ForegroundColor Red
                }
                Write-Host ""
            }

            "3" {
                Write-Host "🗑️  Eliminar API Key" -ForegroundColor Yellow
                Write-Host "━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
                Write-Host ""
                $confirm = Read-Host "¿Estás seguro de eliminar la API Key? (s/N)"

                if ($confirm -eq "s" -or $confirm -eq "S") {
                    if (Test-Path ".env") {
                        $envContent = Get-Content ".env" | Where-Object { $_ -notmatch "^OLLAMA_API_KEY=" }
                        $envContent | Set-Content ".env"
                        Write-Host "✅ API Key eliminada de .env" -ForegroundColor Green
                        Configure-Docker
                    } else {
                        Write-Host "⚠️  No existe archivo .env" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "⏭️  Operación cancelada" -ForegroundColor Cyan
                }
                Write-Host ""
            }

            "4" {
                Test-ApiKey
                Write-Host ""
            }

            "5" {
                Write-Host "👋 ¡Hasta luego!" -ForegroundColor Green
                exit 0
            }

            default {
                Write-Host "❌ Opción no válida" -ForegroundColor Red
                Write-Host ""
            }
        }
    }
}

# Check for command line arguments
if ($args.Count -gt 0) {
    switch ($args[0]) {
        "--set" {
            if ($args.Count -lt 2) {
                Write-Host "❌ Error: Debes proporcionar una API Key" -ForegroundColor Red
                Write-Host "   Uso: .\configure-api-key.ps1 --set <api_key>" -ForegroundColor Yellow
                exit 1
            }

            if (Validate-ApiKey $args[1]) {
                Configure-EnvFile $args[1]
                Configure-Docker
                Write-Host ""
                Write-Host "🎉 API Key configurada exitosamente" -ForegroundColor Green
                exit 0
            } else {
                Write-Host "❌ API Key no válida" -ForegroundColor Red
                exit 1
            }
        }

        "--show" {
            if (Test-Path ".env") {
                $envContent = Get-Content ".env"
                $apiKeyLine = $envContent | Where-Object { $_ -match "^OLLAMA_API_KEY=(.+)$" }

                if ($apiKeyLine) {
                    $currentKey = ($apiKeyLine -split "=", 2)[1]
                    if ($currentKey) {
                        $maskedKey = $currentKey.Substring(0, [Math]::Min(8, $currentKey.Length)) + "***" + $currentKey.Substring([Math]::Max(0, $currentKey.Length - 4))
                        Write-Host "🔑 API Key: $maskedKey" -ForegroundColor Green
                    } else {
                        Write-Host "⚠️  API Key vacía" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "❌ No hay API Key configurada" -ForegroundColor Red
                }
            } else {
                Write-Host "❌ No existe archivo .env" -ForegroundColor Red
            }
            exit 0
        }

        "--remove" {
            if (Test-Path ".env") {
                $envContent = Get-Content ".env" | Where-Object { $_ -notmatch "^OLLAMA_API_KEY=" }
                $envContent | Set-Content ".env"
                Write-Host "✅ API Key eliminada" -ForegroundColor Green
            } else {
                Write-Host "⚠️  No existe archivo .env" -ForegroundColor Yellow
            }
            exit 0
        }

        "--test" {
            Test-ApiKey
            exit 0
        }

        { $_ -in "--help", "-h" } {
            Write-Host "Uso: .\configure-api-key.ps1 [opción] [valor]" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Opciones:" -ForegroundColor Yellow
            Write-Host "  (sin opciones)        Modo interactivo" -ForegroundColor White
            Write-Host "  --set <api_key>       Configurar API Key" -ForegroundColor White
            Write-Host "  --show                Mostrar API Key actual (enmascarada)" -ForegroundColor White
            Write-Host "  --remove              Eliminar API Key" -ForegroundColor White
            Write-Host "  --test                Probar conectividad" -ForegroundColor White
            Write-Host "  --help, -h            Mostrar esta ayuda" -ForegroundColor White
            Write-Host ""
            Write-Host "Ejemplos:" -ForegroundColor Yellow
            Write-Host "  .\configure-api-key.ps1                   # Modo interactivo" -ForegroundColor Gray
            Write-Host "  .\configure-api-key.ps1 --set sk-abc123   # Configurar API Key" -ForegroundColor Gray
            Write-Host "  .\configure-api-key.ps1 --show            # Ver API Key" -ForegroundColor Gray
            Write-Host "  .\configure-api-key.ps1 --test            # Probar conectividad" -ForegroundColor Gray
            Write-Host ""
            exit 0
        }

        default {
            Write-Host "❌ Opción no reconocida: $($args[0])" -ForegroundColor Red
            Write-Host "   Usa --help para ver opciones disponibles" -ForegroundColor Yellow
            exit 1
        }
    }
} else {
    # Interactive mode
    Main
}
