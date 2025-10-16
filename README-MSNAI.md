# MSN-AI - Windows Live Messenger con IA Local

![MSN-AI Logo](assets/general/logo.png)

**Versión 1.0.0** | **Licencia GPL-3.0** | **Por Alan Mac-Arthur García Díaz**

## 🎯 Descripción

MSN-AI es una aplicación web que combina la nostálgica interfaz de Windows Live Messenger 8.5 con la potencia de los modelos de IA local ejecutados a través de Ollama. Disfruta de la experiencia clásica de MSN mientras conversas con asistentes de inteligencia artificial avanzados.

**Desarrollado por**: Alan Mac-Arthur García Díaz  
**Contacto**: [alan.mac.arthur.garcia.diaz@gmail.com](mailto:alan.mac.arthur.garcia.diaz@gmail.com)  
**Licencia**: GNU General Public License v3.0

## ✨ Características principales

### 🎨 Interfaz auténtica
- Recreación pixel-perfect de Windows Live Messenger 8.5
- Sonidos auténticos del MSN original
- Efectos visuales Aero fieles al original
- Scrollbars personalizados estilo Windows Vista/7

### 🤖 IA integrada
- Soporte para múltiples modelos de IA (Mistral, Llama, Phi3, etc.)
- Conversaciones contextuales inteligentes
- Detección automática de modelos disponibles
- Reconexión automática con Ollama

### 💾 Gestión de datos
- Almacenamiento local en el navegador (localStorage)
- Historial completo de conversaciones
- Sistema de búsqueda en chats
- Exportación e importación de chats en JSON

### 🔊 Experiencia inmersiva
- Sonidos auténticos de MSN (login, mensajes, notificaciones)
- Indicadores visuales de estado de conexión
- Animaciones de "IA pensando"
- Interfaz completamente responsive

## 🚀 Instalación y configuración

### Prerrequisitos

1. **Ollama instalado y ejecutándose**
   - Descargar desde: https://ollama.ai
   - O usar el script incluido: `./ai_check_all.sh`

2. **Al menos un modelo de IA descargado**
   ```bash
   ollama pull mistral:7b  # Recomendado para empezar
   ollama pull llama3:8b   # Para mejor rendimiento
   ollama pull phi3:mini   # Para equipos limitados
   ```

### Uso rápido

1. **Abrir el archivo**
   ```bash
   # Opción 1: Navegador web
   firefox MSN-AI/msn-ai.html
   
   # Opción 2: Servidor local simple
   python3 -m http.server 8000
   # Luego abrir: http://localhost:8000/MSN-AI/msn-ai.html
   ```

2. **Verificar conexión**
   - Al iniciar, MSN-AI intentará conectarse automáticamente a Ollama
   - Indicador de estado en la esquina inferior derecha
   - Verde = Conectado, Rojo = Desconectado, Amarillo = Conectando

3. **Comenzar a chatear**
   - Clic en "Nuevo Chat" para crear una conversación
   - Escribe tu mensaje y presiona Enter o clic en "Enviar"
   ### 3. ¡Disfruta de la nostalgia mientras conversas con IA!

   ## ⏹️ Detener MSN-AI correctamente

   **⚠️ IMPORTANTE**: Siempre detén correctamente para evitar daños al sistema:

   ### Método recomendado
   ```bash
   # En la terminal donde ejecutaste start-msnai.sh:
   Ctrl + C
   # El script automáticamente limpiará todos los procesos
   ```

   ### Detención manual (emergencia)
   ```bash
   # Detener todos los procesos relacionados
   pkill -f "python.*http.server"
   pkill -f "http-server" 
   pkill -f "start-msnai"
   pkill ollama  # Solo si fue iniciado por el script

   # Verificar que todo esté detenido
   ps aux | grep -E "(python.*http|ollama|start-msnai)"
   ```

   ### Indicadores de detención exitosa
   - ✅ Mensaje: "👋 ¡Gracias por usar MSN-AI!"
   - ✅ Puerto 8000 liberado (no responde)
   - ✅ Sin procesos relacionados ejecutándose
   - ✅ Terminal disponible para nuevos comandos

   ### ❌ Nunca hagas esto
   - Cerrar terminal sin Ctrl+C
   - Usar `kill -9` directamente
   - Apagar el sistema con servicios activos
   - Forzar cierre del navegador sin detener servicios

   ## 📚 Guía de uso

