# 🌍 Guía de Instalación Multiplataforma - MSN-AI

**Versión 2.1.0** | **Por Alan Mac-Arthur García Díaz**

Esta guía te ayudará a instalar y configurar MSN-AI en **Linux**, **Windows** o **macOS**.

## 🔥 **NUEVO: Ahora con Docker Edition**

MSN-AI v2.1.0 ofrece **instalación simplificada** con DOS opciones:

### 🐳 **Docker Edition v2.1.0** (Recomendado - Instalación Simplificada)
- **Un solo comando** para cualquier plataforma
- **Cero configuración** de firewall o red
- **Auto-detección** de IP y modelos
- **Aislamiento completo** sin "ensuciar" tu sistema
- **Acceso local y remoto** automático

### 💻 **Local Edition** (Clásica - Máximo rendimiento)
- **Instalación nativa** en tu sistema
- **Control total** sobre configuraciones
- **Rendimiento óptimo** sin overhead de contenedores
- **Personalización avanzada** disponible

---

## 🚀 Instalación Rápida (Recomendada)

### 🐳 **Docker Edition - Un comando para todas las plataformas:**
```bash
# Clonar e instalar en una línea:
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI && chmod +x *.sh && ./start-msnai-docker.sh --auto

# O paso a paso:
# Linux:
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI
./start-msnai-docker.sh --auto

# Windows:
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI
.\start-msnai-docker.ps1 --auto

# macOS:
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI
./start-msnai-docker-mac.sh --auto
```

### 💻 **Local Edition - Instalación tradicional:**
```bash
# Linux:
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI
./start-msnai.sh --auto

# Windows:
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI
.\start-msnai.ps1 --auto

# macOS:
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI
./start-msnai-mac.sh --auto
```

---

## 🎯 Selecciona tu método de instalación

