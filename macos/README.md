# MSN-AI - Scripts para macOS

Esta carpeta contiene todos los scripts específicos para sistemas operativos macOS.

## 📋 Contenido

### Scripts de Inicio

- **`start-msnai-mac.sh`** - Inicia MSN-AI localmente con servidor web integrado
- **`start-msnai-docker-mac.sh`** - Inicia MSN-AI usando Docker

### Scripts de Configuración

- **`ai_check_all_mac.sh`** - Verifica el hardware y recomienda el mejor modelo de IA
- **`create-desktop-shortcut-mac.sh`** - Crea un acceso directo en el escritorio

## 🚀 Uso Rápido

### Instalación Local

```bash
# 1. Verificar hardware e instalar modelos requeridos
bash macos/ai_check_all_mac.sh

# 2. Iniciar MSN-AI
bash macos/start-msnai-mac.sh
```

### Instalación con Docker

```bash
# Iniciar MSN-AI con Docker (incluye instalación automática de modelos)
bash macos/start-msnai-docker-mac.sh
```

### Desde la raíz del proyecto

```bash
# El script wrapper detectará automáticamente que estás en macOS
bash start.sh          # Para instalación local
bash start-docker.sh   # Para instalación con Docker
```

## 📦 Modelos Requeridos por Defecto

Los scripts instalarán automáticamente estos modelos:

- `qwen3-vl:235b-cloud` - Modelo de visión y lenguaje
- `gpt-oss:120b-cloud` - Modelo de propósito general
- `qwen3-coder:480b-cloud` - Modelo especializado en código

Además, el script de verificación de hardware (`ai_check_all_mac.sh`) recomendará un modelo adicional optimizado para tu sistema.

## 🔧 Requisitos

### Para instalación local:
- macOS 10.15+ (Catalina o posterior)
- Bash 3.2+ (incluido en macOS)
- Python 3 o Node.js (para servidor web)
- Ollama (se puede instalar automáticamente)
- Conexión a internet (para descargar modelos)

### Para instalación con Docker:
- Docker Desktop para Mac 4.0+
- Docker Compose v2.0+ (incluido en Docker Desktop)
- 10GB+ de espacio libre en disco
- Conexión a internet (para descargar imágenes y modelos)

## 💡 Consejos Específicos para macOS

1. **Primera instalación**: Ejecuta primero `ai_check_all_mac.sh` para verificar tu hardware
2. **Apple Silicon (M1/M2/M3)**: Los modelos de IA están optimizados para Apple Silicon
3. **Rosetta 2**: No es necesario para MSN-AI nativo, pero puede ser requerido para Docker en M1
4. **Espacio en disco**: Los modelos de IA ocupan varios GB, verifica con `df -h`
5. **Tiempo de descarga**: La primera instalación puede tardar bastante dependiendo de tu conexión
6. **Permisos**: macOS puede pedir permisos para ejecutar scripts descargados

## 🍎 Compatibilidad

### Procesadores Apple Silicon (M1/M2/M3/M4)
- ✅ Totalmente compatible
- ✅ Rendimiento optimizado
- ✅ Menor consumo de energía
- ✅ Ejecución nativa (no requiere Rosetta)

### Procesadores Intel (x86_64)
- ✅ Totalmente compatible
- ✅ Puede requerir más recursos
- ⚠️ Menor eficiencia energética

## 🐛 Solución de Problemas

### Error: "Permission denied"
```bash
chmod +x macos/*.sh
```

### Error: "cannot be opened because it is from an unidentified developer"
```bash
# Opción 1: Permitir en Preferencias del Sistema
# Ve a: Preferencias del Sistema > Seguridad y Privacidad > Permitir

# Opción 2: Remover cuarentena
xattr -d com.apple.quarantine macos/*.sh
```

### Error: "Ollama not found"
```bash
# Instalar Ollama manualmente
curl -fsSL https://ollama.com/install.sh | sh

# O descargar desde la web oficial
open https://ollama.com/download
```

### Error: "Docker not found"
```bash
# Instalar Docker Desktop para Mac
open https://www.docker.com/products/docker-desktop
```

### Error con Homebrew
```bash
# Si necesitas Homebrew para instalar dependencias
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## 🔐 Permisos de macOS

En macOS Catalina y posteriores, es posible que necesites:

1. **Permitir acceso a archivos**: Cuando se te solicite, permite el acceso
2. **Permitir acceso a red**: Requerido para Ollama y servidor web
3. **Permitir ejecución de scripts**: En Preferencias del Sistema > Seguridad

## 🌐 Navegadores Recomendados

MSN-AI funciona mejor con:
- Safari (nativo de macOS)
- Google Chrome
- Mozilla Firefox
- Microsoft Edge

## 📧 Soporte

- **Autor**: Alan Mac-Arthur García Díaz
- **Email**: alan.mac.arthur.garcia.diaz@gmail.com
- **Licencia**: GNU General Public License v3.0

---

**Nota**: Todos los scripts están probados en macOS Monterey, Ventura y Sonoma. Si usas una versión anterior, algunos comandos podrían variar ligeramente.