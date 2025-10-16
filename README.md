# 🚀 MSN-AI - Windows Live Messenger con IA Local

![MSN-AI](assets/general/logo.png)

> *Donde la nostalgia se encuentra con la inteligencia artificial moderna*

**Versión 1.0.0** | **Licencia GPL-3.0** | **Por Alan Mac-Arthur García Díaz**

## 🎯 ¿Qué es MSN-AI?

MSN-AI es una aplicación web revolucionaria que combina la interfaz nostálgica de **Windows Live Messenger 8.5** con la potencia de los **modelos de IA local** ejecutados a través de Ollama. 

**Transforma tu experiencia aburrida de terminal con IA en una aventura nostálgica y visual.**

### ✨ Características principales

- 🎨 **Interfaz auténtica** de Windows Live Messenger 8.5
- 🤖 **IA local integrada** - Compatible con Mistral, Llama, Phi3 y más
- 💾 **Historial persistente** - Tus chats se guardan automáticamente
- 🔊 **Sonidos originales** - Efectos auténticos de MSN
- 📤 **Import/Export** - Migra tus conversaciones fácilmente
- 🌐 **100% Local** - Sin dependencias de servicios externos
- ⚡ **Instalación automática** - Un comando y listo

## 🚀 Inicio rápido (2 minutos)

### 🔥 **NUEVO: Instalación Docker (Recomendado)**
```bash
# 🐳 UN SOLO COMANDO PARA TODAS LAS PLATAFORMAS
# Clonar e instalar en un comando:
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI && chmod +x *.sh && ./start-msnai-docker.sh --auto

# O paso a paso:
# Linux:
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
./start-msnai-docker.sh --auto

# Windows:
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
.\start-msnai-docker.ps1 --auto

# macOS:
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
./start-msnai-docker-mac.sh --auto
```
> **✨ Con Docker**: Cero configuración, máxima compatibilidad, instalación automática de todo

---

### 📟 **Instalación Tradicional (Local)**

#### 🐧 Linux
```bash
# 1. Clonar repositorio
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI

# 2. Verificar sistema
./test-msnai.sh

# 3. Configurar IA (opcional)
./ai_check_all.sh

# 4. Iniciar aplicación
./start-msnai.sh --auto
```

#### 🪟 Windows
```powershell
# 1. Clonar repositorio
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI

# 2. Habilitar scripts (solo la primera vez)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Configurar IA (opcional)
.\ai_check_all.ps1

# 4. Iniciar aplicación
.\start-msnai.ps1 --auto
```

#### 🍎 macOS
```bash
# 1. Clonar repositorio
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI

# 2. Dar permisos (solo la primera vez)
chmod +x *.sh

# 3. Configurar IA (opcional)
./ai_check_all_mac.sh

# 4. Iniciar aplicación
./start-msnai-mac.sh --auto
```

### 3. ¡Disfruta!
La aplicación se abrirá automáticamente en tu navegador con sonidos nostálgicos y IA lista para conversar.

---

## 🤔 ¿Docker o Local? ¡Tú decides!

| Característica | 🐳 **Docker** | 💻 **Local** |
|----------------|---------------|---------------|
| **Instalación** | Un comando | Varios pasos |
| **Compatibilidad** | Universal | Dependiente |
| **Dependencias** | Cero config | Manual |
| **Aislamiento** | Completo | Sistema host |
| **Actualizaciones** | Automáticas | Manuales |
| **Rendimiento** | Muy bueno | Nativo |

### 🎯 **Recomendaciones:**
- 🆕 **¿Primera vez?** → Usa **Docker**
- 🏢 **¿Trabajo/Corporativo?** → Usa **Docker**  
- ⚡ **¿Máximo rendimiento?** → Usa **Local**
- 🔧 **¿Ya tienes Python/Ollama?** → Usa **Local**

## ⏹️ Cómo detener MSN-AI de forma segura

**¡IMPORTANTE!** Para evitar daños y pérdida de datos, siempre detén correctamente:

### 🐧 Linux / 🍎 macOS
```bash
# En la terminal donde ejecutaste el script
Ctrl + C
# El script limpiará automáticamente todos los procesos
```

### 🪟 Windows
```powershell
# En la ventana PowerShell donde ejecutaste el script
Ctrl + C
# El script limpiará automáticamente todos los procesos
```

### Detención manual (emergencia)
#### Linux/macOS:
```bash
# Detener procesos específicos
pkill -f "start-msnai"
pkill -f "python.*http.server"
pkill ollama  # Solo si fue iniciado por el script
```

