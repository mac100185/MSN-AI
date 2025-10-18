# Changelog - MSN-AI

Todos los cambios notables de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto se adhiere al [Versionado Semántico](https://semver.org/lang/es/).

**Repositorio oficial**: https://github.com/mac100185/MSN-AI

## [2.1.0] - 2024-12-16

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
  - Online 🟢 - Disponible
  - Away 🟡 - Ausente
  - Busy 🔴 - Ocupado
  - Invisible ⚪ - Aparecer desconectado
- **Notificación de estado a la IA** (opcional)
  - La IA recibe notificación automática cuando cambias tu estado
  - Configurable desde el modal de configuración
  - Persistencia del estado entre sesiones

##### 📝 Edición de Texto Avanzada
- **Ajuste de tamaño de fuente**
  - Botones para aumentar/disminuir tamaño de texto
  - Rango: 10px a 32px
  - Mejora la accesibilidad
- **Emoticones integrados**
  - Categoría Naturales 😊
  - Categoría Amor ❤️
  - Picker desplegable con selección visual
- **Formato de texto**
  - Negrita, Cursiva, Subrayado
  - Editor de texto con botones dedicados
- **Dictado por voz** 🎤
  - Transcripción de voz a texto con Web Speech API
  - Compatible con Chrome, Edge y navegadores modernos
  - Requiere permisos de micrófono
- **Subir archivos de texto**
  - Carga archivos .txt directamente al chat
  - Ideal para consultas largas o código
- **Zumbido/Nudge manual** 📳
  - Botón para enviar "sacudidas" como MSN original
  - Animación y sonido auténtico

##### 🔍 Búsqueda y Organización Mejorada
- **Búsqueda avanzada en dos niveles**
  - Búsqueda general en todos los chats
  - Búsqueda específica dentro de un chat con resaltado
  - Botón para limpiar búsqueda
- **Ordenar historial de chats**
  - Organización por fecha ascendente/descendente
  - Persistencia del orden entre sesiones
- **Exportación flexible de chats**
  - Exportar todos los chats
  - Exportar solo chats seleccionados
  - Exportar chat individual activo

##### 🛠️ Funcionalidades Adicionales de Chat
- **Limpiar chat** - Borra mensajes sin eliminar el chat completo
- **Cerrar chat** - Cierra la vista sin eliminar historial
- **Imprimir chat** - Genera versión imprimible de la conversación
- **Modal de confirmación** para eliminar chats (previene errores)
- **Modal de información** con datos de contacto y documentación

#### 🔧 Mejorado

##### Interface y UX
- **Interface MSN-AI (arquitectura modularizada)**
  - `msn-ai.html` (390 líneas) - Estructura HTML
  - `msn-ai.js` (1,434 líneas) - Lógica JavaScript modular
  - `styles.css` (967 líneas) - Estilos CSS completos
  - Auto-configuración mejorada para acceso local y remoto
  - Carga automática de modelos disponibles
  - Auto-selección del primer modelo disponible
  - Logging detallado para diagnóstico
  - Manejo robusto de errores de conexión

##### Configuración
- **Modal de configuración expandido**
  - Opción para activar/desactivar sonidos
  - Opción para notificar cambios de estado a la IA
  - Configuración de servidor Ollama (autodetección o manual)
  - Selector de modelo de IA con carga dinámica
  - Botón "Probar Conexión" para verificar Ollama

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
- Configuración automática de firewall UFW
- Scripts relacionados con SSH recovery
- Dependencias de configuración manual de puertos
- Complejidad innecesaria en scripts de instalación
- Referencias a directorio `backup/` (no existente)
- Inconsistencias de versiones en documentación

#### 🐛 Corregido
- Problema de detección de modelos Ollama
- Indicador de conexión siempre en rojo
- Conflictos entre localStorage y auto-detección
- Error en método `renderChats()` (corregido a `renderChatList()`)
- Verificaciones DOM en `updateSettingsUI()`
- Inconsistencias en versiones de documentación (unificado a v2.1.0)
- Descripción incorrecta de arquitectura (ahora modular en 3 archivos)

#### 📚 Documentación Actualizada
- **README.md** - Expandido con todas las funcionalidades UI
- **README-MSNAI.md** - Documentación técnica completa con 38 características
- **IMPLEMENTACION-COMPLETA.md** - Actualizado con features implementadas
- **Roadmap actualizado** - Movidas 9 características de "futuro" a "✅ Implementado"
- **Coherencia 100%** entre código (HTML/JS) y documentación

### 💡 Notas Técnicas
- **Firewall**: MSN-AI funciona con firewall deshabilitado para simplicidad máxima
- **Puertos**: 8000 (Web) y 11434 (Ollama) quedan automáticamente disponibles
- **Seguridad**: Para entornos de producción, configurar firewall manualmente según necesidades
- **Arquitectura**: Aplicación modularizada en 3 archivos (HTML + JS + CSS)
- **Total líneas de código**: 2,791 líneas (390 HTML + 1,434 JS + 967 CSS)

### 📊 Estadísticas v2.1.0
- **38 características** completamente funcionales
- **15 nuevas funcionalidades UI** desde v1.0.0
- **7 scripts Docker** de gestión incluidos
- **5 sonidos auténticos** de MSN integrados
- **4 estados de presencia** implementados
- **2 categorías de emoticones** disponibles

---

## [1.0.0] - 2024-11-30

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

#### 🚀 Scripts Incluidos
- `start-msnai.sh` - Instalación local Linux/macOS
- `start-msnai.ps1` - Instalación Windows
- `ai_check_all.sh` - Verificación y configuración de IA
- `test-msnai.sh` - Tests de componentes

#### 🎵 Assets Incluidos
- Sonidos originales MSN (login, mensajes, nudge, etc.)
- Imágenes de interfaz auténticas
- Fondos y elementos visuales de Windows Live Messenger

---

**🚀 MSN-AI** - Donde la nostalgia se encuentra con la inteligencia artificial moderna  
**Desarrollado con ❤️ por Alan Mac-Arthur García Díaz**  
**Licencia GPL-3.0 • 2024**