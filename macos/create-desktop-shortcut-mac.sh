#!/bin/bash
# create-desktop-shortcut-mac.sh - Crea acceso directo de MSN-AI en el escritorio (macOS)
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
# 1. Abre una terminal
# 2. Navega al directorio MSN-AI: cd MSN-AI
# 3. Da permisos de ejecucion: chmod +x create-desktop-shortcut-mac.sh
# 4. Ejecuta este script una sola vez: ./create-desktop-shortcut-mac.sh
# 5. Se creara un acceso directo "MSN-AI" en tu escritorio
# 6. Haz doble clic en el acceso directo para iniciar MSN-AI
#
# NOTA: Solo necesitas ejecutar este script UNA VEZ
#
# ============================================

echo "============================================"
echo "  Creador de Acceso Directo para MSN-AI"
echo "  (macOS)"
echo "============================================"
echo ""
echo "Este script creara un acceso directo en tu escritorio"
echo "para que puedas iniciar MSN-AI con solo hacer doble clic"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "msn-ai.html" ]; then
    echo "❌ ERROR: No se encuentra msn-ai.html"
    echo "   Por favor, ejecuta este script desde el directorio MSN-AI"
    echo ""
    read -p "Presiona Enter para salir..."
    exit 1
fi

# Obtener rutas
CURRENT_PATH="$(pwd)"
SCRIPT_PATH="$CURRENT_PATH/start-msnai-mac.sh"
DESKTOP_PATH="$HOME/Desktop"
APP_PATH="$DESKTOP_PATH/MSN-AI.app"
ICON_PATH="$CURRENT_PATH/assets/general/logo.png"

echo "Configuracion:"
echo "  Directorio MSN-AI: $CURRENT_PATH"
echo "  Script de inicio: $SCRIPT_PATH"
echo "  Escritorio: $DESKTOP_PATH"
echo "  Aplicacion: $APP_PATH"
echo ""

# Verificar que el script de inicio existe
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ ERROR: No se encuentra start-msnai-mac.sh"
    echo "   Asegurate de que el archivo existe en: $SCRIPT_PATH"
    echo ""
    read -p "Presiona Enter para salir..."
    exit 1
fi

# Dar permisos de ejecucion al script de inicio si no los tiene
if [ ! -x "$SCRIPT_PATH" ]; then
    echo "🔧 Dando permisos de ejecucion a start-msnai-mac.sh..."
    chmod +x "$SCRIPT_PATH"
fi

# Preguntar confirmacion
echo "Esto creara una aplicacion llamada 'MSN-AI' en tu escritorio"
read -p "¿Deseas continuar? (s/n): " confirm

if [[ ! "$confirm" =~ ^[sS]$ ]]; then
    echo ""
    echo "⏹️  Operacion cancelada"
    echo ""
    read -p "Presiona Enter para salir..."
    exit 0
fi

echo ""
echo "🔧 Creando acceso directo..."

# Verificar si ya existe y eliminarlo
if [ -d "$APP_PATH" ]; then
    echo "🗑️  Eliminando acceso directo anterior..."
    rm -rf "$APP_PATH"
fi

# Crear estructura de la aplicacion
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Crear el script ejecutable
cat > "$APP_PATH/Contents/MacOS/MSN-AI" << 'EOF'
#!/bin/bash

# Obtener el directorio donde esta el script original
SCRIPT_DIR="$(dirname "$0")"
APP_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Leer la ruta del proyecto desde el archivo de configuracion
CONFIG_FILE="$APP_DIR/Contents/Resources/project_path.txt"

if [ -f "$CONFIG_FILE" ]; then
    PROJECT_PATH=$(cat "$CONFIG_FILE")

    if [ -d "$PROJECT_PATH" ]; then
        cd "$PROJECT_PATH"

        # Abrir Terminal y ejecutar el script
        osascript <<APPLESCRIPT
tell application "Terminal"
    activate
    do script "cd '$PROJECT_PATH' && ./start-msnai-mac.sh --auto"
end tell
APPLESCRIPT
    else
        osascript -e 'display dialog "Error: No se encuentra el directorio de MSN-AI en:\n'$PROJECT_PATH'" buttons {"OK"} default button "OK" with icon stop'
    fi
else
    osascript -e 'display dialog "Error: Configuracion no encontrada" buttons {"OK"} default button "OK" with icon stop'
fi
EOF

# Dar permisos de ejecucion al script
chmod +x "$APP_PATH/Contents/MacOS/MSN-AI"

# Guardar la ruta del proyecto
echo "$CURRENT_PATH" > "$APP_PATH/Contents/Resources/project_path.txt"

# Crear el archivo Info.plist
cat > "$APP_PATH/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MSN-AI</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.msnai.app</string>
    <key>CFBundleName</key>
    <string>MSN-AI</string>
    <key>CFBundleDisplayName</key>
    <string>MSN-AI</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.10</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Copiar el icono si existe
