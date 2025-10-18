# 🐳 MSN-AI - Implementación Docker

**Versión 2.1.0** | **Por Alan Mac-Arthur García Díaz**

Esta guía explica la implementación completa de MSN-AI usando Docker, proporcionando una alternativa robusta y multiplataforma a la instalación local tradicional. **Incluye correcciones para problemas comunes de Docker Compose y dependencias circulares.**

---

## 🎯 ¿Por qué Docker?

### ✅ **Ventajas de la Implementación Docker**

- **🚀 Instalación simplificada** - Solo necesitas Docker, sin configurar Python, Ollama manualmente
- **🔧 Cero configuración del host** - Todo funciona en contenedores aislados
- **🌍 Compatibilidad universal** - Idéntico comportamiento en Linux, Windows y macOS
- **🛡️ Aislamiento completo** - No "ensucia" tu sistema con dependencias
- **📦 Distribución fácil** - Una imagen, múltiples deployments
- **🔄 Rollback sencillo** - Cambiar entre versiones instantáneamente
- **⚡ Escalabilidad** - Ejecutar múltiples instancias sin conflictos

### 🎯 **Casos de Uso Ideales**

- Usuarios que no quieren instalar dependencias localmente
- Entornos corporativos con restricciones de instalación
- Desarrollo y testing con versiones específicas
- Servidores y despliegues de producción
- Usuarios que prefieren contenedores por seguridad

---

## 🏗️ Arquitectura Docker

### 📁 **Estructura de Archivos**

```
MSN-AI/
├── docker/
│   ├── Dockerfile                 # Imagen principal MSN-AI
│   ├── docker-compose.yml         # Orquestación de servicios (sin version obsoleta)
│   ├── docker-entrypoint.sh       # Script de inicio del contenedor
│   ├── healthcheck.sh             # Verificación de salud
│   ├── scripts/                   # Scripts específicos Docker
│   │   └── ai-setup-docker.sh     # Configuración IA mejorada
│   └── README-DOCKER.md           # Esta documentación
├── start-msnai-docker.sh          # Inicio Linux (con detección automática compose)
├── start-msnai-docker.ps1         # Inicio Windows
├── start-msnai-docker-mac.sh      # Inicio macOS
├── docker-start.sh                # 🆕 Script dedicado para iniciar
├── docker-stop.sh                 # 🆕 Script dedicado para detener
├── docker-cleanup.sh              # 🆕 Script de limpieza completa
├── docker-logs.sh                 # 🆕 Visualizador de logs
├── docker-status.sh               # 🆕 Monitor de estado
└── .dockerignore                  # Optimización build
```

### 🐳 **Servicios Docker**

#### **1. msn-ai (Aplicación Web)**
- **Imagen**: Construida desde `docker/Dockerfile`
- **Puerto**: 8000 (configurable)
- **Función**: Servidor web con la aplicación MSN-AI
- **Volúmenes**: Chats, logs, configuración persistente

#### **2. ollama (Servicio de IA)**
- **Imagen**: `ollama/ollama:latest`
- **Puerto**: 11434 (interno)
- **Función**: Servidor de modelos de IA local
- **Volúmenes**: Modelos de IA persistentes

#### **3. ai-setup (Configuración Inicial)**
- **Imagen**: Basada en MSN-AI
- **Función**: Detección de hardware y configuración de modelos
- **Ejecuta una vez**: Configura el modelo óptimo y se detiene

---

## 🚀 Guía de Uso

### 📋 **Prerequisitos**

#### **Para todas las plataformas:**
- **Docker Engine** 20.10+ o Docker Desktop
- **Docker Compose** (incluido en Docker Desktop)
- **8GB+ RAM** (recomendado para IA)
- **4GB+ espacio libre** en disco

#### **Para soporte GPU (opcional):**
- **NVIDIA Container Toolkit** (Linux)
- **Docker Desktop con GPU support** (Windows/macOS)

### 🐧 **Linux**

#### **Instalación rápida:**
```bash
# Todo en una línea
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI && chmod +x *.sh && ./start-msnai-docker.sh --auto
```

#### **Instalación paso a paso:**
```bash
# 1. Clonar repositorio
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI

# 2. Dar permisos
chmod +x *.sh

# 3. Iniciar (instala Docker automáticamente si falta)
./start-msnai-docker.sh

# 4. ¡Usar la aplicación!
# Se abre automáticamente en: http://localhost:8000
```

### 🪟 **Windows**

