# Changelog - MSN-AI

Todos los cambios notables de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto se adhiere al [Versionado Semántico](https://semver.org/lang/es/).

**Repositorio oficial**: https://github.com/mac100185/MSN-AI

---

## [No Publicado]

### ✨ Añadido

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

## [2.1.0] - 2025-10-19

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

- **🌐 Acceso Universal**
  - Local: `http://localhost:8000/msn-ai.html`
  - Remoto: `http://[IP-SERVIDOR]:8000/msn-ai.html`
  - Auto-detección del tipo de acceso en JavaScript
  - URLs de Ollama configuradas automáticamente

##### 🎭 Estados de Presencia (Nueva Funcionalidad)
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

##### 🌍 Sistema Multi-idioma (NUEVO)
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

#### 🔧 Mejorado

##### Interface y UX
- **Interface MSN-AI (arquitectura modularizada)**
  - `msn-ai.html` (475 líneas) - Estructura HTML semántica
  - `msn-ai.js` (2,764 líneas) - Lógica JavaScript modular y robusta
  - `styles.css` (1,099 líneas) - Estilos CSS completos y responsivos
  - **Total: 4,338 líneas de código**
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
- **Scripts locales optimizados**
  - `start-msnai-docker.sh` - Instalación Docker simplificada
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
- ✅ Error "docker-compose: command not found" (scripts actualizados)
- ✅ Warnings de versión obsoleta en docker-compose.yml
- ✅ Problemas de encoding en archivos de idioma
- ✅ Búsqueda dentro de chat no resaltaba correctamente
- ✅ Botón de detener respuesta no se ocultaba correctamente
- ✅ Conflictos al importar chats duplicados

#### 📚 Documentación Actualizada
- **README.md** - Expandido con todas las funcionalidades UI y 22 idiomas
- **README-MSNAI.md** - Documentación técnica completa con 45+ características
- **IMPLEMENTACION-COMPLETA.md** - Actualizado con todas las features implementadas
- **INSTALL-GUIDE.md** - Guía completa multiplataforma con Docker y Local
- **WINDOWS-SETUP.md** - Guía específica para Windows actualizada
- **CHANGELOG.md** - Registro detallado de cambios y mejoras
- **Roadmap actualizado** - Movidas características de "futuro" a "✅ Implementado"
- **Coherencia 100%** entre código (HTML/JS/CSS) y documentación
- **Métricas actualizadas** - Líneas de código, funcionalidades, idiomas

### 💡 Notas Técnicas
- **Firewall**: MSN-AI funciona con firewall deshabilitado para simplicidad máxima
- **Puertos**: 8000 (Web) y 11434 (Ollama) quedan automáticamente disponibles
- **Seguridad**: Para entornos de producción, configurar firewall manualmente según necesidades
- **Arquitectura**: Aplicación modularizada en 3 archivos (HTML + JS + CSS)
- **Total líneas de código**: 4,338 líneas (475 HTML + 2,764 JS + 1,099 CSS)
- **Idiomas**: 22 archivos JSON de traducción en directorio `lang/`
- **Compatibilidad**: Navegadores modernos (Chrome, Edge, Firefox, Safari)
- **Almacenamiento**: localStorage del navegador (sin límite práctico)

### 📊 Estadísticas v2.1.0
- **45+ características** completamente funcionales
- **22 idiomas** soportados con traducciones completas
- **20+ nuevas funcionalidades UI** desde v1.0.0
- **7 scripts Docker** de gestión incluidos
- **6 scripts de inicio/gestión** para instalación local
- **5 sonidos auténticos** de MSN integrados
- **4 estados de presencia** implementados (Online, Away, Busy, Invisible)
- **2 categorías de emoticones** disponibles (30 emojis totales)
- **4,338 líneas** de código frontend
- **3 archivos principales** (HTML, JS, CSS) modularizados

---

## [1.0.0] - 2025-10-15

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

---

---

## 🔮 Próximas versiones

### [1.3.0] - En desarrollo
- 🎨 Personalización de temas y colores
- 📱 Mejoras en responsive design
- 🔐 Cifrado opcional de conversaciones
- 🗂️ Organización de chats por carpetas/categorías
- 📊 Estadísticas de uso y analytics local
- 🔄 Sincronización entre dispositivos (opcional)

### [2.0.0] - Futuro
- 🎥 Soporte para imágenes en conversaciones
- 🤖 Múltiples IAs simultáneas (debates entre modelos)
- 🎮 Modo de juego: Adivina quién (IA vs IA)
- 🌐 API REST para integración externa
- 📦 Plugins y extensiones de comunidad

---

**🚀 MSN-AI** - Donde la nostalgia se encuentra con la inteligencia artificial moderna
**Desarrollado con ❤️ por Alan Mac-Arthur García Díaz**
**Licencia GPL-3.0 • 2024**

📧 **Contacto**: mac100185@gmail.com
🐙 **GitHub**: https://github.com/mac100185/MSN-AI
⭐ **Si te gusta el proyecto, deja una estrella en GitHub!**
