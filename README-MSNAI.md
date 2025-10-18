# MSN-AI - Windows Live Messenger con IA Local

![MSN-AI Logo](assets/general/logo.png)

**Versión 2.1.0** | **Licencia GPL-3.0** | **Por Alan Mac-Arthur García Díaz**

## 🎯 Descripción

MSN-AI es una aplicación web que combina la nostálgica interfaz de Windows Live Messenger 8.5 con la potencia de los modelos de IA local ejecutados a través de Ollama. 

**🐳 NOVEDAD v2.1.0**: Ahora con **instalación simplificada**:
- **Docker Edition**: Instalación de un comando, cero configuración
- **Local Edition**: Máximo rendimiento con instalación tradicional

Disfruta de la experiencia clásica de MSN mientras conversas con asistentes de inteligencia artificial avanzados, eligiendo el método de instalación que prefieras.

**Desarrollado por**: Alan Mac-Arthur García Díaz  
**Contacto**: [alan.mac.arthur.garcia.diaz@gmail.com](mailto:alan.mac.arthur.garcia.diaz@gmail.com)  
**Licencia**: GNU General Public License v3.0

## ✨ Características principales

### 🎨 Interfaz auténtica
- Recreación pixel-perfect de Windows Live Messenger 8.5
- Sonidos auténticos del MSN original
- Efectos visuales Aero fieles al original
- Scrollbars personalizados estilo Windows Vista/7

### 🎭 Estados de presencia (como MSN clásico)
- **Online** 🟢 - Disponible para chatear
- **Away** 🟡 - Ausente temporalmente
- **Busy** 🔴 - Ocupado, no molestar
- **Invisible** ⚪ - Aparecer como desconectado
- **Notificación a IA** - Opción para que la IA sepa tu estado actual

### 🤖 IA integrada
- Soporte para múltiples modelos de IA (Mistral, Llama, Phi3, etc.)
- Conversaciones contextuales inteligentes
- Detección automática de modelos disponibles
- Reconexión automática con Ollama
- **Detector inteligente de hardware** en ambas ediciones
- Notificaciones de cambios de estado opcionales

### 💾 Gestión de datos
- Almacenamiento local en el navegador (localStorage)
- Historial completo de conversaciones
- **Búsqueda avanzada**: En todos los chats o dentro de un chat específico
- **Exportación flexible**: Todos los chats o solo los seleccionados
- Importación de chats en JSON
- **Volúmenes persistentes** en Docker Edition
- **Ordenar historial** por fecha (ascendente/descendente)

### 📝 Edición de texto avanzada
- **Ajuste de tamaño de fuente** - Aumentar/disminuir para mejor legibilidad
- **Emoticones** - Categorías: Naturales 😊 y Amor ❤️
- **Formato de texto** - Negrita, cursiva, subrayado
- **Subir archivos de texto** - Carga archivos .txt directamente al chat
- **Dictado por voz** 🎤 - Transcripción de voz a texto (Web Speech API)
- **Zumbido/Nudge** 📳 - Envía "sacudidas" como en MSN original

### 🔊 Experiencia inmersiva
- Sonidos auténticos de MSN (login, mensajes, notificaciones, nudge)
- Indicadores visuales de estado de conexión
- Animaciones de "IA pensando"
- Interfaz completamente responsive

### 🛠️ Funcionalidades avanzadas
- **Imprimir chat actual** - Genera versión imprimible de la conversación
- **Exportar chat individual** - Descarga solo la conversación abierta
- **Limpiar chat** - Borra mensajes sin eliminar el chat completo
- **Cerrar chat** - Cierra la vista sin eliminar historial
- **Búsqueda con resaltado** - Encuentra texto en conversaciones
- **Modal de información** - Acceso rápido a contacto y documentación

### 🐳 Docker Edition (v2.1.0 - Instalación Simplificada)
- **Instalación de cero prerequisitos** - Solo requiere Docker
- **Containerización completa** - Aislamiento total del sistema
- **Instalación automática de Docker** si no está presente
- **Health checks y monitoreo** integrados
- **Soporte GPU** con NVIDIA Container Toolkit
- **Backup/Restore** automático de datos
- **Compatibilidad universal** - Idéntico en todos los OS

### 💻 Local Edition (Clásica)
- **Máximo rendimiento** - Ejecución nativa
- **Control total** - Configuración avanzada disponible
- **Instalación tradicional** - Para usuarios que prefieren control directo
- **Scripts inteligentes** - Instalación automática de dependencias

## 🚀 Instalación y configuración

### 🎯 Elige tu edición preferida

#### 🐳 **Docker Edition** (Recomendado - Cero configuración)
```bash
# Linux:
./start-msnai-docker.sh --auto

# Windows:
.\start-msnai-docker.ps1 --auto

# macOS:
./start-msnai-docker-mac.sh --auto
```
**✅ Instala Docker automáticamente si falta**  
**✅ Detecta hardware y configura IA óptima**  
**✅ Todo funciona en contenedores aislados**

