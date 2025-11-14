# 🚀 MSN-AI - Windows Live Messenger con IA Local

![MSN-AI](assets/general/logo.png)

> *Donde la nostalgia se encuentra con la inteligencia artificial moderna*

**Versión 3.0.1** | **Licencia GPL-3.0** | **Por Alan Mac-Arthur García Díaz**

<p align="center">
  <img src="assets/screenshots/msn-ai-v3.0.1.png" alt="MSN-AI v3.0.1 - Interfaz principal" width="850"/>
</p>

---

## 📋 Tabla de Contenidos

- [🎯 ¿Qué es MSN-AI?](#-qué-es-msn-ai)
- [✨ Características Principales](#-características-principales)
- [🚀 Inicio Rápido](#-inicio-rápido)
- [📋 Requisitos del Sistema](#-requisitos-del-sistema)
- [🌍 Instalación por Plataforma](#-instalación-por-plataforma)
- [🧠 Comandos de Ollama](#-comandos-de-ollama-para-gestionar-modelos)
- [🎮 Guía de Uso](#-guía-de-uso)
- [⚙️ Configuración](#️-configuración)
- [🏗️ Arquitectura del Proyecto](#️-arquitectura-del-proyecto)
- [📊 Estadísticas del Proyecto](#-estadísticas-del-proyecto)
- [🤝 Contribuir](#-contribuir)
- [📞 Contacto y Soporte](#-contacto-y-soporte)
- [⚖️ Licencia](#️-licencia)


---

## 🎯 ¿Qué es MSN-AI?

MSN-AI es una aplicación web que combina la interfaz nostálgica de **Windows Live Messenger** con modelos de **IA local y en la nube** ejecutados a través de Ollama.

**Dos ediciones disponibles:**

| **🐳 Docker Edition** | **💻 Local Edition** |
|----------------------|---------------------|
| Instalación de 1 comando | Instalación tradicional |
| Cero configuración manual | Máximo control |
| Compatible universal | Rendimiento nativo |
| Ideal para nuevos usuarios | Ideal para desarrolladores |

---

## ✨ Características Principales

### 🎨 Interfaz y Experiencia
- **Interfaz** de Windows Live Messenger (WLM/MSN)
- **5 sonidos originales** de MSN (login, logout, message_in, message_out, nudge)
- **Estados de presencia** - Online 🟢, Away 🟡, Busy 🔴, Invisible ⚪
- **30 emoticones integrados** - 2 categorías (Naturales y Amor)
- **Animaciones MSN** - Efectos visuales clásicos.

### 🤖 Inteligencia Artificial
- **IA local integrada** - Compatible con todos los modelos de Ollama.
- **IA en la nube** - Modelos cloud de Ollama (con API Key o signin).
- **Detección automática de modelos** - Carga dinámica de modelos disponibles.
- **Multi-chat simultáneo** - La IA responde en varios chats a la vez.
- **Salas de Expertos (Expert Rooms)** 🏢 - Chats grupales con múltiples modelos de IA respondiendo secuencialmente.
- **System Prompt para Salas Grupales** 🤖 - Instrucciones contextuales automáticas para cada modelo participante con variables dinámicas `{{MODEL_NAME}}` y `{{PARTICIPANT_LIST}}`.
- **Detener respuesta** ⏹️ - Aborta generación en curso (funciona en chats individuales y salas de expertos).
- **Notificación de estado a IA** - La IA sabe cuando cambias tu estado.

### 💬 Gestión de Chats
- **Persistencia automática** - localStorage del navegador.
- **Búsqueda avanzada** - En todos los chats o dentro de uno específico.
- **Ordenar historial** - Por fecha ascendente/descendente.
- **Indicadores de no leídos** - Resalta chats nuevos en verde.
- **Limpiar chat** - Borra mensajes sin eliminar el chat.
- **Cerrar chat** - Cierra vista sin eliminar (con confirmación)
- **Eliminar chat** - Elimina permanentemente (con modal)
- **Imprimir chat** - Versión imprimible con estilos.

### 📁 Gestión de Archivos
- **Subir archivos TXT** - Carga archivos de texto directamente.
- **Subir archivos PDF** - Procesamiento completo con extracción de texto.
- **Subir archivos JPG, PNG, GIF, SVG** - Procesamiento completo de imágenes.
- **OCR integrado** - Tesseract.js para PDFs escaneados.
- **Fragmentación inteligente** - División automática en chunks.
- **Persistencia en IndexedDB** - Almacenamiento de archivos adjuntos.
- **Descarga de archivos** - Recupera archivos en formato original.
- **Preview de archivos** - Vista previa antes de enviar.
- **Límite de 10MB** - Por archivo para rendimiento óptimo.

### 📝 Edición de Texto
- **Ajuste de tamaño** - 10px a 32px con botones ±
- **Formato de texto** - Negrita, cursiva, subrayado.
- **Dictado por voz** 🎤 - Web Speech API con reconocimiento continuo, feedback visual/auditivo, y soporte multiidioma.
- **Emoticones mejorados** 😊 - 2 categorías (Naturales y Amor) con cierre automático al seleccionar.
- **Zumbido/Nudge** 📳 - Como MSN original.

### 🎨 Generador de Prompts Profesional
- **Formulario avanzado** con 11 campos especializados:
  - 👤 Rol del LLM.
  - 📝 Contexto.
  - 👥 Audiencia.
  - 📋 Tareas (múltiples líneas).
  - ℹ️ Instrucciones.
  - 💬 Empatía y Tono.
  - ❓ Clarificación.
  - 🔄 Refinamiento.
  - 🚫 Límites.
  - ⚠️ Consecuencias.
  - ✨ Ejemplo de Respuesta.
- **Generación automática** de prompts estructurados.
- **Visualización profesional** con formato.
- **Modo edición** para modificar prompts existentes.

### 📚 Gestor de Prompts Guardados
- **Biblioteca completa** de prompts con metadatos:
  - Nombre personalizado.
  - Descripción detallada.
  - Categoría personalizable.
  - Tags/etiquetas múltiples.
  - Fecha de creación.
- **Sistema de filtrado**:
  - Por categoría.
  - Por búsqueda de texto.
  - Visualización tipo Pinterest.
- **Gestión avanzada**:
  - Ver detalles completos.
  - Editar prompts guardados.
  - Usar directamente en chat.
  - Cargar en formulario.
  - Eliminar individual o todos.
- **Import/Export** de prompts (JSON).
- **Contador** de prompts guardados.
- **Almacenamiento** en localStorage.

### 📤 Import/Export
- **Exportar todos** - JSON completo con configuración.
- **Exportar seleccionados** - Con checkboxes.
- **Exportar chat actual** - Conversación individual.
- **Exportar prompts** - Biblioteca completa.
- **Importación inteligente** - Resolución automática de conflictos.
- **Importar prompts** - Desde archivo JSON.

### 🌍 Sistema Multiidioma (22 idiomas)
🇪🇸 Español | 🇬🇧 Inglés | 🇩🇪 Alemán | 🇫🇷 Francés | 🇸🇦 Árabe | 🇨🇳 Chino | 🇮🇳 Hindi | 🇧🇩 Bengalí | 🇵🇹 Portugués | 🇷🇺 Ruso | 🇯🇵 Japonés | 🇰🇷 Coreano | 🇮🇩 Indonesio | 🇹🇷 Turco | 🇵🇰 Urdu | 🇻🇳 Vietnamita | 🇮🇳 Tamil | 🇮🇳 Telugu | 🇮🇳 Maratí | 🇮🇳 Panyabí | 🇵🇪 Quechua | 🇧🇴 Aymara

- **Detección automática** del idioma del navegador.
- **Cambio manual** desde configuración.
- **Persistencia** entre sesiones.
- **Traducción completa** de toda la interfaz.
- **System Prompt multiidioma** - Traducción automática del system prompt al cambiar idioma.

### 🐳 Docker Edition
- **Instalación simplificada** - Un comando para instalar.
- **Scripts de gestión** - Inicio, parada, estado, logs, limpieza.
- **Health checks automáticos** - Monitoreo de servicios.
- **Volúmenes persistentes** - Datos y configuración.
- **Opción Nuclear** - Reset completo de MSN-AI.

### 💻 Local Edition
- **Rendimiento nativo** - Sin overhead de contenedores.
- **Scripts automáticos** - Para Linux, Windows y macOS.
- **Detector de hardware** - Recomienda modelos según tu sistema.
- **Accesos directos** - Lanzadores en escritorio.

---

## 🚀 Inicio Rápido

### 🐳 Docker Edition (Recomendado)

#### 🐧/🍎 Linux / macOS
```bash
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
cd linux  # o cd macos para macOS
chmod +x start-msnai-docker.sh
./start-msnai-docker.sh --auto

```

**Instalación de modelos IA Cloud (Opcional):**
```bash
# Para Linux
./docker-install-cloud-models.sh

# Para macOS
cd ../macos
./docker-install-cloud-models-mac.sh
```

#### 🪟 Windows (PowerShell)
```powershell
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
cd windows
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Unblock-File -Path .\start-msnai-docker.ps1
.\start-msnai-docker.ps1 --auto
```

**Instalación de modelos IA Cloud (Opcional):**
```powershell
Unblock-File -Path .\docker-install-cloud-models.ps1
.\docker-install-cloud-models.ps1
```

#### Scripts de gestión Docker:

**Linux:**
```bash
cd linux
./docker-start.sh              # Iniciar
./docker-status.sh             # Estado
./docker-logs.sh --follow      # Logs en tiempo real
./docker-stop.sh               # Detener
./docker-cleanup.sh -a         # Eliminación total
./docker-check-config.sh       # Verificar configuración
./docker-diagnostics.sh        # Diagnóstico completo
./docker-test-ai.sh            # Probar IA
```

**macOS:**
```bash
cd macos
./docker-diagnostics-mac.sh    # Diagnóstico para macOS
./docker-check-signin-mac.sh   # Verificar signin cloud
# Resto de scripts en carpeta linux/
```

#### Acceso:
- Local: `http://localhost:8000/msn-ai.html`
- Remoto: `http://[IP-SERVIDOR]:8000/msn-ai.html`

### 💻 Local Edition - Un comando
#### 🐧 Linux / 🍎 macOS
```bash
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
cd linux
chmod +x *.sh
./start.sh --auto        # Iniciar MSN-AI
```
#### 🪟 Windows
```powershell
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Unblock-File -Path .\start.ps1
.\start.ps1 --auto       # Iniciar MSN-AI
```


### 💻 Local Edition - Por sistema operativo individual
#### 🐧 Linux
```bash
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
cd linux
chmod +x *.sh
./ai_check_all.sh              # Detecta hardware (opcional)
./start-msnai.sh --auto        # Iniciar MSN-AI
./create-desktop-shortcut.sh   # Crear lanzador
```

#### 🍎 macOS
```bash
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
cd macos
chmod +x *.sh
./ai_check_all_mac.sh          # Detecta hardware (opcional)
./start-msnai-mac.sh --auto    # Iniciar MSN-AI
./create-desktop-shortcut-mac.sh  # Crear un acceso directo en el escritorio
```

#### 🪟 Windows
```powershell
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
cd windows
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Unblock-File -Path .\start-msnai.ps1
Unblock-File -Path .\ai_check_all.ps1
Unblock-File -Path .\create-desktop-shortcut.ps1
.\ai_check_all.ps1             # Detecta hardware (opcional)
.\start-msnai.ps1 --auto       # Iniciar MSN-AI
.\create-desktop-shortcut.ps1  # Crear acceso directo
```

**Acceso:**
- Local: `http://localhost:8000/msn-ai.html`

**Nota importante:** Si el puerto 8000 está en uso, MSN-AI intentará usar el puerto 8001 y así sucesivamente hasta encontrar uno disponible. Si por lo tanto los chats estarán disponibles en el puerto libre encontrado. Por ejemplo si creaste chats en el puerto 8000 y si luego MSN-AI pasa al 8001, los chats del puerto 8000 no estarán disponibles en el puerto 8001.

### ⏹️ Detener Correctamente

**En Docker:**
```bash
cd linux  # Linux o macOS
./docker-stop.sh
```
**En Windows usar la GUI de Docker para detener MSN-AI**

**En Local:**
```bash
Ctrl + C  # En la terminal donde se ejecutó (Windows, Linux, macOS)
```

**Emergencia Docker:**
```bash
cd linux  # Linux o macOS
./docker-cleanup.sh -a  # Reset completo MSN-AI
```

**Emergencia Local:**
```bash
# Linux/macOS
pkill -f "start-msnai"
pkill -f "python.*http.server"

# Windows
Get-Process -Name "python" | Where-Object {$_.CommandLine -like "*http.server*"} | Stop-Process
```

---

## 📋 Requisitos del Sistema

### 🐳 Docker Edition
- **Docker Engine** 20.10+ o Docker Desktop
- **SO**: Linux (Ubuntu 18.04+, Debian 10+), Windows 10/11, macOS 10.14+
- **RAM**: 2GB+ (16GB recomendado para modelos grandes)
- **Disco**: 10GB+ libre
- **GPU**: NVIDIA (opcional, para aceleración)

### 💻 Local Edition

**Linux:**
- Ubuntu 18.04+, Debian 10+, Fedora 32+ o compatible
- Python 3.6+ (generalmente preinstalado)
- Ollama instalado

**Windows:**
- Windows 10/11 (64-bit)
- PowerShell 5.1+
- Python 3.6+ (opcional)
- Ollama instalado

**macOS:**
- macOS 10.14+ (Mojave o superior)
- Python 3.6+ (incluido en el sistema)
- Ollama instalado

### 🌐 Común para Ambas Ediciones
- **Navegador**: Chrome 80+, Firefox 75+, Safari 14+, Edge 80+
- **JavaScript** habilitado
- **localStorage** disponible

### 🤖 Modelos de IA Recomendados

**GPU con 4GB+ VRAM:**
- `mistral:7b` (Local)
- `llama3.2:latest` (Local)
- `qwen2.5:7b` (Local)
- `qwen3-vl:235b-cloud` (Nube)
- `gpt-oss:120b-cloud` (Nube)
- `qwen3-coder:480b-cloud` (Nube)
- Modelos cloud de Ollama (requieren autenticación por signin)

**CPU o GPU NVIDIA con 8GB+ RAM:**
- `phi3:mini` (Local - 3.8GB)
- `gemma2:2b` (Local - 1.6GB)
- `tinyllama` (Local - 637MB)
- `qwen2.5:3b` (Local - 1.9GB)
- `qwen3-vl:235b-cloud` (Nube)
- `gpt-oss:120b-cloud` (Nube)
- `qwen3-coder:480b-cloud` (Nube)
- Modelos cloud de Ollama (requieren autenticación por signin)

**Apple Silicon (M1/M2/M3/M4):**
- `llama3.2:latest` (Local)
- `mistral:7b` (Local)
- `qwen2.5:7b` (Local)
- `deepseek-r1:7b` (Local)
- `qwen3-vl:235b-cloud` (Nube)
- `gpt-oss:120b-cloud` (Nube)
- `qwen3-coder:480b-cloud` (Nube)
- Modelos cloud de Ollama (requieren autenticación por signin)

**Nota:** Cualquier modelo disponible en https://ollama.com/search es compatible con MSN-AI

---

## 🌍 Instalación por Plataforma

### 🐳 Docker Linux

```bash
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
cd linux
chmod +x start-msnai-docker.sh
./start-msnai-docker.sh --auto
```

**GPU NVIDIA (Opcional):**
```bash
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
# Luego ejecutar instalación normal
```

### 🐳 Docker Windows

```powershell
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
cd windows
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Unblock-File -Path .\start-msnai-docker.ps1
.\start-msnai-docker.ps1 --auto
```

### 🐳 Docker macOS

```bash
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
cd macos
chmod +x start-msnai-docker-mac.sh
./start-msnai-docker-mac.sh --auto
```

### 💻 Linux Local

```bash
# 1. Instalar dependencias
sudo apt update
sudo apt install -y python3 curl git                     # Ubuntu/Debian
# sudo dnf install -y python3 curl git                   # Fedora/RHEL

# 2. Instalar Ollama (si no está instalado)
curl -fsSL https://ollama.com/install.sh | sh

# 3. Clonar y configurar
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
cd linux
chmod +x *.sh

# 4. Detectar hardware y configurar modelos (opcional)
./ai_check_all.sh

# 5. Iniciar MSN-AI
./start-msnai.sh --auto

# 6. Crear lanzador en escritorio (opcional)
./create-desktop-shortcut.sh
```

### 💻 Windows Local

```powershell
# 1. Descargar e instalar Ollama desde https://ollama.com

# 2. Clonar repositorio
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
cd windows

# 3. Configurar PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 4. Desbloquear scripts
Unblock-File -Path .\start-msnai.ps1
Unblock-File -Path .\ai_check_all.ps1
Unblock-File -Path .\create-desktop-shortcut.ps1

# 5. Detectar hardware (opcional)
.\ai_check_all.ps1

# 6. Iniciar MSN-AI
.\start-msnai.ps1 --auto

# 7. Crear acceso directo (opcional)
.\create-desktop-shortcut.ps1
```

### 💻 macOS Local

```bash
# 1. Descargar e instalar Ollama desde https://ollama.com

# 2. Clonar repositorio
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
cd macos

# 3. Dar permisos
chmod +x *.sh

# 4. Detectar hardware (opcional)
./ai_check_all_mac.sh

# 5. Iniciar MSN-AI
./start-msnai-mac.sh --auto

# 6. Crear aplicación en escritorio (opcional)
./create-desktop-shortcut-mac.sh
```

---

## 🧠 Comandos de Ollama para Gestionar Modelos

### 📥 Descargar / Crear modelos
```bash
ollama pull <nombre-del-modelo>        # Descarga un modelo
ollama create <nombre> -f <Modelfile>  # Crea modelo personalizado
```

### ▶️ Ejecutar modelos
```bash
ollama run <nombre-del-modelo>         # Ejecuta en modo interactivo
ollama run <nombre> "tu prompt aquí"   # Ejecuta con prompt
```

### 📋 Listar modelos
```bash
ollama list                            # Muestra modelos descargados
```

### 🗑️ Eliminar modelos
```bash
ollama rm <nombre-del-modelo>          # Elimina un modelo
```

### 🔄 Copiar modelos
```bash
ollama cp <origen> <destino>           # Copia modelo con nuevo nombre
```

### ℹ️ Información del modelo
```bash
ollama show <nombre-del-modelo>        # Información detallada
ollama show --modelfile <nombre>       # Muestra Modelfile
ollama show --parameters <nombre>      # Muestra parámetros
ollama show --license <nombre>         # Muestra licencia
ollama show --template <nombre>        # Muestra plantilla de prompt
```

### ⚙️ Gestión del servicio
```bash
ollama serve                           # Inicia servidor manualmente
```

### 🔑 Configuración de API Key (para modelos cloud)
```bash
ollama signin                          # Iniciar sesión en Ollama
ollama signout                         # Cerrar sesión
```

---

## 🖥️ Notas por Sistema Operativo

| Sistema       | Instalación típica                              | Acceso al CLI                     | Notas                                                                 |
|---------------|--------------------------------------------------|-----------------------------------|-----------------------------------------------------------------------|
| **Linux**     | `curl -fsSL https://ollama.com/install.sh \| sh` | Disponible en `$PATH`             | Requiere `systemd` o inicio manual del daemon (`ollama serve`).      |
| **macOS**     | Descargar desde [ollama.com](https://ollama.com) | Disponible en terminal            | Se ejecuta como app en segundo plano; CLI integrado automáticamente. |
| **Windows**   | Descargar desde [ollama.com](https://ollama.com) | Disponible en PowerShell o CMD    | Requiere Windows 10/11 (64-bit); servicio en segundo plano.         |

> 💡 **Importante**: En **Windows y macOS**, el comando `ollama` está disponible en la terminal una vez instalado y en ejecución.

---

## 🎮 Guía de Uso

### 🎭 Cambiar Estado
1. Clic en selector de estado (parte superior de contactos)
2. Selecciona: Online 🟢 | Away 🟡 | Busy 🔴 | Invisible ⚪
3. **Bonus**: Activa "Notificar cambios a IA" en configuración

### 💬 Gestión de Chats

**Crear chat:**
- Clic en botón **"+"** en la lista de contactos
- Empieza a conversar inmediatamente

**Crear sala de expertos:**
1. Clic en botón **"🏢"** (Nueva Sala de Expertos) en la lista de contactos
2. Ingresa nombre personalizado para la sala
3. Selecciona 2 o más modelos de IA que participarán
4. Clic en "Crear Sala"
5. Escribe tu consulta - cada modelo responderá secuencialmente
6. Las respuestas aparecen etiquetadas: "IA (nombre-del-modelo)"
7. Perfecto para comparar respuestas o consultar opiniones múltiples

**Características de salas de expertos:**
- Icono 🏢 diferenciador en la lista
- Sección agrupada "Salas de Expertos"
- Cada modelo procesa con delay para evitar saturación
- Retry automático en errores HTTP 429
- Manejo individual de errores por modelo
- Botón ⏹️ detiene todas las respuestas pendientes
- Exportación incluye info de participantes

**Buscar:**
- Barra superior: busca por nombre en todos los chats
- Botón lupa 🔍: busca contenido en chat actual (resalta)

**Ordenar:**
- Clic en botón de ordenar (lista de chats)
- Alterna ascendente/descendente por fecha

**Exportar:**
- Botón "Exportar": todos los chats a JSON
- Botón "Seleccionar": checkboxes para exportar algunos
- Menú chat (⋮) → "Exportar": chat individual

**Importar:**
- Botón "Importar" → Selecciona archivo JSON
- Resolución automática de conflictos

**Otras acciones:**
- **Limpiar**: borra mensajes, mantiene chat
- **Cerrar**: cierra vista (con confirmación)
- **Eliminar**: elimina permanentemente (con modal)
- **Imprimir**: versión imprimible con estilos

### 🤖 System Prompt para Salas de Expertos

**Configurar instrucciones para modelos en salas grupales:**

1. Clic en configuración ⚙️
2. Desplázate hasta "System Prompt para Salas de Chat Grupales"
3. Verás un editor de texto con la plantilla predeterminada
4. **Variables dinámicas disponibles:**
   - `{{MODEL_NAME}}`: Se reemplaza automáticamente con el nombre de cada modelo
   - `{{PARTICIPANT_LIST}}`: Se reemplaza con la lista de todos los participantes

**Características del System Prompt:**
- ✅ **Traducción automática**: Al cambiar idioma, el prompt se actualiza automáticamente
- ✅ **Personalizable**: Edita el contenido según tus necesidades
- ✅ **Botón Restaurar (🔄)**: Vuelve a la plantilla predeterminada del idioma actual
- ✅ **Instrucciones incluidas**:
  - Identificación obligatoria con formato `[NOMBRE_MODELO]:`
  - Conciencia de entorno multi-agente
  - Protocolo de respuesta colaborativa
  - Reglas de formato y límites
  - Ejemplos de uso

**Personalizar:**
1. Edita el texto en el editor
2. Mantén las variables `{{MODEL_NAME}}` y `{{PARTICIPANT_LIST}}`
3. Guarda cambios con el botón "💾 Guardar"
4. Los cambios se aplican inmediatamente a nuevas salas

**Restaurar predeterminado:**
1. Clic en botón "🔄 Restaurar" junto al título
2. Se carga la plantilla predeterminada del idioma actual
3. Personalización anterior se reemplaza

**Nota**: El system prompt se envía automáticamente a cada modelo al inicio de la conversación en salas de expertos, mejorando significativamente la calidad y coordinación de las respuestas.

### 📝 Generador de Prompts Profesional

**Crear prompt estructurado:**
1. Clic en "Generador de Prompts" en barra de herramientas
2. Completa campos (mínimo: Rol, Contexto, Tareas)
3. Clic en "Generar Prompt"
4. Revisa prompt en modal
5. Opciones:
   - **Copiar**: al portapapeles
   - **Usar en Chat**: inserta en área de texto
   - **Guardar**: abre modal para guardar en biblioteca

**Editar prompt existente:**
1. Abre biblioteca de prompts guardados
2. Clic en "Editar" en el prompt deseado
3. Modifica campos necesarios
4. Clic en "Actualizar Prompt"

### 📚 Gestión de Prompts Guardados

**Guardar prompt:**
1. Después de generar, clic en "Guardar"
2. Completa metadatos:
   - Nombre del prompt
   - Descripción
   - Categoría
   - Tags (separados por comas)
3. Clic en "Guardar Prompt"

**Buscar y filtrar:**
- Campo de búsqueda: por nombre, descripción o tags
- Selector de categoría: filtra por categoría específica
- Visualización tipo Pinterest

**Acciones disponibles:**
- **Ver Detalles**: información completa
- **Editar**: modifica prompt guardado
- **Usar en Chat**: inserta directamente
- **Cargar en Formulario**: para edición
- **Eliminar**: borra individual
- **Eliminar Todos**: limpia biblioteca (con confirmación)

**Import/Export:**
- **Exportar Todos**: descarga biblioteca en JSON
- **Importar**: carga prompts desde JSON

### 📝 Edición de Texto

**Escribir mensaje:**
- Escribe en área de texto
- Presiona **Enter** o clic "Enviar"
- Sonidos automáticos: envío 📤 y recepción 📥

**Ajustar tamaño de fuente:**
- Botones **A-** y **A+**
- Rango: 10px a 32px (pasos de 2px)

**Emoticones:**
- Clic en botón 😊
- Selecciona categoría (Naturales/Amor)
- 30 emojis disponibles

**Formato de texto:**
- Negrita (**B**), Cursiva (*I*), Subrayado (U)
- Selecciona texto y aplica formato

**Zumbido/Nudge:**
- Clic en botón 📳
- Envía "sacudida" como MSN original
- Animación y sonido incluidos

**Dictado por voz:**
1. Clic en botón 🎤 para iniciar grabación
2. Permite permisos de micrófono (primera vez)
3. Botón se vuelve rojo pulsante durante grabación
4. Notificación: "🎤 Grabando... Hable ahora"
5. Habla naturalmente - transcribe en tiempo real
6. Clic nuevamente en 🎤 para detener
7. Texto aparece automáticamente en el área de mensaje

**Características del dictado:**
- Reconocimiento continuo sin pausas
- Feedback visual (botón rojo) y auditivo (sonidos)
- Soporte para español e inglés según configuración
- Detección automática de conexión a internet
- Mensajes claros si no hay internet disponible
- Manejo robusto de errores con notificaciones específicas
- Traducciones en los 22 idiomas del sistema

**Nota importante:** El dictado por voz requiere conexión a internet, ya que utiliza la Web Speech API de Google Chrome/Edge

**Subir archivo:**
- **TXT**: botón 📄, selecciona .txt
- **PDF**: botón PDF, selecciona .pdf (máx. 10MB)
- Contenido procesado y guardado en IndexedDB
- Descarga posterior disponible

### 🌍 Cambiar Idioma
1. Clic en configuración ⚙️
2. Selector de idioma
3. Selecciona entre 22 idiomas
4. Interfaz se traduce instantáneamente
5. Preferencia se guarda automáticamente

---

## ⚙️ Configuración

Accede desde el botón **⚙️** en la interfaz:

- 🔊 **Sonidos** - Activar/desactivar efectos MSN
- 📢 **Notificar cambios de estado** - IA recibe notificación
- 🌍 **Idioma** - 22 idiomas disponibles
- 🌐 **Servidor Ollama** - URL (autodetección o manual)
- 🤖 **Modelo de IA** - Selector dinámico de modelos
- ⏱️ **Timeout API** - Tiempo máximo de espera (30s)
- 🤖 **System Prompt para Salas Grupales** - Editor de instrucciones contextuales con variables dinámicas `{{MODEL_NAME}}` y `{{PARTICIPANT_LIST}}`, botón de restauración, y traducción automática
- 🔌 **Probar conexión** - Verifica Ollama y modelos

**Persistencia:** Todas las configuraciones se guardan automáticamente en localStorage.
</text>

<old_text line=883>
### Funcionalidades
- **30 emoticones** integrados
- **2 categorías** de emoticones (con cierre automático)
- **Salas de expertos** con múltiples modelos de IA
- **System Prompt configurable** con variables dinámicas y traducción automática
- **Dictado por voz** con reconocimiento continuo
- **Sistema de detención** para respuestas individuales y grupales
- **Generador de prompts** con 11 campos especializados
- **Gestor de prompts** con biblioteca completa
- **Sistema de búsqueda** avanzado (global y por chat)
- **Exportación múltiple** (todos, seleccionados, individual)
- **Importación inteligente** con resolución de conflictos

---

## 🏗️ Arquitectura del Proyecto

```
MSN-AI/
├── 📄 msn-ai.html              # HTML (827 líneas) - Estructura
├── 📄 msn-ai.js                # JavaScript (6,882 líneas) - Lógica
├── 📄 msn-ai.js                # CSS (1,666 líneas) - Estilos
├── 📄 start.sh                 # Wrapper universal (Linux/macOS)
├── 📄 start.ps1                # Wrapper universal (Windows)
├── 📄 start-docker.sh          # Lanzador Docker (Linux/macOS)
├── 📄 start-docker.ps1         # Lanzador Docker (Windows)
├── 📄 README.md                # Este archivo
├── 📄 CHANGELOG.md             # Historial de cambios
├── 📄 LICENSE                  # Licencia GPL-3.0
├── 📄 .gitignore               # Archivos ignorados por Git
├── 📄 .dockerignore            # Archivos ignorados por Docker
│
├── 📁 lang/                    # Sistema multiidioma (22 idiomas)
│   ├── es.json, en.json, de.json, fr.json
│   ├── ar.json, zh.json, hi.json, bn.json
│   ├── pt.json, ru.json, ja.json, ko.json
│   ├── id.json, tr.json, ur.json, vi.json
│   ├── ta.json, te.json, mr.json, pa.json
│   └── qu.json, ay.json
│
├── 📁 assets/                  # Recursos multimedia (102 archivos)
│   ├── sounds/                 # 5 archivos WAV originales
│   ├── background/             # Fondos de ventanas
│   ├── chat-window/            # Elementos de chat
│   ├── contacts-window/        # Elementos de contactos
│   ├── general/                # Logo y recursos generales
│   ├── scrollbar/              # Elementos de scrollbar
│   ├── status/                 # Iconos de estado
│   └── screenshots/            # Capturas de pantalla
│
├── 📁 docker/                  # Configuración Docker
│   ├── Dockerfile              # Imagen de MSN-AI
│   ├── docker-compose.yml      # Orquestación de servicios
│   ├── docker-entrypoint.sh    # Script de entrada
│   ├── healthcheck.sh          # Verificación de salud
│   └── scripts/                # Scripts de configuración
│       ├── ai-setup-docker.sh  # Setup automático de IA
│       └── setup-ollama-env.sh # Configuración de Ollama
│
├── 📁 linux/                   # Scripts para Linux (17 archivos)
│   ├── start-msnai.sh          # Iniciar local
│   ├── start-msnai-docker.sh   # Iniciar Docker
│   ├── docker-start.sh         # Iniciar contenedores
│   ├── docker-stop.sh          # Detener contenedores
│   ├── docker-status.sh        # Estado de contenedores
│   ├── docker-logs.sh          # Ver logs
│   ├── docker-cleanup.sh       # Limpieza completa
│   ├── docker-check-config.sh  # Verificar configuración
│   ├── docker-check-signin.sh  # Verificar signin cloud
│   ├── docker-diagnostics.sh   # Diagnóstico completo
│   ├── docker-test-ai.sh       # Probar IA
│   ├── docker-install-cloud-models.sh # Instalar modelos cloud
│   ├── ai_check_all.sh         # Detectar hardware
│   ├── configure-api-key.sh    # Configurar API Key
│   ├── create-desktop-shortcut.sh # Crear lanzador
│   └── test-msnai.sh           # Tests de componentes
│
├── 📁 macos/                   # Scripts para macOS (9 archivos)
│   ├── start-msnai-mac.sh      # Iniciar local
│   ├── start-msnai-docker-mac.sh # Iniciar Docker
│   ├── docker-diagnostics-mac.sh # Diagnóstico
│   ├── docker-check-signin-mac.sh # Verificar signin
│   ├── docker-install-cloud-models-mac.sh # Modelos cloud
│   ├── ai_check_all_mac.sh     # Detectar hardware
│   ├── configure-api-key.sh    # Configurar API Key
│   ├── create-desktop-shortcut-mac.sh # Crear app
│   └── docker-start-debug-mac.sh # Debug Docker
│
└── 📁 windows/                 # Scripts para Windows (8 archivos)
    ├── start-msnai.ps1         # Iniciar local
    ├── start-msnai-docker.ps1  # Iniciar Docker
    ├── docker-start-debug.ps1  # Debug Docker
    ├── docker-diagnostics.ps1  # Diagnóstico
    ├── docker-install-cloud-models.ps1 # Modelos cloud
    ├── ai_check_all.ps1        # Detectar hardware
    ├── configure-api-key.ps1   # Configurar API Key
    └── create-desktop-shortcut.ps1 # Crear acceso directo
```

### 📊 Tecnologías Utilizadas

**Frontend:**
- HTML5, CSS3, JavaScript (ES6+)
- marked.js v12.0.2 - Conversión de Markdown
- DOMPurify v3.0.5 - Sanitización HTML
- Highlight.js v11.10.0 - Resaltado de sintaxis
- PDF.js v3.11.174 - Procesamiento de PDFs
- Tesseract.js v5.0.4 - OCR para PDFs escaneados

**Backend/IA:**
- Ollama - Servidor de IA local
- Modelos compatibles: Mistral, Llama, Phi3, Qwen, Gemma, etc.
- API REST para comunicación con IA

**Almacenamiento:**
- localStorage - Configuración y chats
- IndexedDB - Archivos adjuntos (TXT, PDF)

**Despliegue:**
- Docker - Containerización
- Docker Compose v2 - Orquestación
- Python 3.6+ - Servidor HTTP local

---

## 📊 Estadísticas del Proyecto

### Código Fuente
- **9,750+ líneas totales** de código frontend
  - HTML: 880 líneas
  - JavaScript: 8,150+ líneas
  - CSS: 1,700+ líneas

### Scripts
- **42 scripts** de automatización total
  - 32 scripts Shell (.sh) para Linux/macOS
  - 10 scripts PowerShell (.ps1) para Windows

### Internacionalización
- **22 idiomas** completamente traducidos (100% cobertura)
- **22 archivos JSON** de traducción
- **450+ claves** de traducción por idioma

### Recursos Multimedia
- **102 archivos** en carpeta assets/
  - 5 sonidos WAV originales de MSN
  - 97 imágenes (iconos, fondos, capturas)

### Funcionalidades
- **70+ características** implementadas
- **11 campos** en generador de prompts
- **4 estados** de presencia
- **30 emoticones** integrados
- **2 categorías** de emoticones (con cierre automático)
- **Salas de expertos** con múltiples modelos de IA
- **Dictado por voz** con reconocimiento continuo
- **Sistema de detención** para respuestas individuales y grupales

### Compatibilidad
- **3 sistemas operativos**: Linux, Windows, macOS
- **4 navegadores**: Chrome, Firefox, Safari, Edge
- **2 ediciones**: Docker y Local
- **∞ modelos de IA**: Todos los de Ollama

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Aquí está cómo puedes ayudar:

### 🔧 Desarrollo

1. **Fork** el repositorio
2. **Crea** una rama para tu feature:
   ```bash
   git checkout -b feature/nueva-funcionalidad
   ```
3. **Desarrolla** siguiendo las convenciones del proyecto
4. **Commit** tus cambios:
   ```bash
   git commit -m 'feat: Añade nueva funcionalidad'
   ```
5. **Push** a tu rama:
   ```bash
   git push origin feature/nueva-funcionalidad
   ```
6. **Abre** un Pull Request con descripción detallada

### 📝 Convenciones de Commits

- ✨ `feat:` Nueva funcionalidad
- 🐛 `fix:` Corrección de bug
- 📚 `docs:` Cambios en documentación
- 🎨 `style:` Cambios de formato/estilo
- ♻️ `refactor:` Refactorización de código
- ⚡ `perf:` Mejoras de rendimiento
- ✅ `test:` Añadir o modificar tests
- 🔧 `chore:` Tareas de mantenimiento

### 🐛 Reportar Bugs

**GitHub Issues**: https://github.com/mac100185/MSN-AI/issues

Incluye en tu reporte:
- Sistema operativo y versión
- Navegador y versión
- Pasos para reproducir el bug
- Comportamiento esperado vs actual
- Logs/capturas de pantalla si es posible

### 💡 Sugerir Features

**GitHub Discussions**: https://github.com/mac100185/MSN-AI/discussions

Al sugerir una feature:
- Describe el problema que resuelve
- Explica tu solución propuesta
- Incluye mockups/ejemplos si es posible
- Menciona casos de uso reales

---

## 📞 Contacto y Soporte

**Desarrollador**: Alan Mac-Arthur García Díaz
**Email**: alan.mac.arthur.garcia.diaz@gmail.com
**Repositorio**: https://github.com/mac100185/MSN-AI

### 🆘 Obtener Ayuda

- **Issues**: Para bugs y problemas técnicos
- **Discussions**: Para preguntas y sugerencias
- **Email**: Para soporte directo o consultas privadas

### 🌟 Agradecimientos

Si MSN-AI te resulta útil, considera:
- ⭐ Dar una estrella al repositorio
- 🐛 Reportar bugs que encuentres
- 💡 Sugerir mejoras
- 🔀 Contribuir con código
- 📢 Compartir el proyecto

---

## ⚖️ Licencia

Este proyecto está licenciado bajo **GNU General Public License v3.0**.

### 🔑 GPL-3.0 en Resumen:

- ✅ **Libertad de usar** para cualquier propósito
- ✅ **Libertad de estudiar** (código fuente disponible)
- ✅ **Libertad de modificar** y adaptar
- ✅ **Libertad de distribuir** copias
- ⚖️ **Copyleft**: Las modificaciones deben ser GPL-3.0

Ver [LICENSE](LICENSE) para el texto completo de la licencia.

### 🤝 Créditos y Reconocimientos

- **[androidWG/WLMOnline](https://github.com/androidWG/WLMOnline)** - Proyecto base para la interfaz
- **Microsoft Corporation** - Windows Live Messenger original (Fair Use educativo)
- **[Ollama](https://ollama.ai)** - IA local accesible y fácil de usar
- **Proyecto Escargot** - Preservación del espíritu de MSN
- **Comunidad Open Source** - Por las librerías utilizadas

### 📜 Derechos de Terceros

- **Assets de Microsoft**: Uso bajo Fair Use para preservación histórica y fines educativos (Propiedad y licenciado por Microsoft)
- **Sonidos originales**: Utilizados con fines educativos y nostálgicos Propiedad y licenciado por Microsoft.
- **Marcas registradas**: Son propiedad de sus respectivos dueños, este proyecto no tiene derechos sobre ellas.

---

**MSN-AI v2.1.1** - *Donde la nostalgia se encuentra con la inteligencia artificial moderna*

**Desarrollado con ❤️ por Alan Mac-Arthur García Díaz**

**Licenciado bajo GPL-3.0 | 2024-2025**

---

⭐ **¿Te gusta el proyecto? ¡Deja una estrella en GitHub!**

[![GitHub stars](https://img.shields.io/github/stars/mac100185/MSN-AI?style=social)](https://github.com/mac100185/MSN-AI)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/mac100185/MSN-AI/pulls)
