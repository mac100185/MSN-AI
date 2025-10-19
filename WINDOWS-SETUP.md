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
- [Instalación de Ollama](#instalación-de-ollama)
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

### Paso 4: Iniciar MSN-AI

```powershell
# Modo automático (recomendado)
.\start-msnai.ps1 --auto

# Modo interactivo (te pregunta opciones)
.\start-msnai.ps1
```

**NOTA IMPORTANTE:** Si Ollama no está instalado, el script te guiará para instalarlo:
1. Te preguntará si quieres abrir la página de descarga
2. Descarga e instala OllamaSetup.exe desde https://ollama.com/download
3. **IMPORTANTE:** Después de instalar Ollama, CIERRA PowerShell
4. Abre una NUEVA ventana de PowerShell
5. Navega al directorio MSN-AI y ejecuta `.\start-msnai.ps1 --auto` nuevamente

### Paso 5 (Opcional): Verificar Hardware y Obtener Recomendaciones

```powershell
.\ai_check_all.ps1
```

Este script:
- Detecta tu CPU, RAM y GPU
- Recomienda el mejor modelo de IA según tu hardware
- Te ayuda a instalar Ollama si no lo tienes
- Descarga el modelo recomendado automáticamente

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

## 🤖 Instalación de Ollama

Ollama es el motor de IA que permite a MSN-AI tener conversaciones inteligentes. Su instalación es **opcional**, pero altamente recomendada para aprovechar todas las funciones.

### ¿Cuándo instalar Ollama?

El script `start-msnai.ps1` detecta automáticamente si Ollama está instalado:
- Si **NO está instalado**: Te guiará paso a paso para instalarlo
- Si **YA está instalado**: Verificará los modelos disponibles

### Proceso de Instalación Guiada

1. **Ejecuta MSN-AI por primera vez:**
   ```powershell
   .\start-msnai.ps1 --auto
   ```

2. **El script detecta que Ollama no está instalado y pregunta:**
   ```
   Ollama no esta instalado
   
   Deseas abrir la pagina de descarga de Ollama? (s/n):
   ```

3. **Responde "s" (sí):**
   - Se abrirá automáticamente: https://ollama.com/download
   - Verás instrucciones claras en pantalla

4. **Descarga e instala Ollama:**
   - Descarga **OllamaSetup.exe** desde la página
   - Ejecuta el instalador
   - Sigue el asistente de instalación (Next, Next, Install)
   - Espera a que complete la instalación

5. **⚠️ PASO CRÍTICO - Reiniciar PowerShell:**
   - **CIERRA** completamente la ventana de PowerShell actual
   - **ABRE** una nueva ventana de PowerShell
   - Navega al directorio: `cd MSN-AI`

6. **Ejecuta el script nuevamente:**
   ```powershell
   .\start-msnai.ps1 --auto
   ```

7. **Ahora Ollama es detectado y puedes instalar modelos:**
   ```
   Ollama ya esta ejecutandose
   Verificando modelos de IA instalados...
   No hay modelos de IA instalados
   
   Deseas instalar el modelo mistral:7b (recomendado, 4.1GB)? (s/n):
   ```

### ¿Por qué debo reiniciar PowerShell?

Windows actualiza las variables de entorno (especialmente el PATH) solo cuando se abre una nueva sesión de terminal. PowerShell necesita reiniciarse para "ver" que Ollama está instalado y disponible en el sistema.

### Instalar Modelos de IA

Después de instalar Ollama, necesitas descargar al menos un modelo de IA. El script te lo preguntará automáticamente.

**Modelos recomendados según hardware:**

| Hardware | Modelo Recomendado | Tamaño | Descripción |
|----------|-------------------|--------|-------------|
| GPU 24GB+ VRAM | `llama3:8b` | 4.7 GB | Avanzado, excelente para tareas complejas |
| GPU 12-24GB VRAM | `mistral:7b` | 4.1 GB | Equilibrado, recomendado general |
| GPU 6-12GB VRAM | `phi3:mini` | 2.3 GB | Ligero y eficiente |
| Sin GPU, 32GB+ RAM | `mistral:7b` | 4.1 GB | Funciona en CPU (lento) |
| Sin GPU, 16-32GB RAM | `phi3:mini` | 2.3 GB | Optimizado para CPU |
| Recursos limitados | `tinyllama` | 637 MB | Ultra ligero |

**Para instalar un modelo manualmente:**
```powershell
ollama pull mistral:7b
# O cualquier otro modelo
ollama pull phi3:mini
ollama pull tinyllama
```

### Verificar Instalación de Ollama

```powershell
# Verificar que Ollama está instalado
ollama --version

# Ver modelos instalados
ollama list

# Probar un modelo
ollama run mistral:7b
```

### Usar MSN-AI sin Ollama

Si decides no instalar Ollama (respondiendo "n" cuando el script pregunta):
- ✅ MSN-AI funcionará normalmente
- ✅ Tendrás la interfaz completa de MSN Messenger
- ❌ NO podrás usar las funciones de chat con IA
- ❌ El asistente inteligente no estará disponible

Puedes instalar Ollama en cualquier momento y ejecutar el script nuevamente.

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

# 4. Iniciar aplicación
.\start-msnai.ps1 --auto

# NOTA: Si Ollama no está instalado, el script te guiará para instalarlo.
#       Después de instalar Ollama, CIERRA PowerShell y abre una NUEVA ventana.
#       Luego ejecuta nuevamente: .\start-msnai.ps1 --auto

# 5. (Opcional) Verificar hardware y obtener recomendaciones de modelos IA
.\ai_check_all.ps1
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

# NOTA: Si Docker no está instalado, el script abrirá la página de descarga
#       y te guiará en el proceso de instalación.
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

**Comportamiento del script:**
El script `start-msnai.ps1` detectará que Ollama no está instalado y te preguntará si quieres abrir la página de descarga.

**Pasos a seguir:**
1. Cuando el script pregunte, responde **"s"** (sí)
2. Se abrirá automáticamente: https://ollama.com/download
3. Descarga **OllamaSetup.exe**
4. Ejecuta el instalador y completa el asistente de instalación
5. **IMPORTANTE:** Después de instalar, CIERRA la ventana de PowerShell
6. Abre una **NUEVA** ventana de PowerShell
7. Navega al directorio: `cd MSN-AI`
8. Ejecuta nuevamente: `.\start-msnai.ps1 --auto`
9. Ahora Ollama será detectado y podrás instalar modelos de IA

**¿Por qué debo reiniciar PowerShell?**
Windows actualiza las variables de entorno (PATH) solo al abrir una nueva sesión. PowerShell necesita reiniciarse para detectar que Ollama está instalado.

**Alternativa - Continuar sin Ollama:**
Puedes responder **"n"** (no) cuando el script pregunte, y MSN-AI se ejecutará sin funciones de IA.

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

**No.** MSN-AI se ejecuta con permisos de usuario normal. Solo necesitas habilitar la ejecución de scripts con `Set-ExecutionPolicy` (paso único, no requiere admin).

### ¿Puedo usar MSN-AI sin Ollama?

**Sí**, pero con funcionalidad limitada. La aplicación funcionará perfectamente, pero no podrás usar las funciones de chat con IA. Tendrás la interfaz completa de MSN pero sin el asistente de inteligencia artificial.

### ¿Qué modelo de IA debo instalar?

El script `.\ai_check_all.ps1` detecta automáticamente tu hardware y recomienda el mejor modelo.

**Recomendaciones generales:**
- **GPU 24GB+ VRAM:** `llama3:8b` (4.7 GB)
- **GPU 12-24GB VRAM:** `mistral:7b` (4.1 GB) - Recomendado general
- **GPU 6-12GB VRAM:** `phi3:mini` (2.3 GB)
- **Sin GPU, 32GB+ RAM:** `mistral:7b` (4.1 GB)
- **Sin GPU, 16-32GB RAM:** `phi3:mini` (2.3 GB)
- **Recursos limitados:** `tinyllama` (637 MB)

### ¿Cómo actualizo MSN-AI?

```powershell
cd MSN-AI
git pull origin main
# Desbloquea los scripts si se actualizaron
Unblock-File -Path .\start-msnai.ps1
Unblock-File -Path .\ai_check_all.ps1
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
.\start-msnai.ps1 --auto

# Si Ollama no está instalado, el script te guiará.
# Después de instalar, cierra PowerShell, abre una nueva ventana y ejecuta:
# .\start-msnai.ps1 --auto
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