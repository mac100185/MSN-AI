# MSN-AI - Universal Docker Start Script Wrapper for Windows
# Version: 2.1.0
# Author: Alan Mac-Arthur García Díaz
# License: GNU General Public License v3.0
# Description: Redirects to appropriate Windows docker start script

Write-Host "🐳 MSN-AI v2.1.0 - Docker Windows Launcher" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "📧 Desarrollado por: Alan Mac-Arthur García Díaz" -ForegroundColor White
Write-Host "⚖️ Licencia: GPL-3.0" -ForegroundColor White
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🪟 Sistema operativo: Windows" -ForegroundColor Green
Write-Host "📂 Redirigiendo a: windows\start-msnai-docker.ps1" -ForegroundColor Yellow
Write-Host ""

# Check if the Windows docker script exists
$windowsDockerScript = Join-Path $PSScriptRoot "windows\start-msnai-docker.ps1"

if (Test-Path $windowsDockerScript) {
    # Execute the Windows-specific docker script
    & $windowsDockerScript @args
} else {
    Write-Host "❌ Error: No se encuentra windows\start-msnai-docker.ps1" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Asegúrate de que la estructura del proyecto esté intacta" -ForegroundColor Yellow
    exit 1
}