#### 💻 **Local Edition** (Clásica - Máximo rendimiento)
```bash
# Linux:
./start-msnai.sh --auto

# Windows:
.\start-msnai.ps1 --auto

# macOS:
./start-msnai-mac.sh --auto
```

### Prerrequisitos por edición

#### 🐳 **Docker Edition**
- **Solo Docker** (se instala automáticamente si falta)
- 8GB+ RAM recomendado
- 4GB+ espacio libre
- Navegador moderno

#### 💻 **Local Edition**
1. **Ollama instalado y ejecutándose**
   - Descargar desde: https://ollama.ai
   - O usar el script incluido: `./ai_check_all.sh`

2. **Al menos un modelo de IA descargado**
   ```bash
   ollama pull mistral:7b  # Recomendado para empezar
   ollama pull llama3:8b   # Para mejor rendimiento
   ollama pull phi3:mini   # Para equipos limitados
   ```

### 🚀 Instalación rápida desde GitHub

#### Clonar repositorio:
```bash
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
```

### 🎮 Uso - Ambas ediciones

#### 🚀 Inicio inmediato
```bash
# Docker Edition:
./start-msnai-docker.sh --auto

# Local Edition:
./start-msnai.sh --auto

# ¡La aplicación se abre automáticamente!
```

#### 🌐 Acceso manual
```bash
# Docker Edition - Siempre en:
http://localhost:8000/msn-ai.html

# Local Edition - Servidor automático:
http://localhost:8000/msn-ai.html

# Local Edition - Archivo directo:
file:///ruta/completa/msn-ai.html
```

#### 🎯 Primera experiencia
1. **Sonido de login** - MSN auténtico te da la bienvenida
2. **Conexión automática** - Verde = IA lista, Rojo = Revisar Ollama
3. **Chat de bienvenida** - Conversación inicial automática
4. **Crear nuevo chat** - Botón "+" para nuevas conversaciones

#### 💬 Chatear con IA
1. **Escribir mensaje** - En el área de texto inferior
2. **Enviar** - Enter o botón "Enviar"
3. **Sonido envío** - Efecto auténtico message_out.wav
4. **IA pensando** - Indicador visual animado
5. **Respuesta IA** - Con sonido message_in.wav auténtico
6. **Guardado automático** - Todo se preserva localmente

## ⏹️ Detener MSN-AI correctamente

**⚠️ IMPORTANTE**: Siempre detén correctamente para evitar daños:

### 🐳 Docker Edition
```bash
# Método principal:
docker-compose -f docker/docker-compose.yml down

# Si usaste --daemon:
Ctrl + C  # En la terminal del script
```

### 💻 Local Edition
```bash
# En la terminal donde ejecutaste start-msnai.sh:
Ctrl + C
# El script automáticamente limpiará todos los procesos
```

### 🚨 Detención de emergencia

#### Docker Edition:
```bash
# Detener contenedores forzadamente
docker stop $(docker ps -q --filter "label=com.msnai.service")
docker-compose -f docker/docker-compose.yml down --remove-orphans
```

#### Local Edition:
```bash
# Detener todos los procesos relacionados
pkill -f "python.*http.server"
pkill -f "http-server" 
pkill -f "start-msnai"
pkill ollama  # Solo si fue iniciado por el script

# Verificar que todo esté detenido
ps aux | grep -E "(python.*http|ollama|start-msnai)"
```

### Indicadores de detención exitosa
- ✅ **Docker**: Containers stopped, volumes preserved
- ✅ **Local**: Mensaje "👋 ¡Gracias por usar MSN-AI!"
- ✅ Puerto liberado (8000 no responde)
- ✅ Sin procesos relacionados ejecutándose
- ✅ Terminal disponible para nuevos comandos

### ❌ Nunca hagas esto
- Cerrar terminal sin Ctrl+C
- Usar `kill -9` directamente
- Apagar el sistema con servicios activos
- Forzar cierre del navegador sin detener servicios

## 📚 Guía de uso

### Gestión de chats

#### Crear nuevo chat
- Clic en el botón con icono "+" en la barra de navegación
- Se creará automáticamente con el modelo seleccionado
- El título se genera automáticamente basado en el primer mensaje

#### Seleccionar chat
- Clic en cualquier chat de la lista izquierda
- El chat activo se resalta en azul
- Los mensajes se cargan automáticamente

#### Buscar chats
- **Buscar en todos los chats**: Usar la barra de búsqueda superior
- **Buscar en chat actual**: Botón de lupa en la barra del chat
- Busca en títulos y contenido de mensajes
- Filtrado en tiempo real con resaltado

#### Ordenar historial
- Botón "Ordenar Historial" en la barra de navegación
- Alterna entre orden ascendente y descendente por fecha
- Mantiene el orden entre sesiones

#### Exportar chats
1. **Exportar todos**: Clic en botón de exportar (icono de carpeta)
2. **Exportar seleccionados**: Selecciona chats → botón "Exportar Seleccionados"
3. **Exportar chat actual**: Botón en barra del chat activo
4. Se descarga archivo JSON con las conversaciones

