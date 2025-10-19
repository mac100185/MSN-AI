# create-desktop-shortcut.ps1 - Crea acceso directo de MSN-AI en el escritorio
# Version: 1.0.0
# Autor: Alan Mac-Arthur Garcia Diaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# Licencia: GNU General Public License v3.0
# GitHub: https://github.com/mac100185/MSN-AI
# Descripcion: Crea un acceso directo en el escritorio para iniciar MSN-AI facilmente
#
# ============================================
# INSTRUCCIONES DE USO
# ============================================
#
# 1. Abre PowerShell
# 2. Navega al directorio MSN-AI: cd MSN-AI
# 3. Ejecuta este script una sola vez: .\create-desktop-shortcut.ps1
# 4. Se creara un acceso directo "MSN-AI" en tu escritorio
# 5. Haz doble clic en el acceso directo para iniciar MSN-AI
#
# NOTA: Solo necesitas ejecutar este script UNA VEZ
#
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Creador de Acceso Directo para MSN-AI" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Este script creara un acceso directo en tu escritorio" -ForegroundColor Yellow
Write-Host "para que puedas iniciar MSN-AI con solo hacer doble clic" -ForegroundColor Yellow
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "msn-ai.html")) {
    Write-Host "ERROR: No se encuentra msn-ai.html" -ForegroundColor Red
    Write-Host "Por favor, ejecuta este script desde el directorio MSN-AI" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 1
}

# Obtener rutas
$currentPath = (Get-Location).Path
$scriptPath = Join-Path $currentPath "start-msnai.ps1"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "MSN-AI.lnk"

Write-Host "Configuracion:" -ForegroundColor Cyan
Write-Host "  Directorio MSN-AI: $currentPath" -ForegroundColor Gray
Write-Host "  Script de inicio: $scriptPath" -ForegroundColor Gray
Write-Host "  Escritorio: $desktopPath" -ForegroundColor Gray
Write-Host "  Acceso directo: $shortcutPath" -ForegroundColor Gray
Write-Host ""

# Verificar que el script de inicio existe
if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: No se encuentra start-msnai.ps1" -ForegroundColor Red
    Write-Host "Asegurate de que el archivo existe en: $scriptPath" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 1
}

# Preguntar confirmacion
Write-Host "Esto creara un acceso directo llamado 'MSN-AI' en tu escritorio" -ForegroundColor Yellow
$confirm = Read-Host "Deseas continuar? (s/n)"

if ($confirm -ne "s" -and $confirm -ne "S") {
    Write-Host ""
    Write-Host "Operacion cancelada" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 0
}

Write-Host ""
Write-Host "Creando acceso directo..." -ForegroundColor Cyan

try {
    # Crear objeto WScript.Shell
    $WScriptShell = New-Object -ComObject WScript.Shell
    
    # Crear acceso directo
    $Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
    
    # Configurar el acceso directo para ejecutar PowerShell con el script
    # Usamos -ExecutionPolicy Bypass para evitar problemas con politicas
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`" --auto"
    $Shortcut.WorkingDirectory = $currentPath
    $Shortcut.Description = "MSN-AI - Windows Live Messenger con IA Local"
    $Shortcut.WindowStyle = 1  # 1 = Normal window
    
    # Intentar usar un icono (si existe el logo)
    $iconPath = Join-Path $currentPath "assets\general\logo.png"
    if (Test-Path $iconPath) {
        # PowerShell no puede usar PNG directamente como icono
        # Usaremos el icono por defecto de PowerShell
        $Shortcut.IconLocation = "powershell.exe,0"
    }
    else {
        $Shortcut.IconLocation = "powershell.exe,0"
    }
    
    # Guardar el acceso directo
    $Shortcut.Save()
    
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  Acceso directo creado exitosamente!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "El acceso directo 'MSN-AI' ha sido creado en tu escritorio" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Como usar el acceso directo:" -ForegroundColor Yellow
    Write-Host "  1. Ve a tu escritorio" -ForegroundColor White
    Write-Host "  2. Haz doble clic en 'MSN-AI'" -ForegroundColor White
    Write-Host "  3. Se abrira PowerShell y MSN-AI iniciara automaticamente" -ForegroundColor White
    Write-Host "  4. Para cerrar MSN-AI: Presiona Ctrl+C en la ventana de PowerShell" -ForegroundColor White
    Write-Host ""
    Write-Host "IMPORTANTE:" -ForegroundColor Yellow
    Write-Host "  - NO cierres la ventana de PowerShell sin presionar Ctrl+C" -ForegroundColor White
    Write-Host "  - La ventana de PowerShell debe permanecer abierta mientras uses MSN-AI" -ForegroundColor White
    Write-Host "  - Al hacer Ctrl+C, el servidor se detendra correctamente" -ForegroundColor White
    Write-Host ""
    Write-Host "Deseas probar el acceso directo ahora?" -ForegroundColor Cyan
    $test = Read-Host "(s/n)"
    
    if ($test -eq "s" -or $test -eq "S") {
        Write-Host ""
        Write-Host "Iniciando MSN-AI desde el acceso directo..." -ForegroundColor Green
        Start-Process $shortcutPath
        Write-Host ""
        Write-Host "MSN-AI se esta iniciando en una nueva ventana de PowerShell" -ForegroundColor Green
        Write-Host "Puedes cerrar esta ventana de forma segura" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  Configuracion completada" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "ERROR al crear el acceso directo: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Posibles causas:" -ForegroundColor Yellow
    Write-Host "  - Permisos insuficientes" -ForegroundColor White
    Write-Host "  - El escritorio no es accesible" -ForegroundColor White
    Write-Host "  - Antivirus bloqueando la operacion" -ForegroundColor White
    Write-Host ""
    Write-Host "Solucion alternativa:" -ForegroundColor Cyan
    Write-Host "  1. Crea manualmente un acceso directo en el escritorio" -ForegroundColor White
    Write-Host "  2. Boton derecho -> Nuevo -> Acceso directo" -ForegroundColor White
    Write-Host "  3. Ubicacion: powershell.exe" -ForegroundColor White
    Write-Host "  4. Propiedades -> Destino:" -ForegroundColor White
    Write-Host "     powershell.exe -ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`" --auto" -ForegroundColor Gray
    Write-Host "  5. Iniciar en: $currentPath" -ForegroundColor Gray
    Write-Host ""
}

Read-Host "Presiona Enter para salir"
