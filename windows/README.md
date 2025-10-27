# MSN-AI - Scripts para Windows

Esta carpeta contiene todos los scripts específicos para sistemas operativos Windows.

## 📋 Contenido

### Scripts de Inicio

- **`start-msnai.ps1`** - Inicia MSN-AI localmente con servidor web integrado
- **`start-msnai-docker.ps1`** - Inicia MSN-AI usando Docker

### Scripts de Configuración

- **`ai_check_all.ps1`** - Verifica el hardware y recomienda el mejor modelo de IA
- **`create-desktop-shortcut.ps1`** - Crea un acceso directo en el escritorio

## 🚀 Uso Rápido

### Instalación Local

```powershell
# 1. Verificar hardware e instalar modelos requeridos
.\windows\ai_check_all.ps1

# 2. Iniciar MSN-AI
.\windows\start-msnai.ps1 --auto
```

### Instalación con Docker

```powershell
# Iniciar MSN-AI con Docker (incluye instalación automática de modelos)
.\windows\start-msnai-docker.ps1
```

### Desde la raíz del proyecto

```powershell
# El script wrapper redirigirá automáticamente a los scripts de Windows
.\start.ps1          # Para instalación local
.\start-docker.ps1   # Para instalación con Docker
```

## 📦 Modelos Requeridos por Defecto

Los scripts instalarán automáticamente estos modelos:

- `qwen3-vl:235b-cloud` - Modelo de visión y lenguaje
- `gpt-oss:120b-cloud` - Modelo de propósito general
- `qwen3-coder:480b-cloud` - Modelo especializado en código

Además, el script de verificación de hardware (`ai_check_all.ps1`) recomendará un modelo adicional optimizado para tu sistema.

## 🔧 Requisitos

### Para instalación local:
- Windows 10/11 (64-bit)
- PowerShell 5.1+ (incluido en Windows)
- Python 3 o Node.js (para servidor web)
- Ollama para Windows (se puede instalar manualmente)
- Conexión a internet (para descargar modelos)

### Para instalación con Docker:
- Windows 10/11 Pro/Enterprise (con Hyper-V)
- Docker Desktop para Windows 4.0+
- Docker Compose v2.0+ (incluido en Docker Desktop)
- WSL2 (Windows Subsystem for Linux 2)
- 10GB+ de espacio libre en disco
- Conexión a internet (para descargar imágenes y modelos)

## 💡 Consejos Específicos para Windows

1. **PowerShell como Administrador**: Algunos comandos pueden requerir privilegios elevados
2. **Política de Ejecución**: Si no puedes ejecutar scripts, ejecuta:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. **Primera instalación**: Ejecuta primero `ai_check_all.ps1` para verificar tu hardware
4. **GPU NVIDIA**: Si tienes GPU NVIDIA, instala los drivers más recientes para mejor rendimiento
5. **Espacio en disco**: Los modelos de IA ocupan varios GB, verifica espacio disponible
6. **Tiempo de descarga**: La primera instalación puede tardar bastante dependiendo de tu conexión
7. **Windows Defender**: Puede pedir confirmación para ejecutar scripts

## 🎮 Detección de GPU

El script `ai_check_all.ps1` detecta automáticamente:

### GPU NVIDIA
- ✅ Detección automática de VRAM
- ✅ Recomendación de modelo optimizado
- ✅ Soporte para CUDA
- 💡 Instala GeForce Experience o drivers NVIDIA Studio

### GPU AMD
- ⚠️ Soporte limitado
- ⚠️ Mejor usar modo CPU

### GPU Intel (Integrada)
- ⚠️ Soporte limitado
- ⚠️ Mejor usar modo CPU con modelos ligeros

## 🐛 Solución de Problemas

### Error: "no se puede cargar el archivo porque la ejecución de scripts está deshabilitada"
```powershell
# Ejecutar como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# O temporal para una sesión
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Error: "Ollama no está instalado"
```powershell
# Descargar e instalar Ollama manualmente
# 1. Visita: https://ollama.com/download
# 2. Descarga OllamaSetup.exe
# 3. Ejecuta el instalador
# 4. Reinicia PowerShell
```

### Error: "Docker no encontrado"
```powershell
# Instalar Docker Desktop para Windows
# 1. Visita: https://www.docker.com/products/docker-desktop
# 2. Descarga Docker Desktop
# 3. Ejecuta el instalador
# 4. Habilita WSL2 si se solicita
# 5. Reinicia el sistema
```

### Error: "Puerto 8000 ya en uso"
```powershell
# Ver qué proceso usa el puerto
netstat -ano | findstr :8000

# Detener el proceso (reemplaza PID con el número real)
taskkill /PID <PID> /F
```

### Error con WSL2 para Docker
```powershell
# Instalar WSL2
wsl --install

# Actualizar WSL2
wsl --update

# Establecer WSL2 como predeterminado
wsl --set-default-version 2
```

## 🔐 Permisos y Seguridad

### Windows Defender SmartScreen
Si Windows Defender bloquea la ejecución:
1. Click en "Más información"
2. Click en "Ejecutar de todas formas"

### Antivirus
Algunos antivirus pueden bloquear Ollama o los scripts:
- Agrega excepciones para la carpeta MSN-AI
- Agrega excepciones para Ollama

### Firewall
Si hay problemas de conexión:
- Permite conexiones para Python/Node.js en el firewall
- Permite conexiones para Ollama (puerto 11434)
- Permite conexiones para el servidor web (puerto 8000)

## 🌐 Navegadores Recomendados

MSN-AI funciona mejor con:
- Microsoft Edge (recomendado para Windows)
- Google Chrome
- Mozilla Firefox
- Opera

## ⚡ Optimización de Rendimiento

### Para mejor rendimiento:
1. **Cierra aplicaciones innecesarias** antes de usar modelos de IA
2. **Actualiza drivers de GPU** si tienes NVIDIA
3. **Aumenta memoria virtual** si tienes poca RAM:
   - Panel de Control > Sistema > Configuración avanzada > Rendimiento > Configuración > Opciones avanzadas > Memoria virtual

### Requisitos de Hardware Recomendados:
- **Mínimo**: CPU de 4 núcleos, 8GB RAM
- **Recomendado**: CPU de 8 núcleos, 16GB RAM, GPU con 6GB+ VRAM
- **Óptimo**: CPU de 12+ núcleos, 32GB RAM, GPU con 24GB+ VRAM

## 📊 Monitoreo de Recursos

### Ver uso de GPU NVIDIA:
```powershell
nvidia-smi
```

### Ver uso de RAM y CPU:
```powershell
# Abrir Administrador de Tareas
taskmgr

# O usar PowerShell
Get-Process | Sort-Object -Descending WorkingSet | Select-Object -First 10
```

## 📧 Soporte

- **Autor**: Alan Mac-Arthur García Díaz
- **Email**: alan.mac.arthur.garcia.diaz@gmail.com
- **Licencia**: GNU General Public License v3.0

## 🔗 Enlaces Útiles

- [Ollama para Windows](https://ollama.com/download)
- [Docker Desktop para Windows](https://www.docker.com/products/docker-desktop)
- [Python para Windows](https://www.python.org/downloads/)
- [Node.js para Windows](https://nodejs.org/)
- [NVIDIA Drivers](https://www.nvidia.com/Download/index.aspx)

---

**Nota**: Todos los scripts están probados en Windows 10 y Windows 11. Se recomienda mantener Windows actualizado para mejor compatibilidad.