#### **Instalación rápida:**
```powershell
# En PowerShell
git clone https://github.com/mac100185/MSN-AI.git ; cd MSN-AI ; .\start-msnai-docker.ps1
```

#### **Instalación paso a paso:**
```powershell
# 1. Clonar repositorio
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI

# 2. Habilitar scripts (si es necesario)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Iniciar (instala Docker Desktop si falta)
.\start-msnai-docker.ps1

# 4. ¡Usar la aplicación!
# Se abre automáticamente en: http://localhost:8000
```

### 🍎 **macOS**

#### **Instalación rápida:**
```bash
# En Terminal
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI && chmod +x *.sh && ./start-msnai-docker-mac.sh
```

#### **Instalación paso a paso:**
```bash
# 1. Clonar repositorio
git clone [REPO_URL]
cd MSN-AI

# 2. Dar permisos
chmod +x *.sh

# 3. Iniciar (optimizado para Apple Silicon/Intel)
./start-msnai-docker-mac.sh

# 4. ¡Usar la aplicación!
# Se abre automáticamente en: http://localhost:8000
```

---

## ⚙️ Configuración Avanzada

### 🎛️ **Variables de Entorno**

Puedes personalizar el comportamiento creando un archivo `.env`:

```env
# Configuración básica
MSN_AI_VERSION=1.0.0
MSN_AI_PORT=8000
COMPOSE_PROJECT_NAME=msn-ai

# Configuración de IA
RECOMMENDED_MODEL=mistral:7b
OLLAMA_KEEP_ALIVE=24h
OLLAMA_HOST=0.0.0.0:11434

# Docker
DOCKER_BUILDKIT=1

# Hardware
GPU_SUPPORT=true
MEMORY_GB=16
```

### 🎮 **Soporte GPU**

#### **Linux con NVIDIA:**
```bash
# Instalar NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker

# Habilitar GPU en docker-compose.yml (descomenta las líneas GPU)
```

#### **Windows/macOS:**
```powershell
# Docker Desktop incluye soporte GPU automáticamente
# Asegúrate de tener drivers NVIDIA actualizados
```

## 📊 Comandos de Gestión

### 🆕 Scripts Dedicados (Recomendado)
```bash
# Gestión básica
./docker-start.sh              # Iniciar todos los servicios
./docker-stop.sh               # Detener todos los servicios
./docker-status.sh             # Ver estado de contenedores
./docker-logs.sh --follow      # Ver logs en tiempo real

# Gestión avanzada
./docker-start.sh --build      # Reconstruir e iniciar
./docker-stop.sh --volumes     # Detener y eliminar datos (¡CUIDADO!)
./docker-logs.sh --service ollama  # Logs de servicio específico
./docker-status.sh --detailed  # Estado detallado con recursos
./docker-cleanup.sh --all      # Limpieza completa del sistema

# 🔥 Casos extremos (cuando MSN-AI no funciona)
./docker-cleanup.sh --nuclear  # RESET TOTAL MSN-AI: Elimina TODO de MSN-AI
```

### ⚠️ **Opción Nuclear MSN-AI - Solo para Emergencias**
```bash
# Cuando MSN-AI está completamente roto o corrupto:
./docker-cleanup.sh --nuclear

# ⚠️ IMPORTANTE: Esto elimina SOLO recursos MSN-AI:
# - TODOS los contenedores MSN-AI (etiquetados y por nombre)
# - TODAS las imágenes MSN-AI
# - TODOS los volúmenes MSN-AI
# - TODAS las redes MSN-AI
# - Cache de build relacionado con MSN-AI
# - Recursos huérfanos relacionados con MSN-AI
# ✅ NO afecta otros proyectos Docker

# Úsalo solo cuando MSN-AI:
# - Está corrupto y no responde
# - Tiene problemas persistentes sin solución
# - Necesitas resetear MSN-AI sin afectar otros proyectos
# - Quieres empezar MSN-AI completamente desde cero
```

### 🔧 Comandos Docker Compose Tradicionales
```bash
# El script detecta automáticamente docker-compose vs docker compose
COMPOSE_CMD="docker compose"  # o "docker-compose" según tu instalación

# Ver estado de contenedores
$COMPOSE_CMD -f docker/docker-compose.yml ps

# Ver logs en tiempo real
$COMPOSE_CMD -f docker/docker-compose.yml logs -f

# Ver logs de servicio específico
$COMPOSE_CMD -f docker/docker-compose.yml logs msn-ai
$COMPOSE_CMD -f docker/docker-compose.yml logs ollama

# Reiniciar servicios
$COMPOSE_CMD -f docker/docker-compose.yml restart

# Detener servicios
$COMPOSE_CMD -f docker/docker-compose.yml down

# Detener y limpiar volúmenes (¡CUIDADO! Borra chats guardados)
$COMPOSE_CMD -f docker/docker-compose.yml down -v

# Actualizar imágenes
$COMPOSE_CMD -f docker/docker-compose.yml pull
$COMPOSE_CMD -f docker/docker-compose.yml up -d --build

# Ver uso de recursos
docker stats
```

