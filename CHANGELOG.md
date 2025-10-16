# Changelog - MSN-AI

Todos los cambios notables de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto se adhiere al [Versionado Semántico](https://semver.org/lang/es/).

**Repositorio oficial**: https://github.com/mac100185/MSN-AI

## [2.1.0] - 2024-12-16

### 🎯 Instalación Simplificada (MAJOR)
**¡Versión limpia sin configuración de firewall para máxima simplicidad!**

#### ✨ Añadido
- **🚀 Instalación de un solo comando**
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

#### 🔧 Mejorado
- **Interface MSN-AI (`msn-ai.html`)**
  - Auto-configuración mejorada para acceso local y remoto
  - Carga automática de modelos disponibles
  - Auto-selección del primer modelo disponible
  - Logging detallado para diagnóstico
  - Manejo robusto de errores de conexión

- **Scripts de instalación**
  - `start-msnai-docker.sh` - Instalación Docker simplificada
  - Eliminación de configuración automática de firewall
  - Mensajes informativos mejorados
  - Verificación automática de conectividad

#### 🗑️ Eliminado
- Configuración automática de firewall UFW
- Scripts relacionados con SSH recovery
- Dependencias de configuración manual de puertos
- Complejidad innecesaria en scripts de instalación

#### 🐛 Corregido
- Problema de detección de modelos Ollama
- Indicador de conexión siempre en rojo
- Conflictos entre localStorage y auto-detección
- Error en método `renderChats()` (corregido a `renderChatList()`)
- Verificaciones DOM en `updateSettingsUI()`

### 💡 Notas Técnicas
- **Firewall**: MSN-AI funciona con firewall deshabilitado para simplicidad máxima
- **Puertos**: 8000 (Web) y 11434 (Ollama) quedan automáticamente disponibles
- **Seguridad**: Para entornos de producción, configurar firewall manualmente según necesidades

---

## [1.0.0] - 2024-11-30

### 🎉 Versión Inicial
**Primera versión estable de MSN-AI con interfaz nostálgica de Windows Live Messenger**

#### ✨ Características Principales
- **🎨 Interfaz auténtica** de Windows Live Messenger 8.5
- **🤖 Integración con Ollama** para IA local (Mistral, Llama, Phi3, etc.)
- **💾 Persistencia de chats** con localStorage
- **🔊 Sonidos originales** de MSN Messenger
- **📤 Import/Export** de conversaciones
- **🌐 Instalación local** con servidor Python integrado

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