#### Windows:
```powershell
# Detener procesos específicos
Get-Process -Name "python" | Where-Object {$_.CommandLine -like "*http.server*"} | Stop-Process
Get-Process -Name "ollama" | Stop-Process
```

### ⚠️ Nunca hagas esto
- ❌ Cerrar la terminal/PowerShell sin Ctrl+C
- ❌ Forzar cierre del navegador sin detener el servidor
- ❌ Apagar el sistema sin detener los servicios
- ❌ Usar `kill -9` directamente en los procesos

### 💡 Indicadores de que está bien detenido
- ✅ Mensaje "👋 ¡Gracias por usar MSN-AI!"
- ✅ Puerto liberado (http://localhost:8000 no responde)
- ✅ No hay procesos python/ollama ejecutándose

## 📋 Requisitos por plataforma

### 🐳 **Requisitos Docker (Recomendado)**
- **Solo Docker**: Docker Engine 20.10+ o Docker Desktop
- **Sistema**: Linux, Windows 10/11, macOS 10.14+
- **RAM**: 8GB+ recomendado
- **Disco**: 4GB+ espacio libre
- **GPU**: NVIDIA (opcional, para mejor rendimiento)

### 💻 **Requisitos Instalación Local**

#### 🐧 Linux
- **Obligatorio**: Ubuntu 18.04+, Debian 10+, o similar
- **Terminal**: bash, zsh o compatible
- **Python**: 3.6+ (para servidor web local)
- **Permisos**: Capacidad de ejecutar scripts

#### 🪟 Windows
- **Obligatorio**: Windows 10/11
- **PowerShell**: 5.1+ (incluido en Windows)
- **Python**: 3.6+ (opcional, para servidor web)
- **Permisos**: Capacidad de ejecutar scripts PowerShell

#### 🍎 macOS
- **Obligatorio**: macOS 10.14+ (Mojave)
- **Terminal**: Terminal.app o iTerm2
- **Python**: 3.6+ (incluido en macOS moderno)
- **Homebrew**: Recomendado para dependencias

### Común para todas las plataformas
- 🌐 **Navegador**: Chrome 80+, Firefox 75+, Safari 14+, Edge 80+
- 🤖 **[Ollama](https://ollama.ai)** instalado y funcionando (solo local)
- 💾 **8GB+ RAM** (recomendado)
- 🎮 **GPU con 4GB+ VRAM** (opcional, para mejor rendimiento)
- 🔊 **Altavoces** para la experiencia completa

## 🤖 Instalación de IA por plataforma

### 🐳 **Con Docker (Automático)**
```bash
# 🚀 TODO SE HACE AUTOMÁTICAMENTE
# El detector de hardware funciona igual que en local
# pero dentro del contenedor con instalación cero

# Linux/macOS/Windows: Un solo comando
./start-msnai-docker*.sh  # Se autoconfiguran según tu hardware
```

### 💻 **Instalación Local Manual**

#### 🐧 Linux
```bash
# Detección automática de hardware y recomendación
./ai_check_all.sh

# O instalación manual
curl -fsSL https://ollama.com/install.sh | sh
ollama pull mistral:7b  # Modelo recomendado
```

#### 🪟 Windows
```powershell
# Configurar IA automáticamente
.\ai_check_all.ps1

# O instalación manual
# 1. Descargar Ollama desde https://ollama.com/download
# 2. Instalar el .exe descargado
# 3. ollama pull mistral:7b
```

#### 🍎 macOS
```bash
# Configurar IA automáticamente
./ai_check_all_mac.sh

# O instalación manual
curl -fsSL https://ollama.com/install.sh | sh
ollama pull mistral:7b  # Modelo recomendado
```

## 📁 Estructura del proyecto

```
MSN-AI/                      # 📁 https://github.com/mac100185/MSN-AI
├── msn-ai.html              # 🎯 Aplicación principal (TODO EN UNO)
├── 🐳 DOCKER (NUEVO):
│   ├── start-msnai-docker.sh       # 🐧 Inicio Docker Linux
│   ├── start-msnai-docker.ps1      # 🪟 Inicio Docker Windows
│   ├── start-msnai-docker-mac.sh   # 🍎 Inicio Docker macOS
│   ├── docker/                     # 📁 Configuración Docker
│   │   ├── Dockerfile              # 🏗️ Imagen principal
│   │   ├── docker-compose.yml      # 🎼 Orquestación servicios
│   │   ├── docker-entrypoint.sh    # 🚀 Inicio contenedor
│   │   ├── healthcheck.sh          # 🏥 Verificación salud
│   │   ├── scripts/                # 📁 Scripts Docker
│   │   └── README-DOCKER.md        # 📖 Documentación Docker
│   └── .dockerignore               # 🚫 Exclusiones build
├── 🐧 LINUX (Local):
│   ├── start-msnai.sh       # 🚀 Script de inicio para Linux
│   ├── ai_check_all.sh      # 🤖 Detector de hardware + IA
│   └── test-msnai.sh        # 🧪 Verificación del sistema
├── 🪟 WINDOWS (Local):
│   ├── start-msnai.ps1      # 🚀 Script de inicio PowerShell
│   └── ai_check_all.ps1     # 🤖 Detector de hardware + IA
├── 🍎 macOS (Local):
│   ├── start-msnai-mac.sh   # 🚀 Script de inicio para macOS
│   └── ai_check_all_mac.sh  # 🤖 Detector de hardware + IA
├── 📚 DOCUMENTACIÓN:
│   ├── README.md            # 📖 Guía principal (este archivo)
│   ├── README-MSNAI.md      # 📚 Documentación técnica completa
│   ├── CHANGELOG.md         # 📋 Historial de cambios
│   ├── INSTALL-GUIDE.md     # 🌍 Guía de instalación multiplataforma
│   ├── IMPLEMENTACION-COMPLETA.md  # 🎉 Resumen técnico completo
│   └── LICENSE              # ⚖️ Licencia GPL-3.0
├── assets/                  # 🎨 Recursos multimedia
│   ├── sounds/              # 🔊 Sonidos auténticos de MSN
│   ├── background/          # 🖼️ Fondos e imágenes
│   ├── chat-window/         # 🖼️ Iconos y elementos de chat
│   ├── contacts-window/     # 🖼️ Iconos de lista de contactos
│   ├── general/             # 🖼️ Elementos UI generales
│   ├── scrollbar/           # 🖼️ Elementos personalizados
│   └── status/              # 🖼️ Iconos de estado
└── backup/                  # 🛡️ Respaldos de archivos originales
```

### 🌐 **Clonar repositorio:**
```bash
git clone https://github.com/mac100185/MSN-AI.git
cd MSN-AI
```

## 🎮 Uso básico

### Crear nuevo chat
1. Clic en el botón **"+"** 
2. ¡Sonido de notificación!
3. Empieza a chatear

### Enviar mensaje
1. Escribe en el área de texto
2. Presiona **Enter** o clic **"Enviar"**
3. Escucha el sonido de envío
4. La IA responde con sonido de recepción

### Gestionar chats
- **Buscar**: Usa la barra de búsqueda superior
- **Exportar**: Botón de exportar → Descarga JSON
- **Importar**: Botón de importar → Selecciona archivo JSON
- **Configurar**: Botón de engranaje → Ajustes avanzados

## 🔊 Experiencia auditiva

| Sonido | Cuándo se reproduce |
|--------|-------------------|
| 🎵 `login.wav` | Al iniciar la aplicación |
| 📤 `message_out.wav` | Al enviar tu mensaje |
| 📥 `message_in.wav` | Al recibir respuesta de IA |
| 🔔 `nudge.wav` | Notificaciones y nuevos chats |
| 📞 `calling.wav` | Funcionalidades futuras |

## ⚙️ Configuración

Accede desde el botón de **engranaje** en la interfaz:

- 🔊 **Sonidos**: Activar/desactivar efectos
- 🌐 **Servidor Ollama**: Configurar URL (por defecto: `localhost:11434`)
- 🤖 **Modelo de IA**: Seleccionar modelo preferido
- 🧪 **Test de conexión**: Verificar conectividad

## 🆘 Solución de problemas

### 🐳 **Problemas Docker**

#### "Docker no encontrado"
```bash
# Instalación automática incluida en los scripts
./start-msnai-docker.sh  # Instala Docker automáticamente

# O manualmente:
# Linux: curl -fsSL https://get.docker.com | sh
# Windows/macOS: Descargar Docker Desktop
```

#### "Contenedores no inician"
```bash
# Ver logs detallados
docker-compose -f docker/docker-compose.yml logs

# Reconstruir imágenes
docker-compose -f docker/docker-compose.yml build --no-cache
```

#### "Puerto ocupado"
```bash
# Cambiar puerto en .env
echo "MSN_AI_PORT=8001" > .env
docker-compose -f docker/docker-compose.yml up -d
```

### 💻 **Problemas Instalación Local**

#### "No hay conexión con Ollama"
```bash
# Iniciar Ollama
ollama serve

# Verificar que funcione
curl http://localhost:11434/api/tags
```

#### "Modelo no disponible"
```bash
# Listar modelos disponibles
ollama list

# Instalar modelo recomendado
ollama pull mistral:7b
```

### 🔧 **Problemas Comunes**

#### Sin sonidos
- Permitir autoplay en el navegador
- Verificar que existan archivos en `assets/sounds/`
- Activar sonidos en Configuración

#### La aplicación no carga
```bash
# Docker:
docker-compose -f docker/docker-compose.yml restart

# Local:
python3 -m http.server 8000
# Luego abrir: http://localhost:8000/msn-ai.html
```

#### Detención incorrecta
```bash
# Docker:
docker-compose -f docker/docker-compose.yml down

# Local:
pkill -f "start-msnai"
```

## 📚 Documentación completa

- 📖 **[README-MSNAI.md](README-MSNAI.md)** - Guía detallada de 350+ líneas
- 🎯 **[IMPLEMENTACION-COMPLETA.md](IMPLEMENTACION-COMPLETA.md)** - Detalles técnicos
- 📋 **[CHANGELOG.md](CHANGELOG.md)** - Historial de cambios y roadmap
- 🧪 **`./test-msnai.sh`** - Diagnóstico automático

## 📞 Contacto

**Autor**: Alan Mac-Arthur García Díaz  
**Email**: [alan.mac.arthur.garcia.diaz@gmail.com](mailto:alan.mac.arthur.garcia.diaz@gmail.com)  
**Repositorio**: [https://github.com/mac100185/MSN-AI](https://github.com/mac100185/MSN-AI)

### 🐛 Reportar problemas
- **GitHub Issues**: [https://github.com/mac100185/MSN-AI/issues](https://github.com/mac100185/MSN-AI/issues) - Para bugs y solicitudes de funcionalidades
- **Email directo**: Para soporte técnico urgente
- **Discusiones**: [https://github.com/mac100185/MSN-AI/discussions](https://github.com/mac100185/MSN-AI/discussions) - Para ideas y sugerencias generales

### 💬 Comunidad
- **GitHub**: [https://github.com/mac100185/MSN-AI](https://github.com/mac100185/MSN-AI)
- **Fork y contribuye**: [https://github.com/mac100185/MSN-AI/fork](https://github.com/mac100185/MSN-AI/fork)
- **Releases**: [https://github.com/mac100185/MSN-AI/releases](https://github.com/mac100185/MSN-AI/releases)
- Únete a las discusiones del proyecto
- Comparte tus experiencias nostálgicas
- Contribuye con ideas y mejoras

## 🔒 Política de Privacidad

### 📍 Datos locales únicamente
- **MSN-AI es 100% local** - No envía datos a servidores externos
- **Tus chats permanecen en tu dispositivo** - Almacenados en localStorage del navegador
- **Sin rastreo ni análisis** - No recopilamos información personal
- **Sin cookies de terceros** - Solo almacenamiento local necesario

### 🛡️ Seguridad de datos
- **Cifrado del navegador** - localStorage protegido por las políticas del navegador
- **Sin transmisión de red** - Excepto comunicación local con Ollama
- **Control total** - Puedes exportar, importar o eliminar todos tus datos
- **Código abierto** - Puedes auditar completamente el funcionamiento

### 📤 Export/Import
- **Tus datos son tuyos** - Exporta en cualquier momento en formato JSON estándar
- **Portabilidad completa** - Migra entre dispositivos fácilmente
- **Sin dependencias** - No necesitas cuenta ni registro

## ⚖️ Términos de Uso

### 📋 Uso permitido
- ✅ **Uso personal y educativo** - Sin restricciones
- ✅ **Modificación y distribución** - Bajo los términos de GPL-3.0
- ✅ **Uso comercial** - Permitido bajo GPL-3.0
- ✅ **Contribuciones** - Bienvenidas y apreciadas

### 🚫 Restricciones
- ❌ **No redistribuir sin código fuente** - GPL-3.0 requiere código abierto
- ❌ **No cambiar licencia** - Debe mantenerse GPL-3.0
- ❌ **No usar para actividades ilegales** - Responsabilidad del usuario
- ❌ **No reclamar autoría original** - Respeta los créditos

### 🤝 Responsabilidades
- **Del desarrollador**: Mantener código de calidad y documentación
- **Del usuario**: Uso responsable y respeto a los términos
- **De la comunidad**: Contribuir constructivamente

## 🛡️ Garantía y Limitaciones

### ⚠️ Exención de garantía (Según GPL-3.0)

**MSN-AI se proporciona "TAL COMO ESTÁ", sin garantía de ningún tipo.**

- **Sin garantía de funcionamiento** - El software puede tener bugs
- **Sin garantía de compatibilidad** - Puede no funcionar en todos los sistemas  
- **Sin garantía de permanencia** - Las funcionalidades pueden cambiar
- **Sin responsabilidad por daños** - Usa bajo tu propio riesgo

### 🔧 Limitaciones conocidas
- **Dependencia de Ollama** - Requiere instalación y configuración correcta
- **Compatibilidad de navegador** - Funciones modernas requeridas
- **Recursos del sistema** - IA local consume memoria y procesamiento
- **Sonidos** - Requiere permisos de autoplay del navegador

### 💪 Lo que SÍ garantizamos
- ✅ **Código abierto completo** - Transparencia total
- ✅ **Respuesta a problemas críticos** - En tiempo razonable
- ✅ **Documentación actualizada** - Mantener guías al día
- ✅ **Respeto a la privacidad** - Sin recopilación de datos

### 🆘 Soporte
- **Mejor esfuerzo** - Ayudamos cuando podemos
- **Comunidad** - Los usuarios se ayudan entre sí
- **Issues en GitHub** - Canal oficial para reportes
- **Sin SLA** - No hay garantía de tiempo de respuesta

## 📄 Licencia

Este proyecto está licenciado bajo la **GNU General Public License v3.0**.

### 🔑 Puntos clave de GPL-3.0:
- ✅ **Libertad de usar** - Para cualquier propósito
- ✅ **Libertad de estudiar** - Código fuente disponible
- ✅ **Libertad de modificar** - Adapta según tus necesidades
- ✅ **Libertad de distribuir** - Comparte con otros
- ⚖️ **Copyleft** - Las modificaciones deben ser GPL-3.0 también

Ver el archivo [LICENSE](LICENSE) para el texto completo de la licencia.

### 🤝 Créditos y agradecimientos

- **[androidWG/WLMOnline](https://github.com/androidWG/WLMOnline)** - Proyecto base para la interfaz
- **Microsoft Corporation** - Windows Live Messenger original (Fair Use educativo)
- **[Ollama](https://ollama.ai)** - Por hacer la IA local accesible
- **Proyecto Escargot** - Por mantener vivo el espíritu de MSN
- **Messenger Plus!** - Herramientas de extracción de assets

### 📜 Derechos de terceros
- **Assets de Microsoft** - Usados bajo Fair Use para preservación histórica
- **Sonidos originales** - Extraídos del software original para fines educativos
- **Logotipos** - Marcas registradas de sus respectivos propietarios

## 🚀 ¿Qué sigue?

### 🔮 Roadmap
- [ ] Integración con más modelos de IA
- [ ] Temas personalizables
- [ ] Modo colaborativo
- [ ] App móvil
- [ ] Integración con servidores MSN revividos

### 🤝 Cómo contribuir
1. **Fork** el repositorio
2. **Crea** una rama para tu funcionalidad
3. **Desarrolla** siguiendo las convenciones del proyecto
4. **Documenta** tus cambios
5. **Envía** un Pull Request

---

## 💎 ¿Por qué MSN-AI?

**Porque la nostalgia + IA = Magia pura** ✨

Revive la época dorada del MSN mientras conversas con la IA más avanzada. Una experiencia única que no encontrarás en ningún otro lugar.

**🚀 ¡Inicia tu viaje nostálgico ahora!**

```bash
# 🔥 INSTALACIÓN RÁPIDA EN UNA LÍNEA:
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI && chmod +x *.sh && ./start-msnai-docker.sh --auto
```

### 🐳 Docker (Recomendado):
```bash
# 1. Clonar:
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI

# 2. Iniciar:
# Linux:
./start-msnai-docker.sh --auto

# Windows:
.\start-msnai-docker.ps1 --auto

# macOS:
./start-msnai-docker-mac.sh --auto
```

### 💻 Local (Tradicional):
```bash
# 1. Clonar:
git clone https://github.com/mac100185/MSN-AI.git && cd MSN-AI

# 2. Iniciar:
# Linux:
./start-msnai.sh --auto

# Windows:
.\start-msnai.ps1 --auto

# macOS:
./start-msnai-mac.sh --auto
```

**⏹️ Y recuerda siempre detenerlo correctamente:**

🐳 **Docker**: 
```bash
docker-compose -f docker/docker-compose.yml down
```

💻 **Local**: **Ctrl + C** en la terminal/PowerShell donde lo iniciaste

---

*MSN-AI v1.0.0 - "Donde el pasado conversa con el futuro"*

**Desarrollado con ❤️ por Alan Mac-Arthur García Díaz**  
**Repositorio**: [https://github.com/mac100185/MSN-AI](https://github.com/mac100185/MSN-AI)  
**Licenciado bajo GPL-3.0 | Enero 2025**