### Gestión de chats

#### Crear nuevo chat
- Clic en el botón con icono "+" en la barra de navegación
- Se creará automáticamente con el modelo seleccionado
- El título se genera automáticamente basado en el primer mensaje

#### Seleccionar chat
- Clic en cualquier chat de la lista izquierda
- El chat activo se resalta en azul
- Los mensajes se cargan automáticamente

#### Buscar chats
- Usar la barra de búsqueda superior
- Busca en títulos y contenido de mensajes
- Filtrado en tiempo real

#### Eliminar chat
- Clic derecho sobre un chat → Confirmar eliminación
- **⚠️ Acción irreversible**

### Configuración

#### Acceder a configuración
- Clic en el botón de engranaje (esquina superior derecha)

#### Opciones disponibles
- **Sonidos**: Activar/desactivar efectos de sonido
- **Servidor Ollama**: Cambiar URL del servidor (por defecto: `http://localhost:11434`)
- **Modelo de IA**: Seleccionar modelo preferido para nuevos chats
- **Probar conexión**: Verificar conectividad con Ollama

### Import/Export

#### Exportar chats
1. Clic en botón de exportar (icono de carpeta)
2. Se descarga automáticamente un archivo JSON
3. Formato: `msn-ai-chats-YYYY-MM-DD.json`

#### Importar chats
1. Clic en botón de importar
2. Seleccionar archivo JSON previamente exportado
3. Los chats se agregan a los existentes (no se sobrescriben)

#### Estructura del archivo JSON
```json
{
  "version": "1.0",
  "exportDate": "2025-01-07T10:30:00.000Z",
  "chats": [
    {
      "id": "chat-1704625800000",
      "title": "Consulta sobre JavaScript",
      "date": "2025-01-07T10:30:00.000Z",
      "model": "mistral:7b",
      "messages": [
        {
          "type": "user",
          "content": "¿Cómo funciona async/await?",
          "timestamp": "2025-01-07T10:30:00.000Z"
        },
        {
          "type": "ai",
          "content": "async/await es una sintaxis...",
          "timestamp": "2025-01-07T10:30:15.000Z"
        }
      ]
    }
  ],
  "settings": {
    "soundsEnabled": true,
    "ollamaServer": "http://localhost:11434",
    "selectedModel": "mistral:7b"
  }
}
```

## 🎵 Sonidos incluidos

| Archivo | Descripción | Cuándo se reproduce |
|---------|-------------|-------------------|
| `login.wav` | Sonido de inicio de MSN | Al cargar la aplicación y al importar |
| `message_in.wav` | Mensaje recibido | Cuando la IA responde |
| `message_out.wav` | Mensaje enviado | Al enviar tu mensaje |
| `nudge.wav` | Zumbido/notificación | Al crear nuevo chat y exportar |
| `calling.wav` | Sonido de llamada | Futuras funcionalidades |

## ⚙️ Configuración avanzada

### Modelos recomendados según hardware

| Hardware | Modelo recomendado | Razón |
|----------|-------------------|--------|
| 80GB+ VRAM | `llama3:70b` | Máximo rendimiento |
| 24GB+ VRAM | `llama3:8b` | Excelente para programación |
| 8-16GB VRAM | `mistral:7b` | Balance perfecto |
| Solo CPU, 32GB+ RAM | `mistral:7b` | Funciona en CPU |
| Hardware limitado | `phi3:mini` | Ligero y eficiente |

### Personalización del servidor Ollama

```bash
# Cambiar puerto por defecto
OLLAMA_HOST=0.0.0.0:11435 ollama serve

# Configurar GPU específica
CUDA_VISIBLE_DEVICES=0 ollama serve

# Configurar memoria límite
OLLAMA_GPU_MEMORY_FRACTION=0.8 ollama serve
```

### Configuración de red

Si Ollama está en otro servidor:
1. Ir a Configuración
2. Cambiar "Servidor Ollama" a: `http://IP_SERVIDOR:11434`
3. Asegurar que Ollama permita conexiones externas:
   ```bash
   OLLAMA_HOST=0.0.0.0:11434 ollama serve
   ```

## 🔧 Solución de problemas

