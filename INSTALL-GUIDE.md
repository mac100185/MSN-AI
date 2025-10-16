# 🌍 Guía de Instalación Multiplataforma - MSN-AI

**Versión 1.0.0** | **Por Alan Mac-Arthur García Díaz**

Esta guía te ayudará a instalar y configurar MSN-AI en **Linux**, **Windows** o **macOS**.

---

## 🎯 Selecciona tu plataforma

- [🐧 **LINUX**](#-linux) - Ubuntu, Debian, CentOS, etc.
- [🪟 **WINDOWS**](#-windows) - Windows 10/11
- [🍎 **macOS**](#-macos) - macOS 10.14+

---

## 🐧 LINUX

### ⚡ Instalación rápida (1 comando)
```bash
git clone [URL_DEL_REPO] && cd MSN-AI && chmod +x *.sh && ./start-msnai.sh --auto
```

### 📋 Instalación paso a paso

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
git clone [URL_DEL_REPO]
cd MSN-AI

# Opción B: Descarga directa
wget [URL_ZIP]
unzip msn-ai.zip && cd MSN-AI
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

## 🪟 WINDOWS

### ⚡ Instalación rápida (PowerShell)
```powershell
# 1. Abrir PowerShell como usuario normal
# 2. Habilitar scripts (solo una vez)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Descargar e iniciar
# [Descargar ZIP desde GitHub, extraer y navegar al directorio]
.\start-msnai.ps1 --auto
```

### 📋 Instalación paso a paso

#### 1. Preparar PowerShell
```powershell
# Abrir PowerShell (NO como administrador)
# Windows + R -> "powershell" -> Enter

# Habilitar ejecución de scripts (solo la primera vez)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 2. Descargar MSN-AI
- **Opción A**: Descargar ZIP desde GitHub
  1. Ve al repositorio de MSN-AI
  2. Clic en "Code" > "Download ZIP"
  3. Extrae el ZIP en `C:\Users\TuUsuario\Documents\MSN-AI`

- **Opción B**: Git for Windows
```powershell
# Si tienes Git instalado
git clone [URL_DEL_REPO]
cd MSN-AI
```

#### 3. Navegar al directorio
```powershell
cd "C:\Users\TuUsuario\Documents\MSN-AI"
# O donde hayas extraído los archivos
```

#### 4. Configurar IA (recomendado)
```powershell
.\ai_check_all.ps1
```

#### 5. Iniciar MSN-AI
```powershell
.\start-msnai.ps1 --auto
```

### 🔧 Configuración específica para Windows

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

## 🍎 macOS

### ⚡ Instalación rápida (Terminal)
```bash
curl -o msn-ai.zip [URL_ZIP] && unzip msn-ai.zip && cd MSN-AI && chmod +x *.sh && ./start-msnai-mac.sh --auto
```

### 📋 Instalación paso a paso

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
git clone [URL_DEL_REPO]
cd MSN-AI

# Opción B: Descarga directa
curl -L -o msn-ai.zip [URL_ZIP]
unzip msn-ai.zip && cd MSN-AI
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

### 🔧 Configuración específica para macOS

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

### ❌ "Ollama no responde"
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

### ❌ "Puerto 8000 ocupado"
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
- Descargar desde [python.org](https://www.python.org/downloads/windows/)
- O instalar desde Microsoft Store: "Python 3.11"

#### macOS:
```bash
brew install python3
```

---

## 🔍 Verificación de instalación exitosa

### ✅ Indicadores de éxito:
1. **Sonido de inicio** de MSN al cargar
2. **Conexión verde** en la esquina inferior derecha
3. **Lista de modelos** visible en configuración
4. **Chat de bienvenida** creado automáticamente

### 🧪 Test completo:
```bash
# Linux:
./test-msnai.sh

# macOS:
./test-msnai.sh

# Windows:
# (El test está disponible solo para Linux/macOS por ahora)
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

---

*MSN-AI v1.0.0 - Donde el pasado conversa con el futuro*

**Desarrollado con ❤️ por Alan Mac-Arthur García Díaz**  
**Licenciado bajo GPL-3.0 | Enero 2025**