---

## 🧠 Detección Inteligente de Hardware

### 🎯 **Algoritmo de Selección de Modelos**

El sistema Docker conserva **toda la funcionalidad** del detector de hardware original, pero adaptado para contenedores:

#### **Con GPU Disponible:**
```bash
VRAM >= 80GB  → llama3:70b     (Máximo rendimiento)
VRAM >= 24GB  → llama3:8b      (Avanzado)
VRAM >= 8GB   → mistral:7b     (Eficiente)
VRAM < 8GB    → phi3:mini      (Ligero)
```

#### **Solo CPU:**
```bash
RAM >= 32GB   → mistral:7b     (CPU + Alta RAM)
RAM >= 16GB   → phi3:mini      (CPU + RAM Media)
RAM < 16GB    → tinyllama      (CPU + RAM Limitada)
```

#### **Optimizaciones por Plataforma:**
- **Linux**: Detección completa con `lspci`, `nvidia-smi`
- **Windows**: WMI para GPU, memoria del sistema
- **macOS**: Optimización Apple Silicon vs Intel, `sysctl` para memoria
- **Contenedor**: Adapta detección a recursos asignados al container

### 📋 **Configuración Automática**

El servicio `ai-setup` ejecuta automáticamente:

1. **Detección de hardware** del contenedor
2. **Selección del modelo** óptimo
3. **Descarga automática** del modelo
4. **Verificación** de funcionamiento
5. **Guardado de configuración** persistente

---

## 📁 Persistencia de Datos

### 💾 **Volúmenes Docker**

Los datos se guardan en volúmenes Docker que persisten entre reinicios:

```yaml
# Volúmenes definidos
volumes:
  msn-ai-data:        # Datos generales de la aplicación
  msn-ai-chats:       # Historial de chats (¡importante!)
  msn-ai-logs:        # Logs del sistema
  ollama-data:        # Modelos de IA descargados
```

### 🔄 **Backup y Restauración**

#### **Hacer backup:**
```bash
# Backup de chats
docker run --rm -v msn-ai-chats:/data -v $(pwd):/backup alpine tar czf /backup/chats-backup.tar.gz -C /data .

# Backup de modelos Ollama
docker run --rm -v msn-ai-ollama-data:/data -v $(pwd):/backup alpine tar czf /backup/ollama-backup.tar.gz -C /data .
```

#### **Restaurar backup:**
```bash
# Restaurar chats
docker run --rm -v msn-ai-chats:/data -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/chats-backup.tar.gz"

# Restaurar modelos Ollama
docker run --rm -v msn-ai-ollama-data:/data -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/ollama-backup.tar.gz"
```

### 📤 **Migración entre Hosts**

```bash
# Exportar datos
docker-compose -f docker/docker-compose.yml down
docker run --rm -v msn-ai-chats:/data -v $(pwd):/backup alpine tar czf /backup/msn-ai-complete-backup.tar.gz -C /data .

# En el nuevo host
docker run --rm -v msn-ai-chats:/data -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/msn-ai-complete-backup.tar.gz"
docker-compose -f docker/docker-compose.yml up -d
```

---

## 🔧 Solución de Problemas

### ❌ **Problemas Comunes**

#### **1. "Docker no está instalado"**
```bash
# Linux
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Windows/macOS
# Descargar Docker Desktop desde https://www.docker.com/products/docker-desktop
```

#### **2. "Puerto 8000 ocupado"**
```bash
# Cambiar puerto en .env
echo "MSN_AI_PORT=8001" >> .env
docker-compose -f docker/docker-compose.yml up -d
```

#### **3. "Error construyendo imagen"**
```bash
# Limpiar cache de Docker
docker builder prune -a

# Reconstruir desde cero
docker-compose -f docker/docker-compose.yml build --no-cache
```

#### **4. "Ollama no responde"**
```bash
# Ver logs de Ollama
docker-compose -f docker/docker-compose.yml logs ollama

# Reiniciar solo Ollama
docker-compose -f docker/docker-compose.yml restart ollama
```

