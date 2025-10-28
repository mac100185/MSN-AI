# MSN-AI Docker - Guía de Diagnóstico y Depuración

Esta guía te ayudará a diagnosticar y resolver problemas con MSN-AI Docker.

## 🚀 Inicio Rápido

### Problema: "No space left on device"

Si ves el error `write /var/lib/docker/tmp/...: no space left on device`:

```bash
# 1. Verifica espacio disponible
df -h /var/lib/docker

# 2. Limpia Docker completamente
docker system prune -a --volumes

# 3. O usa el script de limpieza
bash linux/docker-cleanup.sh

# 4. Libera espacio del sistema
# - Elimina archivos temporales: sudo rm -rf /tmp/*
# - Limpia logs antiguos: sudo journalctl --vacuum-size=100M
# - Elimina paquetes no usados: sudo apt autoremove
```

**Espacio mínimo requerido:**
- **Sistema base**: 5GB libres mínimo
- **Docker + Ollama**: 3GB adicionales
- **Total recomendado**: 10GB libres

### Problema: Docker falla sin mensajes

Si Docker cierra la conexión SSH o falla sin mostrar mensajes:

```bash
# Linux/macOS - Modo Debug
bash linux/docker-start-debug.sh

# Windows PowerShell
.\windows\docker-start-debug.ps1
```

Este modo muestra **todos** los logs en tiempo real y guarda todo en archivos.

### Problema: No sé qué está fallando

Ejecuta el script de diagnóstico completo:

```bash
# Linux
bash linux/docker-diagnostics.sh

# macOS
bash macos/docker-diagnostics-mac.sh

# Windows PowerShell
.\windows\docker-diagnostics.ps1
```

Esto generará un archivo `.tar.gz` (Linux/macOS) o `.zip` (Windows) con:
- Logs de todos los contenedores
- Estado del sistema
- Configuración de Docker
- Análisis de errores
- Resumen ejecutivo

## 📊 Scripts Disponibles

### 1. Diagnóstico Completo (`docker-diagnostics`)

**Cuándo usar**: Cuando necesitas un análisis completo del sistema.

**Qué hace**:
- Recopila información del sistema (CPU, RAM, disco)
- Extrae logs de todos los contenedores
- Analiza configuración de Docker
- Busca errores comunes
- Genera resumen ejecutivo
- Empaqueta todo en un archivo comprimido

**Salida**: `msn-ai-diagnostics-YYYYMMDD_HHMMSS.tar.gz` o `.zip`

**Uso**:
```bash
# Linux
bash linux/docker-diagnostics.sh

# Revisar resumen
cat diagnostics_*/RESUMEN.txt

# Ver todos los logs
cat diagnostics_*/diagnostics.log
```

### 2. Modo Debug (`docker-start-debug`)

**Cuándo usar**: Cuando el build o startup falla y necesitas ver qué pasa.

**Qué hace**:
- Construye imágenes con output completo (--progress=plain)
- Muestra todos los logs en tiempo real
- Guarda todo en archivo de log
- Ejecuta contenedores en primer plano (foreground)
- Permite ver exactamente dónde falla

**Salida**: `docker/logs/debug/debug_YYYYMMDD_HHMMSS.log`

**Uso**:
```bash
# Linux
bash linux/docker-start-debug.sh

# Ctrl+C para detener (limpia automáticamente)
```

**Ventajas**:
- Ves TODO lo que pasa
- Identifica rápidamente el punto de falla
- Logs guardados para análisis posterior

### 3. Script Normal con Logs Mejorados

El script normal ahora también guarda logs:

```bash
# Linux
bash linux/start-msnai-docker.sh

# Los logs se guardan en:
# - docker/logs/build_YYYYMMDD_HHMMSS.log
# - docker/logs/startup_YYYYMMDD_HHMMSS.log
```

## 🔍 Problemas Comunes y Soluciones

### 1. "No space left on device" / Sin espacio en disco

**Síntomas:**
- Error durante `docker compose up`
- Error durante descarga de imagen Ollama
- Mensaje: `write /var/lib/docker/tmp/...: no space left on device`
- Contenedores no inician

**Causa:** El disco está lleno. Ollama requiere ~2GB, imágenes base ~1GB.