### Error: "No hay conexión con Ollama"
**Causa**: Ollama no está ejecutándose o no es accesible
**Solución**:
1. Verificar que Ollama esté ejecutándose: `ollama list`
2. Verificar el puerto: `netstat -tlnp | grep 11434`
3. Probar conexión manual: `curl http://localhost:11434/api/tags`

### Error: "Modelo no disponible"
**Causa**: El modelo seleccionado no está descargado
**Solución**:
1. Listar modelos disponibles: `ollama list`
2. Descargar modelo: `ollama pull mistral:7b`
3. Reiniciar MSN-AI

### Los sonidos no se reproducen
**Causa**: Navegador bloquea autoplay o archivos no encontrados
**Solución**:
1. Permitir autoplay en el navegador
2. Verificar que existan los archivos en `assets/sounds/`
3. Desactivar/activar sonidos en Configuración

### Chat lento o no responde
**Causa**: Modelo muy grande para el hardware o problemas de red
**Solución**:
1. Cambiar a modelo más ligero (phi3:mini)
2. Verificar uso de GPU: `nvidia-smi`
3. Verificar log de Ollama: `journalctl -u ollama`

### Pérdida de datos
**Causa**: localStorage del navegador fue limpiado
**Solución**:
1. Los datos se guardan automáticamente en localStorage
2. Exportar regularmente los chats como respaldo
3. Importar desde archivo JSON de respaldo

## 🎨 Características técnicas

### Tecnologías utilizadas
- **Frontend**: HTML5, CSS3, JavaScript ES6+
- **Almacenamiento**: LocalStorage API
- **IA**: Ollama REST API
- **Audio**: Web Audio API
- **Estilo**: CSS Grid y Flexbox

### Compatibilidad de navegadores
- ✅ Chrome 80+
- ✅ Firefox 75+
- ✅ Safari 14+
- ✅ Edge 80+
- ⚠️ Internet Explorer: No soportado

### Tamaño de la aplicación
- **Archivo principal**: ~50KB (msn-ai.html)
- **Assets totales**: ~2MB (imágenes y sonidos)
- **Almacenamiento usado**: Variable según chats guardados

### Rendimiento
- **Carga inicial**: <2 segundos
- **Renderizado de mensajes**: <100ms
- **Respuesta de IA**: Depende del modelo y hardware
- **Uso de memoria**: ~20-50MB típico

## 📖 API de desarrollo

### Clase principal: MSNAI

```javascript
// Crear nueva instancia
const msnai = new MSNAI();

// Crear chat programáticamente
const chatId = msnai.createNewChat();

// Enviar mensaje programáticamente
await msnai.sendMessage('Hola IA', chatId);

// Exportar datos
const data = msnai.exportChats();

// Cambiar configuración
msnai.settings.selectedModel = 'llama3:8b';
msnai.saveSettings();
```

### Eventos disponibles

```javascript
// Escuchar conexión con Ollama
msnai.on('connection', (status) => {
    console.log('Estado de conexión:', status);
});

// Escuchar nuevos mensajes
msnai.on('message', (message) => {
    console.log('Nuevo mensaje:', message);
});
```

## 🤝 Contribución

### Estructura del proyecto
```
MSN-AI/
├── msn-ai.html          # Aplicación principal (todo en uno)
├── ai_check_all.sh      # Script de detección de hardware
├── backup/              # Respaldos de archivos originales
├── assets/              # Recursos multimedia
│   ├── sounds/          # Efectos de sonido
│   ├── background/      # Imágenes de fondo
│   ├── chat-window/     # Iconos de chat
│   ├── contacts-window/ # Iconos de contactos
│   ├── general/         # Elementos generales
│   ├── scrollbar/       # Elementos de scrollbar
│   └── status/          # Iconos de estado
└── README-MSNAI.md      # Esta documentación
```

### Cómo contribuir
1. Fork del repositorio
2. Crear rama feature: `git checkout -b feature/nueva-funcionalidad`
3. Commit cambios: `git commit -am 'Agregar nueva funcionalidad'`
4. Push a la rama: `git push origin feature/nueva-funcionalidad`
5. Crear Pull Request

