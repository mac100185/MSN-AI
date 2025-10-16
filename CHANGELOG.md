# Changelog - MSN-AI

Todos los cambios notables de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto se adhiere al [Versionado Semántico](https://semver.org/lang/es/).

## [1.1.0] - 2025-01-15

### 🐳 Nueva Opción Docker (MAJOR)
**¡Implementación Docker completa como alternativa a la instalación local!**

#### ✨ Añadido - Docker Edition
- **🏗️ Infraestructura Docker completa**
  - `docker/Dockerfile` - Imagen optimizada con usuario no-root y health checks
  - `docker/docker-compose.yml` - Orquestación completa (MSN-AI + Ollama + AI Setup)
  - `docker/docker-entrypoint.sh` - Script de inicio inteligente del contenedor
  - `docker/healthcheck.sh` - Verificación automática de salud
  - `docker/scripts/ai-setup-docker.sh` - Detector de hardware adaptado para contenedores
  - `docker/README-DOCKER.md` - Documentación técnica completa (630+ líneas)

- **🚀 Scripts de inicio multiplataforma Docker**
  - `start-msnai-docker.sh` - Linux con instalación automática de Docker
  - `start-msnai-docker.ps1` - Windows con Docker Desktop automático
  - `start-msnai-docker-mac.sh` - macOS optimizado (Apple Silicon + Intel)

- **🧠 Detector de hardware conservado al 100%**
  - Mismo algoritmo de selección de modelos que la versión local
  - Detecta GPU/CPU/RAM dentro del contenedor
  - Optimizaciones por plataforma (Apple Silicon, Intel, NVIDIA)
  - Configuración automática de modelos según hardware
  - Compatible con NVIDIA Container Toolkit para GPU

- **⚙️ Características Docker avanzadas**
  - Instalación cero prerequisitos (solo requiere Docker)
  - Volúmenes persistentes para chats, modelos y configuración
  - Health checks automáticos y monitoreo
  - Backup/Restore integrado
  - Soporte para GPU (NVIDIA Container Toolkit)
  - Configuración por variables de entorno

#### 🔧 Mejoras técnicas
- **`.dockerignore`** optimizado para build context eficiente
- **Multi-stage builds** para imágenes ligeras
- **Networking** aislado con comunicación inter-contenedor
- **Security** - Usuario no-root, permisos mínimos
- **Escalabilidad** - Múltiples instancias sin conflictos

#### 📚 Documentación actualizada
- Todas las guías actualizadas con opciones Docker
- Comparación detallada Docker vs Local
- Guías de troubleshooting específicas para Docker
- Ejemplos de despliegue en producción

### 🎯 Filosofía preservada
- **Opción adicional** (no reemplazo de la instalación local)
- **Libertad de elección** entre Docker o instalación local
- **Misma experiencia** nostálgica y funcionalidades
- **Coexistencia perfecta** de ambas opciones

### 💡 Experiencia de usuario mejorada
- **Un solo comando** para instalación completa: `./start-msnai-docker.sh --auto`
- **Compatibilidad universal** - idéntico comportamiento en todos los OS
- **Instalación automática** de Docker si no está presente
- **Detección inteligente** de plataforma y optimizaciones automáticas

## [1.0.0] - 2025-01-07

### 🎉 Lanzamiento inicial
Primera versión completa de MSN-AI que combina la nostalgia de Windows Live Messenger con IA local moderna.

### 🌍 Soporte multiplataforma completo
- **Linux**: Scripts nativos bash con detección automática
- **Windows**: Scripts PowerShell con instalación automática
- **macOS**: Scripts optimizados para Apple Silicon y Intel

### ✨ Añadido
- **Interfaz completa de Windows Live Messenger 8.5**
  - Recreación pixel-perfect de la UI original
  - Efectos Aero auténticos 
  - Scrollbars personalizados estilo Windows Vista/7
  - Colores y gradientes fieles al original

- **Integración completa con IA local (Ollama)**
  - Soporte para múltiples modelos (Mistral, Llama3, Phi3, etc.)
  - Conversaciones contextuales inteligentes
  - Detección automática de modelos disponibles
  - Reconexión automática en caso de desconexión

- **Sistema de chats históricos**
  - Almacenamiento persistente en localStorage del navegador
  - Generación automática de títulos de conversación
  - Búsqueda en tiempo real en todos los chats
  - Gestión completa de conversaciones (crear, seleccionar, eliminar)

- **Experiencia auditiva auténtica**
  - 5 sonidos originales de MSN integrados:
    - `login.wav` - Sonido de inicio de sesión
    - `message_in.wav` - Mensaje recibido de la IA
    - `message_out.wav` - Mensaje enviado por el usuario
    - `nudge.wav` - Notificaciones y nuevos chats
    - `calling.wav` - Para funcionalidades futuras
  - Control de volumen y activación por usuario

- **Sistema de Import/Export robusto**
  - Exportación completa de chats en formato JSON
  - Importación con validación de datos
  - Preservación de metadatos y timestamps
  - Nombres de archivo automáticos con fecha
  - Fusión inteligente sin duplicados

- **Configuración avanzada**
  - Configuración del servidor Ollama
  - Selección de modelo de IA preferido
  - Control de sonidos
  - Test de conectividad integrado
  - Interfaz modal estilo Windows

- **Scripts de automatización multiplataforma**
  - **Linux**: `start-msnai.sh` y `ai_check_all.sh` - Scripts bash nativos
  - **Windows**: `start-msnai.ps1` y `ai_check_all.ps1` - Scripts PowerShell
  - **macOS**: `start-msnai-mac.sh` y `ai_check_all_mac.sh` - Scripts optimizados
  - `test-msnai.sh` - Verificación universal con detección de plataforma
  - Instalación automática de Ollama en todas las plataformas

- **Funcionalidades de UI avanzadas**
  - Indicador visual de "IA pensando" con animación
  - Estados de conexión en tiempo real
  - Formato de mensajes con markdown básico
  - Timestamps localizados en español
  - Interfaz responsive para diferentes tamaños de pantalla

- **Documentación completa**
  - `README.md` - Guía principal clara y concisa
  - `README-MSNAI.md` - Documentación técnica detallada (358 líneas)
  - `IMPLEMENTACION-COMPLETA.md` - Resumen técnico completo
  - Guías de instalación, uso y solución de problemas

### 🔧 Técnico
- **Arquitectura**: Aplicación web monolítica en un solo archivo HTML
- **Frontend**: HTML5 + CSS3 + JavaScript ES6+ (927 líneas de código)
- **Almacenamiento**: LocalStorage API para persistencia
- **IA**: Integración con Ollama REST API
- **Audio**: Web Audio API para sonidos
- **Plataformas**: Linux, Windows 10/11, macOS 10.14+
- **Compatibilidad**: Chrome 80+, Firefox 75+, Safari 14+, Edge 80+

### 🛡️ Seguridad y respaldos
- Sistema de respaldo automático de archivos originales
- Validación de datos en import/export
- Manejo robusto de errores de red y API
- Sin transmisión de datos a servicios externos

### 📊 Métricas
- **Total de líneas de código**: 2,200+ (incluye scripts multiplataforma)
- **Scripts por plataforma**: 6 scripts especializados
- **Funcionalidades implementadas**: 15/15 ✅
- **Archivos de sonido**: 5 archivos auténticos
- **Assets gráficos**: 50+ elementos de UI
- **Plataformas soportadas**: 3 (Linux, Windows, macOS)
- **Compatibilidad de navegadores**: 95%+ de usuarios
- **Tiempo de carga típico**: <2 segundos

## [0.1.0] - Base WLMOnline
### 📦 Heredado del proyecto original
- Interfaz estática de Windows Live Messenger
- Assets gráficos extraídos del WLM original
- Estructura CSS modular
- Recreación visual fiel de WLM 8.5

---

## 🔮 Roadmap futuro

### [1.1.0] - Mejoras multiplataforma (Próximamente)
- [ ] Instalador GUI para Windows (.msi)
- [ ] App Bundle para macOS (.app)
- [ ] Package .deb/.rpm para distribuciones Linux
- [ ] Temas personalizables (modo oscuro, diferentes colores)
- [ ] Emoticons animados
- [ ] Sistema de plugins para extensiones

### [1.2.0] - Funcionalidades avanzadas
- [ ] Soporte para más modelos de IA (Claude local, GPT4All)
- [ ] Cifrado end-to-end para chats sensibles
- [ ] Colaboración en tiempo real entre usuarios
- [ ] Integración con servicios de nube opcionales

### [2.0.0] - Expansión mayor
- [ ] App móvil híbrida (PWA)
- [ ] Integración con servidores MSN revividos (Escargot)
- [ ] Sistema de usuarios y perfiles
- [ ] Funcionalidades de videollamada simulada

---

## 🏷️ Convenciones de versionado

- **MAJOR** (X.0.0): Cambios incompatibles o rediseño completo
- **MINOR** (1.X.0): Nuevas funcionalidades compatibles hacia atrás  
- **PATCH** (1.0.X): Corrección de bugs y mejoras menores

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Ver [README.md](README.md) para guías de contribución.

## 📄 Licencia

Este proyecto está bajo la Licencia GNU General Public License v3.0. Ver [LICENSE](LICENSE) para más detalles.

---

**Autor**: Alan Mac-Arthur García Díaz  
**Contacto**: alan.mac.arthur.garcia.diaz@gmail.com  
**Proyecto base**: [WLMOnline por androidWG](https://github.com/androidWG/WLMOnline)