#### Importar chats
1. Clic en botón de importar
2. Seleccionar archivo JSON exportado previamente
3. Los chats se agregan al historial existente

#### Limpiar chat
- Botón "Limpiar chat" (escoba) en barra superior
- Borra todos los mensajes del chat actual
- Mantiene el chat en el historial

#### Cerrar chat
- Botón "Cerrar chat" (X) en barra superior
- Cierra la vista actual sin eliminar
- Sugiere crear nuevo chat

#### Eliminar chat
- Clic derecho sobre un chat → Confirmar eliminación
- Modal de confirmación para evitar errores
- **⚠️ Acción irreversible - elimina todo el historial**

#### Imprimir chat
- Botón "Imprimir" en barra del chat
- Genera versión imprimible de la conversación
- Abre diálogo de impresión del navegador

### Edición de texto y mensajes

#### Cambiar estado de presencia
- Clic en el botón de estado (debajo del avatar)
- Seleccionar: Online, Away, Busy o Invisible
- El icono y texto se actualizan inmediatamente
- **Opcional**: Notificar cambio a la IA en chat activo

#### Ajustar tamaño de texto
- **Aumentar**: Botón "+" en barra del chat
- **Disminuir**: Botón "-" en barra del chat
- Rango: 10px a 32px
- Se aplica solo al chat actual

#### Usar emoticones
- **Naturales** 😊: Botón con cara sonriente
- **Amor** ❤️: Botón con corazón
- Picker desplegable con selección visual
- Se insertan en el área de texto

#### Formato de texto
- Botón "Editor de texto" en área de envío
- **N** = Negrita, **C** = Cursiva, **S** = Subrayado
- Se aplica al texto seleccionado

#### Enviar zumbido/nudge
- Botón "Sumbido" (📳) en área de envío
- Reproduce sonido y animación de sacudida
- Funcionalidad clásica de MSN

#### Dictado por voz
- Botón "Dictado" (🎤) en área de envío
- Requiere permisos de micrófono
- Transcribe voz a texto automáticamente
- Compatible con navegadores modernos (Chrome, Edge)

#### Subir archivo de texto
- Botón "Subir archivo" en barra del chat
- Seleccionar archivo .txt
- El contenido se carga en el área de mensaje
- Perfecto para consultas largas o código

### Configuración

#### Acceder a configuración
- Clic en el botón de engranaje (esquina superior derecha)

#### Opciones disponibles
- **Activar sonidos**: Checkbox para habilitar/deshabilitar efectos de audio
- **Notificar cambios de estado a la IA**: La IA recibirá un mensaje automático cuando cambies tu estado (Online/Away/Busy/Invisible)
- **Sonidos**: Activar/desactivar efectos de sonido
- **Servidor Ollama**: Cambiar URL del servidor (por defecto: `http://localhost:11434`)
- **Modelo de IA**: Seleccionar modelo preferido para nuevos chats
- **Probar conexión**: Verificar conectividad con Ollama

### Import/Export

#### Exportar chats
1. Clic en botón de exportar (icono de carpeta)
2. Se descarga automáticamente un archivo JSON
3. Formato: `msn-ai-chats-YYYY-MM-DD.json`

#### Importar chats
1. Clic en botón de importar
2. Seleccionar archivo JSON previamente exportado
3. Los chats se agregan a los existentes (no se sobrescriben)

#### Estructura del archivo JSON
```json
{
  "version": "1.0",
  "exportDate": "2025-01-07T10:30:00.000Z",
  "chats": [
    {
      "id": "chat-1704625800000",
      "title": "Consulta sobre JavaScript",
      "date": "2025-01-07T10:30:00.000Z",
      "model": "mistral:7b",
      "messages": [
        {
          "type": "user",
          "content": "¿Cómo funciona async/await?",
          "timestamp": "2025-01-07T10:30:00.000Z"
        },
        {
          "type": "ai",
          "content": "async/await es una sintaxis...",
          "timestamp": "2025-01-07T10:30:15.000Z"
        }
      ]
    }
  ],
  "settings": {
    "soundsEnabled": true,
    "ollamaServer": "http://localhost:11434",
    "selectedModel": "mistral:7b"
  }
}
```

## 🎵 Sonidos incluidos

| Archivo | Descripción | Cuándo se reproduce |
|---------|-------------|-------------------|
| `login.wav` | Sonido de inicio de MSN | Al cargar la aplicación y al importar |
| `message_in.wav` | Mensaje recibido | Cuando la IA responde |
| `message_out.wav` | Mensaje enviado | Al enviar tu mensaje |
| `nudge.wav` | Zumbido/notificación | Al crear nuevo chat y exportar |
| `calling.wav` | Sonido de llamada | Reservado para futuras funcionalidades |

## ⚙️ Configuración avanzada

### 🧠 Detector inteligente de hardware (Ambas ediciones)

**MSN-AI incluye un detector automático que recomienda el modelo óptimo:**

