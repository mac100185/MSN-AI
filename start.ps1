# MSN-AI - Universal Start Script Wrapper for Windows
# Version: 2.1.0
# Author: Alan Mac-Arthur García Díaz
# License: GNU General Public License v3.0
# Description: Redirects to appropriate Windows start script

Write-Host "🚀 MSN-AI v2.1.0 - Windows Launcher" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "📧 Desarrollado por: Alan Mac-Arthur García Díaz" -ForegroundColor White
Write-Host "⚖️ Licencia: GPL-3.0" -ForegroundColor White
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🪟 Sistema operativo: Windows" -ForegroundColor Green
Write-Host "📂 Redirigiendo a: windows\start-msnai.ps1" -ForegroundColor Yellow
Write-Host ""

# Check if the Windows script exists
$windowsScript = Join-Path $PSScriptRoot "windows\start-msnai.ps1"

if (Test-Path $windowsScript) {
    # Execute the Windows-specific script
    & $windowsScript @args
} else {
    Write-Host "❌ Error: No se encuentra windows\start-msnai.ps1" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Asegúrate de que la estructura del proyecto esté intacta" -ForegroundColor Yellow
    exit 1
}
