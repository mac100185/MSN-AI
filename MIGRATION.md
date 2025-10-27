# Guía de Migración - MSN-AI v2.1.0

## 📋 Resumen de Cambios

En la versión 2.1.0 de MSN-AI, hemos reorganizado completamente la estructura de scripts para mejorar la organización y facilitar el uso según tu sistema operativo.

## 🔄 Cambios Principales

### 1. Reorganización de Scripts por Sistema Operativo

Los scripts ahora están organizados en carpetas específicas:

```
MSN-AI/
├── linux/      # Scripts para Linux
├── macos/      # Scripts para macOS
├── windows/    # Scripts para Windows
└── docker/     # Configuración Docker
```

### 2. Modelos de IA Requeridos por Defecto

Ahora se instalan **3 modelos requeridos** automáticamente:
- `qwen3-vl:235b-cloud` - Modelo de visión y lenguaje
- `gpt-oss:120b-cloud` - Modelo de propósito general
- `qwen3-coder:480b-cloud` - Modelo especializado en código

### 3. Docker Mejorado

- ✅ Corregidos problemas de creación e inicio de contenedores
- ✅ Instalación automática de modelos requeridos
- ✅ Mejor manejo de dependencias y healthchecks
- ✅ Tiempos de espera optimizados

## 🚀 Cómo Usar los Nuevos Scripts

### Opción 1: Scripts Universales (Recomendado)

Desde la raíz del proyecto, usa los scripts universales que detectan automáticamente tu sistema operativo:

```bash
# Para instalación local
bash start.sh          # Linux/macOS
.\start.ps1            # Windows

# Para instalación con Docker
bash start-docker.sh   # Linux/macOS
.\start-docker.ps1     # Windows
```

### Opción 2: Scripts Específicos por Sistema Operativo

#### Linux

```bash
# Verificar hardware e instalar modelos
bash linux/ai_check_all.sh

# Iniciar MSN-AI local
bash linux/start-msnai.sh

# Iniciar MSN-AI con Docker
bash linux/start-msnai-docker.sh

# Otros scripts útiles
bash linux/docker-status.sh      # Ver estado de contenedores
bash linux/docker-logs.sh        # Ver logs
bash linux/docker-stop.sh        # Detener Docker
bash linux/docker-cleanup.sh     # Limpiar recursos Docker
bash linux/test-msnai.sh         # Ejecutar pruebas
```

#### macOS

```bash
# Verificar hardware e instalar modelos
bash macos/ai_check_all_mac.sh

# Iniciar MSN-AI local
bash macos/start-msnai-mac.sh

# Iniciar MSN-AI con Docker
bash macos/start-msnai-docker-mac.sh
```

#### Windows

```powershell
# Verificar hardware e instalar modelos
.\windows\ai_check_all.ps1

# Iniciar MSN-AI local
.\windows\start-msnai.ps1 --auto

# Iniciar MSN-AI con Docker
.\windows\start-msnai-docker.ps1
```

## 📦 Migración de Comandos Antiguos

### Scripts de Inicio

| Comando Antiguo | Nuevo Comando (Universal) | Nuevo Comando (Específico) |
|----------------|---------------------------|----------------------------|
| `./start-msnai.sh` | `bash start.sh` | `bash linux/start-msnai.sh` |
| `./start-msnai-mac.sh` | `bash start.sh` | `bash macos/start-msnai-mac.sh` |
| `.\start-msnai.ps1` | `.\start.ps1` | `.\windows\start-msnai.ps1` |

### Scripts de Docker

| Comando Antiguo | Nuevo Comando (Universal) | Nuevo Comando (Específico) |
|----------------|---------------------------|----------------------------|
| `./start-msnai-docker.sh` | `bash start-docker.sh` | `bash linux/start-msnai-docker.sh` |
| `./start-msnai-docker-mac.sh` | `bash start-docker.sh` | `bash macos/start-msnai-docker-mac.sh` |
| `.\start-msnai-docker.ps1` | `.\start-docker.ps1` | `.\windows\start-msnai-docker.ps1` |

### Scripts de Verificación

| Comando Antiguo | Nuevo Comando |
|----------------|---------------|
| `./ai_check_all.sh` | `bash linux/ai_check_all.sh` |
| `./ai_check_all_mac.sh` | `bash macos/ai_check_all_mac.sh` |
| `.\ai_check_all.ps1` | `.\windows\ai_check_all.ps1` |

### Scripts de Docker Auxiliares

| Comando Antiguo | Nuevo Comando |
|----------------|---------------|
| `./docker-start.sh` | `bash linux/docker-start.sh` |
| `./docker-stop.sh` | `bash linux/docker-stop.sh` |
| `./docker-status.sh` | `bash linux/docker-status.sh` |
| `./docker-logs.sh` | `bash linux/docker-logs.sh` |
| `./docker-cleanup.sh` | `bash linux/docker-cleanup.sh` |

## 🔧 Corrección de Problemas de Docker

Si tenías problemas con Docker en versiones anteriores:

1. **Limpia la instalación anterior**:
   ```bash
   # Linux/macOS
   bash linux/docker-cleanup.sh
   
   # Windows
   docker compose -f docker/docker-compose.yml down -v
   docker system prune -a
   ```

