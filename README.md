# 🚀 MSN-AI - Windows Live Messenger con IA Local

![MSN-AI](assets/general/logo.png)

> *Donde la nostalgia se encuentra con la inteligencia artificial moderna*

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

### 1. Verificar el sistema
```bash
./test-msnai.sh
```

### 2. Instalar automáticamente
```bash
./start-msnai.sh --auto
```

### 3. ¡Disfruta!
La aplicación se abrirá automáticamente en tu navegador con sonidos nostálgicos y IA lista para conversar.

## 📋 Requisitos

### Obligatorio
- 🐧 Linux, macOS o Windows
- 🌐 Navegador moderno (Chrome 80+, Firefox 75+, Safari 14+)
- 🤖 [Ollama](https://ollama.ai) instalado

### Recomendado  
- 💾 8GB+ RAM
- 🎮 GPU con 4GB+ VRAM (para mejor rendimiento)
- 🔊 Altavoces para la experiencia completa

## 🤖 Instalación de IA

Si no tienes Ollama o modelos instalados:

```bash
# Detección automática de hardware y recomendación
./ai_check_all.sh

# Instalación manual
curl -fsSL https://ollama.com/install.sh | sh
ollama pull mistral:7b  # Modelo recomendado
```

## 📁 Estructura del proyecto

```
MSN-AI/
├── msn-ai.html              # 🎯 Aplicación principal (TODO EN UNO)
├── start-msnai.sh           # 🚀 Script de inicio automático
├── ai_check_all.sh          # 🤖 Detector de hardware + IA
├── test-msnai.sh            # 🧪 Verificación del sistema
├── README-MSNAI.md          # 📚 Documentación completa
├── assets/                  # 🎨 Recursos multimedia
│   ├── sounds/              # 🔊 Sonidos auténticos de MSN
│   ├── background/          # 🖼️ Fondos e imágenes
│   └── ...                  # Más assets organizados
└── backup/                  # 🛡️ Respaldos de archivos originales
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

### "No hay conexión con Ollama"
```bash
# Iniciar Ollama
ollama serve

# Verificar que funcione
curl http://localhost:11434/api/tags
```

### "Modelo no disponible"
```bash
# Listar modelos disponibles
ollama list

# Instalar modelo recomendado
ollama pull mistral:7b
```

### Sin sonidos
- Permitir autoplay en el navegador
- Verificar que existan archivos en `assets/sounds/`
- Activar sonidos en Configuración

### La aplicación no carga
```bash
# Usar servidor local
python3 -m http.server 8000
# Luego abrir: http://localhost:8000/msn-ai.html
```

## 📚 Documentación completa

- 📖 **[README-MSNAI.md](README-MSNAI.md)** - Guía detallada de 350+ líneas
- 🎯 **[IMPLEMENTACION-COMPLETA.md](IMPLEMENTACION-COMPLETA.md)** - Detalles técnicos
- 🧪 **`./test-msnai.sh`** - Diagnóstico automático

## 🎨 Capturas de pantalla

*Próximamente: Screenshots de la interfaz nostálgica funcionando*

## 🤝 Créditos y agradecimientos

- **[androidWG/WLMOnline](https://github.com/androidWG/WLMOnline)** - Proyecto base para la interfaz
- **Microsoft** - Windows Live Messenger original
- **[Ollama](https://ollama.ai)** - Por hacer la IA local accesible
- **Proyecto Escargot** - Por mantener vivo el espíritu de MSN

## 📄 Licencia

Proyecto bajo Licencia MIT. Los assets gráficos pertenecen a Microsoft Corporation y se usan bajo criterios de Fair Use educativo.

## 🚀 ¿Qué sigue?

- [ ] Integración con más modelos de IA
- [ ] Temas personalizables
- [ ] Modo colaborativo
- [ ] App móvil
- [ ] Integración con servidores MSN revividos

---

## 💎 ¿Por qué MSN-AI?

**Porque la nostalgia + IA = Magia pura** ✨

Revive la época dorada del MSN mientras conversas con la IA más avanzada. Una experiencia única que no encontrarás en ningún otro lugar.

**🚀 ¡Inicia tu viaje nostálgico ahora!**

```bash
./start-msnai.sh --auto
```

---

*MSN-AI v1.0 - "Donde el pasado conversa con el futuro"*