**Solución inmediata:**
```bash
# Ver espacio disponible
df -h

# Limpiar Docker (CUIDADO: elimina TODO lo de Docker)
docker system prune -a --volumes -f

# Verificar cuánto se liberó
docker system df

# Si no es suficiente, limpiar sistema
sudo apt clean
sudo apt autoremove
sudo rm -rf /tmp/*
sudo journalctl --vacuum-size=100M
```

**Prevención:**
- Mantén al menos 10GB libres antes de instalar
- Usa el script: `bash linux/start-msnai-docker.sh` (ahora verifica espacio)
- Limpia regularmente: `bash linux/docker-cleanup.sh`

### 2. "Docker cierra la conexión SSH"

**Causa probable**: Falta de memoria o recursos.

**Solución**:
1. Verifica recursos del sistema:
   ```bash
   free -h  # Memoria
   df -h    # Disco
   ```

2. Revisa límites en `docker-compose.yml`:
   ```yaml
   deploy:
     resources:
       limits:
         memory: 512M  # Ajusta según tu sistema
   ```

3. Aumenta memoria disponible o reduce límites.
4. **Verifica espacio en disco:** El error de SSH puede ser por falta de espacio

### 3. "Build falla sin mensaje"

**Causa probable**: Falta de espacio en disco o timeout.

**Solución**:
1. Limpia imágenes antiguas:
   ```bash
   docker system prune -a --volumes
   ```

2. Usa modo debug para ver el error exacto:
   ```bash
   bash linux/docker-start-debug.sh
   ```

3. **Verifica espacio en disco:**
   ```bash
   df -h /var/lib/docker
   # Si < 5GB: docker system prune -a --volumes
   ```

### 4. "Ollama no responde"

**Causa probable**: Ollama tarda en iniciar o faltan recursos.

**Solución**:
1. Verifica logs de Ollama:
   ```bash
   docker logs msn-ai-ollama
   ```

2. Aumenta timeout en `docker-compose.yml`:
   ```yaml
   healthcheck:
     start_period: 180s  # Aumenta si necesario
     retries: 30
   ```

3. Verifica que el puerto 11434 esté libre:
   ```bash
   netstat -tuln | grep 11434
   ```

### 5. "Contenedor se detiene inmediatamente"

**Causa probable**: Error en entrypoint o falta de archivo.

**Solución**:
1. Revisa logs del contenedor:
   ```bash
   docker logs msn-ai-app
   ```

2. Inspecciona el contenedor:
   ```bash
   docker inspect msn-ai-app
   ```

3. Ejecuta diagnóstico completo:
   ```bash
   bash linux/docker-diagnostics.sh
   cat diagnostics_*/error_analysis.txt
   ```

4. **Verifica espacio en disco:**
   ```bash
   docker logs msn-ai-app | grep -i "space\|disk"
   ```

### 6. "Error construyendo imagen"

**Causa probable**: Problema en Dockerfile o contexto de build.

**Solución**:
1. Usa modo debug para ver qué paso falla:
   ```bash
   bash linux/docker-start-debug.sh
   ```

2. Verifica archivos necesarios:
   ```bash
   ls -la docker/
   ls -la docker/scripts/
   ```

3. Construye sin caché:
   ```bash
   cd docker
   docker compose build --no-cache --progress=plain
   ```

## 📝 Interpretando Logs

### Logs de Build

Busca estas líneas clave:
```
✅ Build completado exitosamente
❌ Build falló con código: X
ERROR: failed to solve
```

### Logs de Startup

Busca estas líneas clave:
```
✅ Servicios iniciados
✅ Ollama está listo
✅ MSN-AI está listo
⚠️  Timeout esperando servicios
```

### Logs de Contenedor

Errores comunes:
```
Error: ENOENT: no such file or directory
❌ Error: No se encuentra msn-ai.html
❌ No se encontró servidor web disponible
⚠️ Ollama no responde
```

## 🛠️ Comandos Útiles

### Ver logs en tiempo real
```bash
docker logs -f msn-ai-app
docker logs -f msn-ai-ollama
```

### Ver estado de contenedores
```bash
docker ps
docker compose -f docker/docker-compose.yml ps
```

### Reiniciar servicios
```bash
cd docker
docker compose restart
docker compose restart ollama  # Solo Ollama
```

### Detener y limpiar
```bash
cd docker
docker compose down
docker compose down -v  # También borra volúmenes
```

### Entrar en contenedor
```bash
docker exec -it msn-ai-app bash
docker exec -it msn-ai-ollama bash
```