| Hardware detectado | Modelo recomendado | Nivel |
|-------------------|-------------------|--------|
| 80GB+ VRAM | `llama3:70b` | Máximo (alto rendimiento) |
| 24GB+ VRAM | `llama3:8b` | Avanzado (programación) |
| 8-16GB VRAM | `mistral:7b` | Eficiente (balance perfecto) |
| Solo CPU, 32GB+ RAM | `mistral:7b` | Eficiente (CPU + alta RAM) |
| Solo CPU, 16GB+ RAM | `phi3:mini` | Ligero (CPU + RAM media) |
| Hardware limitado | `tinyllama` | Básico (equipos limitados) |

### 🐳 Configuración Docker Edition

#### Variables de entorno disponibles:
```env
# Archivo .env (creado automáticamente)
MSN_AI_VERSION=1.1.0
MSN_AI_PORT=8000
COMPOSE_PROJECT_NAME=msn-ai
DOCKER_BUILDKIT=1
RECOMMENDED_MODEL=mistral:7b
GPU_SUPPORT=true
MEMORY_GB=16
```

#### Comandos Docker útiles:
```bash
# Ver estado de contenedores
docker-compose -f docker/docker-compose.yml ps

# Logs en tiempo real
docker-compose -f docker/docker-compose.yml logs -f

# Entrar al contenedor MSN-AI
docker exec -it msn-ai-app /bin/bash

# Ver uso de recursos
docker stats

# Backup de datos
docker run --rm -v msn-ai-chats:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz -C /data .
```

### 💻 Personalización Local Edition

```bash
# Cambiar puerto por defecto Ollama
OLLAMA_HOST=0.0.0.0:11435 ollama serve

# Configurar GPU específica
CUDA_VISIBLE_DEVICES=0 ollama serve

# Configurar memoria límite
OLLAMA_GPU_MEMORY_FRACTION=0.8 ollama serve
```

### Configuración de red

Si Ollama está en otro servidor:
1. Ir a Configuración
2. Cambiar "Servidor Ollama" a: `http://IP_SERVIDOR:11434`
3. Asegurar que Ollama permita conexiones externas:
   ```bash
   OLLAMA_HOST=0.0.0.0:11434 ollama serve
   ```

## 🔧 Solución de problemas

### 🐳 Docker Edition - Troubleshooting

#### ❌ "Docker no encontrado"
```bash
# Linux/macOS - Se instala automáticamente
./start-msnai-docker.sh

# Windows - Descarga Docker Desktop automáticamente
.\start-msnai-docker.ps1
```

#### ❌ "Contenedores no inician"
```bash
# Ver logs específicos
docker-compose -f docker/docker-compose.yml logs ollama
docker-compose -f docker/docker-compose.yml logs msn-ai

# Reconstruir desde cero
docker-compose -f docker/docker-compose.yml build --no-cache
docker-compose -f docker/docker-compose.yml up -d
```

#### ❌ "Puerto ocupado"
```bash
# Cambiar puerto automáticamente
echo "MSN_AI_PORT=8001" >> .env
docker-compose -f docker/docker-compose.yml up -d
```

#### ❌ "Health check failed"
```bash
# Verificar health check manualmente
docker exec msn-ai-app /app/healthcheck.sh

# Ver detalles del contenedor
docker inspect msn-ai-app
```

### 💻 Local Edition - Troubleshooting

#### ❌ "No hay conexión con Ollama"
**Causa**: Ollama no está ejecutándose o no es accesible
**Solución**:
1. Verificar que Ollama esté ejecutándose: `ollama list`
2. Verificar el puerto: `netstat -tlnp | grep 11434`
3. Probar conexión manual: `curl http://localhost:11434/api/tags`

#### ❌ "Modelo no disponible"
**Causa**: El modelo seleccionado no está descargado
**Solución**:
1. Listar modelos disponibles: `ollama list`
2. Descargar modelo: `ollama pull mistral:7b`
3. Reiniciar MSN-AI

#### ❌ "Script no se detiene"
```bash
# Forzar limpieza (último recurso)
pkill -f "start-msnai"
./test-msnai.sh  # Para ver procesos activos
```

### 🔧 Problemas comunes (Ambas ediciones)

#### ❌ "Los sonidos no se reproducen"
**Causa**: Navegador bloquea autoplay o archivos no encontrados
**Solución**:
1. Permitir autoplay en el navegador
2. Verificar que existan los archivos en `assets/sounds/`
3. Desactivar/activar sonidos en Configuración

#### ❌ "Chat lento o no responde"
**Causa**: Modelo muy grande para el hardware
**Solución**:
1. **Docker**: Los modelos se seleccionan automáticamente según hardware
2. **Local**: Cambiar a modelo más ligero (phi3:mini)
3. Verificar uso de GPU: `nvidia-smi` (local) o `docker exec msn-ai-ollama nvidia-smi` (docker)
3. Verificar log de Ollama: `journalctl -u ollama`

