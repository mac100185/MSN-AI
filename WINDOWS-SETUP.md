# Guía de Instalación y Uso de MSN-AI en Windows

> **Versión:** 1.0.0  
> **Autor:** Alan Mac-Arthur Garcia Diaz  
> **Email:** alan.mac.arthur.garcia.diaz@gmail.com  
> **Licencia:** GPL-3.0  
> **GitHub:** https://github.com/mac100185/MSN-AI

---

## 📋 Tabla de Contenidos

- [Requisitos del Sistema](#requisitos-del-sistema)
- [Instalación Rápida](#instalación-rápida)
- [Problema Común: Scripts Bloqueados](#problema-común-scripts-bloqueados)
- [Modo Local (Recomendado)](#modo-local-recomendado)
- [Modo Docker](#modo-docker)
- [Solución de Problemas](#solución-de-problemas)
- [Preguntas Frecuentes](#preguntas-frecuentes)

---

## 🖥️ Requisitos del Sistema

### Mínimos
- **Sistema Operativo:** Windows 10 o superior
- **PowerShell:** 5.1+ (incluido en Windows)
- **RAM:** 4GB (8GB recomendado)
- **Espacio en disco:** 2GB libres
- **Navegador:** Chrome, Edge, Firefox o Brave

### Opcionales
- **Python:** 3.6+ (para modo servidor local)
- **Docker Desktop:** Para modo Docker
- **Ollama:** Para funcionalidad de IA (se instala automáticamente)

---

## 🚀 Instalación Rápida

### Paso 1: Clonar el Repositorio

Abre **PowerShell** y ejecuta:

```powershell
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
```

### Paso 2: Habilitar Ejecución de Scripts (Solo Primera Vez)

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Paso 3: ⚠️ IMPORTANTE - Desbloquear Scripts

**Este es el paso MÁS IMPORTANTE si descargaste los archivos de Internet:**

```powershell
# Desbloquear todos los scripts de PowerShell
Unblock-File -Path .\start-msnai.ps1
Unblock-File -Path .\start-msnai-docker.ps1
Unblock-File -Path .\ai_check_all.ps1
```

### Paso 4: Verificar Hardware (Opcional)

```powershell
.\ai_check_all.ps1
```

Este script detectará tu hardware y recomendará el mejor modelo de IA.

### Paso 5: Iniciar MSN-AI

```powershell
# Modo automático (recomendado)
.\start-msnai.ps1 --auto

# Modo interactivo (te pregunta opciones)
.\start-msnai.ps1
```

---

## 🔒 Problema Común: Scripts Bloqueados

### ¿Por qué necesito usar `Unblock-File`?

Windows marca automáticamente los archivos descargados de Internet con un "flag de seguridad" que impide su ejecución. Esto es una medida de seguridad de Windows llamada **Mark of the Web (MOTW)**.

### Síntomas de Scripts Bloqueados

Si intentas ejecutar un script bloqueado, verás errores como:

```
En D:\MSN-AI-main\start-msnai.ps1: 55 Carácter: 5
+     }
+     ~
Token '}' inesperado en la expresión o la instrucción.
```

O un mensaje de seguridad de Windows que dice:
```
El archivo proviene de otro equipo y puede estar bloqueado para proteger este equipo.
```

### Solución: Desbloquear Archivos

**Opción 1: Desbloquear archivos específicos (Recomendado)**

```powershell
# Navega al directorio MSN-AI
cd MSN-AI

# Desbloquea cada script
Unblock-File -Path .\start-msnai.ps1
Unblock-File -Path .\start-msnai-docker.ps1
Unblock-File -Path .\ai_check_all.ps1
```

**Opción 2: Desbloquear todos los archivos .ps1 del directorio**

```powershell
Get-ChildItem -Path . -Filter *.ps1 -Recurse | Unblock-File
```

**Opción 3: Desbloquear mediante Interfaz Gráfica**

1. Haz clic derecho en el archivo `.ps1`
2. Selecciona **Propiedades**
3. En la pestaña **General**, al final verás:
   - ☑️ **Desbloquear** - Marca esta casilla
4. Haz clic en **Aplicar** y luego **Aceptar**
5. Repite para cada archivo `.ps1`

### Verificar si un Archivo Está Bloqueado

```powershell
Get-Item .\start-msnai.ps1 | Get-ItemProperty -Name "Zone.Identifier" -ErrorAction SilentlyContinue
```

Si devuelve algo, el archivo está bloqueado. Si no devuelve nada, está desbloqueado.

---

## 💻 Modo Local (Recomendado)

### Ventajas
- ✅ Máximo rendimiento
- ✅ Sin dependencias de Docker
- ✅ Inicio más rápido
- ✅ Menor uso de recursos

### Requisitos Adicionales
- Python 3.6+ instalado ([Descargar Python](https://www.python.org/downloads/))

### Instalación

```powershell
# 1. Clonar repositorio
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI

# 2. Habilitar scripts (solo la primera vez)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Desbloquear scripts (IMPORTANTE)
Unblock-File -Path .\start-msnai.ps1
Unblock-File -Path .\ai_check_all.ps1

# 4. Verificar hardware (opcional)
.\ai_check_all.ps1

# 5. Iniciar aplicación
.\start-msnai.ps1 --auto
```

### Opciones de Inicio

```powershell
# Modo automático (servidor local)
.\start-msnai.ps1 --auto

# Modo interactivo (elige opción)
.\start-msnai.ps1

# Opciones disponibles:
# 1) Servidor local - Requiere Python (recomendado)
# 2) Archivo directo - Sin servidor (limitaciones CORS)
# 3) Solo verificar - Verifica el sistema sin iniciar
```

### Detener el Servidor

1. Ve a la ventana de PowerShell donde ejecutaste el script
2. Presiona **Ctrl + C**
3. Espera a que el script limpie los procesos
4. **NO cierres** la ventana sin presionar Ctrl+C

---

## 🐳 Modo Docker

### Ventajas
- ✅ Entorno aislado y portable
- ✅ No requiere Python
- ✅ Incluye todo preconfigurado
- ✅ Fácil de actualizar

### Requisitos Adicionales
- Docker Desktop para Windows ([Descargar Docker](https://www.docker.com/products/docker-desktop))

### Instalación

```powershell
# 1. Clonar repositorio
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI

# 2. Habilitar scripts (solo la primera vez)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Desbloquear scripts (IMPORTANTE)
Unblock-File -Path .\start-msnai-docker.ps1

# 4. Iniciar aplicación (instalará Docker si falta)
.\start-msnai-docker.ps1 --auto
```

### Gestión de Contenedores

```powershell
# Iniciar contenedores
.\start-msnai-docker.ps1 --auto

# Detener contenedores
docker-compose -f docker/docker-compose.yml down

# Ver contenedores activos
docker ps

# Ver logs
docker-compose -f docker/docker-compose.yml logs -f

# Reiniciar contenedores
docker-compose -f docker/docker-compose.yml restart
```

---

## 🔧 Solución de Problemas

### Error: "No se puede cargar el archivo porque la ejecución de scripts está deshabilitada"

**Solución:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Error: "Token inesperado" o errores de sintaxis

**Causa:** Archivo bloqueado por Windows

**Solución:**
```powershell
Unblock-File -Path .\start-msnai.ps1
```

### Error: "Python no está instalado"

**Solución:**
1. Descarga Python desde: https://www.python.org/downloads/
2. Durante la instalación, marca ☑️ **"Add Python to PATH"**
3. Reinicia PowerShell
4. Verifica: `python --version`

**Alternativa:** Usa el modo archivo directo (opción 2) o modo Docker

### Error: "No se encuentra msn-ai.html"

**Causa:** No estás en el directorio correcto

**Solución:**
```powershell
cd MSN-AI
.\start-msnai.ps1
```

### Error: "Ollama no está instalado"

**Solución Automática:**
El script te preguntará si deseas instalar Ollama automáticamente. Responde **"s"** (sí).

**Solución Manual:**
1. Descarga Ollama desde: https://ollama.com/download
2. Instala el ejecutable
3. Ejecuta: `ollama pull mistral:7b`

### El navegador no se abre automáticamente

**Solución:**
Abre manualmente en tu navegador:
```
http://localhost:8000/msn-ai.html
```

### Problemas con puertos ocupados

El script busca automáticamente puertos disponibles (8000-8020).

**Verificar puertos en uso:**
```powershell
Get-NetTCPConnection -LocalPort 8000
```

**Liberar puerto:**
```powershell
# Buscar proceso usando el puerto
Get-NetTCPConnection -LocalPort 8000 | Select-Object -Property OwningProcess
# Detener proceso (reemplaza XXXX con el PID)
Stop-Process -Id XXXX
```

### Docker Desktop no se inicia

**Solución:**
1. Verifica que la virtualización esté habilitada en BIOS (VT-x/AMD-V)
2. Activa Hyper-V:
   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   ```
3. Reinicia el equipo

---

## ❓ Preguntas Frecuentes

### ¿Necesito permisos de administrador?

**No.** MSN-AI se ejecuta con permisos de usuario normal. Solo necesitas habilitar la ejecución de scripts (paso único).

### ¿Puedo usar MSN-AI sin Ollama?

**Sí**, pero con funcionalidad limitada. La aplicación funcionará, pero no podrás chatear con la IA. Solo tendrás la interfaz de MSN.

### ¿Qué modelo de IA debo instalar?

Ejecuta `.\ai_check_all.ps1` para que detecte tu hardware y recomiende el mejor modelo.

**Recomendaciones generales:**
- **8GB+ RAM:** `mistral:7b` (recomendado)
- **16GB+ RAM:** `llama2:13b` o `mixtral:8x7b`
- **32GB+ RAM con GPU:** `llama2:70b` o `codellama:34b`

### ¿Cómo actualizo MSN-AI?

```powershell
cd MSN-AI
git pull origin main
.\start-msnai.ps1 --auto
```

### ¿Puedo ejecutar MSN-AI en segundo plano?

**Modo Local:** No, el servidor debe estar activo en PowerShell.

**Modo Docker:** Sí, los contenedores siguen ejecutándose:
```powershell
docker-compose -f docker/docker-compose.yml up -d
```

### ¿Cómo cambio el puerto del servidor?

Edita el archivo `start-msnai.ps1` y modifica la línea:
```powershell
$script:ServerPort = 8000  # Cambia a tu puerto deseado
```

### ¿Funciona sin Internet?

**Sí**, una vez descargado todo (incluyendo modelos de IA), MSN-AI funciona completamente offline.

---

## 📚 Recursos Adicionales

- **Repositorio GitHub:** https://github.com/mac100185/MSN-AI
- **Documentación completa:** Ver README.md
- **Reportar problemas:** https://github.com/mac100185/MSN-AI/issues
- **Contacto:** alan.mac.arthur.garcia.diaz@gmail.com

---

## 📝 Comandos de Referencia Rápida

### Instalación Completa
```powershell
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Unblock-File -Path .\start-msnai.ps1
Unblock-File -Path .\ai_check_all.ps1
.\ai_check_all.ps1
.\start-msnai.ps1 --auto
```

### Inicio Rápido (después de instalación)
```powershell
cd MSN-AI
.\start-msnai.ps1 --auto
```

### Detener
```
Ctrl + C (en la ventana de PowerShell)
```

### Verificar Estado
```powershell
# Python
python --version

# Ollama
ollama list

# Docker
docker ps
```

---

## 🛡️ Seguridad

### ¿Es seguro usar `Unblock-File`?

**Sí**, es seguro para archivos de fuentes confiables (como este repositorio de GitHub). 

**Recomendaciones:**
- ✅ Verifica que el repositorio es oficial: https://github.com/mac100185/MSN-AI
- ✅ Revisa el contenido de los scripts antes de ejecutarlos
- ✅ Usa `Get-FileHash` para verificar integridad si tienes dudas
- ❌ NO desbloquees scripts de fuentes desconocidas

### Verificar Integridad de Archivos

```powershell
# Ver hash SHA256 de un archivo
Get-FileHash .\start-msnai.ps1 -Algorithm SHA256
```

---

## 📄 Licencia

Este proyecto está licenciado bajo GPL-3.0. Ver [LICENSE](LICENSE) para más detalles.

---

## 🙏 Agradecimientos

- **Microsoft Corporation** - Por Windows Live Messenger original
- **Ollama Team** - Por hacer la IA local accesible
- **Comunidad Open Source** - Por herramientas y librerías utilizadas

---

**¿Listo para revivir la nostalgia?** 🎉

```powershell
.\start-msnai.ps1 --auto
```

**¡Disfruta de MSN-AI!** 💬✨