## 📦 Estructura de Logs

```
MSN-AI/
├── docker/
│   └── logs/
│       ├── build_20240101_120000.log      # Logs de construcción
│       ├── startup_20240101_120000.log    # Logs de inicio
│       └── debug/
│           └── debug_20240101_120000.log  # Logs de modo debug
├── diagnostics_20240101_120000/           # Diagnóstico completo
│   ├── RESUMEN.txt                        # ⭐ Lee esto primero
│   ├── diagnostics.log                    # Log principal
│   ├── logs_msnai_app.txt                 # Logs de MSN-AI
│   ├── logs_ollama.txt                    # Logs de Ollama
│   ├── error_analysis.txt                 # Análisis de errores
│   └── ... (50+ archivos de diagnóstico)
└── msn-ai-diagnostics-*.tar.gz           # Archivo comprimido
```

## 🎯 Flujo de Diagnóstico Recomendado

1. **Primera vez que falla**: Usa modo debug
   ```bash
   bash linux/docker-start-debug.sh
   ```

2. **Si el problema persiste**: Diagnóstico completo
   ```bash
   bash linux/docker-diagnostics.sh
   ```

3. **Revisa el resumen ejecutivo**:
   ```bash
   cat diagnostics_*/RESUMEN.txt
   ```

4. **Busca errores específicos**:
   ```bash
   grep -i "error" diagnostics_*/logs_*.txt
   ```

5. **Si no puedes resolverlo**: Envía el archivo comprimido al soporte
   - Email: alan.mac.arthur.garcia.diaz@gmail.com
   - Incluye: `msn-ai-diagnostics-YYYYMMDD_HHMMSS.tar.gz`

## 🚑 Solución de Emergencia

Si nada funciona, intenta desde cero:

```bash
# 1. Detener todo
cd docker
docker compose down -v

# 2. Limpiar Docker
docker system prune -a --volumes -f

# 3. Verificar recursos
free -h
df -h

# 4. Iniciar en modo debug
cd ..
bash linux/docker-start-debug.sh
```

## 💡 Tips para Evitar Problemas

1. **Verifica espacio ANTES de instalar**: `df -h` (mínimo 10GB libres)
2. **Limpia Docker regularmente**: `docker system prune -a --volumes`
3. **Asegura suficiente memoria**: Mínimo 4GB RAM disponible
4. **Espacio en disco**: Mínimo 10GB libres (crítico para Ollama)
5. **No cierres SSH**: Usa `screen` o `tmux` para sesiones persistentes
6. **Revisa firewall**: Asegura que puertos 8000 y 11434 estén abiertos
7. **Usa logs**: Siempre revisa los logs antes de reportar problemas
8. **Monitorea espacio**: `watch -n 5 df -h` durante instalación

## 📊 Requisitos de Espacio en Disco

### Desglose de Espacio Necesario:

| Componente | Espacio Requerido |
|------------|-------------------|
| Imagen base Python | ~500 MB |
| MSN-AI aplicación | ~100 MB |
| Imagen Ollama | ~1.9 GB |
| Modelos de IA (opcional) | Variable (1-10 GB) |
| Espacio temporal Docker | ~1 GB |
| **TOTAL MÍNIMO** | **5 GB** |
| **RECOMENDADO** | **10-15 GB** |

### Verificar Espacio:
```bash
# Espacio total disponible
df -h /

# Espacio usado por Docker
docker system df

# Espacio detallado de Docker
du -sh /var/lib/docker

# Limpiar si es necesario
docker system prune -a --volumes -f
```

### Si se Queda Sin Espacio Durante Instalación:

1. **Detener la instalación**: `Ctrl+C`
2. **Limpiar Docker**: `docker system prune -a --volumes -f`
3. **Limpiar sistema**: 
   ```bash
   sudo apt clean
   sudo apt autoremove
   sudo rm -rf /tmp/*
   ```
4. **Verificar espacio liberado**: `df -h`
5. **Reintentar**: `bash linux/start-msnai-docker.sh`

## 📚 Referencias

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Ollama Documentation](https://github.com/ollama/ollama)

---

**MSN-AI Docker Diagnostics**  
Version: 1.0.0  
Author: Alan Mac-Arthur García Díaz  
Email: alan.mac.arthur.garcia.diaz@gmail.com  
License: GPL-3.0