#### ❌ "Pérdida de datos"
**Causa**: Cierre incorrecto o problemas del navegador
**Solución**:
1. **Docker**: Los datos están en volúmenes persistentes - `docker volume ls`
2. **Local**: Datos en localStorage del navegador - Revisar configuración del navegador
3. Usar Export regular como backup
4. **Docker**: Backup manual: `docker run --rm -v msn-ai-chats:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz -C /data .`

#### ❌ "La aplicación no carga"
**Docker**:
```bash
# Verificar contenedores
docker-compose -f docker/docker-compose.yml ps

# Reiniciar servicios
docker-compose -f docker/docker-compose.yml restart
```

**Local**:
```bash
# Usar servidor local
python3 -m http.server 8000
# Luego abrir: http://localhost:8000/msn-ai.html
```

## 🎯 Casos de uso

### 👨‍💻 Desarrollo y programación
- Consultas técnicas con contexto histórico
- Revisión de código y debugging asistido
- Documentación automática de proyectos
- Aprendizaje de nuevas tecnologías

### 📚 Educación y aprendizaje
- Tutoría personalizada en cualquier materia
- Explicaciones paso a paso guardadas
- Práctica de idiomas con contexto
- Resolución de ejercicios académicos

### 💼 Productividad profesional
- Asistencia en escritura de documentos
- Brainstorming y lluvia de ideas
- Análisis de textos y datos
- Automatización de tareas repetitivas

### 🎮 Entretenimiento nostálgico
- Conversación casual con IA
- Roleplay y creatividad narrativa
- Revivir la época dorada del MSN
- Mostrar a amigos la fusión retro-futurista

### 🏢 Casos empresariales (Docker Edition)
- Despliegue en servidores corporativos
- Múltiples instancias para equipos
- Aislamiento de datos por proyecto
- Fácil escalabilidad y mantenimiento

## 🏗️ Arquitectura técnica

### 📱 Frontend (Aplicación web)
```javascript
// Estructura principal
class MSNAI {
  constructor() {
    this.chats = [];
    this.currentChatId = null;
    this.ollamaUrl = 'http://localhost:11434';
    this.models = [];
    this.soundsEnabled = true;
  }
  
  // Funciones principales
  async connectToOllama() { /* ... */ }
  async sendMessage(content) { /* ... */ }
  saveToLocalStorage() { /* ... */ }
  exportChats() { /* ... */ }
  importChats(file) { /* ... */ }
}
```

### 🐳 Docker Architecture
```yaml
# Servicios Docker
services:
  msn-ai:        # Aplicación web + servidor HTTP
  ollama:        # Servicio IA local
  ai-setup:      # Configuración automática hardware
```

### 💾 Almacenamiento de datos
- **Docker**: Volúmenes persistentes (`msn-ai-chats`, `ollama-data`)
- **Local**: localStorage del navegador
- **Formato**: JSON estructurado con metadatos
- **Backup**: Exportación manual o automática (Docker)

### 🔊 Sistema de audio
```javascript
// Gestión de sonidos
const playSound = (soundName) => {
  if (!soundsEnabled) return;
  const audio = new Audio(`assets/sounds/${soundName}.wav`);
  audio.play().catch(console.warn);
};
```

### 🌐 Comunicación con IA
```javascript
// API Ollama
const response = await fetch(`${ollamaUrl}/api/generate`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    model: selectedModel,
    prompt: userMessage,
    stream: false
  })
});
```

## 🚀 Roadmap futuro

### [1.2.0] - Mejoras multiplataforma
- [ ] **Docker**: Soporte para más architecturas (ARM32, RISC-V)
- [ ] **Local**: Instalador GUI para Windows (.msi)
- [ ] **macOS**: App Bundle nativo (.app)
- [ ] **Linux**: Packages .deb/.rpm para todas las distros
- [ ] **Mobile**: PWA (Progressive Web App) para móviles

### [1.3.0] - Funcionalidades avanzadas
- [x] **Emoticons**: Integrados (Naturales y Amor) ✅
- [x] **Dictado por voz**: Speech-to-text implementado ✅
- [x] **Estados de presencia**: Online/Away/Busy/Invisible ✅
- [x] **Búsqueda avanzada**: En chats y dentro de chats ✅
- [x] **Editor de texto**: Formato y ajuste de tamaño ✅
- [ ] **Temas**: Modo oscuro, colores personalizables
- [ ] **Emoticons animados**: Versión animada estilo MSN original
- [ ] **IA múltiple**: Varios modelos simultáneos
- [ ] **Plugins**: Sistema de extensiones
- [ ] **Cifrado**: End-to-end para chats sensibles

### [2.0.0] - Expansión mayor
- [ ] **Colaborativo**: Chat tiempo real entre usuarios
- [ ] **MSN Revival**: Integración con servidores Escargot
- [ ] **Cloud opcional**: Sincronización entre dispositivos
- [ ] **API pública**: Para desarrolladores externos
- [ ] **IA especializada**: Modelos fine-tuned para casos específicos