#### **5. "Sin modelos de IA"**
```bash
# Forzar reconfiguración
docker-compose -f docker/docker-compose.yml run --rm ai-setup /app/docker/scripts/ai-setup-docker.sh
```

### 📊 **Health Checks**

Los contenedores incluyen health checks automáticos:

```bash
# Ver estado de salud
docker-compose -f docker/docker-compose.yml ps

# Health check manual
docker exec msn-ai-app /app/healthcheck.sh
```

### 🔍 **Debugging**

```bash
# Entrar al contenedor
docker exec -it msn-ai-app /bin/bash

# Ver procesos dentro del contenedor
docker exec msn-ai-app ps aux

# Ver uso de recursos
docker stats msn-ai-app msn-ai-ollama

# Inspeccionar configuración
docker inspect msn-ai-app
```

---

## 🚀 Despliegue de Producción

### 🌐 **Servidor Remoto**

```bash
# En el servidor
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI

# Configurar para producción
cat > .env << EOF
MSN_AI_PORT=80
COMPOSE_PROJECT_NAME=msn-ai-prod
DOCKER_BUILDKIT=1
EOF

# Iniciar servicios
docker-compose -f docker/docker-compose.yml up -d

# Configurar proxy reverso (opcional)
# nginx, traefik, etc.
```

### 🔄 **CI/CD Integration**

```yaml
# Ejemplo GitHub Actions
name: Deploy MSN-AI
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to server
        run: |
          ssh user@server 'cd MSN-AI && git pull && docker-compose -f docker/docker-compose.yml up -d --build'
```

### 📊 **Monitoreo**

```bash
# Logs centralizados
docker-compose -f docker/docker-compose.yml logs -f --tail=100

# Métricas de sistema
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# Alertas (ejemplo con script)
#!/bin/bash
if ! curl -f http://localhost:8000 >/dev/null 2>&1; then
    echo "MSN-AI is down!" | mail -s "Alert" admin@example.com
fi
```

---

## 🔒 Consideraciones de Seguridad

### 🛡️ **Mejores Prácticas**

```bash
# 1. Usuario no-root en contenedores
USER msnai  # Ya configurado en Dockerfile

# 2. Recursos limitados
docker-compose -f docker/docker-compose.yml up -d --scale msn-ai=1 --memory=2g --cpus=1.0

# 3. Network isolation
# Ya configurado con network dedicada msn-ai-network

# 4. Volúmenes con permisos correctos
# Ya configurado en docker-compose.yml
```

### 🔐 **Hardening**

```yaml
# docker-compose.override.yml para producción
version: '3.8'
services:
  msn-ai:
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID
```

---

## 🎯 Comparación: Docker vs Local

| Aspecto | 🐳 Docker | 💻 Local |
|---------|-----------|----------|
| **Instalación** | ⭐⭐⭐⭐⭐ Un comando | ⭐⭐⭐ Varios pasos |
| **Compatibilidad** | ⭐⭐⭐⭐⭐ Universal | ⭐⭐⭐ Dependiente del SO |
| **Aislamiento** | ⭐⭐⭐⭐⭐ Completo | ⭐⭐ Instala en el sistema |
| **Rendimiento** | ⭐⭐⭐⭐ Muy bueno | ⭐⭐⭐⭐⭐ Nativo |
| **Actualización** | ⭐⭐⭐⭐⭐ Instantáneo | ⭐⭐⭐ Manual |
| **Debugging** | ⭐⭐⭐ Contenedor | ⭐⭐⭐⭐ Directo |
| **Recursos** | ⭐⭐⭐ Overhead mínimo | ⭐⭐⭐⭐⭐ Sin overhead |
| **Seguridad** | ⭐⭐⭐⭐⭐ Aislado | ⭐⭐⭐ Depende del usuario |

### 🎯 **Cuándo usar cada uno:**

#### **🐳 Usar Docker cuando:**
- Quieres instalación sin complicaciones
- Trabajas en múltiples sistemas
- Necesitas aislamiento y seguridad
- Desarrollas o testeas con versiones específicas
- Despliegas en servidores
- Prefieres contenedores por filosofía

#### **💻 Usar Local cuando:**
- Quieres máximo rendimiento
- Necesitas debugging profundo
- Prefieres control total del sistema
- Tienes limitaciones de recursos
- Ya tienes las dependencias instaladas

---

## 📚 Recursos Adicionales

### 🔗 **Enlaces Útiles**