2. **Inicia con la nueva configuración**:
   ```bash
   bash start-docker.sh    # Linux/macOS
   .\start-docker.ps1      # Windows
   ```

3. **Verifica el estado**:
   ```bash
   bash linux/docker-status.sh
   ```

## 📊 Cambios en Modelos de IA

### Antes (v1.x)

Los scripts instalaban un único modelo recomendado según el hardware:
- Ejemplo: `mistral:7b`, `phi3:mini`, `llama3:8b`

### Ahora (v2.1.0)

Los scripts instalan **3 modelos requeridos** + 1 modelo recomendado:

**Modelos Requeridos (instalación automática)**:
1. `qwen3-vl:235b-cloud`
2. `gpt-oss:120b-cloud`
3. `qwen3-coder:480b-cloud`

**Modelo Recomendado (según tu hardware)**:
- Detectado automáticamente por el script de verificación

### ¿Por qué este cambio?

- **Versatilidad**: Cada modelo tiene capacidades especializadas
- **Compatibilidad**: Asegura que todas las funciones de MSN-AI estén disponibles
- **Experiencia completa**: Visión, lenguaje y código en un solo paquete

### Requisitos de Espacio

⚠️ **IMPORTANTE**: Los modelos requeridos necesitan más espacio en disco:

- **Antes**: ~4-5 GB por modelo
- **Ahora**: ~15-20 GB total (3 modelos requeridos)
- **Recomendado**: 25-30 GB libres para instalación completa

### Si no tienes suficiente espacio

Puedes instalar solo los modelos requeridos manualmente:

```bash
# Instalar modelos uno por uno según espacio disponible
ollama pull qwen3-vl:235b-cloud      # ~8 GB
ollama pull gpt-oss:120b-cloud       # ~5 GB
ollama pull qwen3-coder:480b-cloud   # ~6 GB
```

O usar versiones más ligeras:

```bash
# Alternativas ligeras (no oficiales para MSN-AI)
ollama pull llama3:8b        # ~4.7 GB
ollama pull mistral:7b       # ~4.1 GB
ollama pull phi3:mini        # ~2.3 GB
```

## 🆕 Nuevas Funcionalidades

### 1. Scripts Universales

Los scripts `start.sh` y `start.ps1` en la raíz detectan automáticamente tu sistema operativo.

### 2. README por Sistema Operativo

Cada carpeta tiene su propio README con instrucciones específicas:
- `linux/README.md`
- `macos/README.md`
- `windows/README.md`

### 3. Mejor Gestión de Docker

- Healthchecks mejorados
- Timeouts optimizados
- Mejor manejo de errores
- Instalación automática de modelos requeridos

## ⚠️ Notas Importantes

### Para Usuarios Existentes

1. **Tus datos están seguros**: Los chats y configuraciones se mantienen intactos
2. **No necesitas desinstalar**: La actualización es compatible con instalaciones anteriores
3. **Scripts antiguos eliminados**: Los scripts en la raíz fueron movidos, usa los nuevos

### Para Docker

1. **Primera vez más lenta**: La instalación de 3 modelos toma más tiempo
2. **Más espacio requerido**: Verifica tener al menos 30 GB libres
3. **Mejor estabilidad**: Los contenedores ahora inician correctamente

### Compatibilidad

- ✅ Compatible con todas las versiones anteriores de datos
- ✅ Compatible con modelos ya instalados (no se reinstalan)
- ✅ Compatible con configuraciones existentes
- ⚠️ Los scripts viejos en la raíz ya no existen (fueron movidos)

## 🐛 Solución de Problemas

### "Script no encontrado"

```bash
# Verifica que estés en el directorio correcto
pwd  # Debe mostrar .../MSN-AI

# Verifica la estructura
ls -la linux/ macos/ windows/
```

### "Permission denied" (Linux/macOS)

```bash
# Da permisos de ejecución
chmod +x start.sh start-docker.sh
chmod +x linux/*.sh macos/*.sh
```

### "Execution policy" (Windows)

```powershell
# Permite ejecución de scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "No space left on device"

```bash
# Verifica espacio disponible
df -h  # Linux/macOS
Get-PSDrive  # Windows

# Limpia espacio si es necesario
docker system prune -a  # Limpia Docker
```

## 📚 Recursos Adicionales

- **Documentación Principal**: `README.md`
- **Linux**: `linux/README.md`
- **macOS**: `macos/README.md`
- **Windows**: `windows/README.md`
- **Changelog**: `CHANGELOG.md`

## 💡 Recomendaciones

1. **Primera instalación**: Usa los scripts de verificación (`ai_check_all`) primero
2. **Docker**: Ideal para evitar configuraciones complejas
3. **Local**: Mejor rendimiento si tienes el hardware adecuado
4. **Espacio**: Mantén al menos 30 GB libres en disco

## 📧 Soporte

Si tienes problemas con la migración:

- **Autor**: Alan Mac-Arthur García Díaz
- **Email**: alan.mac.arthur.garcia.diaz@gmail.com
- **Licencia**: GNU General Public License v3.0

---

**¡Gracias por usar MSN-AI v2.1.0!** 🚀