if [ -f "$ICON_PATH" ]; then
    echo "🎨 Copiando icono..."

    # Intentar convertir PNG a ICNS si existe sips
    if command -v sips &> /dev/null && command -v iconutil &> /dev/null; then
        # Crear iconset temporal
        ICONSET_PATH="/tmp/MSN-AI.iconset"
        mkdir -p "$ICONSET_PATH"

        # Generar diferentes tamaños
        sips -z 16 16 "$ICON_PATH" --out "$ICONSET_PATH/icon_16x16.png" &> /dev/null
        sips -z 32 32 "$ICON_PATH" --out "$ICONSET_PATH/icon_16x16@2x.png" &> /dev/null
        sips -z 32 32 "$ICON_PATH" --out "$ICONSET_PATH/icon_32x32.png" &> /dev/null
        sips -z 64 64 "$ICON_PATH" --out "$ICONSET_PATH/icon_32x32@2x.png" &> /dev/null
        sips -z 128 128 "$ICON_PATH" --out "$ICONSET_PATH/icon_128x128.png" &> /dev/null
        sips -z 256 256 "$ICON_PATH" --out "$ICONSET_PATH/icon_128x128@2x.png" &> /dev/null
        sips -z 256 256 "$ICON_PATH" --out "$ICONSET_PATH/icon_256x256.png" &> /dev/null
        sips -z 512 512 "$ICON_PATH" --out "$ICONSET_PATH/icon_256x256@2x.png" &> /dev/null
        sips -z 512 512 "$ICON_PATH" --out "$ICONSET_PATH/icon_512x512.png" &> /dev/null

        # Convertir a icns
        iconutil -c icns "$ICONSET_PATH" -o "$APP_PATH/Contents/Resources/AppIcon.icns" &> /dev/null

        # Limpiar
        rm -rf "$ICONSET_PATH"
    else
        # Si no hay herramientas, copiar el PNG directamente
        cp "$ICON_PATH" "$APP_PATH/Contents/Resources/AppIcon.png"
    fi
else
    echo "⚠️  No se encontro el icono, se usara el predeterminado"
fi

# Verificar si se creo correctamente
if [ ! -d "$APP_PATH" ]; then
    echo ""
    echo "❌ ERROR al crear el acceso directo"
    echo ""
    echo "Posibles causas:"
    echo "  - Permisos insuficientes"
    echo "  - El escritorio no es accesible"
    echo "  - Sistema de archivos de solo lectura"
    echo ""
    echo "Solucion alternativa:"
    echo "  1. Crea un Automator Application:"
    echo "     - Abre Automator"
    echo "     - Selecciona 'Aplicacion'"
    echo "     - Agrega 'Ejecutar script de shell'"
    echo "     - Pega: cd '$CURRENT_PATH' && ./start-msnai-mac.sh --auto"
    echo "     - Guarda en el escritorio como 'MSN-AI'"
    echo ""
    read -p "Presiona Enter para salir..."
    exit 1
fi

echo ""
echo "============================================"
echo "  ✅ Acceso directo creado exitosamente!"
echo "============================================"
echo ""
echo "La aplicacion 'MSN-AI' ha sido creada en tu escritorio"
echo ""
echo "Como usar el acceso directo:"
echo "  1. Ve a tu escritorio"
echo "  2. Haz doble clic en 'MSN-AI.app'"
echo "  3. Se abrira Terminal y MSN-AI iniciara automaticamente"
echo "  4. Para cerrar MSN-AI: Presiona Ctrl+C en la ventana de Terminal"
echo ""
echo "IMPORTANTE:"
echo "  - NO cierres Terminal sin presionar Ctrl+C"
echo "  - La ventana de Terminal debe permanecer abierta mientras uses MSN-AI"
echo "  - Al hacer Ctrl+C, el servidor se detendra correctamente"
echo ""
echo "NOTA SOBRE SEGURIDAD:"
echo "  - Si macOS muestra un aviso de seguridad:"
echo "    1. Ve a Preferencias del Sistema > Seguridad y Privacidad"
echo "    2. Haz clic en 'Abrir de todos modos'"
echo "  - O: Ctrl+clic en la app y selecciona 'Abrir'"
echo ""

# Ofrecer probar el acceso directo
read -p "¿Deseas probar el acceso directo ahora? (s/n): " test

if [[ "$test" =~ ^[sS]$ ]]; then
    echo ""
    echo "🚀 Iniciando MSN-AI desde el acceso directo..."
    open "$APP_PATH"
    echo ""
    echo "✅ MSN-AI se esta iniciando en una nueva ventana de Terminal"
    echo "   Puedes cerrar esta ventana de forma segura"
fi

echo ""
echo "============================================"
echo "  Configuracion completada"
echo "============================================"
echo ""
echo "📧 Desarrollado por: Alan Mac-Arthur Garcia Diaz"
echo "⚖️  Licencia: GPL-3.0"
echo "🔗 GitHub: https://github.com/mac100185/MSN-AI"
echo ""
read -p "Presiona Enter para salir..."
