# MSN-AI - Scripts para Linux

Esta carpeta contiene todos los scripts específicos para sistemas operativos Linux.

## 📋 Contenido

### Scripts de Inicio

- **`start-msnai.sh`** - Inicia MSN-AI localmente con servidor web integrado
- **`start-msnai-docker.sh`** - Inicia MSN-AI usando Docker

### Scripts de Configuración

- **`ai_check_all.sh`** - Verifica el hardware y recomienda el mejor modelo de IA
- **`create-desktop-shortcut.sh`** - Crea un acceso directo en el escritorio

### Scripts de Docker

- **`docker-start.sh`** - Inicia los contenedores Docker
- **`docker-stop.sh`** - Detiene los contenedores Docker
- **`docker-status.sh`** - Muestra el estado de los contenedores
- **`docker-logs.sh`** - Muestra los logs de los contenedores
- **`docker-cleanup.sh`** - Limpia contenedores, volúmenes e imágenes
- **`docker-check-config.sh`** - Verifica la configuración de Docker
- **`docker-test-ai.sh`** - Prueba la conexión con el servicio de IA

### Scripts de Prueba

- **`test-msnai.sh`** - Ejecuta pruebas del sistema MSN-AI

## 🚀 Uso Rápido

### Instalación Local

```bash
# 1. Verificar hardware e instalar modelos requeridos
bash linux/ai_check_all.sh

# 2. Iniciar MSN-AI
bash linux/start-msnai.sh
```

### Instalación con Docker

```bash
# Iniciar MSN-AI con Docker (incluye instalación automática de modelos)
bash linux/start-msnai-docker.sh
```

### Desde la raíz del proyecto

```bash
# El script wrapper detectará automáticamente que estás en Linux
bash start.sh          # Para instalación local
bash start-docker.sh   # Para instalación con Docker
```

## 📦 Modelos Requeridos por Defecto

Los scripts instalarán automáticamente estos modelos:

- `qwen3-vl:235b-cloud` - Modelo de visión y lenguaje
- `gpt-oss:120b-cloud` - Modelo de propósito general
- `qwen3-coder:480b-cloud` - Modelo especializado en código

Además, el script de verificación de hardware (`ai_check_all.sh`) recomendará un modelo adicional optimizado para tu sistema.

## 🔧 Requisitos

### Para instalación local:
- Bash 4.0+
- Python 3 o Node.js (para servidor web)
- Ollama (se puede instalar automáticamente)
- Conexión a internet (para descargar modelos)

### Para instalación con Docker:
- Docker 20.10+
- Docker Compose v2.0+
- 10GB+ de espacio libre en disco
- Conexión a internet (para descargar imágenes y modelos)

## 💡 Consejos

1. **Primera instalación**: Ejecuta primero `ai_check_all.sh` para verificar tu hardware
2. **Espacio en disco**: Los modelos de IA ocupan varios GB, asegúrate de tener suficiente espacio
3. **Tiempo de descarga**: La primera instalación puede tardar bastante dependiendo de tu conexión
4. **Permisos**: Si tienes problemas de permisos, ejecuta `chmod +x *.sh` en esta carpeta

## 🐛 Solución de Problemas

### Error: "Permission denied"
```bash
chmod +x linux/*.sh
```

### Error: "Ollama not found"
```bash
# Instalar Ollama manualmente
curl -fsSL https://ollama.com/install.sh | sh
```

### Error: "Docker not found"
```bash
# Instalar Docker en Ubuntu/Debian
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

## 📧 Soporte

- **Autor**: Alan Mac-Arthur García Díaz
- **Email**: alan.mac.arthur.garcia.diaz@gmail.com
- **Licencia**: GNU General Public License v3.0

---

**Nota**: Todos los scripts están optimizados para distribuciones basadas en Debian/Ubuntu, pero deberían funcionar en la mayoría de distribuciones Linux.