### [2.1.0] - Funcionalidades avanzadas IA
- [ ] **RAG**: Retrieval-Augmented Generation con documentos
- [ ] **Code execution**: Ejecución de código en sandbox
- [ ] **Multimodal**: Soporte para imágenes y archivos
- [ ] **Voice mejorado**: Text-to-speech para respuestas de IA
- [ ] **Memoria extendida**: Base de datos vectorial
- [ ] **Compartir chats**: Generar links para compartir conversaciones
- [ ] **Backup automático**: Exportación programada de chats

## 📊 Métricas y estadísticas

### 📈 Rendimiento típico
- **Tiempo de carga**: < 2 segundos
- **Latencia IA**: 1-5 segundos (según modelo)
- **Uso de memoria**: 50-200MB (navegador)
- **Espacio en disco**: 
  - **Docker**: 2-4GB (imágenes + modelos)
  - **Local**: 500MB-8GB (según modelos Ollama)

### 🎯 Compatibilidad
- **Navegadores**: 98% usuarios (Chrome, Firefox, Safari, Edge)
- **Sistemas**: Linux, Windows, macOS
- **Arquitecturas**: x86_64, ARM64 (Apple Silicon)
- **Docker**: Engine 20.10+, Compose 1.25+
- **Hardware**: Desde Raspberry Pi hasta workstations

### 📦 Tamaños de descarga
- **Aplicación base**: 15MB (assets incluidos)
- **Docker images**: 1.2GB (MSN-AI + Ollama)
- **Modelos IA típicos**:
  - `phi3:mini`: 2.3GB
  - `mistral:7b`: 4.1GB
  - `llama3:8b`: 4.7GB
  - `llama3:70b`: 40GB

## 🤝 Contribuir al proyecto

### 🐛 Reportar bugs
1. **Issues en GitHub**: Problemas y solicitudes de funcionalidades
2. **Email directo**: alan.mac.arthur.garcia.diaz@gmail.com
3. **Información útil a incluir**:
   - Edición (Docker/Local)
   - Sistema operativo y versión
   - Navegador y versión
   - Pasos para reproducir
   - Logs de error

### 💡 Sugerir funcionalidades
- Crear GitHub Issue con etiqueta "enhancement"
- Describir caso de uso específico
- Mockups o ejemplos visuales (si aplica)
- Considerar compatibilidad multiplataforma

### 🔧 Contribuir código
```bash
# Fork del repositorio
git clone https://github.com/TU_USUARIO/MSN-AI.git
cd MSN-AI

# Crear rama para tu funcionalidad
git checkout -b feature/nueva-funcionalidad

# Realizar cambios y testear
# Docker: docker-compose -f docker/docker-compose.yml up -d
# Local: ./start-msnai.sh

# Commit y push
git add .
git commit -m "Añadir nueva funcionalidad X"
git push origin feature/nueva-funcionalidad

# Crear Pull Request en GitHub
```

### 📚 Contribuir documentación
- Mejoras en README files
- Traducciones a otros idiomas
- Tutoriales y guías de uso
- Casos de estudio reales

### 🎨 Contribuir assets
- Nuevos temas visuales
- Sonidos adicionales (respetando copyright)
- Iconos y elementos UI
- Fondos y personalizaciones

## 📞 Soporte y contacto

### 📧 Contacto directo
**Desarrollador**: Alan Mac-Arthur García Díaz  
**Email**: [alan.mac.arthur.garcia.diaz@gmail.com](mailto:alan.mac.arthur.garcia.diaz@gmail.com)

### 🌐 Enlaces oficiales
- **Repositorio**: https://github.com/mac100185/MSN-AI
- **Clonar**: `git clone https://github.com/mac100185/MSN-AI.git`
- **Issues**: https://github.com/mac100185/MSN-AI/issues
- **Releases**: https://github.com/mac100185/MSN-AI/releases
- **Documentación**: [README-DOCKER.md](docker/README-DOCKER.md)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)
- **Instalación**: [INSTALL-GUIDE.md](INSTALL-GUIDE.md)

### 💬 Comunidad
- **GitHub Discussions**: https://github.com/mac100185/MSN-AI/discussions
- **GitHub Issues**: https://github.com/mac100185/MSN-AI/issues
- **Email**: Para soporte técnico urgente

### 🆘 Soporte empresarial
Para uso empresarial o despliegues masivos:
- Consultoría personalizada disponible
- Configuraciones específicas
- Soporte técnico prioritario
- Funcionalidades customizadas

## ⚖️ Licencia y créditos

### 📄 Licencia
**GNU General Public License v3.0**

**Puntos clave**:
- ✅ Uso comercial y personal permitido
- ✅ Modificación y distribución libre
- ✅ Patent protection incluida
- ⚖️ Copyleft: modificaciones deben ser GPL-3.0
- ⚖️ Código fuente debe proporcionarse

