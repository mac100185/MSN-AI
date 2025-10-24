# Changelog - MSN-AI

Todos los cambios notables de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto se adhiere al [Versionado Semántico](https://semver.org/lang/es/).

**Repositorio oficial**: https://github.com/mac100185/MSN-AI

---

## [2.1.1] 2025-10-23

### ✨ Añadido

#### 🎨 Generador de Prompts Profesional
- **Sistema completo de generación de prompts** estructurados
  - Formulario avanzado con 11 campos especializados:
    - 👤 Rol del LLM
    - 📝 Contexto
    - 👥 Audiencia
    - 📋 Tareas (múltiples líneas)
    - ℹ️ Instrucciones
    - 💬 Empatía y Tono
    - ❓ Clarificación
    - 🔄 Refinamiento
    - 🚫 Límites
    - ⚠️ Consecuencias
    - ✨ Ejemplo de Respuesta
  - Generación automática de prompts estructurados
  - Visualización en modal con formato profesional
  - Modo edición para modificar prompts existentes

#### 📚 Gestor de Prompts Guardados
- **Biblioteca completa de prompts**
  - Guardar prompts con metadatos completos:
    - Nombre personalizado
    - Descripción detallada
    - Categoría (personalizable)
    - Tags/etiquetas múltiples
    - Fecha de creación
  - Sistema de filtrado:
    - Por categoría
    - Por búsqueda de texto
    - Visualización en tarjetas tipo Pinterest
  - Gestión avanzada:
    - Ver detalles completos del prompt
    - Editar prompts guardados
    - Usar prompt directamente en el chat
    - Cargar en formulario para edición
    - Eliminar prompts individuales
    - Eliminar todos los prompts (con confirmación)
  - Import/Export:
    - Exportar todos los prompts (JSON)
    - Importar prompts desde archivo
    - Compatibilidad de formato garantizada
  - Contador de prompts guardados
  - Almacenamiento en localStorage

#### 🖥️ Accesos Directos de Escritorio
- **Script de acceso directo para Linux** (`create-desktop-shortcut.sh`)
  - Crea archivo `.desktop` en el escritorio automáticamente
  - Lanzador compatible con GNOME, KDE, XFCE y otros entornos
  - Detección automática del directorio Desktop/Escritorio
  - Configuración de iconos y permisos automática
  - Integración con el sistema de aplicaciones de Linux

- **Script de acceso directo para macOS** (`create-desktop-shortcut-mac.sh`)
  - Crea aplicación `.app` nativa en el escritorio
  - Integración completa con el sistema macOS
  - Conversión automática de icono PNG a ICNS
  - Abre Terminal automáticamente al ejecutar
  - Manejo de permisos y seguridad de macOS

- **Características comunes de ambos scripts**
  - Instalación de un solo comando
  - Verificaciones de integridad del proyecto
  - Modo interactivo con confirmaciones
  - Prueba del acceso directo después de crearlo
  - Instrucciones detalladas de uso
  - Manejo de errores con soluciones alternativas

---

## [2.1.0] - 2025-01-19

### 🎯 Instalación Simplificada (MAJOR)
**¡Versión limpia sin configuración de firewall para máxima simplicidad!**

#### ✨ Añadido

##### 🚀 Instalación y Despliegue
- **Instalación de un solo comando**
  - Configuración automática local y remota sin firewall
  - Auto-detección inteligente de IP del servidor
  - Detección automática de modelos Ollama instalados
  - Zero-config: Sin configuración adicional requerida

- **🐳 Docker Edition optimizada**
  - Contenedores Docker con configuración automática
  - Scripts de gestión dedicados (`docker-start.sh`, `docker-stop.sh`, etc.)
  - Health checks automáticos para todos los servicios
  - Volúmenes persistentes para datos y chats
  - Docker Compose v2 (sin warnings de versión obsoleta)

- **🌐 Acceso Universal**
  - Local: `http://localhost:8000/msn-ai.html`
  - Remoto: `http://[IP-SERVIDOR]:8000/msn-ai.html`
  - Auto-detección del tipo de acceso en JavaScript
  - URLs de Ollama configuradas automáticamente

##### 🎭 Estados de Presencia
- **Selector de estados de usuario** como MSN clásico
  - 🟢 Online - Disponible
  - 🟡 Away - Ausente
  - 🔴 Busy - Ocupado
  - ⚪ Invisible - Aparecer desconectado
- **Notificación de estado a la IA** (opcional)
  - La IA recibe notificación automática cuando cambias tu estado
  - La IA responde contextualmente al cambio de estado
  - Configurable desde el modal de configuración
  - Persistencia del estado entre sesiones
  - Mensajes de sistema diferenciados visualmente

##### 📝 Edición de Texto Avanzada
- **Ajuste de tamaño de fuente**
  - Botones para aumentar/disminuir tamaño de texto
  - Rango: 10px a 32px (ajustable en pasos de 2px)
  - Persistencia de preferencia entre sesiones
  - Mejora la accesibilidad
- **Emoticones integrados**
  - Categoría Naturales 😊 (15 emojis)
  - Categoría Amor ❤️ (15 emojis)
  - Picker desplegable con selección visual
  - Inserción directa en el área de texto
- **Formato de texto**
  - Negrita, Cursiva, Subrayado
  - Editor de texto con botones dedicados
  - Aplicación de formato mediante comandos de documento
- **Dictado por voz** 🎤
  - Transcripción de voz a texto con Web Speech API
  - Compatible con Chrome, Edge y navegadores modernos
  - Requiere permisos de micrófono
  - Indicador visual durante la grabación
  - Manejo de errores y permisos denegados
- **Subir archivos de texto**
  - Carga archivos .txt directamente al chat
  - Ideal para consultas largas o código
  - Preview del contenido antes de enviar
- **Subir archivos PDF** 📄
  - Carga y procesamiento de archivos PDF
  - Extracción de texto con PDF.js
  - OCR integrado con Tesseract.js para PDFs escaneados
  - Soporte para múltiples idiomas (español e inglés)
  - Fragmentación inteligente de texto en chunks
  - Límite de 10MB por archivo
  - Vista previa del nombre y número de páginas
  - Contexto PDF temporal (no se guarda en historial)
- **Zumbido/Nudge manual** 📳
  - Botón para enviar "sacudidas" como MSN original
  - Animación de vibración auténtica
  - Sonido característico de MSN
  - La IA responde al nudge contextualmente

##### 🔍 Búsqueda y Organización Mejorada
- **Búsqueda avanzada en dos niveles**
  - Búsqueda general: filtra lista de chats por título
  - Búsqueda específica: busca dentro del chat activo
  - Resaltado de coincidencias en mensajes
  - Botón para limpiar búsqueda
  - Búsqueda en tiempo real (sin necesidad de presionar Enter)
- **Ordenar historial de chats**
  - Organización por fecha ascendente/descendente
  - Icono visual que indica el orden actual
  - Persistencia del orden entre sesiones
  - Toggle fácil con un clic
- **Exportación flexible de chats**
  - Exportar todos los chats (formato JSON)
  - Exportar solo chats seleccionados (con checkboxes)
  - Exportar chat individual activo
  - Incluye configuración y metadatos

##### 🛠️ Funcionalidades Adicionales de Chat
- **Limpiar chat** - Borra mensajes sin eliminar el chat completo
- **Cerrar chat** - Cierra la vista sin eliminar historial (con confirmación)
- **Imprimir chat** - Genera versión imprimible de la conversación con estilos
- **Modal de confirmación** para eliminar chats (previene errores accidentales)
- **Modal de información** con datos de contacto y documentación completa
- **Sistema de selección múltiple** - Checkboxes para exportación selectiva
- **Indicadores de no leídos** - Resalta chats con mensajes nuevos en verde
- **Multi-chat simultáneo** - La IA responde en varios chats mientras navegas
- **Detener respuesta** - Botón para abortar generación de IA en curso
- **Importación inteligente** - Resolución automática de conflictos al importar
- **Agrupación por modelo** - Los chats se agrupan por modelo de IA utilizado
- **Cambio automático de modelo** - Al seleccionar un chat, cambia al modelo usado

##### 🌍 Sistema Multi-idioma
- **22 idiomas soportados**
  - Español (es), Inglés (en), Alemán (de), Francés (fr)
  - Árabe (ar), Chino (zh), Hindi (hi), Bengalí (bn)
  - Portugués (pt), Ruso (ru), Japonés (ja), Coreano (ko)
  - Indonesio (id), Turco (tr), Urdu (ur), Vietnamita (vi)
  - Tamil (ta), Telugu (te), Maratí (mr), Panyabí (pa)
  - Quechua (qu), Aymara (ay)
- **Detección automática de idioma del navegador**
- **Selector de idioma en configuración**
- **Traducción completa de interfaz**
- **Persistencia de preferencia de idioma**
- **Archivos JSON de traducción** en directorio `lang/`

##### 🔒 Seguridad y Renderizado
- **Renderizado seguro de Markdown**
  - Integración con marked.js para conversión de Markdown
  - Sanitización con DOMPurify para prevenir XSS
  - Resaltado de sintaxis con Highlight.js
  - Soporte para bloques de código con lenguajes
  - Listas, tablas, enlaces y formato completo

#### 🔧 Mejorado

##### Interface y UX
- **Interface MSN-AI (arquitectura modularizada)**
  - `msn-ai.html` (827 líneas) - Estructura HTML semántica
  - `msn-ai.js` (4,697 líneas) - Lógica JavaScript modular y robusta
  - `styles.css` (1,666 líneas) - Estilos CSS completos y responsivos
  - **Total: 7,190 líneas de código**
  - Auto-configuración mejorada para acceso local y remoto
  - Carga automática de modelos disponibles
  - Auto-selección del primer modelo disponible
  - Logging detallado para diagnóstico
  - Manejo robusto de errores de conexión
  - Sistema de eventos para componentes UI
  - Gestión de estados de respuesta múltiple

##### Configuración
- **Modal de configuración expandido**
  - Opción para activar/desactivar sonidos
  - Opción para notificar cambios de estado a la IA
  - Selector de idioma de interfaz (22 idiomas)
  - Configuración de servidor Ollama (autodetección o manual)
  - Selector de modelo de IA con carga dinámica
  - Botón "Probar Conexión" para verificar Ollama
  - Timeout de API configurable
  - Persistencia de todas las configuraciones

##### Scripts de Instalación
- **Scripts Docker mejorados**
  - `docker-start.sh` - Inicio automático
  - `docker-stop.sh` - Detención segura
  - `docker-status.sh` - Monitor de estado
  - `docker-logs.sh` - Visualización de logs
  - `docker-cleanup.sh` - Limpieza completa
  - `docker-check-config.sh` - Verificación de configuración
  - `docker-test-ai.sh` - Test de IA en Docker
  - `ai-setup-docker.sh` - Configuración automática de hardware y modelos
- **Scripts locales optimizados**
  - `start-msnai.sh` - Instalación local Linux
  - `start-msnai-mac.sh` - Instalación local macOS
  - `start-msnai.ps1` - Instalación Windows PowerShell
  - `start-msnai-docker.sh` - Instalación Docker Linux
  - `start-msnai-docker-mac.sh` - Instalación Docker macOS
  - `start-msnai-docker.ps1` - Instalación Docker Windows
  - `ai_check_all.sh` - Verificación IA Linux
  - `ai_check_all_mac.sh` - Verificación IA macOS
  - `ai_check_all.ps1` - Verificación IA Windows
  - Eliminación de configuración automática de firewall
  - Mensajes informativos mejorados
  - Verificación automática de conectividad

#### 🗑️ Eliminado
- Configuración automática de firewall UFW (simplificación)
- Scripts relacionados con SSH recovery (innecesarios)
- Dependencias de configuración manual de puertos
- Complejidad innecesaria en scripts de instalación
- Referencias a directorio `backup/` (no existente)
- Inconsistencias de versiones en documentación
- Warnings de versión obsoleta en Docker Compose

#### 🐛 Corregido
- ✅ Problema de detección de modelos Ollama
- ✅ Indicador de conexión siempre en rojo (ahora funcional)
- ✅ Conflictos entre localStorage y auto-detección
- ✅ Error en método `renderChats()` (corregido a `renderChatList()`)
- ✅ Verificaciones DOM en `updateSettingsUI()`
- ✅ Inconsistencias en versiones de documentación (unificado a v2.1.0)
- ✅ Descripción incorrecta de arquitectura (ahora modular en 3 archivos)
- ✅ Healthcheck circular dependency en Docker
- ✅ Error "docker-compose: command not found" (scripts actualizados a Docker Compose v2)
- ✅ Warnings de versión obsoleta en docker-compose.yml
- ✅ Problemas de encoding en archivos de idioma
- ✅ Búsqueda dentro de chat no resaltaba correctamente
- ✅ Botón de detener respuesta no se ocultaba correctamente
- ✅ Conflictos al importar chats duplicados
- ✅ Scroll automático al fondo al recibir respuestas
- ✅ Detección de scroll manual del usuario

#### 📚 Documentación Actualizada
- **README.md** - Expandido con todas las funcionalidades UI y 22 idiomas
- **CHANGELOG.md** - Registro detallado de cambios y mejoras (este archivo)
- **Coherencia 100%** entre código (HTML/JS/CSS) y documentación
- **Métricas actualizadas** - Líneas de código, funcionalidades, idiomas

### 💡 Notas Técnicas
- **Firewall**: MSN-AI funciona con firewall deshabilitado para simplicidad máxima
- **Puertos**: 8000 (Web) y 11434 (Ollama) quedan automáticamente disponibles
- **Seguridad**: Para entornos de producción, configurar firewall manualmente según necesidades
- **Arquitectura**: Aplicación modularizada en 3 archivos (HTML + JS + CSS)
- **Total líneas de código**: 7,190 líneas (827 HTML + 4,697 JS + 1,666 CSS)
- **Idiomas**: 22 archivos JSON de traducción en directorio `lang/`
- **Compatibilidad**: Navegadores modernos (Chrome, Edge, Firefox, Safari)
- **Almacenamiento**: localStorage del navegador (sin límite práctico)
- **Librerías externas**:
  - marked.js (v12.0.2) - Conversión de Markdown
  - DOMPurify (v3.0.5) - Sanitización HTML
  - Highlight.js (v11.10.0) - Resaltado de sintaxis
  - PDF.js (v3.11.174) - Procesamiento de PDFs
  - Tesseract.js (v5.0.4) - OCR para PDFs escaneados

### 📊 Estadísticas v2.1.0
- **50+ características** completamente funcionales
- **22 idiomas** soportados con traducciones completas
- **25+ funcionalidades UI** avanzadas
- **19 scripts** de instalación y gestión (7 Docker + 12 locales)
- **7 scripts Docker** de gestión incluidos
- **5 sonidos auténticos** de MSN integrados
- **4 estados de presencia** implementados (Online, Away, Busy, Invisible)
- **2 categorías de emoticones** disponibles (30 emojis totales)
- **7,190 líneas** de código frontend
- **3 archivos principales** (HTML, JS, CSS) modularizados
- **4 volúmenes Docker** para persistencia de datos
- **3 servicios Docker** (msn-ai, ollama, ai-setup)
- **2 modos de instalación** (Docker y Local)

---

## [1.0.0] - 2025-01-15

### 🎉 Versión Inicial
**Primera versión estable de MSN-AI con interfaz nostálgica de Windows Live Messenger**

#### ✨ Características Principales
- **🎨 Interfaz auténtica** de Windows Live Messenger 8.5
- **🤖 Integración con Ollama** para IA local (Mistral, Llama, Phi3, etc.)
- **💾 Persistencia de chats** con localStorage del navegador
- **🔊 Sonidos originales** de MSN Messenger (5 sonidos incluidos)
- **📤 Import/Export** de conversaciones en formato JSON
- **🌐 Instalación local** con servidor Python/HTTP integrado
- **💬 Gestión básica de chats** (crear, seleccionar, eliminar)
- **🔍 Búsqueda básica** en lista de chats
- **⚙️ Configuración** de servidor Ollama y modelo de IA

#### 🚀 Scripts Incluidos (Local)
- `start-msnai.sh` - Instalación local Linux
- `start-msnai-mac.sh` - Instalación local macOS
- `start-msnai.ps1` - Instalación Windows PowerShell
- `ai_check_all.sh` - Verificación y configuración de IA Linux
- `ai_check_all_mac.sh` - Verificación IA macOS
- `ai_check_all.ps1` - Verificación IA Windows
- `test-msnai.sh` - Tests de componentes
- `create-desktop-shortcut.ps1` - Crear acceso directo Windows

#### 🎵 Assets Incluidos
- Sonidos originales MSN (login, mensajes, nudge, etc.)
- Imágenes de interfaz auténticas
- Fondos y elementos visuales de Windows Live Messenger

#### 📏 Métricas v1.0.0
- **25+ características** básicas funcionales
- **1 idioma** soportado (Español)
- **8 scripts** de instalación y gestión
- **5 sonidos** integrados
- **~2,500 líneas** de código frontend

---

## 🔮 Próximas versiones

### [2.2.0] - Planificado
- 🎨 Personalización de temas y colores
- 📱 Mejoras en responsive design para móviles
- 🔐 Cifrado opcional de conversaciones (AES-256)
- 🗂️ Organización de chats por carpetas/categorías
- 📊 Estadísticas de uso y analytics local
- 🔄 Sincronización entre dispositivos (opcional)
- 🎯 Asistente de mejora de prompts con IA
- 📝 Plantillas de prompts predefinidas por categoría
- 🌟 Sistema de favoritos y destacados
- 🔍 Búsqueda avanzada con filtros múltiples

### [3.0.0] - Futuro
- 🎥 Soporte para imágenes en conversaciones (modelos multimodales)
- 🤖 Múltiples IAs simultáneas (debates entre modelos)
- 🎮 Modo de juego: Adivina quién (IA vs IA)
- 🌐 API REST para integración externa
- 📦 Plugins y extensiones de comunidad
- 🔌 Sistema de extensiones con marketplace
- 🎤 Síntesis de voz (TTS) para respuestas de IA
- 📹 Videollamadas simuladas con avatares IA
- 🌍 Modo colaborativo multi-usuario
- 💼 Modo empresarial con gestión de equipos

---

## 🏆 Hitos del Proyecto

### Diciembre 2024
- 🎄 Concepción del proyecto MSN-AI
- 📐 Diseño de arquitectura inicial
- 🎨 Prototipo de interfaz nostálgica

### Enero 2025
- 🚀 **v1.0.0** - Primera versión estable (15 de enero)
- 🎭 **v2.1.0** - Versión con múltiples mejoras (19 de enero)
- 📚 Documentación completa y profesional
- 🌍 Sistema multi-idioma implementado
- 🐳 Docker Edition optimizada

### Octubre 2025
- 📝 Sistema de generador de prompts profesional
- 💾 Gestor completo de biblioteca de prompts
- 🔧 Mejoras continuas en estabilidad y UX

---

## 📋 Notas de Desarrollo

### Convenciones de Commits
- ✨ `feat:` Nueva funcionalidad
- 🐛 `fix:` Corrección de bug
- 📚 `docs:` Cambios en documentación
- 🎨 `style:` Cambios de formato/estilo
- ♻️ `refactor:` Refactorización de código
- ⚡ `perf:` Mejoras de rendimiento
- ✅ `test:` Añadir o modificar tests
- 🔧 `chore:` Tareas de mantenimiento
- 🚀 `deploy:` Cambios relacionados con despliegue

### Versionado Semántico
- **MAJOR** (X.0.0): Cambios incompatibles con versiones anteriores
- **MINOR** (x.Y.0): Nueva funcionalidad compatible con versiones anteriores
- **PATCH** (x.y.Z): Correcciones de bugs compatibles

---

**🚀 MSN-AI** - Donde la nostalgia se encuentra con la inteligencia artificial moderna

**Desarrollado con ❤️ por Alan Mac-Arthur García Díaz**

**Licencia GPL-3.0 • 2024-2025**

---

📧 **Contacto**: mac100185@gmail.com
🐙 **GitHub**: https://github.com/mac100185/MSN-AI
⭐ **Si te gusta el proyecto, deja una estrella en GitHub!**

---

## 📜 Licencia

Este proyecto está licenciado bajo la Licencia Pública General GNU v3.0 (GPL-3.0).

**Derechos**: © 2024-2025 Alan Mac-Arthur García Díaz

Para más información sobre la licencia, consulta el archivo [LICENSE](LICENSE) en la raíz del proyecto.

---

*Última actualización: 23 de octubre de 2025*