### 🐳 **Docker Edition:**
- [🐧 **DOCKER LINUX**](#-docker-linux)
- [🪟 **DOCKER WINDOWS**](#-docker-windows)
- [🍎 **DOCKER macOS**](#-docker-macos)

### 💻 **Local Edition (Tradicional):**
- [🐧 **LINUX LOCAL**](#-linux-local) - Ubuntu, Debian, CentOS, etc.
- [🪟 **WINDOWS LOCAL**](#-windows-local) - Windows 10/11
- [🍎 **macOS LOCAL**](#-macos-local) - macOS 10.14+

---

## 🐳 DOCKER LINUX

### ⚡ Instalación súper rápida (1 comando)
```bash
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI && chmod +x *.sh && ./start-msnai-docker.sh --auto
```
> **✨ Con Docker**: Se instala Docker automáticamente si no lo tienes, detecta tu hardware y configura la IA óptima

### 📋 Instalación paso a paso Docker

#### 1. Descargar MSN-AI
```bash
# Git (recomendado)
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI

# O descarga directa
wget https://github.com/mac100185/MSN-AI/archive/refs/heads/main.zip
unzip main.zip && cd MSN-AI-main
```

#### 2. Dar permisos y ejecutar
```bash
chmod +x *.sh
./start-msnai-docker.sh --auto
```

#### 3. ¡Listo! 
- Docker se instala automáticamente si falta
- La aplicación se configura sola según tu hardware
- Se abre MSN-AI en tu navegador
- Todo funciona en contenedores aislados

### 🔧 Configuración específica Docker Linux

#### Si Docker ya está instalado:
```bash
# Verificar Docker
docker --version
docker-compose --version

# Iniciar MSN-AI directamente
./start-msnai-docker.sh --auto
```

#### Para uso con GPU NVIDIA:
```bash
# El script detecta automáticamente GPU y configura soporte
# No necesitas hacer nada manual
```

#### Comandos útiles Docker:
```bash
# Ver estado de contenedores
docker-compose -f docker/docker-compose.yml ps

# Ver logs
docker-compose -f docker/docker-compose.yml logs -f

# Detener servicios
docker-compose -f docker/docker-compose.yml down

# Reiniciar servicios
docker-compose -f docker/docker-compose.yml restart
```

---

## 🪟 DOCKER WINDOWS

### ⚡ Instalación súper rápida (PowerShell)
```powershell
# Clonar e iniciar
git clone https://github.com/mac100185/MSN-AI.git ; cd MSN-AI ; .\start-msnai-docker.ps1 --auto
```

### 📋 Instalación paso a paso Docker

#### 1. Abrir PowerShell
```powershell
# Windows + R -> "powershell" -> Enter
# (NO necesita ser como administrador)
```

#### 2. Habilitar scripts (si es necesario)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 3. Descargar y ejecutar
```powershell
# Clonar repositorio
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI

# Iniciar (instala Docker Desktop automáticamente si falta)
.\start-msnai-docker.ps1 --auto
```

### 🔧 Configuración específica Docker Windows

#### Docker Desktop se instala automáticamente:
- El script detecta si Docker falta
- Descarga e instala Docker Desktop
- Configura todo automáticamente
- Reinicia servicios si es necesario

#### Compatibilidad Windows:
- **Windows 10/11 Pro/Enterprise**: Hyper-V nativo
- **Windows 10/11 Home**: WSL 2 automático
- **GPU NVIDIA**: Soporte automático si tienes drivers

---

## 🍎 DOCKER macOS

### ⚡ Instalación súper rápida (Terminal)
```bash
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI && chmod +x *.sh && ./start-msnai-docker-mac.sh --auto
```

### 📋 Instalación paso a paso Docker

#### 1. Abrir Terminal
```bash
# Aplicaciones -> Utilidades -> Terminal
# O CMD + Espacio -> "Terminal"
```

#### 2. Descargar y ejecutar
```bash
# Clonar repositorio
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI

# Dar permisos
chmod +x *.sh

# Iniciar (optimizado para tu Mac)
./start-msnai-docker-mac.sh --auto
```

### 🔧 Configuración específica Docker macOS

#### Apple Silicon (M1/M2/M3) - Optimizado:
- Detecta arquitectura ARM64 automáticamente
- Descarga Docker Desktop para Apple Silicon
- Optimiza modelos de IA para Neural Engine
- Aprovecha memoria unificada eficientemente

#### Intel Mac - Compatible:
- Detecta arquitectura x86_64
- Descarga Docker Desktop para Intel
- Configura modelos según RAM disponible
- Funciona perfectamente en Macs Intel

#### Homebrew Integration:
```bash
# Si prefieres instalar Docker via Homebrew:
# El script ofrece esta opción automáticamente
```

---

## 💻 LINUX LOCAL

### ⚡ Instalación rápida tradicional (1 comando)
```bash
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI && chmod +x *.sh && ./start-msnai.sh --auto
```

### 📋 Instalación paso a paso tradicional

#### 1. Preparar el sistema
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install curl python3 git

# CentOS/RHEL/Fedora
sudo yum install curl python3 git  # o dnf install

# Arch Linux
sudo pacman -S curl python git
```

#### 2. Descargar MSN-AI
```bash
# Opción A: Git (recomendado)
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI

# Opción B: Descarga directa
wget https://github.com/mac100185/MSN-AI/archive/refs/heads/main.zip
unzip main.zip && cd MSN-AI-main
```

#### 3. Dar permisos a los scripts
```bash
chmod +x *.sh
```

#### 4. Verificar el sistema
```bash
./test-msnai.sh
```

#### 5. Configurar IA (recomendado)
```bash
./ai_check_all.sh
```

#### 6. Iniciar MSN-AI
```bash
./start-msnai.sh --auto
```

### 🔧 Configuración específica para Linux

#### Distribuciones sin Python 3
```bash
# Ubuntu/Debian
sudo apt install python3

# CentOS/RHEL
sudo yum install python3

# Arch Linux  
sudo pacman -S python
```

#### Firewall (si tienes problemas de conexión)
```bash
# UFW (Ubuntu)
sudo ufw allow 8000/tcp
sudo ufw allow 11434/tcp  # Ollama

# firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --permanent --add-port=11434/tcp
sudo firewall-cmd --reload
```

#### Problemas de sonido
```bash
# Instalar códecs de audio
sudo apt install ubuntu-restricted-extras  # Ubuntu
sudo yum groupinstall multimedia          # CentOS/RHEL
```

---

## 🪟 WINDOWS LOCAL

### ⚡ Instalación rápida tradicional (PowerShell)
```powershell
# 1. Abrir PowerShell como usuario normal
# 2. Habilitar scripts (solo una vez)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Descargar e iniciar
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI
.\start-msnai.ps1 --auto
```

### 📋 Instalación paso a paso tradicional

#### 1. Preparar PowerShell
```powershell
# Abrir PowerShell (NO como administrador)
# Windows + R -> "powershell" -> Enter

# Habilitar ejecución de scripts (solo la primera vez)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 2. Descargar MSN-AI
- **Opción A**: Git for Windows (recomendado)
```powershell
# Instalar Git si no lo tienes: https://git-scm.com/download/win
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
```

- **Opción B**: Descargar ZIP desde GitHub
  1. Ve a https://github.com/mac100185/MSN-AI
  2. Clic en "Code" > "Download ZIP"
  3. Extrae el ZIP en `C:\Users\TuUsuario\Documents\MSN-AI`

#### 3. Navegar al directorio
```powershell
cd "C:\Users\TuUsuario\Documents\MSN-AI"
# O donde hayas extraído los archivos
```

#### 4. Iniciar MSN-AI
```powershell
.\start-msnai.ps1 --auto

# NOTA: Si Ollama no está instalado, el script te guiará para instalarlo.
#       Después de instalar Ollama, CIERRA PowerShell y abre una NUEVA ventana.
#       Luego ejecuta nuevamente: .\start-msnai.ps1 --auto
```

#### 5. (Opcional) Verificar hardware y obtener recomendaciones de modelos IA
```powershell
.\ai_check_all.ps1
```

### 🔧 Configuración específica local para Windows

#### Instalar Python (opcional, para servidor web)
```powershell
# Opción A: Microsoft Store
# Buscar "Python 3.11" en Microsoft Store e instalar

# Opción B: Descarga oficial
# Ir a python.org/downloads/windows y descargar
```

#### Problemas con Windows Defender
```powershell
# Si Windows Defender bloquea Ollama
# 1. Ir a Configuración > Actualización y Seguridad > Seguridad de Windows
# 2. Protección contra virus y amenazas > Configuración
# 3. Agregar exclusión para la carpeta de Ollama
```

#### Navegadores recomendados
- ✅ **Microsoft Edge** (incluido en Windows)
- ✅ **Google Chrome** 
- ✅ **Mozilla Firefox**
- ⚠️ Internet Explorer **NO soportado**

---

## 🍎 macOS LOCAL

### ⚡ Instalación rápida tradicional (Terminal)
```bash
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI && chmod +x *.sh && ./start-msnai-mac.sh --auto
```

### 📋 Instalación paso a paso tradicional

#### 1. Preparar el sistema
```bash
# Instalar Homebrew (si no lo tienes)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar dependencias básicas
brew install curl python3 git
```

#### 2. Descargar MSN-AI
```bash
# Opción A: Git (recomendado)
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI

# Opción B: Descarga directa
curl -L -o main.zip https://github.com/mac100185/MSN-AI/archive/refs/heads/main.zip
unzip main.zip && cd MSN-AI-main
```

#### 3. Dar permisos a los scripts
```bash
chmod +x *.sh
```

#### 4. Configurar IA (recomendado)
```bash
./ai_check_all_mac.sh
```

#### 5. Iniciar MSN-AI
```bash
./start-msnai-mac.sh --auto
```

### 🔧 Configuración específica local para macOS

#### Apple Silicon (M1/M2/M3)
```bash
# Los Macs con Apple Silicon tienen excelente rendimiento con IA
# Modelos recomendados:
# - 16GB+ RAM: llama3:8b
# - 8-16GB RAM: mistral:7b
# - <8GB RAM: phi3:mini
```

#### Intel Mac
```bash
# Macs Intel pueden necesitar más RAM
# Modelos recomendados:
# - 32GB+ RAM: mistral:7b
# - 16-32GB RAM: phi3:mini
# - <16GB RAM: tinyllama
```

#### Problemas de permisos
```bash
# Si aparece "permiso denegado"
sudo xattr -rd com.apple.quarantine MSN-AI/
chmod +x *.sh
```

#### Navegadores recomendados
- ✅ **Safari** (incluido en macOS)
- ✅ **Google Chrome**
- ✅ **Mozilla Firefox**

---

## 🛠️ Resolución de problemas comunes

### 🐳 **Problemas Docker Edition**

#### ❌ "Docker no encontrado"
```bash
# Linux/macOS - Se instala automáticamente:
./start-msnai-docker.sh  # Detecta e instala Docker

# Windows - Descarga Docker Desktop automáticamente:
.\start-msnai-docker.ps1  # Instala Docker Desktop
```

#### ❌ "Contenedores no inician"
```bash
# Ver logs detallados
docker-compose -f docker/docker-compose.yml logs -f

# Reconstruir imágenes completamente
docker-compose -f docker/docker-compose.yml build --no-cache
docker-compose -f docker/docker-compose.yml up -d
```

#### ❌ "Puerto ocupado en Docker"
```bash
# Cambiar puerto automáticamente
echo "MSN_AI_PORT=8001" >> .env
docker-compose -f docker/docker-compose.yml up -d
```

#### 🔥 "Problemas extremos - Reset nuclear MSN-AI"
```bash
# Para casos extremos donde nada funciona:
./docker-cleanup.sh --nuclear

# ⚠️ IMPORTANTE: Solo afecta recursos MSN-AI:
# - Elimina TODOS los contenedores MSN-AI
# - Elimina TODAS las imágenes MSN-AI  
# - Elimina TODOS los volúmenes MSN-AI
# - Elimina TODAS las redes MSN-AI
# ✅ NO afecta otros proyectos Docker

# Requiere confirmación doble:
# "Para continuar, escribe 'NUCLEAR MSN-AI': NUCLEAR MSN-AI"
# "¿Estás SEGURO de resetear MSN-AI? Escribe 'RESETEAR MSN-AI': RESETEAR MSN-AI"
```

### 💻 **Problemas Local Edition**

#### ❌ "Ollama no responde"
```bash
# Verificar que Ollama esté ejecutándose
# Linux/macOS:
ps aux | grep ollama

# Windows:
Get-Process -Name "ollama" -ErrorAction SilentlyContinue
```

**Solución**:
```bash
# Reiniciar Ollama
# Linux/macOS:
ollama serve &

# Windows:
Start-Process -FilePath "ollama" -ArgumentList "serve" -NoNewWindow
```

#### ❌ "Puerto 8000 ocupado"
El script automáticamente buscará un puerto libre (8001, 8002, etc.)

**Solución manual**:
```bash
# Linux/macOS:
lsof -i :8000
kill [PID_DEL_PROCESO]

# Windows:
netstat -ano | findstr :8000
taskkill /PID [PID_DEL_PROCESO] /F
```

### ❌ "Sin sonido"
1. **Permitir autoplay** en el navegador:
   - Chrome: Configuración > Privacidad y seguridad > Configuración del sitio > Sonido
   - Firefox: about:preferences#privacy > Permisos > Reproducción automática

2. **Verificar archivos de sonido**:
```bash
ls -la assets/sounds/
# Debe mostrar: login.wav, message_in.wav, message_out.wav, nudge.wav, calling.wav
```

### ❌ "Scripts de PowerShell bloqueados"
```powershell
# Ejecutar como administrador una sola vez:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine

# O solo para el usuario actual:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### ❌ "Python no encontrado"
#### Linux:
```bash
sudo apt install python3  # Ubuntu/Debian
sudo yum install python3  # CentOS/RHEL
```

#### Windows:
# Windows:
- Descargar desde [python.org](https://www.python.org/downloads/windows/)
- O instalar desde Microsoft Store: "Python 3.11"

#### macOS:
```bash
brew install python3
```

---

## 🔍 Verificación de instalación exitosa

### ✅ Indicadores de éxito para ambas ediciones:

#### 🐳 **Docker Edition:**
1. **Contenedores ejecutándose**: `docker-compose -f docker/docker-compose.yml ps`
2. **MSN-AI accesible**: http://localhost:8000/msn-ai.html
3. **Sonido de inicio** de MSN al cargar
4. **Conexión verde** con Ollama
5. **Health check verde**: Contenedores saludables

#### 💻 **Local Edition:**
1. **Sonido de inicio** de MSN al cargar
2. **Conexión verde** en la esquina inferior derecha
3. **Lista de modelos** visible en configuración
4. **Chat de bienvenida** creado automáticamente
5. **Procesos activos**: Python server + Ollama

### 🧪 Test completo:
```bash
# Docker Edition:
docker-compose -f docker/docker-compose.yml logs
docker stats --no-stream

# Local Edition:
# Linux/macOS:
./test-msnai.sh

# Windows local: (disponible pronto)
# Get-Process python, ollama
```

---

## 🆘 Obtener ayuda

### 📧 Contacto directo
**Alan Mac-Arthur García Díaz**  
Email: [alan.mac.arthur.garcia.diaz@gmail.com](mailto:alan.mac.arthur.garcia.diaz@gmail.com)

### 🐛 Reportar problemas
- **GitHub Issues**: Para bugs y solicitudes de funcionalidades
- **Email**: Para soporte urgente
- **Documentación**: [README-MSNAI.md](README-MSNAI.md)

### 💡 Información útil para reportes
```bash
# Incluye esta información al reportar problemas:
echo "Plataforma: $(uname -a)"
echo "Versión MSN-AI: 1.0.0"
echo "Ollama: $(ollama --version)"
echo "Python: $(python3 --version)"
echo "Navegador: [Indica cuál usas]"
```

---

## 🎉 ¡Instalación completada!

Una vez que MSN-AI esté funcionando:

1. **Crea tu primer chat** con el botón "+"
2. **Envía un mensaje** y escucha los sonidos nostálgicos
3. **Explora la configuración** con el botón de engranaje
4. **Exporta tus chats** regularmente como respaldo

### ⏹️ Recuerda siempre detener correctamente:
En cualquier plataforma: **Ctrl + C** en la terminal/PowerShell donde iniciaste MSN-AI

## 🎯 Recomendaciones por tipo de usuario

### 🆕 **Usuario nuevo/casual:**
- **Usa Docker Edition** - Instalación de un comando, cero configuración
- Ideal para probar MSN-AI sin complicaciones
- Perfecto para usuarios no técnicos

### 🏢 **Entorno corporativo:**
- **Usa Docker Edition** - Aislamiento completo, fácil despliegue
- Sin modificaciones del sistema host
- Fácil escalabilidad y gestión

### ⚡ **Usuario avanzado/desarrollador:**
- **Usa Local Edition** si quieres máximo rendimiento
- **Usa Docker Edition** si prefieres containerización
- Ambas opciones ofrecen funcionalidad completa

### 🎮 **Máximo rendimiento IA:**
- **Local Edition** para rendimiento puro
- **Docker Edition con GPU** para balance perfecto
- Ambas soportan hardware GPU completamente

---

### 🔄 Migración entre ediciones

### Cambiar de Local a Docker:
```bash
# Si ya tienes MSN-AI Local
# 1. Exportar chats desde Local Edition
# (en la interfaz web: Configuración -> Exportar)

# 2. Clonar repositorio actualizado (si no tienes Docker Edition)
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI

# 3. Iniciar Docker Edition
./start-msnai-docker.sh --auto

# 4. Importar chats en Docker Edition
# (en la interfaz web: Configuración -> Importar)
```

### Reset completo MSN-AI (casos extremos):
```bash
# Cuando MSN-AI tiene problemas graves que no se resuelven:
./docker-cleanup.sh --nuclear

# ⚠️ IMPORTANTE: 
# - Solo elimina recursos de MSN-AI
# - NO afecta otros proyectos Docker
# - Resetea MSN-AI a estado fresco
# - Requiere confirmación doble

# Después del reset nuclear:
./start-msnai-docker.sh --auto  # Instalación completamente nueva
```

### Cambiar de Docker a Local:
```bash
# 1. Detener Docker
docker-compose -f docker/docker-compose.yml down

# 2. Backup de volúmenes (opcional)
docker run --rm -v msn-ai-chats:/data -v $(pwd):/backup alpine tar czf /backup/chats.tar.gz -C /data .

# 3. Iniciar Local Edition
./start-msnai.sh --auto

# 4. Los chats se importan desde la interfaz web
```

---

*MSN-AI v2.1.0 - Donde el pasado conversa con el futuro, y donde tú eliges cómo*

**Desarrollado con ❤️ por Alan Mac-Arthur García Díaz**  
**Licenciado bajo GPL-3.0 | Enero 2025**

**🐳 Docker con opción nuclear MSN-AI | 💻 Funciones locales conservadas | 🎯 Libertad total de elección**