### 🤝 Créditos y agradecimientos
- **[androidWG/WLMOnline](https://github.com/androidWG/WLMOnline)** - Proyecto base para la interfaz
- **Microsoft Corporation** - Windows Live Messenger original (Fair Use educativo)
- **[Ollama Team](https://ollama.ai)** - Por hacer la IA local accesible a todos
- **Proyecto Escargot** - Por mantener vivo el espíritu de MSN
- **Messenger Plus! Community** - Por las herramientas de extracción de assets

### 📜 Derechos de terceros
- **Assets de Microsoft**: Usados bajo Fair Use para preservación histórica
- **Sonidos MSN**: Extraídos del software original con fines educativos
- **Logotipos**: Marcas registradas de sus respectivos propietarios
- **Docker**: Marca registrada de Docker, Inc.

## 🎉 Mensaje final

**¡Gracias por elegir MSN-AI!**

Has descubierto una aplicación única que:

🎨 **Preserva la historia** - Mantiene viva la nostalgia del MSN  
🤖 **Abraza el futuro** - Integra IA local de última generación  
🐳 **Ofrece opciones** - Docker para simplicidad, Local para control  
❤️ **Respeta al usuario** - Libertad total de elección y privacidad  
🌍 **Es verdaderamente universal** - Funciona en cualquier sistema  

### 🌟 Tu experiencia nostálgica te espera

**Docker Edition**: Un comando, cero configuración, máxima compatibilidad  
**Local Edition**: Control total, rendimiento óptimo, personalización avanzada

```bash
# ¿Listo para el viaje nostálgico?
# 1. Clonar repositorio:
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI

# 2. Elegir tu edición:
# Docker (recomendado):
./start-msnai-docker.sh --auto

# Local (clásico):
./start-msnai.sh --auto
```

---

*"Donde cada mensaje es una conexión entre el pasado que amamos y el futuro que construimos"*

**MSN-AI v2.1.0 - Desarrollado con ❤️ por Alan Mac-Arthur García Díaz**  
**Licenciado bajo GPL-3.0 | Diciembre 2024**

**🐳 Docker Edition | 💻 Local Edition | 🎯 Tu elección, tu experiencia**
**Causa**: localStorage del navegador fue limpiado
**Solución**:
1. Los datos se guardan automáticamente en localStorage
2. Exportar regularmente los chats como respaldo
3. Importar desde archivo JSON de respaldo

## 🎨 Características técnicas

### Tecnologías utilizadas
- **Frontend**: HTML5, CSS3, JavaScript ES6+
- **Almacenamiento**: LocalStorage API
- **IA**: Ollama REST API
- **Audio**: Web Audio API
- **Estilo**: CSS Grid y Flexbox

### Compatibilidad de navegadores
- ✅ Chrome 80+
- ✅ Firefox 75+
- ✅ Safari 14+
- ✅ Edge 80+
- ⚠️ Internet Explorer: No soportado

### Tamaño de la aplicación
- **Archivo principal**: ~50KB (msn-ai.html)
- **Assets totales**: ~2MB (imágenes y sonidos)
- **Almacenamiento usado**: Variable según chats guardados

### Rendimiento
- **Carga inicial**: <2 segundos
- **Renderizado de mensajes**: <100ms
- **Respuesta de IA**: Depende del modelo y hardware
- **Uso de memoria**: ~20-50MB típico

## 📖 API de desarrollo

### Clase principal: MSNAI

```javascript
// Crear nueva instancia
const msnai = new MSNAI();

// Crear chat programáticamente
const chatId = msnai.createNewChat();

// Enviar mensaje programáticamente
await msnai.sendMessage('Hola IA', chatId);

// Exportar datos
const data = msnai.exportChats();

// Cambiar configuración
msnai.settings.selectedModel = 'llama3:8b';
msnai.saveSettings();
```

### Eventos disponibles

```javascript
// Escuchar conexión con Ollama
msnai.on('connection', (status) => {
    console.log('Estado de conexión:', status);
});

// Escuchar nuevos mensajes
msnai.on('message', (message) => {
    console.log('Nuevo mensaje:', message);
});
```

## 🤝 Contribución

### Estructura del proyecto
```
MSN-AI/
├── msn-ai.html          # Aplicación principal HTML
├── msn-ai.js            # Lógica JavaScript (modularizado)
├── styles.css           # Estilos CSS (modularizado)
├── ai_check_all.sh      # Script de detección de hardware
├── docker/              # Configuración Docker v2.1.0
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── docker-entrypoint.sh
│   ├── healthcheck.sh
│   ├── scripts/
│   └── README-DOCKER.md
├── assets/              # Recursos multimedia
│   ├── sounds/          # Efectos de sonido
│   ├── background/      # Imágenes de fondo
│   ├── chat-window/     # Iconos de chat
│   ├── contacts-window/ # Iconos de contactos
│   ├── general/         # Elementos generales
│   ├── scrollbar/       # Elementos de scrollbar
│   └── status/          # Iconos de estado
└── README-MSNAI.md      # Esta documentación
```

### Cómo contribuir
1. Fork del repositorio
2. Crear rama feature: `git checkout -b feature/nueva-funcionalidad`
3. Commit cambios: `git commit -am 'Agregar nueva funcionalidad'`
4. Push a la rama: `git push origin feature/nueva-funcionalidad`
5. Crear Pull Request

### Roadmap

#### ✅ Implementado en v2.1.0
- [x] Estados de presencia (Online, Away, Busy, Invisible)
- [x] Emoticones (Naturales y Amor)
- [x] Dictado por voz (Speech-to-text)
- [x] Editor de texto avanzado (formato y tamaño)
- [x] Búsqueda avanzada en chats
- [x] Subir archivos de texto
- [x] Zumbido/Nudge manual
- [x] Exportación selectiva de chats
- [x] Imprimir y ordenar historial

#### 🔮 Próximas versiones
- [ ] Soporte para más modelos de IA (Claude, GPT local)
- [ ] Sistema de plugins para extensiones
- [ ] Temas personalizables (modo oscuro)
- [ ] Emoticones animados estilo MSN
- [ ] Integración con servicios de nube
- [ ] App móvil híbrida (PWA)
- [ ] Cifrado end-to-end para chats
- [ ] Colaboración en tiempo real
- [ ] Integración con Escargot/MSN servers
- [ ] Text-to-speech para respuestas de IA

## 📄 Licencia y Términos Legales

### ⚖️ Licencia Principal
Este proyecto está licenciado bajo la **GNU General Public License v3.0**.

**Puntos clave de GPL-3.0:**
- ✅ Libertad de usar para cualquier propósito
- ✅ Libertad de estudiar y modificar el código
- ✅ Libertad de distribuir copias  
- ✅ Libertad de distribuir modificaciones
- ⚖️ Copyleft: Las modificaciones deben ser GPL-3.0 también

Ver el archivo [LICENSE](LICENSE) para el texto completo.

### 🛡️ Garantía y Responsabilidad
**SOFTWARE PROPORCIONADO "TAL COMO ESTÁ"** según GPL-3.0:
- ❌ Sin garantía de funcionamiento
- ❌ Sin garantía de compatibilidad
- ❌ Sin responsabilidad por daños
- ✅ Código abierto para auditoría completa
- ✅ Soporte de mejor esfuerzo de la comunidad

### 📜 Derechos de Terceros
- **Assets de Microsoft**: Usados bajo Fair Use para preservación histórica
- **Sonidos originales**: Extraídos para fines educativos
- **Proyecto base WLMOnline**: Por androidWG, respetando licencia original
- **Ollama**: Software independiente con su propia licencia

### 🔒 Política de Privacidad
- **100% Local**: Sin envío de datos a servidores externos
- **Sin rastreo**: No recopilamos información personal
- **LocalStorage únicamente**: Datos almacenados en tu navegador
- **Control total**: Exporta, importa o elimina tus datos cuando quieras

## 🙏 Agradecimientos

- **androidWG** por el proyecto original [WLMOnline](https://github.com/androidWG/WLMOnline)
- **Microsoft Corporation** por Windows Live Messenger original
- **Ollama** por hacer accesible la IA local
- **Escargot Project** por mantener vivos los servidores de MSN
- **Messenger Plus!** por las herramientas de extracción de assets
- **Comunidad Open Source** por las librerías y herramientas utilizadas

## 📞 Soporte y Contacto

### 👨‍💻 Desarrollador
**Alan Mac-Arthur García Díaz**  
📧 **Email**: [alan.mac.arthur.garcia.diaz@gmail.com](mailto:alan.mac.arthur.garcia.diaz@gmail.com)

### 🆘 Obtener ayuda
¿Necesitas ayuda? ¿Encontraste un bug? ¿Tienes una idea genial?

- 🐛 **GitHub Issues**: Para reportes de bugs y solicitudes de funcionalidades
- 💬 **Discusiones**: Para preguntas y sugerencias generales  
- 📧 **Email directo**: Para soporte técnico urgente
- 🤝 **Comunidad**: Los usuarios se ayudan entre sí

### ⏱️ Tiempo de respuesta
- **Issues críticos**: Mejor esfuerzo, sin garantía de SLA
- **Preguntas generales**: Respuesta cuando sea posible
- **Contribuciones**: Revisión activa de Pull Requests
- **Email directo**: Para casos urgentes únicamente

### 🤝 Código de conducta
- Respeta a otros usuarios y colaboradores
- Proporciona información detallada en reportes
- Sé constructivo en críticas y sugerencias
- Mantén las discusiones on-topic

---

## 🔗 Enlaces importantes

- 📖 **Documentación**: [README.md](README.md) - Guía principal  
- 📋 **Cambios**: [CHANGELOG.md](CHANGELOG.md) - Historial de versiones
- ⚖️ **Licencia**: [LICENSE](LICENSE) - Texto completo GPL-3.0
- 🏠 **Proyecto base**: [WLMOnline](https://github.com/androidWG/WLMOnline)

---

**¡Disfruta de la nostalgia con el poder de la IA moderna! 🚀✨**

*MSN-AI v2.1.0 - Donde el pasado se encuentra con el futuro*

**Desarrollado con ❤️ por Alan Mac-Arthur García Díaz**  
**Licenciado bajo GPL-3.0 | Enero 2025**