### Roadmap
- [ ] Soporte para más modelos de IA (Claude, GPT local)
- [ ] Sistema de plugins para extensiones
- [ ] Temas personalizables
- [ ] Integración con servicios de nube
- [ ] App móvil híbrida
- [ ] Cifrado end-to-end para chats
- [ ] Colaboración en tiempo real
- [ ] Integración con Escargot/MSN servers

## 📄 Licencia y Términos Legales

### ⚖️ Licencia Principal
Este proyecto está licenciado bajo la **GNU General Public License v3.0**.

**Puntos clave de GPL-3.0:**
- ✅ Libertad de usar para cualquier propósito
- ✅ Libertad de estudiar y modificar el código
- ✅ Libertad de distribuir copias  
- ✅ Libertad de distribuir modificaciones
- ⚖️ Copyleft: Las modificaciones deben ser GPL-3.0 también

Ver el archivo [LICENSE](LICENSE) para el texto completo.

### 🛡️ Garantía y Responsabilidad
**SOFTWARE PROPORCIONADO "TAL COMO ESTÁ"** según GPL-3.0:
- ❌ Sin garantía de funcionamiento
- ❌ Sin garantía de compatibilidad
- ❌ Sin responsabilidad por daños
- ✅ Código abierto para auditoría completa
- ✅ Soporte de mejor esfuerzo de la comunidad

### 📜 Derechos de Terceros
- **Assets de Microsoft**: Usados bajo Fair Use para preservación histórica
- **Sonidos originales**: Extraídos para fines educativos
- **Proyecto base WLMOnline**: Por androidWG, respetando licencia original
- **Ollama**: Software independiente con su propia licencia

### 🔒 Política de Privacidad
- **100% Local**: Sin envío de datos a servidores externos
- **Sin rastreo**: No recopilamos información personal
- **LocalStorage únicamente**: Datos almacenados en tu navegador
- **Control total**: Exporta, importa o elimina tus datos cuando quieras

## 🙏 Agradecimientos

- **androidWG** por el proyecto original [WLMOnline](https://github.com/androidWG/WLMOnline)
- **Microsoft Corporation** por Windows Live Messenger original
- **Ollama** por hacer accesible la IA local
- **Escargot Project** por mantener vivos los servidores de MSN
- **Messenger Plus!** por las herramientas de extracción de assets
- **Comunidad Open Source** por las librerías y herramientas utilizadas

## 📞 Soporte y Contacto

### 👨‍💻 Desarrollador
**Alan Mac-Arthur García Díaz**  
📧 **Email**: [alan.mac.arthur.garcia.diaz@gmail.com](mailto:alan.mac.arthur.garcia.diaz@gmail.com)

### 🆘 Obtener ayuda
¿Necesitas ayuda? ¿Encontraste un bug? ¿Tienes una idea genial?

- 🐛 **GitHub Issues**: Para reportes de bugs y solicitudes de funcionalidades
- 💬 **Discusiones**: Para preguntas y sugerencias generales  
- 📧 **Email directo**: Para soporte técnico urgente
- 🤝 **Comunidad**: Los usuarios se ayudan entre sí

### ⏱️ Tiempo de respuesta
- **Issues críticos**: Mejor esfuerzo, sin garantía de SLA
- **Preguntas generales**: Respuesta cuando sea posible
- **Contribuciones**: Revisión activa de Pull Requests
- **Email directo**: Para casos urgentes únicamente

### 🤝 Código de conducta
- Respeta a otros usuarios y colaboradores
- Proporciona información detallada en reportes
- Sé constructivo en críticas y sugerencias
- Mantén las discusiones on-topic

---

## 🔗 Enlaces importantes

- 📖 **Documentación**: [README.md](README.md) - Guía principal  
- 📋 **Cambios**: [CHANGELOG.md](CHANGELOG.md) - Historial de versiones
- ⚖️ **Licencia**: [LICENSE](LICENSE) - Texto completo GPL-3.0
- 🏠 **Proyecto base**: [WLMOnline](https://github.com/androidWG/WLMOnline)

---

**¡Disfruta de la nostalgia con el poder de la IA moderna! 🚀✨**

*MSN-AI v1.0.0 - Donde el pasado se encuentra con el futuro*

**Desarrollado con ❤️ por Alan Mac-Arthur García Díaz**  
**Licenciado bajo GPL-3.0 | Enero 2025**