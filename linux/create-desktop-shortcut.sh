#!/bin/bash
# create-desktop-shortcut.sh - Crea acceso directo de MSN-AI en el escritorio (Linux)
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
# 3. Da permisos de ejecucion: chmod +x create-desktop-shortcut.sh
# 4. Ejecuta este script una sola vez: ./create-desktop-shortcut.sh
# 5. Se creara un acceso directo "MSN-AI" en tu escritorio
# 6. Haz doble clic en el acceso directo para iniciar MSN-AI
#
# NOTA: Solo necesitas ejecutar este script UNA VEZ
#
# ============================================

echo "============================================"
echo "  Creador de Acceso Directo para MSN-AI"
echo "============================================"
echo ""
echo "Este script creara un acceso directo en tu escritorio"
echo "para que puedas iniciar MSN-AI con solo hacer doble clic"
echo ""

# Detect and change to project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT" || {
    echo "❌ Error: No se pudo cambiar al directorio del proyecto"
    exit 1
}

# Verificar que estamos en el directorio correcto
if [ ! -f "msn-ai.html" ]; then
    echo "❌ ERROR: No se encuentra msn-ai.html"
    echo "   Estructura del proyecto incorrecta"
    echo ""
    read -p "Presiona Enter para salir..."
    exit 1
fi

# Obtener rutas
CURRENT_PATH="$(pwd)"
SCRIPT_PATH="$CURRENT_PATH/linux/start-msnai.sh"
DESKTOP_PATH="$HOME/Desktop"
SHORTCUT_PATH="$DESKTOP_PATH/MSN-AI.desktop"
ICON_PATH="$CURRENT_PATH/assets/general/logo.png"

# Verificar si existe el directorio Desktop, si no, intentar con Escritorio
if [ ! -d "$DESKTOP_PATH" ]; then
    DESKTOP_PATH="$HOME/Escritorio"
    SHORTCUT_PATH="$DESKTOP_PATH/MSN-AI.desktop"
fi

if [ ! -d "$DESKTOP_PATH" ]; then
    echo "⚠️  ADVERTENCIA: No se encontro el directorio del escritorio"
    echo "   Se intentara crear en: $HOME/Desktop"
    DESKTOP_PATH="$HOME/Desktop"
    SHORTCUT_PATH="$DESKTOP_PATH/MSN-AI.desktop"
fi

echo "Configuracion:"
echo "  Directorio MSN-AI: $CURRENT_PATH"
echo "  Script de inicio: $SCRIPT_PATH"
echo "  Escritorio: $DESKTOP_PATH"
echo "  Acceso directo: $SHORTCUT_PATH"
echo ""

# Verificar que el script de inicio existe
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ ERROR: No se encuentra start-msnai.sh"
    echo "   Asegurate de que el archivo existe en: $SCRIPT_PATH"
    echo ""
    read -p "Presiona Enter para salir..."
    exit 1
fi

# Dar permisos de ejecucion al script de inicio si no los tiene
if [ ! -x "$SCRIPT_PATH" ]; then
    echo "🔧 Dando permisos de ejecucion a start-msnai.sh..."
    chmod +x "$SCRIPT_PATH"
fi

# Preguntar confirmacion
echo "Esto creara un acceso directo llamado 'MSN-AI' en tu escritorio"
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

# Crear el archivo .desktop
cat > "$SHORTCUT_PATH" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=MSN-AI
Comment=Windows Live Messenger con IA Local
Exec=bash -c "cd '$CURRENT_PATH' && ./start-msnai.sh --auto"
Icon=$ICON_PATH
Terminal=true
Categories=Network;InstantMessaging;
StartupNotify=true
EOF

# Verificar si se creo correctamente
if [ ! -f "$SHORTCUT_PATH" ]; then
    echo ""
    echo "❌ ERROR al crear el acceso directo"
    echo ""
    echo "Posibles causas:"
    echo "  - Permisos insuficientes"
    echo "  - El escritorio no es accesible"
    echo "  - Sistema de archivos de solo lectura"
    echo ""
    echo "Solucion alternativa:"
    echo "  1. Crea manualmente un archivo llamado MSN-AI.desktop en tu escritorio"
    echo "  2. Copia el siguiente contenido:"
    echo ""
    echo "[Desktop Entry]"
    echo "Version=1.0"
    echo "Type=Application"
    echo "Name=MSN-AI"
    echo "Comment=Windows Live Messenger con IA Local"
    echo "Exec=bash -c \"cd '$CURRENT_PATH' && ./start-msnai.sh --auto\""
    echo "Icon=$ICON_PATH"
    echo "Terminal=true"
    echo "Categories=Network;InstantMessaging;"
    echo "StartupNotify=true"
    echo ""
    echo "  3. Dale permisos de ejecucion: chmod +x ~/Desktop/MSN-AI.desktop"
    echo ""
    read -p "Presiona Enter para salir..."
    exit 1
fi

# Dar permisos de ejecucion al acceso directo
chmod +x "$SHORTCUT_PATH"

# Intentar marcar como confiable (para algunas distribuciones)
if command -v gio &> /dev/null; then
    gio set "$SHORTCUT_PATH" metadata::trusted true 2>/dev/null
fi

echo ""
echo "============================================"
echo "  ✅ Acceso directo creado exitosamente!"
echo "============================================"
echo ""
echo "El acceso directo 'MSN-AI' ha sido creado en tu escritorio"
echo ""
echo "Como usar el acceso directo:"
echo "  1. Ve a tu escritorio"
echo "  2. Haz doble clic en 'MSN-AI'"
echo "  3. Si tu sistema pregunta, selecciona 'Ejecutar' o 'Confiar y ejecutar'"
echo "  4. Se abrira una terminal y MSN-AI iniciara automaticamente"
echo "  5. Para cerrar MSN-AI: Presiona Ctrl+C en la terminal"
echo ""
echo "IMPORTANTE:"
echo "  - NO cierres la terminal sin presionar Ctrl+C"
echo "  - La terminal debe permanecer abierta mientras uses MSN-AI"
echo "  - Al hacer Ctrl+C, el servidor se detendra correctamente"
echo ""

# Ofrecer probar el acceso directo
read -p "¿Deseas probar el acceso directo ahora? (s/n): " test

if [[ "$test" =~ ^[sS]$ ]]; then
    echo ""
    echo "🚀 Iniciando MSN-AI desde el acceso directo..."

    # Intentar abrir el acceso directo
    if command -v gtk-launch &> /dev/null; then
        gtk-launch MSN-AI.desktop &
    elif command -v kioclient5 &> /dev/null; then
        kioclient5 exec "$SHORTCUT_PATH" &
    elif command -v exo-open &> /dev/null; then
        exo-open "$SHORTCUT_PATH" &
    else
        # Fallback: ejecutar directamente
        bash -c "cd '$CURRENT_PATH' && ./start-msnai.sh --auto" &
    fi

    echo ""
    echo "✅ MSN-AI se esta iniciando en una nueva terminal"
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