- **MSN-AI GitHub**: https://github.com/mac100185/MSN-AI
- **Clonar repositorio**: `git clone https://github.com/mac100185/MSN-AI.git`
- **Issues y soporte**: https://github.com/mac100185/MSN-AI/issues
- **Docker Official**: https://docs.docker.com/
- **Docker Compose**: https://docs.docker.com/compose/
- **Ollama Docker**: https://hub.docker.com/r/ollama/ollama
- **NVIDIA Container Toolkit**: https://github.com/NVIDIA/nvidia-docker

### 📖 **Documentación MSN-AI**

- **README principal**: [../README.md](../README.md)
- **Documentación técnica**: [../README-MSNAI.md](../README-MSNAI.md)
- **Guía de instalación**: [../INSTALL-GUIDE.md](../INSTALL-GUIDE.md)
- **Changelog**: [../CHANGELOG.md](../CHANGELOG.md)

### 🤝 **Contribuir**

```bash
# Fork del repositorio en GitHub: https://github.com/mac100185/MSN-AI/fork
git clone https://github.com/TU_USUARIO/MSN-AI.git
cd MSN-AI

# Crear rama para mejoras Docker
git checkout -b docker-improvements

# Realizar cambios
# Especialmente en docker/ directory

# Commit y push
git add .
git commit -m "Mejoras en Docker Edition"
git push origin docker-improvements

# Crear Pull Request en: https://github.com/mac100185/MSN-AI/compare
```

---

## 🆘 Soporte

### 📧 **Contacto**

**Desarrollador**: Alan Mac-Arthur García Díaz  
**Email**: [alan.mac.arthur.garcia.diaz@gmail.com](mailto:alan.mac.arthur.garcia.diaz@gmail.com)

### 🐛 **Reportar Problemas Docker**

Al reportar problemas relacionados con Docker, incluye:

```bash
# Información del sistema
docker --version
docker-compose --version
uname -a

# Logs de contenedores
docker-compose -f docker/docker-compose.yml logs

# Estado de servicios
docker-compose -f docker/docker-compose.yml ps

# Uso de recursos
docker stats --no-stream
```

### 💬 **Comunidad**

- **GitHub Issues**: https://github.com/mac100185/MSN-AI/issues (Para bugs específicos de Docker)
- **GitHub Discussions**: https://github.com/mac100185/MSN-AI/discussions (Para preguntas y mejoras)
- **Email**: Para soporte directo

---

## 🎉 ¡Disfruta MSN-AI con Docker!

La implementación Docker de MSN-AI te ofrece:

- ✅ **Instalación sin esfuerzo**
- ✅ **Compatibilidad universal**  
- ✅ **Aislamiento y seguridad**
- ✅ **Mismo detector inteligente de hardware**
- ✅ **Persistencia de datos**
- ✅ **Fácil actualización y rollback**

**🚀 Inicia tu experiencia nostálgica con IA ahora:**

```bash
# 1. Clonar repositorio
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI

# 2. Opción rápida (detecta plataforma automáticamente):
./docker-start.sh

# 3. O usar scripts específicos de plataforma:
# Linux
./start-msnai-docker.sh

# Windows  
.\start-msnai-docker.ps1

# macOS
./start-msnai-docker-mac.sh
```

### 🆕 Gestión Simplificada
```bash
# Comandos básicos post-instalación
./docker-status.sh             # ¿Cómo está todo?
./docker-logs.sh --follow      # ¿Qué está pasando?
./docker-stop.sh               # Detener limpiamente
./docker-cleanup.sh --all      # Empezar de cero
```

---

*MSN-AI Docker v1.1.0 - "La nostalgia contenida, ahora sin problemas"*

**🔧 Correcciones v1.1.0:**
- ✅ Docker Compose compatibility (docker-compose vs docker compose)
- ✅ Healthcheck circular dependency fixed
- ✅ Removed obsolete version warning
- ✅ Added dedicated management scripts
- ✅ Improved error handling and diagnostics
- ✅ Nuclear cleanup option for MSN-AI extreme cases

**🔥 Nuclear Cleanup MSN-AI:**
- Opción de reset total de MSN-AI (solo MSN-AI)
- Para casos extremos cuando MSN-AI está corrupto
- Elimina TODO de MSN-AI (contenedores, imágenes, volúmenes, redes)
- NO afecta otros proyectos Docker
- Requiere confirmación doble para evitar accidentes

**Desarrollado con ❤️ por Alan Mac-Arthur García Díaz**  
**Licenciado bajo GPL-3.0 | Enero 2025**