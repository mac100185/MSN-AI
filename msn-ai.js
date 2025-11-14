// ===================
// SISTEMA MSN-AI (EXTENDIDO CON FUNCIONALIDADES COMPLETAS)
// ===================
class MSNAI {
  constructor() {
    this.chats = [];
    this.currentChatId = null;
    this.isConnected = false;
    this.availableModels = [];
    this.sounds = {};
    this.fontSize = 14;
    this.chatSortOrder = "asc"; // valor inicial: ascendente
    this.pendingFileAttachment = null;
    this.pendingPdfContext = null; // Contexto PDF temporal (no se guarda en historial)
    this.pendingImageContext = null; // Contexto de imágenes temporal (no se guarda en historial)
    this.userScrolledUp = false; // Flag para detectar si el usuario hizo scroll manual
    this.abortControllers = {}; // Mapa de controladores por chatId
    this.expertRoomAbortControllers = {}; // Mapa de controladores de abort para salas de expertos por chatId
    this.respondingChats = new Set(); // Set de chatIds que están recibiendo respuesta
    this.wasAborted = false; // Flag para saber si se abortó la última respuesta
    this.accumulatedResponses = {}; // Mapa de respuestas acumuladas por chatId
    this.unreadChats = new Set(); // Set de chatIds con mensajes no leídos
    this.renderThrottleTimers = {}; // Timers para throttling de renderizado por chat
    this.lastRenderTimes = {}; // Últimos tiempos de renderizado por chat
    this.streamingBuffers = {}; // Buffers de contenido sin formatear por chatId
    this.pendingFrames = {}; // Frames de animación pendientes por chatId
    this.isProcessingStream = {}; // Flag para saber si se está procesando stream por chatId
    this.lastMainThreadCheck = Date.now(); // Para detectar bloqueos del hilo principal
    this.userInteracting = false; // Flag para detectar interacción del usuario
    this.lastUserInteraction = 0; // Timestamp de última interacción
    this.markdownCache = new Map(); // Caché de renderizado de markdown (content -> html)
    this.lastStreamRender = {}; // Timestamp del último render durante streaming por chatId
    this.voiceRecognition = null; // Instancia de SpeechRecognition
    this.isRecording = false; // Flag para saber si está grabando voz
    this.voiceRecognitionError = false; // Flag para saber si hubo error en reconocimiento de voz
    this.voiceRecognitionStarted = false; // Flag para saber si el reconocimiento inició correctamente

    this.translations = {}; // Diccionario de traducciones
    this.availableLanguages = []; // Idiomas disponibles
    this.currentLanguage = "es"; // Idioma por defecto
    this.translationsReady = false; // Flag para indicar si las traducciones están listas
    this.db = null; // IndexedDB para almacenar archivos adjuntos

    // Sistema de rate limiting y gestión de solicitudes
    this.rateLimiter = null; // Instancia del gestor de rate limiting
    this.requestQueue = []; // Cola de solicitudes pendientes
    this.activeRequests = 0; // Número de solicitudes activas
    this.maxConcurrentRequests = 3; // Máximo de solicitudes simultáneas
    this.rateLimitEvents = []; // Registro de eventos de rate limit

    // Detectar Microsoft Edge
    const userAgent = navigator.userAgent.toLowerCase();
    this.isEdgeBrowser = userAgent.includes("edg/");
    if (this.isEdgeBrowser) {
      console.log(
        "🌐 Microsoft Edge detectado - Aplicando optimizaciones específicas",
      );
    }
    const currentHost = window.location.hostname;
    const isRemoteAccess =
      currentHost !== "localhost" && currentHost !== "127.0.0.1";
    const defaultServer = isRemoteAccess
      ? `http://${currentHost}:11434`
      : "http://localhost:11434";
    console.log(`🌐 MSN-AI Inicializando:`);
    console.log(`   Host: ${currentHost}`);
    console.log(`   Acceso: ${isRemoteAccess ? "REMOTO" : "LOCAL"}`);
    console.log(`   Servidor Ollama: ${defaultServer}`);
    this.settings = {
      soundsEnabled: true,
      ollamaServer: defaultServer,
      selectedModel: "",
      apiTimeout: 30000,
      notifyStatusChanges: true,
      language: "es",
      temperature: 0.7,
      topK: 40,
      topP: 0.9,
      maxTokens: 2000,
      groupChatSystemPrompt: "", // Se llenará con la traducción por defecto
    };
    this.currentStatus = "online"; // Estado inicial

    this.init();
    this.startMainThreadMonitor();
  }

  /**
   * Monitor de bloqueo del hilo principal
   * Detecta cuando el navegador no responde por más de 50ms
   */
  startMainThreadMonitor() {
    console.log("🔍 [Monitor] Iniciando monitor de bloqueo del hilo principal");

    // Verificar cada 100ms si el hilo está respondiendo
    this.mainThreadBlockDetector = setInterval(() => {
      const now = Date.now();
      const elapsed = now - this.lastMainThreadCheck;

      // Si han pasado más de 150ms, el hilo estuvo bloqueado
      if (elapsed > 150) {
        console.error(
          `❌❌❌ [Monitor] HILO PRINCIPAL BLOQUEADO por ${elapsed}ms (esperado: ~100ms)`,
        );

        // Verificar qué está activo
        if (this.respondingChats.size > 0) {
          console.error(
            `❌ [Monitor] Chats respondiendo activos:`,
            Array.from(this.respondingChats),
          );
        }

        if (Object.keys(this.isProcessingStream).length > 0) {
          console.error(
            `❌ [Monitor] Streams en procesamiento:`,
            Object.keys(this.isProcessingStream),
          );
        }
      }

      this.lastMainThreadCheck = now;
    }, 100);
  }

  /**
   * Configura detección de interacciones del usuario
   * Para pausar actualizaciones de streaming cuando el usuario interactúa
   */
  setupUserInteractionDetection() {
    console.log(
      "🖱️ [Monitor] Configurando detección de interacciones del usuario",
    );

    const events = ["click", "keydown", "mousedown", "touchstart", "wheel"];

    events.forEach((eventType) => {
      document.addEventListener(
        eventType,
        () => {
          this.userInteracting = true;
          this.lastUserInteraction = Date.now();

          // Resetear flag después de 100ms para mayor fluidez
          setTimeout(() => {
            this.userInteracting = false;
          }, 100);
        },
        { passive: true, capture: true },
      );
    });

    console.log("✅ [Monitor] Detección de interacciones configurada");
  }

  /**
   * Fuerza actualización de tooltips específicamente para Microsoft Edge
   * Este método se ejecuta múltiples veces con retrasos para asegurar que Edge actualice correctamente
   */
  forceUpdateTooltipsForEdge() {
    if (!this.isEdgeBrowser || !this.translationsReady) {
      return;
    }

    // Actualizar todos los tooltips con data-i18n-title
    const tooltipElements = document.querySelectorAll("[data-i18n-title]");
    tooltipElements.forEach((element) => {
      const key = element.getAttribute("data-i18n-title");
      const translation = this.t(key);

      // Verificar que la traducción sea válida y no sea la misma clave
      if (translation && translation !== key && !translation.includes(".")) {
        // En Edge, forzar la eliminación y reinserción del atributo
        element.removeAttribute("title");
        // Usar requestAnimationFrame para asegurar que el navegador procese la eliminación
        requestAnimationFrame(() => {
          element.setAttribute("title", translation);
          // Forzar un reflow para que Edge actualice el tooltip
          void element.offsetHeight;
        });
      } else if (
        translation === key ||
        (translation && translation.includes("."))
      ) {
        // Si la traducción falló, intentar nuevamente después de un delay
        setTimeout(() => {
          const retranslation = this.t(key);
          if (
            retranslation &&
            retranslation !== key &&
            !retranslation.includes(".")
          ) {
            element.removeAttribute("title");
            requestAnimationFrame(() => {
              element.setAttribute("title", retranslation);
              // Forzar un reflow para que Edge actualice el tooltip
              void element.offsetHeight;
            });
          }
        }, 100);
      }
    });
  }

  // =================== RENDERIZADO SEGURO DE MARKDOWN ===================
  /**
   * Configura marked para renderizado seguro
   */
  initMarkdownRenderer() {
    if (typeof marked === "undefined") {
      console.error("❌ marked no está cargado");
      return;
    }

    // Configurar marked
    marked.setOptions({
      gfm: true,
      breaks: true,
      smartypants: false,
      mangle: false,
      headerIds: false,
      highlight: (code, lang) => {
        if (typeof hljs !== "undefined" && lang && hljs.getLanguage(lang)) {
          try {
            return hljs.highlight(code, { language: lang }).value;
          } catch (e) {
            console.warn("Error resaltando código:", e);
          }
        }
        return code;
      },
    });

    console.log("✅ Renderizador de Markdown inicializado");
  }

  /**
   * Renderiza Markdown de forma segura usando marked + DOMPurify con caché
   * @param {string} markdown - Texto en Markdown
   * @param {boolean} useCache - Si usar caché (default: true)
   * @returns {string} HTML sanitizado
   */
  renderMarkdownSafe(markdown, useCache = true) {
    if (typeof markdown !== "string") {
      console.warn("renderMarkdownSafe recibió un valor no string:", markdown);
      return "";
    }

    if (typeof marked === "undefined" || typeof DOMPurify === "undefined") {
      console.error("❌ marked o DOMPurify no están disponibles");
      return this.escapeHtml(markdown);
    }

    // Verificar caché para contenido ya procesado
    if (useCache && this.markdownCache.has(markdown)) {
      return this.markdownCache.get(markdown);
    }

    const renderStart = performance.now();

    try {
      const mdLength = markdown.length;

      // 1. Convertir Markdown a HTML
      const parseStart = performance.now();
      const rawHtml = marked.parse(markdown);
      const parseTime = performance.now() - parseStart;

      if (parseTime > 100) {
        console.warn(
          `⚠️ [Markdown] marked.parse LENTO: ${parseTime.toFixed(2)}ms para ${mdLength} caracteres`,
        );
      }

      // 2. Sanitizar con DOMPurify
      const sanitizeStart = performance.now();
      const cleanHtml = DOMPurify.sanitize(rawHtml, {
        ALLOWED_TAGS: [
          "p",
          "h1",
          "h2",
          "h3",
          "h4",
          "h5",
          "h6",
          "ul",
          "ol",
          "li",
          "blockquote",
          "strong",
          "em",
          "del",
          "code",
          "pre",
          "br",
          "hr",
          "div",
          "span",
          "a",
          "table",
          "thead",
          "tbody",
          "tr",
          "th",
          "td",
          "button",
        ],
        ALLOWED_ATTR: ["class", "href", "target", "data-code", "title"],
        FORBID_TAGS: [
          "form",
          "input",
          "script",
          "iframe",
          "style",
          "link",
          "object",
          "embed",
        ],
        FORBID_ATTR: [
          "onclick",
          "onerror",
          "onload",
          "onmouseover",
          "onfocus",
          "onblur",
        ],
      });
      const sanitizeTime = performance.now() - sanitizeStart;

      if (sanitizeTime > 50) {
        console.warn(
          `⚠️ [Markdown] DOMPurify.sanitize LENTO: ${sanitizeTime.toFixed(2)}ms`,
        );
      }

      // 3. Agregar botones de copiar y descargar a bloques de código
      const buttonsStart = performance.now();
      const safeHtml = this.addCodeBlockButtons(cleanHtml);
      const buttonsTime = performance.now() - buttonsStart;

      if (buttonsTime > 50) {
        console.warn(
          `⚠️ [Markdown] addCodeBlockButtons LENTO: ${buttonsTime.toFixed(2)}ms`,
        );
      }

      const totalTime = performance.now() - renderStart;

      // Guardar en caché si el contenido es final (más de 100 caracteres)
      if (useCache && mdLength > 100) {
        this.markdownCache.set(markdown, safeHtml);

        // Limitar el tamaño del caché a 100 entradas
        if (this.markdownCache.size > 100) {
          const firstKey = this.markdownCache.keys().next().value;
          this.markdownCache.delete(firstKey);
        }
      }

      if (totalTime > 100) {
        console.warn(
          `⚠️ [Markdown] Renderizado LENTO: ${totalTime.toFixed(2)}ms para ${mdLength} caracteres`,
        );
      }

      return safeHtml;
    } catch (error) {
      console.error("❌ Error al renderizar Markdown:", error);
      return `<p style="color: #c00;">⚠️ Error al procesar la respuesta.</p>`;
    }
  }

  /**
   * Agrega botones de copiar y descargar a los bloques de código
   * @param {string} html - HTML con bloques de código
   * @returns {string} HTML con botones agregados
   */
  addCodeBlockButtons(html) {
    const tempDiv = document.createElement("div");
    tempDiv.innerHTML = html;

    const codeBlocks = tempDiv.querySelectorAll("pre > code");
    codeBlocks.forEach((codeElement, index) => {
      const pre = codeElement.parentElement;
      const code = codeElement.textContent;

      // Crear contenedor para el bloque de código con toolbar
      const wrapper = document.createElement("div");
      wrapper.className = "code-block-wrapper";

      // Crear toolbar con botones
      const toolbar = document.createElement("div");
      toolbar.className = "code-block-toolbar";

      // Detectar el lenguaje
      const langClass = Array.from(codeElement.classList).find((cls) =>
        cls.startsWith("language-"),
      );
      const language = langClass
        ? langClass.replace("language-", "").toUpperCase()
        : "CODE";

      // Label del lenguaje
      const langLabel = document.createElement("span");
      langLabel.className = "code-block-lang";
      langLabel.textContent = language;

      // Botón copiar
      const copyBtn = document.createElement("button");
      copyBtn.className = "code-block-btn";
      copyBtn.innerHTML = "📋 Copiar";
      copyBtn.title = "Copiar código";
      copyBtn.setAttribute("data-code", code);

      // Botón descargar
      const downloadBtn = document.createElement("button");
      downloadBtn.className = "code-block-btn";
      downloadBtn.innerHTML = "💾 Descargar";
      downloadBtn.title = "Descargar código";
      downloadBtn.setAttribute("data-code", code);
      downloadBtn.setAttribute("data-lang", language.toLowerCase());

      toolbar.appendChild(langLabel);
      toolbar.appendChild(copyBtn);
      toolbar.appendChild(downloadBtn);

      // Insertar toolbar antes del pre
      pre.parentNode.insertBefore(wrapper, pre);
      wrapper.appendChild(toolbar);
      wrapper.appendChild(pre);
    });

    return tempDiv.innerHTML;
  }

  /**
   * Escapa HTML para prevenir XSS (fallback si no hay librerías)
   * @param {string} text - Texto a escapar
   * @returns {string} Texto escapado
   */
  escapeHtml(text) {
    const map = {
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#039;",
    };
    return text.replace(/[&<>"']/g, (m) => map[m]);
  }

  // =================== SISTEMA DE TRADUCCIÓN ===================
  async loadLanguages() {
    console.log(`🌍 Detectando archivos de idioma en lang/...`);

    // Lista de códigos ISO 639-1 más comunes para intentar cargar
    // Se incluyen los idiomas más hablados del mundo y variantes regionales comunes
    const commonLanguages = [
      "aa",
      "ab",
      "af",
      "ak",
      "am",
      "an",
      "ar",
      "as",
      "av",
      "ay",
      "az",
      "ba",
      "be",
      "bg",
      "bh",
      "bi",
      "bm",
      "bn",
      "bo",
      "br",
      "bs",
      "ca",
      "ce",
      "ch",
      "co",
      "cr",
      "cs",
      "cu",
      "cv",
      "cy",
      "da",
      "de",
      "dv",
      "dz",
      "ee",
      "el",
      "en",
      "eo",
      "es",
      "et",
      "eu",
      "fa",
      "ff",
      "fi",
      "fj",
      "fo",
      "fr",
      "fy",
      "ga",
      "gd",
      "gl",
      "gn",
      "gu",
      "gv",
      "ha",
      "he",
      "hi",
      "ho",
      "hr",
      "ht",
      "hu",
      "hy",
      "hz",
      "ia",
      "id",
      "ie",
      "ig",
      "ii",
      "ik",
      "io",
      "is",
      "it",
      "iu",
      "ja",
      "jv",
      "ka",
      "kg",
      "ki",
      "kj",
      "kk",
      "kl",
      "km",
      "kn",
      "ko",
      "kr",
      "ks",
      "ku",
      "kv",
      "kw",
      "ky",
      "la",
      "lb",
      "lg",
      "li",
      "ln",
      "lo",
      "lt",
      "lu",
      "lv",
      "mg",
      "mh",
      "mi",
      "mk",
      "ml",
      "mn",
      "mr",
      "ms",
      "mt",
      "my",
      "na",
      "nb",
      "nd",
      "ne",
      "ng",
      "nl",
      "nn",
      "no",
      "nr",
      "nv",
      "ny",
      "oc",
      "oj",
      "om",
      "or",
      "os",
      "pa",
      "pi",
      "pl",
      "ps",
      "pt",
      "qu",
      "rm",
      "rn",
      "ro",
      "ru",
      "rw",
      "sa",
      "sc",
      "sd",
      "se",
      "sg",
      "si",
      "sk",
      "sl",
      "sm",
      "sn",
      "so",
      "sq",
      "sr",
      "ss",
      "st",
      "su",
      "sv",
      "sw",
      "ta",
      "te",
      "tg",
      "th",
      "ti",
      "tk",
      "tl",
      "tn",
      "to",
      "tr",
      "ts",
      "tt",
      "tw",
      "ty",
      "ug",
      "uk",
      "ur",
      "uz",
      "ve",
      "vi",
      "vo",
      "wa",
      "wo",
      "xh",
      "yi",
      "yo",
      "za",
      "zh",
      "zu",
    ];

    // Intentar cargar cada posible archivo de idioma de forma concurrente
    // pero con límite para no sobrecargar el navegador
    const batchSize = 10; // Cargar 10 archivos a la vez
    const allLanguages = [];

    for (let i = 0; i < commonLanguages.length; i += batchSize) {
      const batch = commonLanguages.slice(i, i + batchSize);
      const loadPromises = batch.map(async (lang) => {
        try {
          const response = await fetch(`lang/${lang}.json`);
          if (response.ok) {
            const translations = await response.json();
            // Verificar que tenga la estructura correcta
            if (translations.language_name) {
              return {
                code: lang,
                name: translations.language_name,
                data: translations,
              };
            }
          }
          return null;
        } catch (error) {
          // Silenciar errores para archivos no encontrados (esperado)
          return null;
        }
      });

      const results = await Promise.all(loadPromises);
      allLanguages.push(...results.filter((lang) => lang !== null));
    }

    // Asignar y ordenar los idiomas encontrados
    this.availableLanguages = allLanguages;
    this.availableLanguages.sort((a, b) => a.code.localeCompare(b.code));

    console.log(
      `✅ ${this.availableLanguages.length} idiomas detectados y cargados:`,
    );
    this.availableLanguages.forEach((lang) => {
      console.log(`   - ${lang.name} (${lang.code})`);
    });

    // Si no se encontró ningún idioma, intentar cargar español como mínimo
    if (this.availableLanguages.length === 0) {
      console.warn(
        "⚠️ No se encontraron archivos de idioma, intentando cargar español...",
      );
      try {
        const response = await fetch("lang/es.json");
        if (response.ok) {
          const translations = await response.json();
          this.availableLanguages.push({
            code: "es",
            name: translations.language_name || "Español",
            data: translations,
          });
        }
      } catch (error) {
        console.error(
          "❌ Error crítico: No se pudo cargar ningún idioma",
          error,
        );
      }
    }

    // Cargar idioma guardado o español por defecto
    const savedLang = localStorage.getItem("msnai-language") || "es";
    await this.setLanguage(savedLang);
    this.updateLanguageSelect();
  }

  async setLanguage(langCode) {
    let langData = this.availableLanguages.find((l) => l.code === langCode);

    // Si el idioma solicitado no está disponible, intentar con español
    if (!langData) {
      console.warn(`⚠️ Idioma no disponible: ${langCode}, usando español`);
      langData = this.availableLanguages.find((l) => l.code === "es");

      // Si tampoco está español, usar el primer idioma disponible
      if (!langData && this.availableLanguages.length > 0) {
        console.warn(
          `⚠️ Español no disponible, usando primer idioma disponible`,
        );
        langData = this.availableLanguages[0];
      }
    }

    // Aplicar el idioma si se encontró alguno
    if (langData) {
      this.currentLanguage = langData.code;
      this.translations = langData.data;
      this.settings.language = langData.code;
      localStorage.setItem("msnai-language", langData.code);
      console.log(`🌍 Idioma establecido: ${langData.name} (${langData.code})`);
      console.log(
        `🔍 Traducciones cargadas: ${Object.keys(this.translations).length} categorías`,
      );
      console.log(
        `🔍 Estructura tooltips:`,
        this.translations.tooltips
          ? Object.keys(this.translations.tooltips).length + " claves"
          : "NO EXISTE",
      );
      console.log(
        `🔍 Ejemplo tooltip:`,
        this.translations.tooltips?.upload_image_file || "NO ENCONTRADO",
      );

      // Marcar traducciones como listas
      this.translationsReady = true;

      // Actualizar el system prompt para salas de chat grupales con la nueva traducción
      this.updateGroupChatSystemPrompt();

      // Actualizar toda la interfaz
      this.updateUI();

      // En Microsoft Edge, asegurar que los tooltips se actualicen después de que el DOM esté listo
      // Usar setTimeout con 0ms para permitir que el navegador procese los cambios del DOM
      setTimeout(() => {
        this.updateDataI18nElements();
      }, 0);

      // Asegurar múltiples actualizaciones para Edge con tiempos incrementales
      setTimeout(() => {
        this.updateDataI18nElements();
      }, 50);

      setTimeout(() => {
        this.updateDataI18nElements();
      }, 100);

      // Timeouts adicionales para Microsoft Edge con actualizaciones forzadas
      if (this.isEdgeBrowser) {
        setTimeout(() => {
          this.updateDataI18nElements();
          this.forceUpdateTooltipsForEdge();
        }, 200);

        setTimeout(() => {
          this.updateDataI18nElements();
          this.forceUpdateTooltipsForEdge();
        }, 500);

        setTimeout(() => {
          this.forceUpdateTooltipsForEdge();
        }, 1000);
      }

      // Forzar re-render del chat actual para actualizar tooltips
      if (this.currentChatId) {
        const chat = this.chats.find((c) => c.id === this.currentChatId);
        if (chat && chat.messages.length > 0) {
          console.log(
            `🔄 Re-renderizando chat ${this.currentChatId} después de cambio de idioma`,
          );
          this.renderMessages(chat);
        }
      }
    } else {
      console.error(`❌ Error crítico: No hay idiomas disponibles para cargar`);
      this.translations = {}; // Asegurar que translations esté definido aunque sea vacío
      this.translationsReady = false;
    }
  }

  /**
   * Actualiza el system prompt de salas de chat grupales cuando cambia el idioma
   */
  updateGroupChatSystemPrompt() {
    const defaultPrompt =
      this.t("settings.default_group_chat_system_prompt") || "";

    // Si el system prompt actual es el default del idioma anterior, actualizarlo
    // Solo actualizamos si está en la UI de settings abierta o si coincide con un default anterior
    if (defaultPrompt) {
      // Verificar si el modal de settings está abierto
      const settingsModal = document.getElementById("settings-modal");
      const groupChatSystemPromptEl = document.getElementById(
        "group-chat-system-prompt",
      );

      if (settingsModal && groupChatSystemPromptEl) {
        // Obtener el valor actual en el campo
        const currentValue = groupChatSystemPromptEl.value.trim();

        // Si el campo está vacío o tiene un default, actualizarlo
        if (!currentValue || this.isDefaultSystemPrompt(currentValue)) {
          this.settings.groupChatSystemPrompt = defaultPrompt;
          groupChatSystemPromptEl.value = defaultPrompt;
          console.log(
            `🔄 System prompt actualizado para idioma: ${this.currentLanguage}`,
          );
        }
      } else {
        // Si el modal no está abierto, verificar si el setting guardado es un default
        if (
          !this.settings.groupChatSystemPrompt ||
          this.isDefaultSystemPrompt(this.settings.groupChatSystemPrompt)
        ) {
          this.settings.groupChatSystemPrompt = defaultPrompt;
          console.log(
            `🔄 System prompt actualizado en settings para idioma: ${this.currentLanguage}`,
          );
        }
      }
    }
  }

  /**
   * Verifica si un system prompt es uno de los defaults (en cualquier idioma)
   */
  isDefaultSystemPrompt(prompt) {
    if (!prompt) return true;

    // Lista de patrones que identifican un system prompt default
    const defaultPatterns = [
      "SISTEMA:",
      "SYSTEM:",
      "SYSTÈME:",
      "سيستم:",
      "সিস্টেম:",
      "システム:",
      "시스템:",
      "सिस्टम:",
      "CHAT GRUPAL MULTI-MODELO",
      "MULTI-MODEL GROUP CHAT",
      "CHAT DE GROUPE MULTI-MODÈLE",
      "MULTI-MODELL-GRUPPENCHAT",
      "{{MODEL_NAME}}",
      "{{PARTICIPANT_LIST}}",
    ];

    // Si contiene alguno de estos patrones, probablemente es un default
    return defaultPatterns.some((pattern) => prompt.includes(pattern));
  }

  t(key, replacements = {}) {
    // Obtener traducción por clave (soporta notación de punto)
    const keys = key.split(".");
    let value = this.translations;

    // Verificar que translations esté inicializado y listo
    if (
      !this.translationsReady ||
      !this.translations ||
      typeof this.translations !== "object"
    ) {
      // Traducciones aún no están listas, usar fallback inmediatamente
      return this.getFallbackTranslation(key, replacements);
    }

    // Verificar que translations no esté vacío (Edge puede tener timing issues)
    if (Object.keys(this.translations).length === 0) {
      // Traducción aún no cargada, usar fallback inmediatamente sin warning
      return this.getFallbackTranslation(key, replacements);
    }

    for (const k of keys) {
      if (value && typeof value === "object") {
        value = value[k];
      } else {
        // La traducción no fue encontrada, intentar fallback
        console.warn(
          `⚠️ Traducción no encontrada: "${key}" en idioma "${this.currentLanguage}", usando fallback`,
        );
        return this.getFallbackTranslation(key, replacements);
      }
    }

    // Si value es undefined o no es string, intentar fallback
    if (value === undefined || typeof value !== "string") {
      console.warn(
        `⚠️ Traducción no encontrada: "${key}" en idioma "${this.currentLanguage}", usando fallback`,
      );
      return this.getFallbackTranslation(key, replacements);
    }

    // Reemplazar variables {variable}
    if (Object.keys(replacements).length > 0) {
      return value.replace(/\{(\w+)\}/g, (match, key) => {
        return replacements[key] !== undefined ? replacements[key] : match;
      });
    }

    return value;
  }

  getFallbackTranslation(key, replacements = {}) {
    // Intentar obtener traducción desde español como fallback
    const esLang = this.availableLanguages.find((l) => l.code === "es");
    if (esLang && esLang.data) {
      const keys = key.split(".");
      let value = esLang.data;

      for (const k of keys) {
        if (value && typeof value === "object") {
          value = value[k];
        } else {
          value = undefined;
          break;
        }
      }

      // Si encontramos la traducción en español, usarla
      if (value !== undefined && typeof value === "string") {
        // Reemplazar variables si es necesario
        if (Object.keys(replacements).length > 0) {
          return value.replace(/\{(\w+)\}/g, (match, key) => {
            return replacements[key] !== undefined ? replacements[key] : match;
          });
        }
        return value;
      }
    }

    // Si tampoco está en español, devolver la clave
    return key;
  }

  updateLanguageSelect() {
    const select = document.getElementById("language-select");
    if (!select) return;

    select.innerHTML = "";
    this.availableLanguages.forEach((lang) => {
      const option = document.createElement("option");
      option.value = lang.code;
      option.textContent = lang.name;
      if (lang.code === this.currentLanguage) {
        option.selected = true;
      }
      select.appendChild(option);
    });
  }

  updateUI() {
    // Actualizar todos los textos de la interfaz
    this.updateDataI18nElements();
    this.updateStaticTexts();
    this.updateButtons();
    this.updateModals();
    this.updatePlaceholders();
    // Actualizar el texto del estado actual sin notificar
    if (this.currentStatus) {
      this.updateStatusDisplay(this.currentStatus, true);
    }
    this.renderChatList();
    if (this.currentChatId) {
      const chat = this.chats.find((c) => c.id === this.currentChatId);
      if (chat) {
        this.renderMessages(chat);
      }
    }
  }

  updateDataI18nElements() {
    // Actualizar todos los elementos con data-i18n
    document.querySelectorAll("[data-i18n]").forEach((element) => {
      const key = element.getAttribute("data-i18n");
      const translation = this.t(key);

      // Si el elemento tiene innerHTML con HTML tags, usar innerHTML
      if (element.innerHTML.includes("<")) {
        element.innerHTML = translation;
      } else {
        element.textContent = translation;
      }
    });

    // Actualizar elementos con data-i18n-title (tooltips)
    document.querySelectorAll("[data-i18n-title]").forEach((element) => {
      const key = element.getAttribute("data-i18n-title");
      const translation = this.t(key);
      // Verificar que la traducción sea válida y no sea la misma clave
      if (translation && translation !== key && !translation.includes(".")) {
        // En Edge, forzar la eliminación y reinserción del atributo para asegurar actualización
        if (this.isEdgeBrowser) {
          element.removeAttribute("title");
          requestAnimationFrame(() => {
            element.setAttribute("title", translation);
            void element.offsetHeight;
          });
        } else {
          element.setAttribute("title", translation);
        }
      } else if (
        this.isEdgeBrowser &&
        (translation === key || !translation || translation.includes("."))
      ) {
        // En Microsoft Edge, si la traducción falló, intentar nuevamente
        setTimeout(() => {
          const retranslation = this.t(key);
          if (
            retranslation &&
            retranslation !== key &&
            !retranslation.includes(".")
          ) {
            element.removeAttribute("title");
            requestAnimationFrame(() => {
              element.setAttribute("title", retranslation);
              void element.offsetHeight;
            });
          }
        }, 100);
      }
    });

    // Actualizar elementos con data-i18n-placeholder (placeholders de input/textarea)
    document.querySelectorAll("[data-i18n-placeholder]").forEach((element) => {
      const key = element.getAttribute("data-i18n-placeholder");
      const translation = this.t(key);
      element.setAttribute("placeholder", translation);
    });

    // Actualizar elementos con data-i18n-template (requieren variables)
    document.querySelectorAll("[data-i18n-template]").forEach((element) => {
      const key = element.getAttribute("data-i18n-template");
      // Estos elementos se actualizan dinámicamente cuando se necesiten
      element.setAttribute("data-i18n-key", key);
    });
  }

  updateStaticTexts() {
    // Actualizar textos estáticos
    const elements = {
      "ai-connection-status": () =>
        `(${this.t(`status.${this.currentStatus}`)})`,
      "connection-text": () =>
        this.t(`status.${this.isConnected ? "connected" : "disconnected"}`),
    };

    Object.keys(elements).forEach((id) => {
      const el = document.getElementById(id);
      if (el) el.textContent = elements[id]();
    });
  }

  updateButtons() {
    // Los botones ahora se actualizan con data-i18n
    // Esta función se mantiene para compatibilidad pero ya no es necesaria
    // ya que updateDataI18nElements() maneja todos los elementos con data-i18n
  }

  updateModals() {
    // Actualizar títulos de modales
    const modalTitles = {
      "settings-modal": "settings.title",
      "export-modal": "export_import.export_title",
      "import-modal": "export_import.import_title",
      "delete-chat-modal": "delete_chat.title",
      "search-chat-modal": "search_chat.title",
      "info-modal": "info.title",
      "import-conflict-modal": "import_conflict.title",
      "import-summary-modal": "import_summary.title",
    };

    Object.keys(modalTitles).forEach((id) => {
      const modal = document.getElementById(id);
      if (modal) {
        const h3 = modal.querySelector(".modal-header h3");
        if (h3) h3.textContent = this.t(modalTitles[id]);
      }
    });

    // Actualizar contenidos específicos de modales
    this.updateSettingsModal();
    this.updateDeleteModal();
    this.updateSearchModal();
    this.updateExportImportModal();
  }

  updateSettingsModal() {
    // Los modales ahora se actualizan con data-i18n
    // Esta función se mantiene para compatibilidad
  }

  updateDeleteModal() {
    // Los modales ahora se actualizan con data-i18n
  }

  updateSearchModal() {
    const modal = document.getElementById("search-chat-modal");
    if (!modal) return;

    const input = modal.querySelector("#search-term-input");
    if (input) input.placeholder = this.t("search_chat.placeholder");
  }

  updateExportImportModal() {
    // Los modales ahora se actualizan con data-i18n
  }

  updatePlaceholders() {
    const input = document.getElementById("message-input");
    if (input) {
      input.placeholder = this.t("chat.message_placeholder");
    }

    const searchInput = document.getElementById("chat-search-input");
    if (searchInput) {
      searchInput.placeholder = this.t("chat.search_placeholder");
    }
  }

  // =================== FUNCIONES NUEVAS ===================
  updateStatusDisplay(status, skipNotification = false) {
    const statusIcon = document.getElementById("status-icon");
    const statusText = document.getElementById("ai-connection-status");

    // Verificar que los elementos existan
    if (!statusIcon || !statusText) {
      console.warn(
        "⚠️ Elementos del DOM no encontrados aún, intentando más tarde...",
      );
      // Intentar de nuevo después de que el DOM esté listo
      setTimeout(() => {
        const icon = document.getElementById("status-icon");
        const text = document.getElementById("ai-connection-status");
        if (icon && text) {
          icon.src = `assets/status/${status}.png`;
          text.textContent = `(${this.t(`status.${status}`)})`;
          console.log(`✅ Estado actualizado (reintento): ${status}`);
        }
      }, 100);
      return;
    }

    // Mapear el estado a la ruta del ícono
    const iconPath = `assets/status/${status}.png`;
    statusIcon.src = iconPath;

    // Actualizar el texto usando el sistema de traducción i18n
    statusText.textContent = `(${this.t(`status.${status}`)})`;

    // Guardar el estado anterior para comparar
    const previousStatus = this.currentStatus;
    this.currentStatus = status;
    localStorage.setItem("msnai-current-status", status);

    console.log(`🔄 Estado actualizado a: ${status}`);
    console.log(
      `   Guardado en localStorage: msnai-current-status = ${status}`,
    );

    // ===== NOTIFICAR A LA IA AUTOMÁTICAMENTE (SI ESTÁ ACTIVADO) =====
    // ✅ AÑADIR: No notificar si skipNotification es true (usado en init)
    if (
      !skipNotification &&
      this.currentChatId &&
      previousStatus !== status &&
      this.settings.notifyStatusChanges
    ) {
      this.notifyStatusChangeToAI(status, previousStatus);
    }
  }
  //------------------------------------------
  // =================== NUEVA FUNCIÓN: NOTIFICAR CAMBIO DE ESTADO ===================
  // =================== NUEVA FUNCIÓN: NOTIFICAR CAMBIO DE ESTADO ===================
  async notifyStatusChangeToAI(newStatus, oldStatus) {
    const chat = this.chats.find((c) => c.id === this.currentChatId);
    if (!chat) return;

    // Mensajes personalizados según el estado usando traducciones i18n
    const statusName = this.t(`status.${newStatus}`);
    const statusMessage =
      this.t(`messages.status_${newStatus}`) || this.t("messages.no_message");
    const userMessage = this.t("messages.status_changed", {
      status: statusName,
      message: statusMessage,
    });

    // Crear mensaje del usuario (sistema)
    const systemMessage = {
      type: "user",
      content: userMessage,
      timestamp: new Date().toISOString(),
      isSystem: true, // Marcador para distinguir mensajes automáticos
    };

    chat.messages.push(systemMessage);
    this.renderMessages(chat);
    this.saveChats();
    this.playSound("message-out");

    // Crear mensaje vacío para la respuesta de la IA
    const aiMessage = {
      type: "ai",
      content: "",
      timestamp: new Date().toISOString(),
    };
    chat.messages.push(aiMessage);
    this.renderMessages(chat);

    // Mostrar thinking solo si es el chat actual
    if (this.currentChatId === chat.id) {
      this.showAIThinking(true);
    }

    try {
      // Enviar contexto del cambio de estado a la IA
      const oldStatusName = this.t(`status.${oldStatus}`);
      const newStatusName = this.t(`status.${newStatus}`);
      const contextPrompt = `El usuario ha cambiado su estado de "${oldStatusName}" a "${newStatusName}". ${userMessage} Responde de manera breve y amigable reconociendo este cambio de estado.`;

      const onToken = (token) => {
        // Acumular en el sistema de respuestas
        this.accumulatedResponses[chat.id] += token;
        aiMessage.content = this.accumulatedResponses[chat.id];

        // Solo renderizar si es el chat actual, con sistema de buffering asíncrono
        if (this.currentChatId === chat.id) {
          this.scheduleStreamUpdate(chat);
        }
      };

      await this.sendToAI(contextPrompt, chat.id, onToken);

      // Limpiar recursos de streaming
      this.cleanupStreamResources(chat.id);

      // Render final optimizado del último mensaje
      if (this.currentChatId === chat.id) {
        this.updateFinalMessage(chat);
      }

      this.playSound("message-in");
    } catch (error) {
      console.error("Error notificando cambio de estado:", error);

      // No mostrar error si fue un abort intencional
      if (error.name === "AbortError") {
        if (aiMessage.content) {
          aiMessage.content += `\n\n[⏹️ ${this.t("chat.response_stopped")}]`;
        } else {
          const statusName = this.t(`status.${newStatus}`);
          aiMessage.content = `He notado tu cambio de estado a ${statusName}.`;
        }
      } else {
        const statusName = this.t(`status.${newStatus}`);
        aiMessage.content = `He notado tu cambio de estado a ${statusName}. ¿En qué puedo ayudarte?`;
      }

      // Limpiar recursos de streaming
      this.cleanupStreamResources(chat.id);

      if (this.currentChatId === chat.id) {
        this.renderMessages(chat);
      }
    } finally {
      // Verificar si fue abortado y añadir marcador SIEMPRE
      if (this.wasAborted) {
        if (aiMessage.content && !aiMessage.content.includes("[⏹️")) {
          aiMessage.content += `\n\n[⏹️ ${this.t("chat.response_stopped")}]`;
        } else if (!aiMessage.content) {
          aiMessage.content = `[⏹️ ${this.t("messages.nudge_stopped")}]`;
        }

        // Limpiar recursos de streaming
        this.cleanupStreamResources(chat.id);

        if (this.currentChatId === chat.id) {
          this.renderMessages(chat);
        }
        this.wasAborted = false;
      }

      this.saveChats();

      this.renderChatList();
    }
  }

  //----------------------------------------
  insertEmojiAtCursor(emoji) {
    const input = document.getElementById("message-input");
    if (input.disabled) return;
    const start = input.selectionStart;
    const end = input.selectionEnd;
    const text = input.value;
    input.value = text.slice(0, start) + emoji + text.slice(end);
    input.focus();
    input.setSelectionRange(start + emoji.length, start + emoji.length);
  }

  setupEmoticonPickers() {
    const naturalEmojis =
      "😊 😄 😁 🥰 😇 🤗 🥹 🥲 🤔 🤨 😏 😌 😅 😆 😂 🤣 😭 😢 😞 😟".split(" ");
    const amorEmojis =
      "❤️ 💖 💕 💞 💓 💗 💘 💙 💚 💛 💜 🤍 🤎 💔 💌 💓 💞".split(" ");

    const closeAllPickers = () => {
      document.getElementById("emoticon-natural-picker").style.display = "none";
      document.getElementById("emoticon-amor-picker").style.display = "none";
    };

    const createPicker = (id, emojis) => {
      const picker = document.getElementById(id);
      picker.innerHTML = "";
      emojis.forEach((e) => {
        const span = document.createElement("span");
        span.textContent = e;
        span.addEventListener("click", (event) => {
          event.stopPropagation();
          this.insertEmojiAtCursor(e);
          closeAllPickers();
        });
        picker.appendChild(span);
      });
    };
    createPicker("emoticon-natural-picker", naturalEmojis);
    createPicker("emoticon-amor-picker", amorEmojis);

    const showPicker = (btn, pickerId) => {
      const btnRect = btn.getBoundingClientRect();
      const picker = document.getElementById(pickerId);
      const isCurrentlyVisible = picker.style.display === "flex";

      // Cerrar todos los pickers primero
      closeAllPickers();

      // Si el picker actual no estaba visible, mostrarlo
      if (!isCurrentlyVisible) {
        picker.style.top = btnRect.bottom + "px";
        picker.style.left = btnRect.left + "px";
        picker.style.display = "flex";
      }
    };

    document
      .getElementById("emoticon-natural-btn")
      .addEventListener("click", (e) => {
        e.stopPropagation();
        showPicker(e.currentTarget, "emoticon-natural-picker");
      });
    document
      .getElementById("emoticon-amor-btn")
      .addEventListener("click", (e) => {
        e.stopPropagation();
        showPicker(e.currentTarget, "emoticon-amor-picker");
      });
    document.addEventListener("click", (e) => {
      if (
        !e.target.closest(".emoticon-picker") &&
        !e.target.closest("#emoticon-natural-btn") &&
        !e.target.closest("#emoticon-amor-btn")
      ) {
        closeAllPickers();
      }
    });
  }

  async sendNudge() {
    const chatPanel = document.getElementById("chat-panel");
    chatPanel.style.animation = "nudge 0.5s ease";
    setTimeout(() => (chatPanel.style.animation = ""), 500);
    this.playSound("nudge");

    const chat = this.chats.find((c) => c.id === this.currentChatId);
    if (!chat) return;

    const nudgeMsg = {
      type: "user",
      content: this.t("messages.nudge_sent"),
      timestamp: new Date().toISOString(),
    };
    chat.messages.push(nudgeMsg);
    this.renderMessages(chat);
    this.saveChats();

    // Crear mensaje de IA vacío para streaming
    const aiMessage = {
      type: "ai",
      content: "",
      timestamp: new Date().toISOString(),
    };
    chat.messages.push(aiMessage);
    this.renderMessages(chat);

    // Mostrar thinking solo si es el chat actual
    if (this.currentChatId === chat.id) {
      this.showAIThinking(true);
    }

    try {
      const onToken = (token) => {
        // Acumular en el sistema de respuestas
        this.accumulatedResponses[chat.id] += token;
        aiMessage.content = this.accumulatedResponses[chat.id];

        // Solo renderizar si es el chat actual, con sistema de buffering asíncrono
        if (this.currentChatId === chat.id) {
          this.scheduleStreamUpdate(chat);
        }
      };

      await this.sendToAI(this.t("messages.nudge_sent"), chat.id, onToken);

      // Limpiar recursos de streaming
      this.cleanupStreamResources(chat.id);

      // Render final optimizado del último mensaje
      if (this.currentChatId === chat.id) {
        this.updateFinalMessage(chat);
      }

      this.playSound("message-in");
    } catch (error) {
      console.error("Error enviando mensaje:", error);

      // No mostrar error si fue un abort intencional
      if (error.name === "AbortError") {
        if (aiMessage.content) {
          aiMessage.content += `\n\n[⏹️ ${this.t("chat.response_stopped")}]`;
        } else {
          aiMessage.content = this.t("chat.response_stopped_before");
        }
      } else {
        // Mostrar mensaje de error apropiado
        aiMessage.content = error.message;
      }

      // Limpiar recursos de streaming
      this.cleanupStreamResources(chat.id);

      if (this.currentChatId === chat.id) {
        this.renderMessages(chat);
      }
    } finally {
      // Verificar si fue abortado y añadir marcador SIEMPRE
      if (this.wasAborted) {
        if (aiMessage.content && !aiMessage.content.includes("[⏹️")) {
          aiMessage.content += `\n\n[⏹️ ${this.t("chat.response_stopped")}]`;
        } else if (!aiMessage.content) {
          aiMessage.content = `[⏹️ ${this.t("messages.nudge_stopped")}]`;
        }

        // Limpiar recursos de streaming
        this.cleanupStreamResources(chat.id);

        if (this.currentChatId === chat.id) {
          this.renderMessages(chat);
        }
        this.wasAborted = false;
      }

      this.saveChats();

      this.renderChatList();
    }
  }

  startVoiceInput() {
    // Si ya está grabando, detener
    if (this.isRecording) {
      this.stopVoiceInput();
      return;
    }

    if (
      !("SpeechRecognition" in window || "webkitSpeechRecognition" in window)
    ) {
      this.showNotification(
        this.t("errors.voice_not_supported") ||
          "Tu navegador no soporta reconocimiento de voz.",
        "error",
      );
      return;
    }

    // Verificar conectividad de red
    if (!navigator.onLine) {
      this.showNotification(
        this.t("errors.voice_requires_internet") ||
          "⚠️ El reconocimiento de voz requiere conexión a internet. Por favor, conéctate y vuelve a intentarlo.",
        "error",
      );
      return;
    }

    const voiceBtn = document.getElementById("texto-por-voz-btn");
    const input = document.getElementById("message-input");

    // Crear nueva instancia de reconocimiento
    this.voiceRecognition = new (window.SpeechRecognition ||
      window.webkitSpeechRecognition)();

    // Configurar reconocimiento
    this.voiceRecognition.lang =
      this.settings.language === "en" ? "en-US" : "es-ES";
    this.voiceRecognition.interimResults = true;
    this.voiceRecognition.continuous = true;
    this.voiceRecognition.maxAlternatives = 1;

    // Resetear flags
    this.voiceRecognitionError = false;
    this.voiceRecognitionStarted = false;

    // Marcar como grabando
    this.isRecording = true;

    // Cambiar apariencia del botón
    if (voiceBtn) {
      voiceBtn.style.backgroundColor = "#ff4444";
      voiceBtn.style.animation = "pulse-stop 1.5s ease-in-out infinite";
      voiceBtn.title = this.t("tooltips.voice_input_stop") || "Detener Dictado";
    }

    // Guardar posición inicial del cursor
    let interimText = "";

    this.voiceRecognition.onstart = () => {
      console.log("🎤 Reconocimiento de voz iniciado");
      this.voiceRecognitionStarted = true;
      this.playSound("nudge");
      this.showNotification(
        this.t("messages.voice_recording_started") ||
          "🎤 Grabando... Hable ahora",
        "info",
      );
    };

    this.voiceRecognition.onresult = (event) => {
      let finalTranscript = "";
      interimText = "";

      for (let i = event.resultIndex; i < event.results.length; i++) {
        const transcript = event.results[i][0].transcript;
        if (event.results[i].isFinal) {
          finalTranscript += transcript + " ";
        } else {
          interimText += transcript;
        }
      }

      if (finalTranscript) {
        // Agregar texto final al input
        const currentValue = input.value;
        input.value = currentValue + finalTranscript;
        input.focus();
      }

      // Mostrar feedback visual del texto provisional
      if (interimText && !finalTranscript) {
        console.log("🎤 Provisional:", interimText);
      }
    };

    this.voiceRecognition.onerror = (event) => {
      console.error("❌ Error en reconocimiento de voz:", event.error);

      // Marcar que hubo un error para evitar doble llamada en onend
      this.voiceRecognitionError = true;

      let errorMsg =
        this.t("errors.voice_error") || "Error en el reconocimiento de voz";

      if (event.error === "no-speech") {
        errorMsg =
          this.t("errors.voice_no_speech") ||
          "No se detectó ninguna voz. Intente nuevamente.";
      } else if (event.error === "audio-capture") {
        errorMsg =
          this.t("errors.voice_no_microphone") ||
          "No se pudo acceder al micrófono.";
      } else if (event.error === "not-allowed") {
        errorMsg =
          this.t("errors.voice_permission_denied") ||
          "Permiso de micrófono denegado.";
      } else if (event.error === "network") {
        errorMsg =
          this.t("errors.voice_network_connection") ||
          "⚠️ Error de conexión. El reconocimiento de voz requiere internet. Verifica tu conexión y vuelve a intentarlo.";
      } else if (event.error === "aborted") {
        // No mostrar error si fue abortado intencionalmente
        this.voiceRecognitionError = false;
        return;
      } else if (event.error === "service-not-allowed") {
        errorMsg =
          this.t("errors.voice_service_not_allowed") ||
          "Servicio de reconocimiento de voz no disponible.";
      }

      this.showNotification(errorMsg, "error");

      // Solo detener si realmente está grabando
      if (this.isRecording) {
        this.stopVoiceInput();
      }
    };

    this.voiceRecognition.onend = () => {
      console.log("🎤 Reconocimiento de voz finalizado");

      // Si hubo un error, ya se manejó en onerror, no hacer nada aquí
      if (this.voiceRecognitionError) {
        this.voiceRecognitionError = false;
        return;
      }

      // Si todavía está marcado como grabando, es porque terminó automáticamente
      if (this.isRecording) {
        this.playSound("nudge");
        this.showNotification(
          this.t("messages.voice_recording_stopped") || "🎤 Grabación detenida",
          "info",
        );
        this.stopVoiceInput();
      }
    };

    // Timeout de seguridad para detectar si no inicia
    const startTimeout = setTimeout(() => {
      if (this.isRecording && !this.voiceRecognitionStarted) {
        console.error("❌ Timeout: El reconocimiento no se inició");
        this.showNotification(
          this.t("errors.voice_start_timeout") ||
            "⚠️ No se pudo conectar al servicio de reconocimiento de voz. Verifica tu conexión a internet.",
          "error",
        );
        this.stopVoiceInput();
      }
    }, 5000);

    try {
      this.voiceRecognition.start();

      // Limpiar timeout si inicia correctamente
      this.voiceRecognition.addEventListener(
        "start",
        () => {
          clearTimeout(startTimeout);
        },
        { once: true },
      );
    } catch (error) {
      clearTimeout(startTimeout);
      console.error("❌ Error iniciando reconocimiento:", error);
      this.showNotification(
        this.t("errors.voice_start_error") ||
          "No se pudo iniciar el reconocimiento de voz",
        "error",
      );
      this.stopVoiceInput();
    }
  }

  stopVoiceInput() {
    if (!this.isRecording && !this.voiceRecognition) {
      return;
    }

    const voiceBtn = document.getElementById("texto-por-voz-btn");

    // Restaurar estado primero para evitar llamadas recursivas
    this.isRecording = false;

    // Detener reconocimiento si existe
    if (this.voiceRecognition) {
      try {
        this.voiceRecognition.stop();
      } catch (error) {
        console.error("Error deteniendo reconocimiento:", error);
      }
      this.voiceRecognition = null;
    }

    // Restaurar apariencia del botón
    if (voiceBtn) {
      voiceBtn.style.backgroundColor = "";
      voiceBtn.style.animation = "";
      voiceBtn.title = this.t("tooltips.voice_input") || "Dictado por voz";
    }

    // Resetear flags
    this.voiceRecognitionError = false;
    this.voiceRecognitionStarted = false;

    console.log("🎤 Reconocimiento de voz detenido");
  }

  increaseFontSize() {
    this.fontSize = Math.min(this.fontSize + 2, 32);
    document.getElementById("messages-area").style.fontSize =
      this.fontSize + "px";
  }

  decreaseFontSize() {
    this.fontSize = Math.max(this.fontSize - 2, 10);
    document.getElementById("messages-area").style.fontSize =
      this.fontSize + "px";
  }

  // =================== GESTIÓN DE ARCHIVOS ADJUNTOS CON INDEXEDDB ===================

  /**
   * Inicializa la base de datos IndexedDB para almacenar archivos adjuntos
   */
  async initAttachmentsDB() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open("msnai-attachments", 2);

      request.onerror = () => {
        console.error("❌ Error abriendo IndexedDB:", request.error);
        reject(request.error);
      };

      request.onsuccess = () => {
        this.db = request.result;
        console.log("✅ IndexedDB inicializada para archivos adjuntos");
        resolve();
      };

      request.onupgradeneeded = (event) => {
        const db = event.target.result;
        if (!db.objectStoreNames.contains("attachments")) {
          const objectStore = db.createObjectStore("attachments", {
            keyPath: "id",
          });
          objectStore.createIndex("chatId", "chatId", { unique: false });
          console.log("📦 Object store 'attachments' creado");
        }
        // Nuevo store para archivos binarios (PDF y TXT originales)
        if (!db.objectStoreNames.contains("fileAttachments")) {
          const fileStore = db.createObjectStore("fileAttachments", {
            keyPath: "key",
          });
          fileStore.createIndex("chatId", "chatId", { unique: false });
          console.log("📦 Object store 'fileAttachments' creado");
        }
      };
    });
  }

  /**
   * Guarda un archivo adjunto en IndexedDB
   * @param {Object} attachment - Objeto con datos del archivo
   */
  async saveAttachment(attachment) {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error("IndexedDB no inicializada"));
        return;
      }

      const transaction = this.db.transaction(["attachments"], "readwrite");
      const objectStore = transaction.objectStore("attachments");
      const request = objectStore.put(attachment);

      request.onsuccess = () => {
        console.log(`✅ Archivo guardado en IndexedDB: ${attachment.name}`);
        resolve();
      };

      request.onerror = () => {
        console.error(
          "❌ Error guardando archivo en IndexedDB:",
          request.error,
        );
        reject(request.error);
      };
    });
  }

  /**
   * Obtiene un archivo adjunto desde IndexedDB
   * @param {string} attachmentId - ID del archivo adjunto
   */
  async getAttachment(attachmentId) {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error("IndexedDB no inicializada"));
        return;
      }

      const transaction = this.db.transaction(["attachments"], "readonly");
      const objectStore = transaction.objectStore("attachments");
      const request = objectStore.get(attachmentId);

      request.onsuccess = () => {
        resolve(request.result);
      };

      request.onerror = () => {
        console.error(
          "❌ Error obteniendo archivo de IndexedDB:",
          request.error,
        );
        reject(request.error);
      };
    });
  }

  /**
   * Guarda un archivo binario en IndexedDB
   * @param {string} key - Clave única del archivo
   * @param {ArrayBuffer} data - Datos binarios del archivo
   * @param {string} type - Tipo MIME del archivo
   * @param {string} name - Nombre del archivo
   * @param {string} chatId - ID del chat
   */
  async saveFileAttachment(key, data, type, name, chatId) {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error("IndexedDB no inicializada"));
        return;
      }

      const transaction = this.db.transaction(["fileAttachments"], "readwrite");
      const objectStore = transaction.objectStore("fileAttachments");
      const request = objectStore.put({ key, data, type, name, chatId });

      request.onsuccess = () => {
        console.log(`✅ Archivo binario guardado en IndexedDB: ${name}`);
        resolve();
      };

      request.onerror = () => {
        console.error(
          "❌ Error guardando archivo binario en IndexedDB:",
          request.error,
        );
        reject(request.error);
      };
    });
  }

  /**
   * Obtiene un archivo binario desde IndexedDB
   * @param {string} key - Clave única del archivo
   */
  async getFileAttachment(key) {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error("IndexedDB no inicializada"));
        return;
      }

      const transaction = this.db.transaction(["fileAttachments"], "readonly");
      const objectStore = transaction.objectStore("fileAttachments");
      const request = objectStore.get(key);

      request.onsuccess = () => {
        resolve(request.result);
      };

      request.onerror = () => {
        console.error(
          "❌ Error obteniendo archivo binario de IndexedDB:",
          request.error,
        );
        reject(request.error);
      };
    });
  }

  /**
   * Elimina un archivo binario de IndexedDB
   * @param {string} key - Clave única del archivo
   */
  async deleteFileAttachment(key) {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error("IndexedDB no inicializada"));
        return;
      }

      const transaction = this.db.transaction(["fileAttachments"], "readwrite");
      const objectStore = transaction.objectStore("fileAttachments");
      const request = objectStore.delete(key);

      request.onsuccess = () => {
        console.log(`🗑️ Archivo binario eliminado de IndexedDB: ${key}`);
        resolve();
      };

      request.onerror = () => {
        console.error(
          "❌ Error eliminando archivo binario de IndexedDB:",
          request.error,
        );
        reject(request.error);
      };
    });
  }

  /**
   * Elimina un archivo adjunto de IndexedDB
   * @param {string} attachmentId - ID del archivo adjunto
   */
  async deleteAttachment(attachmentId) {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error("IndexedDB no inicializada"));
        return;
      }

      const transaction = this.db.transaction(["attachments"], "readwrite");
      const objectStore = transaction.objectStore("attachments");
      const request = objectStore.delete(attachmentId);

      request.onsuccess = () => {
        console.log(`🗑️ Archivo eliminado de IndexedDB: ${attachmentId}`);
        resolve();
      };

      request.onerror = () => {
        console.error(
          "❌ Error eliminando archivo de IndexedDB:",
          request.error,
        );
        reject(request.error);
      };
    });
  }

  /**
   * Elimina todos los archivos adjuntos de un chat
   * @param {string} chatId - ID del chat
   */
  async deleteAllChatAttachments(chatId) {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error("IndexedDB no inicializada"));
        return;
      }

      // Eliminar archivos de texto/contenido
      const transaction = this.db.transaction(["attachments"], "readwrite");
      const objectStore = transaction.objectStore("attachments");
      const index = objectStore.index("chatId");
      const request = index.openCursor(IDBKeyRange.only(chatId));

      request.onsuccess = (event) => {
        const cursor = event.target.result;
        if (cursor) {
          cursor.delete();
          cursor.continue();
        } else {
          console.log(`🗑️ Todos los archivos del chat ${chatId} eliminados`);

          // Eliminar archivos binarios
          this.deleteAllChatFileAttachments(chatId)
            .then(() => resolve())
            .catch((err) => {
              console.error("Error eliminando archivos binarios:", err);
              resolve(); // Continuar aunque falle
            });
        }
      };

      request.onerror = () => {
        console.error("❌ Error eliminando archivos del chat:", request.error);
        reject(request.error);
      };
    });
  }

  /**
   * Elimina todos los archivos binarios de un chat
   * @param {string} chatId - ID del chat
   */
  async deleteAllChatFileAttachments(chatId) {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error("IndexedDB no inicializada"));
        return;
      }

      const transaction = this.db.transaction(["fileAttachments"], "readwrite");
      const objectStore = transaction.objectStore("fileAttachments");
      const index = objectStore.index("chatId");
      const request = index.openCursor(IDBKeyRange.only(chatId));

      request.onsuccess = (event) => {
        const cursor = event.target.result;
        if (cursor) {
          cursor.delete();
          cursor.continue();
        } else {
          console.log(
            `🗑️ Todos los archivos binarios del chat ${chatId} eliminados`,
          );
          resolve();
        }
      };

      request.onerror = () => {
        console.error(
          "❌ Error eliminando archivos binarios del chat:",
          request.error,
        );
        reject(request.error);
      };
    });
  }

  // =================== CARGA DE ARCHIVOS DE TEXTO ===================

  uploadTextFile() {
    if (!this.currentChatId) {
      alert(
        this.t("errors.select_chat_first") ||
          "Por favor selecciona un chat primero",
      );
      return;
    }

    const input = document.createElement("input");
    input.type = "file";
    input.accept = ".txt,text/plain";
    input.onchange = async (e) => {
      const file = e.target.files[0];
      if (!file) return;
      if (!file.name.endsWith(".txt") && file.type !== "text/plain") {
        alert(this.t("errors.only_txt_files"));
        return;
      }

      // Validar tamaño (máximo 10 MB para archivos de texto)
      const maxSize = 10 * 1024 * 1024; // 10 MB en bytes
      if (file.size > maxSize) {
        this.showNotification(
          this.t("errors.text_file_too_large") ||
            "El archivo de texto es demasiado grande (máximo 10 MB)",
          "error",
        );
        return;
      }

      // Leer el archivo como texto
      const textReader = new FileReader();
      textReader.onload = async (ev) => {
        const content = ev.target.result;
        const inputEl = document.getElementById("message-input");

        // Fragmentar el contenido en chunks
        const chunks = this.chunkTextByTokens(content, 6000);

        // Crear clave para el archivo binario
        const fileKey = `txt-${this.currentChatId}-${Date.now()}`;

        // Leer el archivo como ArrayBuffer para guardarlo completo
        const binaryReader = new FileReader();
        binaryReader.onload = async (binaryEv) => {
          const arrayBuffer = binaryEv.target.result;

          // Crear objeto de attachment
          const attachmentId = `${this.currentChatId}_${Date.now()}_${file.name}`;
          const attachment = {
            id: attachmentId,
            chatId: this.currentChatId,
            name: file.name,
            type: "text/plain",
            size: file.size,
            content: content,
            chunks: chunks,
            uploadDate: new Date().toISOString(),
            fileAttachmentKey: fileKey, // Referencia al archivo binario
          };

          try {
            // Guardar archivo binario en IndexedDB
            await this.saveFileAttachment(
              fileKey,
              arrayBuffer,
              file.type || "text/plain",
              file.name,
              this.currentChatId,
            );

            // Guardar el attachment con el contenido de texto
            await this.saveAttachment(attachment);

            // Agregar a la lista de attachments del chat
            const chat = this.chats.find((c) => c.id === this.currentChatId);
            if (chat) {
              if (!chat.attachments) {
                chat.attachments = [];
              }
              chat.attachments.push({
                id: attachmentId,
                name: file.name,
                type: "text/plain",
                size: file.size,
                chunks: chunks.length,
                uploadDate: attachment.uploadDate,
                fileAttachmentKey: fileKey, // Guardar la referencia
              });
              this.saveChats();
            }

            // Establecer como pending para el próximo mensaje
            this.pendingFileAttachment = {
              name: file.name,
              content: content,
              chunks: chunks,
            };

            const currentMsg = inputEl.value.trim();
            inputEl.value = `${currentMsg ? currentMsg + " " : ""}[Archivo adjunto: ${file.name}]`;
            inputEl.focus();

            // Renderizar el chat para mostrar el attachment
            this.renderMessages(chat);

            console.log(`📎 Archivo TXT adjuntado al chat: ${file.name}`);
          } catch (error) {
            console.error("Error guardando archivo adjunto:", error);
            alert(
              this.t("errors.attachment_save_failed") ||
                "Error al guardar el archivo adjunto",
            );
          }
        };
        binaryReader.readAsArrayBuffer(file);
      };
      textReader.readAsText(file);
    };
    input.click();
  }

  // =================== CARGA Y PROCESAMIENTO DE ARCHIVOS PDF ===================

  /**
   * Abre diálogo para cargar archivo PDF y lo procesa
   */
  uploadPdfFile() {
    if (!this.currentChatId) {
      alert(
        this.t("errors.select_chat_first") ||
          "Por favor selecciona un chat primero",
      );
      return;
    }

    const input = document.createElement("input");
    input.type = "file";
    input.accept = ".pdf,application/pdf";
    input.onchange = async (e) => {
      const file = e.target.files[0];
      if (!file) return;

      // Validar tipo de archivo
      if (
        !file.name.toLowerCase().endsWith(".pdf") &&
        file.type !== "application/pdf"
      ) {
        this.showNotification(this.t("errors.only_pdf_files"), "error");
        return;
      }

      // Validar tamaño (máximo 25 MB)
      const maxSize = 25 * 1024 * 1024; // 25 MB en bytes
      if (file.size > maxSize) {
        this.showNotification(this.t("errors.pdf_too_large"), "error");
        return;
      }

      // Mostrar indicador de procesamiento
      this.showNotification(this.t("errors.pdf_processing"), "info");

      try {
        const pdfData = await this.processPdfFile(file);

        if (!pdfData.text || pdfData.text.trim().length === 0) {
          this.showNotification(this.t("errors.pdf_no_text"), "error");
          return;
        }

        // Crear clave para el archivo binario
        const fileKey = `pdf-${this.currentChatId}-${Date.now()}`;

        // Leer el archivo como ArrayBuffer para guardarlo completo
        const reader = new FileReader();
        reader.onload = async (ev) => {
          const arrayBuffer = ev.target.result;

          // Crear objeto de attachment persistente
          const attachmentId = `${this.currentChatId}_${Date.now()}_${file.name}`;
          const attachment = {
            id: attachmentId,
            chatId: this.currentChatId,
            name: file.name,
            type: "application/pdf",
            size: file.size,
            content: pdfData.text,
            pages: pdfData.numPages,
            chunks: this.chunkTextByTokens(pdfData.text, 6000),
            uploadDate: new Date().toISOString(),
            fileAttachmentKey: fileKey, // Referencia al archivo binario
          };

          try {
            // Guardar archivo binario en IndexedDB
            await this.saveFileAttachment(
              fileKey,
              arrayBuffer,
              file.type || "application/pdf",
              file.name,
              this.currentChatId,
            );

            // Guardar el attachment con el contenido de texto extraído
            await this.saveAttachment(attachment);

            // Agregar a la lista de attachments del chat
            const chat = this.chats.find((c) => c.id === this.currentChatId);
            if (chat) {
              if (!chat.attachments) {
                chat.attachments = [];
              }
              chat.attachments.push({
                id: attachmentId,
                name: file.name,
                type: "application/pdf",
                size: file.size,
                pages: pdfData.numPages,
                uploadDate: attachment.uploadDate,
                fileAttachmentKey: fileKey, // Guardar la referencia
              });
              this.saveChats();
            }

            // Guardar contexto PDF temporalmente para el próximo mensaje
            this.pendingPdfContext = {
              name: file.name,
              text: pdfData.text,
              pages: pdfData.numPages,
              chunks: attachment.chunks,
            };

            // Actualizar input con indicador visual
            const inputEl = document.getElementById("message-input");
            const currentMsg = inputEl.value.trim();
            inputEl.value = `${currentMsg ? currentMsg + " " : ""}[PDF: ${file.name} - ${pdfData.numPages} ${this.t("pdf.pages")}]`;
            inputEl.focus();

            // Renderizar el chat para mostrar el attachment
            this.renderMessages(chat);

            this.showNotification(
              this.t("errors.pdf_loaded", { filename: file.name }),
              "success",
            );

            console.log(`📎 Archivo PDF adjuntado al chat: ${file.name}`);
          } catch (saveError) {
            console.error("Error guardando archivo adjunto:", saveError);
            this.showNotification(
              this.t("errors.attachment_save_failed") ||
                "Error al guardar el archivo adjunto",
              "error",
            );
          }
        };
        reader.readAsArrayBuffer(file);
      } catch (error) {
        console.error("Error procesando PDF:", error);
        this.showNotification(
          this.t("errors.pdf_error", { error: error.message }),
          "error",
        );
      }
    };
    input.click();
  }

  /**
   * Procesa un archivo PDF y extrae el texto
   * @param {File} file - Archivo PDF
   * @returns {Promise<{text: string, numPages: number}>}
   */
  async processPdfFile(file) {
    // Configurar PDF.js worker
    if (typeof pdfjsLib !== "undefined") {
      pdfjsLib.GlobalWorkerOptions.workerSrc =
        "https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.worker.min.js";
    }

    const arrayBuffer = await file.arrayBuffer();
    let extractedText = "";
    let numPages = 0;

    try {
      // Intentar extraer texto con PDF.js (para PDFs con texto real)
      const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;
      numPages = pdf.numPages;

      this.showNotification(this.t("errors.pdf_extracting_text"), "info");

      for (let i = 1; i <= numPages; i++) {
        const page = await pdf.getPage(i);
        const textContent = await page.getTextContent();
        const pageText = textContent.items.map((item) => item.str).join(" ");
        extractedText += pageText + "\n\n";
      }

      // Si no se extrajo suficiente texto, intentar OCR
      if (extractedText.trim().length < 100) {
        console.log("Poco texto extraído, aplicando OCR...");
        extractedText = await this.applyOcrToPdf(arrayBuffer, numPages);
      }
    } catch (error) {
      console.error("Error con PDF.js, intentando OCR:", error);
      // Si falla PDF.js, intentar OCR directamente
      try {
        const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;
        numPages = pdf.numPages;
        extractedText = await this.applyOcrToPdf(arrayBuffer, numPages);
      } catch (ocrError) {
        throw new Error(this.t("pdf.invalid_file"));
      }
    }

    return {
      text: extractedText.trim(),
      numPages: numPages,
    };
  }

  /**
   * Aplica OCR a un PDF escaneado
   * @param {ArrayBuffer} arrayBuffer - Datos del PDF
   * @param {number} numPages - Número de páginas
   * @returns {Promise<string>}
   */
  async applyOcrToPdf(arrayBuffer, numPages) {
    if (typeof Tesseract === "undefined") {
      throw new Error("Tesseract.js no está disponible");
    }

    const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;
    let ocrText = "";

    for (let i = 1; i <= numPages; i++) {
      this.showNotification(
        this.t("errors.pdf_ocr_processing") + ` (${i}/${numPages})`,
        "info",
      );

      const page = await pdf.getPage(i);
      const viewport = page.getViewport({ scale: 2.0 });

      // Crear canvas para renderizar la página
      const canvas = document.createElement("canvas");
      const context = canvas.getContext("2d");
      canvas.width = viewport.width;
      canvas.height = viewport.height;

      await page.render({
        canvasContext: context,
        viewport: viewport,
      }).promise;

      // Aplicar OCR a la imagen del canvas
      const {
        data: { text },
      } = await Tesseract.recognize(
        canvas.toDataURL(),
        "spa+eng", // Español e inglés
        {
          logger: (info) => {
            if (info.status === "recognizing text") {
              console.log(
                `OCR página ${i}: ${Math.round(info.progress * 100)}%`,
              );
            }
          },
        },
      );

      ocrText += text + "\n\n";
    }

    return ocrText;
  }

  // =================== CARGA Y PROCESAMIENTO DE ARCHIVOS DE IMAGEN ===================

  /**
   * Abre diálogo para cargar archivo de imagen y lo procesa
   * @param {File} fileParam - Archivo opcional a procesar (para soporte de paste)
   */
  async uploadImageFile(fileParam = null) {
    if (!this.currentChatId) {
      alert(
        this.t("errors.select_chat_first") ||
          "Por favor selecciona un chat primero",
      );
      return;
    }

    // Si se proporciona un archivo directamente, procesarlo
    if (fileParam) {
      await this.processImageFile(fileParam);
      return;
    }

    // Si no hay archivo, abrir el diálogo de selección
    const input = document.createElement("input");
    input.type = "file";
    input.accept = "image/jpeg,image/jpg,image/png,image/gif,image/webp";
    input.onchange = async (e) => {
      const file = e.target.files[0];
      if (!file) return;
      await this.processImageFile(file);
    };
    input.click();
  }

  /**
   * Procesa un archivo de imagen (usado tanto para upload como para paste)
   * @param {File} file - Archivo de imagen a procesar
   */
  async processImageFile(file) {
    // Validar tipo de archivo
    const validTypes = [
      "image/jpeg",
      "image/jpg",
      "image/png",
      "image/gif",
      "image/webp",
    ];
    if (
      !validTypes.includes(file.type) &&
      !file.name.match(/\.(jpg|jpeg|png|gif|webp)$/i)
    ) {
      this.showNotification(this.t("errors.only_image_files"), "error");
      return;
    }

    // Validar tamaño (máximo 20 MB)
    const maxSize = 20 * 1024 * 1024; // 20 MB en bytes
    if (file.size > maxSize) {
      this.showNotification(this.t("errors.image_too_large"), "error");
      return;
    }

    // Mostrar indicador de procesamiento con traducción validada
    let processingMsg = this.t("messages.image_processing");
    if (
      !processingMsg ||
      processingMsg.includes("messages.") ||
      processingMsg === "messages.image_processing"
    ) {
      processingMsg = "Procesando imagen...";
    }
    this.showNotification(processingMsg, "info");

    try {
      // Convertir imagen a base64
      const base64Image = await this.convertImageToBase64(file);

      // Crear clave para el archivo binario
      const fileKey = `img-${this.currentChatId}-${Date.now()}`;

      // Leer el archivo como ArrayBuffer para guardarlo completo
      const reader = new FileReader();
      reader.onload = async (ev) => {
        const arrayBuffer = ev.target.result;

        // Crear objeto de attachment persistente
        const attachmentId = `${this.currentChatId}_${Date.now()}_${file.name}`;
        const attachment = {
          id: attachmentId,
          chatId: this.currentChatId,
          name: file.name,
          type: file.type,
          size: file.size,
          base64Data: base64Image, // Base64 puro sin prefijo
          uploadDate: new Date().toISOString(),
          fileAttachmentKey: fileKey,
        };

        try {
          // Guardar archivo binario en IndexedDB
          await this.saveFileAttachment(
            fileKey,
            arrayBuffer,
            file.type,
            file.name,
            this.currentChatId,
          );

          // Guardar el attachment con los datos base64
          await this.saveAttachment(attachment);

          // Agregar a la lista de attachments del chat
          const chat = this.chats.find((c) => c.id === this.currentChatId);
          if (chat) {
            if (!chat.attachments) {
              chat.attachments = [];
            }
            chat.attachments.push({
              id: attachmentId,
              name: file.name,
              type: file.type,
              size: file.size,
              uploadDate: attachment.uploadDate,
              fileAttachmentKey: fileKey,
            });
            this.saveChats();
          }

          // Guardar contexto de imagen temporalmente para el próximo mensaje
          this.pendingImageContext = {
            name: file.name,
            type: file.type,
            base64Data: base64Image,
          };

          // Actualizar input con indicador visual
          const inputEl = document.getElementById("message-input");
          const currentMsg = inputEl.value.trim();
          let attachedMsg = this.t("messages.image_attached");
          if (!attachedMsg || attachedMsg.includes("messages.")) {
            attachedMsg = "Imagen adjunta";
          }
          inputEl.value = `${currentMsg ? currentMsg + " " : ""}[${attachedMsg}: ${file.name}]`;
          inputEl.focus();

          // Renderizar el chat para mostrar el attachment
          this.renderMessages(chat);

          // Mostrar notificación de éxito con traducción validada
          let loadedMsg = this.t("messages.image_loaded", {
            filename: file.name,
          });
          if (
            !loadedMsg ||
            loadedMsg.includes("messages.") ||
            loadedMsg.includes("{filename}")
          ) {
            loadedMsg = `Imagen cargada: ${file.name}`;
          }
          this.showNotification(loadedMsg, "success");

          console.log(`📎 Archivo de imagen adjuntado al chat: ${file.name}`);
        } catch (saveError) {
          console.error("Error guardando archivo adjunto:", saveError);
          this.showNotification(
            this.t("errors.attachment_save_failed") ||
              "Error al guardar el archivo adjunto",
            "error",
          );
        }
      };
      reader.readAsArrayBuffer(file);
    } catch (error) {
      console.error("Error procesando imagen:", error);
      this.showNotification(
        this.t("errors.image_error", { error: error.message }),
        "error",
      );
    }
  }

  /**
   * Convierte una imagen a base64
   * @param {File} file - Archivo de imagen
   * @returns {Promise<string>}
   */
  async convertImageToBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        // Extraer solo la parte base64 (sin el prefijo data:image/...)
        // Ollama requiere base64 puro, sin prefijo
        const base64String = e.target.result.split(",")[1];
        resolve(base64String);
      };
      reader.onerror = (error) => reject(error);
      reader.readAsDataURL(file);
    });
  }

  /**
   * Fragmenta texto en chunks basados en tokens estimados
   * @param {string} text - Texto completo a fragmentar
   * @param {number} maxTokens - Máximo de tokens por chunk (aproximado)
   * @returns {Array<string>}
   */
  chunkTextByTokens(text, maxTokens = 6000) {
    // Estimación: 1 token ≈ 4 caracteres
    const maxChars = maxTokens * 4;

    // Intentar dividir por párrafos (doble salto de línea)
    let paragraphs = text.split(/\n\n+/).filter((p) => p.trim());

    // Si no hay párrafos separados por doble salto, usar saltos de línea simples
    if (paragraphs.length === 1) {
      paragraphs = text.split(/\n/).filter((p) => p.trim());
    }

    // Si tampoco hay saltos de línea, dividir por oraciones
    if (paragraphs.length === 1 && text.length > maxChars) {
      paragraphs = text.split(/\. /).filter((p) => p.trim());
    }

    const chunks = [];
    let currentChunk = "";

    for (const paragraph of paragraphs) {
      const separator = text.includes("\n\n")
        ? "\n\n"
        : text.includes("\n")
          ? "\n"
          : ". ";

      if ((currentChunk + paragraph).length > maxChars && currentChunk) {
        chunks.push(currentChunk.trim());
        currentChunk = paragraph;
      } else {
        currentChunk += (currentChunk ? separator : "") + paragraph;
      }
    }

    if (currentChunk) {
      chunks.push(currentChunk.trim());
    }

    return chunks.length > 0 ? chunks : [text];
  }

  setupTextFormatPicker() {
    const picker = document.getElementById("text-format-picker");
    const btn = document.getElementById("editor-texto-btn");
    const showPicker = () => {
      const rect = btn.getBoundingClientRect();
      picker.style.top = rect.bottom + "px";
      picker.style.left = rect.left + "px";
      picker.style.display = "flex";
    };
    btn.addEventListener("click", showPicker);
    picker.querySelectorAll("span").forEach((span) => {
      span.addEventListener("click", () => {
        const action = span.textContent;
        const input = document.getElementById("message-input");
        const start = input.selectionStart;
        const end = input.selectionEnd;
        const selected = input.value.substring(start, end);
        if (!selected) {
          alert(this.t("errors.select_text_to_format"));
          return;
        }
        let wrapped = selected;
        if (action === "N") wrapped = `**${selected}**`;
        else if (action === "C") wrapped = `*${selected}*`;
        else if (action === "S") wrapped = `__${selected}__`;
        input.value =
          input.value.substring(0, start) +
          wrapped +
          input.value.substring(end);
        input.focus();
        input.setSelectionRange(start, start + wrapped.length);
        picker.style.display = "none";
      });
    });
    document.addEventListener("click", (e) => {
      if (
        !e.target.closest("#text-format-picker") &&
        e.target.id !== "editor-texto-btn"
      ) {
        picker.style.display = "none";
      }
    });
  }
  orderChatHistory() {
    // Determinar el estado actual del orden
    const isAscending = this.chatSortOrder === "asc";
    this.chatSortOrder = isAscending ? "desc" : "asc";

    // Ordenar solo por título (chat.title), ignorando búsqueda
    this.chats.sort((a, b) => {
      const titleA = a.title.trim().toLowerCase();
      const titleB = b.title.trim().toLowerCase();
      if (this.chatSortOrder === "asc") {
        return titleA.localeCompare(titleB);
      } else {
        return titleB.localeCompare(titleA);
      }
    });

    this.saveChats();
    this.renderChatList();
    if (this.currentChatId) {
      this.selectChat(this.currentChatId);
    }
  }
  async exportSelectedChats() {
    const selectedChats = this.chats.filter((chat) => chat.selected);

    if (selectedChats.length === 0) {
      alert(this.t("export_import.no_selected"));
      return;
    }

    try {
      // Verificar estado de IndexedDB
      if (!this.db) {
        console.warn(
          "⚠️ IndexedDB no está inicializada, esperando inicialización...",
        );
        await this.initAttachmentsDB();
      }

      // Obtener todos los attachments de IndexedDB
      const allAttachments = await this.getAllAttachments();

      // Filtrar solo los attachments de los chats seleccionados
      const selectedChatIds = new Set(selectedChats.map((c) => c.id));
      const selectedAttachments = allAttachments.filter((att) =>
        selectedChatIds.has(att.chatId),
      );

      console.log(
        `📤 Exportando ${selectedChats.length} chats con ${selectedAttachments.length} archivos adjuntos`,
      );

      if (selectedAttachments.length > 0) {
        console.log(
          "📦 Primeros 3 attachments:",
          selectedAttachments.slice(0, 3).map((a) => ({
            id: a.id,
            name: a.name,
            type: a.type,
            hasContent: !!a.content,
            contentLength: a.content ? a.content.length : 0,
          })),
        );
      }

      // Obtener todos los archivos binarios y filtrar los de chats seleccionados
      const allFileAttachments = await this.getAllFileAttachments();
      const selectedFileAttachments = allFileAttachments.filter((file) =>
        selectedChatIds.has(file.chatId),
      );

      console.log(
        `📤 Exportando ${selectedFileAttachments.length} archivos binarios`,
      );

      // Convertir ArrayBuffers a Base64 para incluirlos en JSON
      const fileAttachmentsBase64 = selectedFileAttachments.map((file) => ({
        key: file.key,
        data: this.arrayBufferToBase64(file.data),
        type: file.type,
        name: file.name,
        chatId: file.chatId,
      }));

      const data = {
        version: "2.1",
        exportDate: new Date().toISOString(),
        chats: selectedChats,
        attachments: selectedAttachments,
        fileAttachments: fileAttachmentsBase64,
      };

      console.log(
        `📦 Tamaño total del JSON: ${JSON.stringify(data).length} caracteres`,
      );

      const blob = new Blob([JSON.stringify(data, null, 2)], {
        type: "application/json",
      });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `msn-ai-selected-chats-${new Date().toISOString().split("T")[0]}.json`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      this.playSound("nudge");

      console.log("✅ Exportación selectiva completada exitosamente");
    } catch (error) {
      console.error("❌ Error exportando chats seleccionados:", error);
      alert(
        this.t("errors.export_failed") ||
          "Error al exportar chats seleccionados",
      );
    }
  }

  exportCurrentChat() {
    const chat = this.chats.find((c) => c.id === this.currentChatId);
    if (!chat) return;

    // Agregar encabezado con información de la sala si es una sala de expertos
    let header = "";
    if (chat.isExpertRoom) {
      header = `=== ${chat.title} ===\n`;
      header += `Participantes: ${chat.models.join(", ")}\n`;
      header += `Fecha: ${new Date(chat.date).toLocaleString()}\n`;
      header += `${"=".repeat(50)}\n\n`;
    }

    const content = chat.messages
      .map((m) => {
        const sender =
          m.type === "user"
            ? "Tú"
            : chat.isExpertRoom && m.model
              ? `IA (${m.model})`
              : "IA";
        return `${sender}: ${m.content}`;
      })
      .join("\n");

    const blob = new Blob([header + content], { type: "text/plain" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `chat-${chat.title.replace(/\s+/g, "_")}.txt`;
    a.click();
    URL.revokeObjectURL(url);
  }

  printCurrentChat() {
    const chat = this.chats.find((c) => c.id === this.currentChatId);
    if (!chat) return;

    // Agregar encabezado con información de la sala si es una sala de expertos
    let header = "";
    if (chat.isExpertRoom) {
      header = `<div style="border-bottom:2px solid #333;padding-bottom:10px;margin-bottom:20px;">
        <h2>${chat.title}</h2>
        <p><strong>Participantes:</strong> ${chat.models.join(", ")}</p>
        <p><strong>Fecha:</strong> ${new Date(chat.date).toLocaleString()}</p>
      </div>`;
    }

    const messagesHTML = chat.messages
      .map((m) => {
        const sender =
          m.type === "user"
            ? "Tú"
            : chat.isExpertRoom && m.model
              ? `IA (${m.model})`
              : "IA";
        return `${sender}: ${m.content}`;
      })
      .join("\n");

    const printContent = `<html><head><title>Chat</title><style>body{font-family:Tahoma;font-size:9pt;}pre{white-space:pre-wrap;word-wrap:break-word;}</style></head><body>${header}<pre>${messagesHTML}</pre></body></html>`;
    const win = window.open("", "", "width=800,height=600");
    win.document.write(printContent);
    win.document.close();
    win.focus();
    win.print();
    win.close();
  }

  openSearchModal() {
    document.getElementById("search-chat-modal").style.display = "block";
    document.getElementById("search-term-input").focus();
  }

  highlightSearchResults(term) {
    const messagesArea = document.getElementById("messages-area");
    const originalHTML = messagesArea.innerHTML;
    if (!term) {
      messagesArea.innerHTML = originalHTML;
      return;
    }
    const regex = new RegExp(
      `(${term.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")})`,
      "gi",
    );
    messagesArea.innerHTML = originalHTML.replace(
      regex,
      '<mark style="background:#ffeb3b;color:#000;">$1</mark>',
    );
  }

  closeCurrentChat() {
    if (confirm(this.t("errors.close_chat_confirm"))) {
      this.createNewChat();
    }
  }

  showInfo() {
    document.getElementById("info-modal").style.display = "block";
  }

  /**
   * Muestra una notificación temporal al usuario
   * @param {string} message - Mensaje a mostrar
   * @param {string} type - Tipo de notificación: 'info', 'success', 'error'
   */
  showNotification(message, type = "info") {
    // Si el mensaje parece ser una clave de traducción sin traducir (contiene puntos y no espacios),
    // intentar traducirlo
    if (message && message.includes(".") && !message.includes(" ")) {
      let translated = this.t(message);
      // En Edge, asegurarse de que la traducción sea válida antes de usarla
      if (translated && translated !== message && !translated.includes(".")) {
        message = translated;
      } else {
        // Si la traducción falló, usar un mensaje por defecto si es un error conocido
        console.warn(`⚠️ Traducción no disponible para: ${message}`);
        // Intentar mostrar un mensaje por defecto si es un error conocido
        if (message === "errors.model_no_image_support") {
          message =
            "El modelo de IA seleccionado no soporta el procesamiento de imágenes";
        } else if (message === "messages.image_processing") {
          message = "Procesando imagen...";
        } else if (message.includes("messages.image_loaded")) {
          message = "Imagen cargada correctamente";
        }
      }
    }

    // Crear elemento de notificación si no existe
    let notification = document.getElementById("app-notification");
    if (!notification) {
      notification = document.createElement("div");
      notification.id = "app-notification";
      notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 12px 20px;
        border-radius: 4px;
        font-size: 8pt;
        font-family: Tahoma, sans-serif;
        z-index: 10000;
        box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        transition: opacity 0.3s ease;
        max-width: 300px;
      `;
      document.body.appendChild(notification);
    }

    // Establecer estilo según tipo
    const colors = {
      info: { bg: "#2196F3", color: "#fff" },
      success: { bg: "#4CAF50", color: "#fff" },
      error: { bg: "#f44336", color: "#fff" },
    };
    const style = colors[type] || colors.info;
    notification.style.backgroundColor = style.bg;
    notification.style.color = style.color;
    notification.textContent = message;
    notification.style.display = "block";
    notification.style.opacity = "1";

    // Ocultar después de 3 segundos
    setTimeout(() => {
      notification.style.opacity = "0";
      setTimeout(() => {
        notification.style.display = "none";
      }, 300);
    }, 3000);
  }

  // =================== ENVÍO DE MENSAJE CON ARCHIVO ===================

  async sendMessage() {
    const input = document.getElementById("message-input");
    const message = input.value.trim();
    if (!message || !this.currentChatId) return;
    const chat = this.chats.find((c) => c.id === this.currentChatId);
    if (!chat) return;

    let displayedMessage = message;
    let fileContent = "";
    let pdfContext = null;
    let imageContext = null;

    // Manejar archivo de texto adjunto
    if (this.pendingFileAttachment) {
      const match = message.match(/^(.*?)\s*\[Archivo adjunto: [^\]]+\]$/);
      if (match) {
        displayedMessage = match[1] || "";
      }
      fileContent = this.pendingFileAttachment.content;
    }

    // Manejar contexto PDF (no se guarda en historial)
    if (this.pendingPdfContext) {
      const pdfMatch = message.match(/^(.*?)\s*\[PDF: [^\]]+\]$/);
      if (pdfMatch) {
        displayedMessage = pdfMatch[1] || "";
      }
      pdfContext = this.pendingPdfContext;
    }

    // Manejar contexto de imagen (no se guarda en historial)
    if (this.pendingImageContext) {
      const imageMatch = message.match(/^(.*?)\s*\[.+?: [^\]]+\]$/);
      if (imageMatch) {
        displayedMessage = imageMatch[1] || "";
      }
      imageContext = this.pendingImageContext;
    }

    input.value = "";
    const originalAttachment = this.pendingFileAttachment;
    this.pendingFileAttachment = null;
    this.pendingPdfContext = null;
    this.pendingImageContext = null;

    const userMessage = {
      type: "user",
      content: message,
      timestamp: new Date().toISOString(),
    };
    chat.messages.push(userMessage);
    chat.title = this.generateChatTitle(chat);
    this.renderMessages(chat);
    this.playSound("message-out");

    const aiMessage = {
      type: "ai",
      content: "",
      timestamp: new Date().toISOString(),
    };
    chat.messages.push(aiMessage);
    this.renderMessages(chat);

    // Mostrar thinking solo si es el chat actual
    if (this.currentChatId === chat.id) {
      this.showAIThinking(true);
    }

    try {
      let actualMessageToSend = displayedMessage;

      // Construir mensaje con archivo de texto si existe
      if (fileContent) {
        // IMPORTANTE: Enviar el contenido COMPLETO del archivo
        // Anteriormente se limitaba a solo 3 chunks (~72KB), causando pérdida de información
        // El rate limiter (20 req/min, 1000ms intervalo, máx 2 concurrentes) gestiona
        // automáticamente el flujo para evitar errores 429 incluso con archivos grandes
        let textContent = fileContent;

        // Advertencia si el archivo es muy grande
        if (textContent.length > 50000) {
          console.warn(
            `⚠️ [SendMessage] Enviando archivo grande (${Math.round(textContent.length / 1000)}KB). Esto puede aumentar el tiempo de respuesta.`,
          );
        }

        actualMessageToSend = `[Archivo: ${originalAttachment.name}]\n${textContent}\n\nMensaje del usuario: ${displayedMessage || "(sin mensaje adicional)"}`;
      }

      // Construir contexto con PDF si existe (se pasa por separado)
      let pdfContextText = null;
      if (pdfContext) {
        // IMPORTANTE: Enviar el contenido COMPLETO del PDF
        // Anteriormente se limitaba a solo 3 chunks, causando pérdida de información
        // El rate limiter gestiona automáticamente el flujo para evitar errores 429

        // Advertencia si el PDF es muy grande
        if (pdfContext.text.length > 50000) {
          console.warn(
            `⚠️ [SendMessage] Enviando PDF grande (${Math.round(pdfContext.text.length / 1000)}KB, ${pdfContext.pages} páginas). Esto puede aumentar el tiempo de respuesta.`,
          );
        }

        pdfContextText = `[Contexto PDF: ${pdfContext.name} - ${pdfContext.pages} páginas]\n\n${pdfContext.text}`;
      }

      const onToken = (token) => {
        // Acumular en el sistema de respuestas
        this.accumulatedResponses[chat.id] += token;
        aiMessage.content = this.accumulatedResponses[chat.id];

        // Solo renderizar si es el chat actual, con sistema de buffering asíncrono
        if (this.currentChatId === chat.id) {
          this.scheduleStreamUpdate(chat);
        }
      };

      console.log(
        `📤 [SendMessage] Enviando mensaje a IA para chat ${chat.id}`,
      );
      const sendStart = performance.now();

      const response = await this.sendToAI(
        actualMessageToSend,
        chat.id,
        onToken,
        pdfContextText,
        imageContext,
      );

      const sendTime = performance.now() - sendStart;
      console.log(
        `✅ [SendMessage] Respuesta recibida en ${sendTime.toFixed(2)}ms`,
      );

      // Limpiar recursos de streaming
      this.cleanupStreamResources(chat.id);

      // Render final optimizado: solo actualizar el último mensaje
      console.log(`🔵 [SendMessage] Haciendo render final del último mensaje`);
      const renderStart = performance.now();

      if (this.currentChatId === chat.id) {
        this.updateFinalMessage(chat);
      }

      const renderTime = performance.now() - renderStart;
      console.log(
        `✅ [SendMessage] Render final completado en ${renderTime.toFixed(2)}ms`,
      );

      this.playSound("message-in");
    } catch (error) {
      console.error("Error enviando mensaje:", error);

      // No mostrar error si fue un abort intencional
      if (error.name === "AbortError") {
        // La respuesta parcial ya está en aiMessage.content
        if (aiMessage.content) {
          aiMessage.content += `\n\n[⏹️ ${this.t("chat.response_stopped")}]`;
        } else {
          aiMessage.content = `[⏹️ ${this.t("messages.nudge_stopped")}]`;
        }
      } else {
        // Mostrar mensaje de error apropiado
        // Si el error tiene una clave de traducción, usarla; sino usar el mensaje directamente
        if (error.translationKey) {
          let errorMsg = this.t(error.translationKey);
          // Si la traducción falló, usar el mensaje del error directamente
          if (!errorMsg || errorMsg.includes(".")) {
            errorMsg = error.message;
          }
          aiMessage.content = errorMsg;
        } else {
          aiMessage.content = error.message;
        }
      }

      // Limpiar recursos de streaming
      this.cleanupStreamResources(chat.id);

      if (this.currentChatId === chat.id) {
        this.renderMessages(chat);
      }
    } finally {
      // Verificar si fue abortado y añadir marcador SIEMPRE
      if (this.wasAborted) {
        if (aiMessage.content && !aiMessage.content.includes("[⏹️")) {
          aiMessage.content += `\n\n[⏹️ ${this.t("chat.response_stopped")}]`;
        } else if (!aiMessage.content) {
          aiMessage.content = `[⏹️ ${this.t("chat.response_stopped_before")}]`;
        }

        // Limpiar recursos de streaming
        this.cleanupStreamResources(chat.id);

        if (this.currentChatId === chat.id) {
          this.renderMessages(chat);
        }
        this.wasAborted = false;
      }

      this.saveChats();

      this.renderChatList();
    }
  }

  // =================== FUNCIONES EXISTENTES (sin cambios) ===================

  initSounds() {
    const soundIds = ["login", "message-in", "message-out", "nudge", "calling"];
    soundIds.forEach((id) => {
      const audio = document.getElementById(`sound-${id}`);
      if (audio) {
        this.sounds[id] = audio;
        audio.volume = 0.5;
      }
    });
  }

  playSound(soundName) {
    if (!this.settings.soundsEnabled) return;
    const sound = this.sounds[soundName];
    if (sound) {
      sound.currentTime = 0;
      sound
        .play()
        .catch((e) => console.log("No se pudo reproducir sonido:", soundName));
    }
  }

  loadSettings() {
    const saved = localStorage.getItem("msnai-settings");
    if (saved) {
      const savedSettings = JSON.parse(saved);
      const currentOllamaServer = this.settings.ollamaServer;
      // Asegurar valores por defecto para configuraciones críticas
      const defaults = {
        temperature: 0.7,
        topK: 40,
        topP: 0.9,
        maxTokens: 2000,
      };
      this.settings = { ...this.settings, ...defaults, ...savedSettings };
      const currentHost = window.location.hostname;
      const isLocalAccess =
        currentHost === "localhost" || currentHost === "127.0.0.1";
      const savedServerIsLocal =
        savedSettings.ollamaServer &&
        savedSettings.ollamaServer.includes("localhost");
      if (!isLocalAccess && savedServerIsLocal) {
        this.settings.ollamaServer = currentOllamaServer;
        console.log(
          `🔄 Auto-detección: Usando ${currentOllamaServer} en lugar de ${savedSettings.ollamaServer}`,
        );
      }
    }
    this.updateSettingsUI();
  }

  saveSettings() {
    localStorage.setItem("msnai-settings", JSON.stringify(this.settings));
    this.updateSettingsUI();
  }

  loadChats() {
    const saved = localStorage.getItem("msnai-chats");
    if (saved) {
      this.chats = JSON.parse(saved);
      // Asegurar que todos los chats tengan la propiedad attachments
      this.chats.forEach((chat) => {
        if (!chat.attachments) {
          chat.attachments = [];
        }
      });
    } else {
      this.chats = [
        {
          id: "welcome-" + Date.now(),
          title: "Bienvenida a MSN-AI",
          date: new Date().toISOString(),
          model: this.settings.selectedModel,
          attachments: [],
          messages: [
            {
              type: "ai",
              content:
                "¡Hola! Soy tu asistente de IA integrado en esta nostálgica interfaz de Windows Live Messenger. ¿En qué puedo ayudarte hoy?",
              timestamp: new Date().toISOString(),
            },
          ],
        },
      ];
    }
  }

  saveChats() {
    localStorage.setItem("msnai-chats", JSON.stringify(this.chats));
  }

  async checkConnection() {
    console.log(`🔍 Verificando conexión con Ollama...`);
    console.log(`   Servidor: ${this.settings.ollamaServer}`);
    this.updateConnectionStatus("connecting");
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000);

      // Usar el rate limiter para verificar la conexión
      const response = await this.rateLimiter.makeRequest(
        async () => {
          return await fetch(`${this.settings.ollamaServer}/api/tags`, {
            method: "GET",
            signal: controller.signal,
            headers: { Accept: "application/json" },
          });
        },
        { priority: "high", skipQueue: true }, // Alta prioridad y sin cola para verificación
      );

      clearTimeout(timeoutId);
      if (response.ok) {
        const data = await response.json();
        this.availableModels = data.models || [];
        this.isConnected = true;
        this.updateConnectionStatus("connected");
        this.updateModelStatus();
        this.updateModelSelect();
        console.log(
          `✅ Conexión exitosa. Modelos encontrados: ${this.availableModels.length}`,
        );
        this.availableModels.forEach((model) => {
          const sizeGB = (model.size / 1024 / 1024 / 1024).toFixed(1);
          console.log(`📦 - ${model.name} (${sizeGB}GB)`);
        });
        return true;
      }
    } catch (error) {
      console.error("❌ Error conectando con Ollama:", error);
    }
    this.isConnected = false;
    this.availableModels = [];
    this.updateConnectionStatus("disconnected");
    this.updateModelSelect();
    return false;
  }

  async sendToAI(
    message,
    chatId,
    onToken,
    pdfContext = null,
    imageContext = null,
  ) {
    if (!this.isConnected) throw new Error(this.t("errors.no_connection"));
    const chat = this.chats.find((c) => c.id === chatId);
    if (!chat) throw new Error(this.t("errors.chat_not_found"));

    // Crear nuevo AbortController para este chat específico
    this.abortControllers[chatId] = new AbortController();
    this.respondingChats.add(chatId);

    // Actualizar UI para mostrar indicador visual en el título del chat
    this.updateChatTitleRespondingState(chatId, true);

    // Inicializar acumulador de respuesta para este chat
    this.accumulatedResponses[chatId] = "";

    // Mostrar botón de detener solo si estamos en este chat
    this.updateStopButtonVisibility();

    // Construir contexto del historial (solo últimos 10 mensajes de interacción)
    const context = chat.messages
      .slice(-10)
      .map(
        (msg) =>
          `${msg.type === "user" ? "Usuario" : "Asistente"}: ${msg.content}`,
      )
      .join("\n");

    // Cargar todos los archivos adjuntos del chat desde IndexedDB
    let attachmentsContext = "";
    let attachmentImages = []; // Array para almacenar imágenes de attachments
    if (chat.attachments && chat.attachments.length > 0) {
      const attachmentsData = [];
      for (const attachmentMeta of chat.attachments) {
        try {
          const attachment = await this.getAttachment(attachmentMeta.id);
          if (attachment) {
            if (attachment.type === "text/plain") {
              // IMPORTANTE: Enviar el contenido COMPLETO del archivo de texto
              // El rate limiter evita sobrecargar el servidor Ollama
              let textContent = attachment.content;
              attachmentsData.push(
                `[Archivo TXT: ${attachment.name}]\n${textContent}\n`,
              );
            } else if (attachment.type === "application/pdf") {
              // IMPORTANTE: Enviar el contenido COMPLETO del PDF
              // El rate limiter evita sobrecargar el servidor Ollama
              attachmentsData.push(
                `[Archivo PDF: ${attachment.name} - ${attachment.pages} páginas]\n${attachment.content}\n`,
              );
            } else if (
              attachment.type &&
              attachment.type.startsWith("image/")
            ) {
              // Para imágenes, agregar al array de imágenes (no al contexto de texto)
              if (attachment.base64Data) {
                attachmentImages.push(attachment.base64Data);
                attachmentsData.push(`[Imagen: ${attachment.name}]\n`);
              }
            }
          }
        } catch (error) {
          console.error(
            `Error cargando attachment ${attachmentMeta.id}:`,
            error,
          );
        }
      }
      if (attachmentsData.length > 0) {
        attachmentsContext = `\n\n=== ${this.t("chat.attachments_context_header")} ===\n${attachmentsData.join("\n---\n")}\n=== ${this.t("chat.attachments_context_footer")} ===\n\n`;
      }
    }

    // Construir prompt: Archivos adjuntos + Contexto PDF temporal (si existe) + Historial + Mensaje actual
    let prompt = "";
    if (attachmentsContext || pdfContext) {
      prompt = `${attachmentsContext}${pdfContext ? pdfContext + "\n\n---\n\n" : ""}Historial de conversación:\n${context}\n\nUsuario: ${message}`;
    } else {
      prompt = context ? `${context}\nUsuario: ${message}` : message;
    }

    let fullResponse = ""; // Mover fuera del try para que sea accesible en catch

    try {
      // Preparar el cuerpo de la petición según la documentación de Ollama
      const requestBody = {
        model: chat.model,
        prompt: prompt,
        stream: true,
        options: {
          temperature: parseFloat(this.settings.temperature) || 0.7,
          top_k: parseInt(this.settings.topK) || 40,
          top_p: parseFloat(this.settings.topP) || 0.9,
          num_predict: parseInt(this.settings.maxTokens) || 2000,
        },
        keep_alive: "5m", // Mantener modelo en memoria por 5 minutos
      };

      // Si hay contexto de imagen o imágenes de attachments, agregarlas
      // Ollama requiere que las imágenes estén en el array 'images' como base64 puro (sin prefijo data:image)
      if (imageContext && imageContext.base64Data) {
        requestBody.images = [imageContext.base64Data];
      } else if (attachmentImages.length > 0) {
        // Usar solo la primera imagen de los attachments para no saturar
        requestBody.images = [attachmentImages[0]];
      }

      // Usar el rate limiter para hacer la solicitud
      const response = await this.rateLimiter.makeRequest(
        async () => {
          return await fetch(`${this.settings.ollamaServer}/api/generate`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(requestBody),
            signal: this.abortControllers[chatId].signal,
          });
        },
        { priority: "normal", chatId: chatId },
      );

      if (!response.ok) {
        // Manejar error 401 (Unauthorized) para modelos cloud
        if (response.status === 401) {
          const error = new Error(`HTTP 401: Unauthorized`);
          error.statusCode = 401;
          throw error;
        }

        // Manejar error específico de modelo sin soporte de imágenes
        if (
          (response.status === 400 || response.status === 500) &&
          (imageContext || attachmentImages.length > 0)
        ) {
          try {
            const errorText = await response.text();
            let errorMessage = errorText;

            // Intentar parsear JSON para obtener el mensaje de error real
            try {
              const errorJson = JSON.parse(errorText);
              errorMessage = errorJson.error || errorText;
            } catch (jsonError) {
              // Si no es JSON, usar el texto tal cual
              errorMessage = errorText;
            }

            // Verificar si el error está relacionado con imágenes no soportadas
            if (
              errorMessage.includes("does not support images") ||
              errorMessage.includes("no soporta imágenes") ||
              errorMessage.includes("model does not support") ||
              errorMessage.includes("vision") ||
              errorMessage.includes("multimodal") ||
              errorMessage.includes("illegal base64") ||
              errorMessage.includes("invalid base64") ||
              errorMessage.includes("unmarshal") ||
              errorMessage.includes("invalid character") ||
              errorMessage.includes("looking for beginning of value")
            ) {
              // Obtener mensaje traducido antes de lanzar el error
              let errorMsg = this.t("errors.model_no_image_support");
              // Si la traducción falló, usar mensaje por defecto
              if (!errorMsg || errorMsg.includes("errors.")) {
                errorMsg =
                  "El modelo de IA seleccionado no soporta el procesamiento de imágenes";
              }
              const error = new Error(errorMsg);
              error.translationKey = "errors.model_no_image_support";
              throw error;
            }
          } catch (e) {
            // Si es nuestro error personalizado, relanzarlo
            if (e.translationKey === "errors.model_no_image_support") {
              throw e;
            }
            // Si hay imagen pero error 400/500, probablemente sea falta de soporte
            let errorMsg = this.t("errors.model_no_image_support");
            // Si la traducción falló, usar mensaje por defecto
            if (!errorMsg || errorMsg.includes("errors.")) {
              errorMsg =
                "El modelo de IA seleccionado no soporta el procesamiento de imágenes";
            }
            const error = new Error(errorMsg);
            error.translationKey = "errors.model_no_image_support";
            throw error;
          }
        }
        throw new Error(
          this.t("errors.server_error", { status: response.status }),
        );
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();

      console.log(`🔵 [Stream] Iniciando streaming para chat ${chatId}`);
      console.log(
        `🔵 [Stream] respondingChats activo:`,
        Array.from(this.respondingChats),
      );
      const streamStartTime = performance.now();
      let chunkCount = 0;
      let tokenCount = 0;
      let lastLogTime = streamStartTime;

      try {
        let tokenBatch = "";
        let batchCount = 0;
        const BATCH_SIZE = 3; // Reducido para actualizaciones más frecuentes pero ligeras
        let totalTokensSent = 0;

        while (true) {
          const readStart = performance.now();
          const { done, value } = await reader.read();
          const readTime = performance.now() - readStart;

          if (readTime > 100) {
            console.warn(`⚠️ [Stream] Lectura lenta: ${readTime.toFixed(2)}ms`);
          }

          if (done) {
            // Enviar cualquier token restante en el batch
            if (tokenBatch) {
              console.log(
                `🔵 [Stream] Enviando tokens finales: ${tokenBatch.length} caracteres`,
              );
              onToken(tokenBatch);
            }
            const totalTime = performance.now() - streamStartTime;
            console.log(
              `✅ [Stream] Streaming completado en ${totalTime.toFixed(2)}ms - ${chunkCount} chunks, ${tokenCount} tokens`,
            );
            break;
          }

          chunkCount++;
          const chunk = decoder.decode(value, { stream: true });
          const lines = chunk.split("\n").filter((line) => line.trim() !== "");

          const parseStart = performance.now();
          for (const line of lines) {
            try {
              const json = JSON.parse(line);

              // Verificar si hay un error en el stream según documentación de Ollama
              if (json.error) {
                console.error(
                  "❌ [Stream] Error durante streaming:",
                  json.error,
                );
                throw new Error(json.error);
              }

              if (json.response) {
                fullResponse += json.response;
                tokenBatch += json.response;
                batchCount++;
                tokenCount++;

                // Solo llamar onToken cada BATCH_SIZE tokens para reducir actualizaciones
                if (batchCount >= BATCH_SIZE) {
                  const tokenStart = performance.now();
                  onToken(tokenBatch);
                  const tokenTime = performance.now() - tokenStart;
                  totalTokensSent++;

                  // Log periódico cada 2 segundos
                  const now = performance.now();
                  if (now - lastLogTime > 2000) {
                    console.log(
                      `📊 [Stream] Progreso: ${tokenCount} tokens (${totalTokensSent} envíos), ${chunkCount} chunks, ${(now - streamStartTime).toFixed(0)}ms transcurridos`,
                    );
                    lastLogTime = now;
                  }

                  if (tokenTime > 50) {
                    console.warn(
                      `⚠️ [Stream] onToken lento: ${tokenTime.toFixed(2)}ms para ${tokenBatch.length} caracteres`,
                    );
                  }

                  tokenBatch = "";
                  batchCount = 0;
                }
              }
              if (json.done) {
                // Enviar tokens restantes antes de terminar
                if (tokenBatch) {
                  console.log(
                    `🔵 [Stream] Enviando tokens finales (done): ${tokenBatch.length} caracteres`,
                  );
                  onToken(tokenBatch);
                  tokenBatch = "";
                }
                break;
              }
            } catch (e) {
              // Si es un error de parsing JSON, solo advertir
              // Si es un error real del stream, lanzarlo
              if (e.message && !e.message.includes("Unexpected")) {
                throw e;
              }
              console.warn("⚠️ [Stream] Línea no JSON:", line);
            }
          }

          const parseTime = performance.now() - parseStart;
          if (parseTime > 50) {
            console.warn(
              `⚠️ [Stream] Parseo lento: ${parseTime.toFixed(2)}ms para ${lines.length} líneas`,
            );
          }

          // Permitir que el navegador respire después de cada chunk
          // Esto es crítico para mantener la UI responsiva
          // Yield más frecuente si hay muchas líneas
          if (lines.length > 3) {
            await new Promise((resolve) => setTimeout(resolve, 15));
          } else {
            await new Promise((resolve) => setTimeout(resolve, 5));
          }
        }
      } finally {
        reader.releaseLock();
        console.log(`🔵 [Stream] Reader liberado para chat ${chatId}`);
      }

      return fullResponse;
    } catch (error) {
      if (error.name === "AbortError") {
        console.log("⏹️ Respuesta de IA detenida por el usuario");
        this.wasAborted = true;
        // fullResponse contiene lo generado hasta el momento del abort
        // No lanzar error, solo retornar lo que se generó
        return fullResponse;
      }

      // Crear mensaje de error amigable usando el mismo sistema que salas de expertos
      const errorMessage = error.message || "";
      let friendlyError = new Error();

      if (
        errorMessage.includes("TimeoutError") ||
        errorMessage.includes("timed out")
      ) {
        friendlyError.message = this.t("expert_room.error_timeout", {
          model: chat.model,
        });
      } else if (
        errorMessage.includes("HTTP 401") ||
        errorMessage.includes("Unauthorized")
      ) {
        friendlyError.message = this.t("expert_room.error_http_401", {
          model: chat.model,
        });
        // Fallback si la traducción no está disponible
        if (
          !friendlyError.message ||
          friendlyError.message.includes("expert_room.error_")
        ) {
          friendlyError.message = `🔐 ${chat.model}: Este modelo requiere autenticación. Por favor, ejecuta 'ollama signin' en tu terminal.`;
        }
      } else if (
        errorMessage.includes("HTTP 429") ||
        errorMessage.includes("Too Many Requests")
      ) {
        friendlyError.message = this.t("expert_room.error_http_429", {
          model: chat.model,
        });
      } else if (errorMessage.includes("HTTP 500")) {
        friendlyError.message = this.t("expert_room.error_http_500", {
          model: chat.model,
        });
      } else if (errorMessage.includes("HTTP 404")) {
        friendlyError.message = this.t("expert_room.error_http_404", {
          model: chat.model,
        });
      } else if (errorMessage.includes("HTTP 503")) {
        friendlyError.message = this.t("expert_room.error_http_503", {
          model: chat.model,
        });
      } else if (
        errorMessage.includes("network") ||
        errorMessage.includes("fetch")
      ) {
        friendlyError.message = this.t("expert_room.error_network", {
          model: chat.model,
        });
      } else {
        friendlyError.message = this.t("expert_room.error_generic", {
          model: chat.model,
        });
      }

      // Fallback si la traducción no está disponible
      if (
        !friendlyError.message ||
        friendlyError.message.includes("expert_room.error_")
      ) {
        friendlyError.message = `⚠️ ${chat.model}: No se pudo obtener respuesta en este momento.`;
      }

      throw friendlyError;
    } finally {
      // Asegurar que la respuesta acumulada se guarde en el mensaje
      const chat = this.chats.find((c) => c.id === chatId);
      if (chat && chat.messages.length > 0) {
        const lastMessage = chat.messages[chat.messages.length - 1];
        if (lastMessage.type === "ai" && this.accumulatedResponses[chatId]) {
          lastMessage.content = this.accumulatedResponses[chatId];
        }
      }

      // Limpiar estado de este chat
      this.respondingChats.delete(chatId);
      delete this.abortControllers[chatId];
      delete this.accumulatedResponses[chatId];

      // Actualizar UI para remover indicador visual del título del chat
      this.updateChatTitleRespondingState(chatId, false);

      // Marcar como no leído si no es el chat actual
      if (this.currentChatId !== chatId) {
        this.unreadChats.add(chatId);
        this.renderChatList();
      }

      // Actualizar visibilidad del botón de detener
      this.updateStopButtonVisibility();

      // Actualizar thinking indicator solo si es el chat actual
      if (this.currentChatId === chatId) {
        this.showAIThinking(false);
      }
    }
  }

  updateStopButtonVisibility() {
    const stopBtn = document.getElementById("detener-respuesta-ia-btn");
    if (stopBtn) {
      // Mostrar botón solo si el chat actual está respondiendo
      stopBtn.style.display = this.respondingChats.has(this.currentChatId)
        ? "inline-block"
        : "none";
    }
  }

  updateChatTitleRespondingState(chatId, isResponding) {
    // Buscar el elemento del chat en la lista
    const chatElement = document.querySelector(`[data-chat-id="${chatId}"]`);
    if (chatElement) {
      const titleDiv = chatElement.querySelector(".chat-title");
      if (titleDiv) {
        if (isResponding) {
          titleDiv.classList.add("ai-responding");
        } else {
          titleDiv.classList.remove("ai-responding");
        }
      }
    }
  }

  stopAIResponse() {
    // Detener la respuesta del chat actual si está respondiendo
    if (this.currentChatId && this.respondingChats.has(this.currentChatId)) {
      const chat = this.chats.find((c) => c.id === this.currentChatId);

      // Verificar si es una sala de expertos
      if (chat && chat.isExpertRoom) {
        console.log("🛑 Deteniendo respuestas de sala de expertos...");
        const expertControllers =
          this.expertRoomAbortControllers[this.currentChatId];
        if (expertControllers && expertControllers.length > 0) {
          // Abortar todos los controladores pendientes
          expertControllers.forEach((controller) => {
            if (controller && !controller.signal.aborted) {
              controller.abort();
            }
          });
          // Limpiar controladores
          delete this.expertRoomAbortControllers[this.currentChatId];
        }
        this.respondingChats.delete(this.currentChatId);
        this.updateStopButtonVisibility();
        this.showAIThinking(false);
        this.playSound("nudge");
        return;
      }

      // Manejo de chat normal
      const abortController = this.abortControllers[this.currentChatId];
      if (abortController) {
        console.log("🛑 Deteniendo respuesta de IA...");
        abortController.abort();
        this.updateStopButtonVisibility();
        this.showAIThinking(false);
        this.playSound("nudge");
      }
    }
  }

  createNewChat() {
    const chatId = "chat-" + Date.now();
    const newChat = {
      id: chatId,
      title: this.t("chat.new_chat_title", { number: this.chats.length + 1 }),
      date: new Date().toISOString(),
      model: this.settings.selectedModel,
      messages: [],
      attachments: [],
    };
    this.chats.unshift(newChat);
    this.saveChats();
    this.renderChatList();
    this.selectChat(chatId);
    this.playSound("nudge");
  }

  selectChat(chatId) {
    this.currentChatId = chatId;
    const chat = this.chats.find((c) => c.id === chatId);
    if (!chat) return;

    // Marcar como leído
    this.unreadChats.delete(chatId);

    document
      .querySelectorAll(".chat-item")
      .forEach((item) => item.classList.remove("active"));
    const chatElement = document.querySelector(`[data-chat-id="${chatId}"]`);
    if (chatElement) chatElement.classList.add("active");
    document.getElementById("chat-contact-name").textContent = chat.title;
    document.getElementById("chat-status-message").textContent = this.t(
      "chat.model_info",
      { model: chat.model, count: chat.messages.length },
    );

    // Si hay respuesta acumulada pendiente, actualizarla
    if (this.accumulatedResponses[chatId]) {
      const lastMessage = chat.messages[chat.messages.length - 1];
      if (lastMessage && lastMessage.type === "ai") {
        lastMessage.content = this.accumulatedResponses[chatId];
      }
    }

    this.renderMessages(chat);
    this.renderChatList(); // Re-renderizar para actualizar indicador de no leído
    document.getElementById("message-input").disabled = false;
    document.getElementById("send-button").disabled = false;

    // Actualizar visibilidad del botón de detener según el chat seleccionado
    this.updateStopButtonVisibility();

    // Actualizar thinking indicator según el chat seleccionado
    this.showAIThinking(this.respondingChats.has(chatId));

    // Cambiar automáticamente el modelo al seleccionar un chat
    if (this.settings.selectedModel !== chat.model && chat.model) {
      this.settings.selectedModel = chat.model;
      this.saveSettings();
      this.updateModelSelect();
      this.updateModelStatus();

      // Actualizar visualmente los headers de modelo
      this.updateModelHeadersVisual();

      console.log(`🤖 Modelo cambiado automáticamente a: ${chat.model}`);
    }
  }

  generateChatTitle(chat) {
    if (chat.messages.length === 0) return "Nuevo chat";
    const firstMessage = chat.messages.find((m) => m.type === "user");
    if (!firstMessage) return "Nuevo chat";
    const title = firstMessage.content.substring(0, 50);
    return title.length < firstMessage.content.length ? title + "..." : title;
  }

  async deleteChat(chatId) {
    // Ya no se necesita confirm() aquí: la confirmación se hizo en el modal

    // Eliminar todos los archivos adjuntos del chat de IndexedDB
    try {
      await this.deleteAllChatAttachments(chatId);
    } catch (error) {
      console.error("Error eliminando archivos adjuntos del chat:", error);
    }

    this.chats = this.chats.filter((c) => c.id !== chatId);

    // Limpiar caché de markdown para liberar memoria
    this.markdownCache.clear();

    this.saveChats();
    this.renderChatList();
    if (this.currentChatId === chatId) {
      this.currentChatId = null;
      this.clearChatArea();
    }
  }
  renderChatList() {
    const chatList = document.getElementById("chat-list");
    chatList.innerHTML = "";

    // Separar salas de expertos de chats normales
    const expertRooms = [];
    const regularChats = [];
    this.chats.forEach((chat) => {
      if (chat.isExpertRoom) {
        expertRooms.push(chat);
      } else {
        regularChats.push(chat);
      }
    });

    // Agrupar chats regulares por modelo
    const chatsByModel = {};
    regularChats.forEach((chat) => {
      const model = chat.model || "Sin modelo";
      if (!chatsByModel[model]) {
        chatsByModel[model] = [];
      }
      chatsByModel[model].push(chat);
    });

    // Agregar modelos instalados que no tienen chats
    this.availableModels.forEach((model) => {
      if (!chatsByModel[model.name]) {
        chatsByModel[model.name] = [];
      }
    });

    // Si no hay modelos ni chats
    if (Object.keys(chatsByModel).length === 0) {
      chatList.innerHTML = `<li style="padding: 20px; text-align: center; color: #666;">${this.t("chat.no_models")}</li>`;
      return;
    }

    // Renderizar salas de expertos primero (si existen)
    if (expertRooms.length > 0) {
      const expertRoomsGroup = document.createElement("li");
      expertRoomsGroup.className = "model-group";
      expertRoomsGroup.style.padding = "0";
      expertRoomsGroup.style.margin = "0";

      const expertRoomsHeader = document.createElement("div");
      expertRoomsHeader.className = "model-header";
      expertRoomsHeader.style.display = "flex";
      expertRoomsHeader.style.alignItems = "center";
      expertRoomsHeader.style.padding = "8px 10px";
      expertRoomsHeader.style.cursor = "pointer";
      expertRoomsHeader.style.backgroundColor = "#fff3e0";
      expertRoomsHeader.style.borderBottom = "1px solid #ccc";
      expertRoomsHeader.style.fontWeight = "bold";
      expertRoomsHeader.style.fontSize = "11px";

      const expertArrowIcon = document.createElement("img");
      expertArrowIcon.src = "assets/contacts-window/37.png";
      expertArrowIcon.style.width = "14px";
      expertArrowIcon.style.height = "14px";
      expertArrowIcon.style.marginRight = "8px";
      expertArrowIcon.dataset.expanded = "true";

      const expertRoomsNameSpan = document.createElement("span");
      expertRoomsNameSpan.textContent = `🏢 ${this.t("expert_room.models_label") || "Salas de Expertos"} (${expertRooms.length})`;
      expertRoomsNameSpan.style.flex = "1";

      expertRoomsHeader.appendChild(expertArrowIcon);
      expertRoomsHeader.appendChild(expertRoomsNameSpan);

      const expertRoomsContainer = document.createElement("ul");
      expertRoomsContainer.className = "model-chats-container";
      expertRoomsContainer.style.listStyle = "none";
      expertRoomsContainer.style.padding = "0";
      expertRoomsContainer.style.margin = "0";

      expertRooms.forEach((room) => {
        const roomElement = this.createChatElement(room);
        expertRoomsContainer.appendChild(roomElement);
      });

      expertRoomsHeader.addEventListener("click", () => {
        const isExpanded = expertArrowIcon.dataset.expanded === "true";
        if (isExpanded) {
          expertRoomsContainer.style.display = "none";
          expertArrowIcon.src = "assets/contacts-window/38.png";
          expertArrowIcon.dataset.expanded = "false";
        } else {
          expertRoomsContainer.style.display = "block";
          expertArrowIcon.src = "assets/contacts-window/37.png";
          expertArrowIcon.dataset.expanded = "true";
        }
      });

      expertRoomsGroup.appendChild(expertRoomsHeader);
      expertRoomsGroup.appendChild(expertRoomsContainer);
      chatList.appendChild(expertRoomsGroup);
    }

    // Renderizar cada grupo de modelo
    Object.keys(chatsByModel).forEach((modelName) => {
      const chatsInModel = chatsByModel[modelName];

      // Crear elemento de grupo/categoría del modelo
      const modelGroup = document.createElement("li");
      modelGroup.className = "model-group";
      modelGroup.style.padding = "0";
      modelGroup.style.margin = "0";

      // Header del modelo (con ícono y nombre)
      const modelHeader = document.createElement("div");
      modelHeader.className = "model-header";
      modelHeader.style.display = "flex";
      modelHeader.style.alignItems = "center";
      modelHeader.style.padding = "8px 10px";
      modelHeader.style.cursor = "pointer";
      modelHeader.style.backgroundColor = "#e8f0f8";
      modelHeader.style.borderBottom = "1px solid #ccc";
      modelHeader.style.fontWeight = "bold";
      modelHeader.style.fontSize = "11px";

      // Ícono del modelo (imagen de avatar)
      const arrowIcon = document.createElement("img");
      arrowIcon.src = "assets/contacts-window/37.png"; // Verde (expandido)
      arrowIcon.style.width = "14px";
      arrowIcon.style.height = "14px";
      arrowIcon.style.marginRight = "8px";
      arrowIcon.dataset.expanded = "true";

      // Nombre del modelo
      const modelNameSpan = document.createElement("span");
      modelNameSpan.textContent = `${modelName} (${chatsInModel.length})`;
      modelNameSpan.style.flex = "1";

      // Indicador visual si es el modelo actualmente seleccionado
      if (this.settings.selectedModel === modelName) {
        modelHeader.style.backgroundColor = "#d0e5f5";
        modelHeader.style.fontWeight = "900";
      }

      // Ensamblar header
      modelHeader.appendChild(arrowIcon);
      modelHeader.appendChild(modelNameSpan);

      // Contenedor de chats dentro del grupo
      const chatsContainer = document.createElement("ul");
      chatsContainer.className = "model-chats-container";
      chatsContainer.style.listStyle = "none";
      chatsContainer.style.padding = "0";
      chatsContainer.style.margin = "0";

      // Límite de chats visibles inicialmente
      const maxVisible = 3;

      // Renderizar cada chat del modelo
      chatsInModel.forEach((chat, index) => {
        const chatElement = this.createChatElement(chat);

        // Ocultar chats adicionales si hay más de maxVisible
        if (index >= maxVisible) {
          chatElement.style.display = "none";
          chatElement.dataset.hiddenChat = "true";
        }

        chatsContainer.appendChild(chatElement);
      });

      // Botón "Ver más" si hay más de 3 chats
      if (chatsInModel.length > maxVisible) {
        const showMoreBtn = document.createElement("li");
        showMoreBtn.className = "show-more-btn";
        showMoreBtn.style.padding = "5px 10px 5px 30px";
        showMoreBtn.style.cursor = "pointer";
        showMoreBtn.style.fontSize = "10px";
        showMoreBtn.style.color = "#0066cc";
        showMoreBtn.style.fontStyle = "italic";
        showMoreBtn.textContent = `▼ ${this.t("chat.show_more", { count: chatsInModel.length - maxVisible })}`;
        showMoreBtn.dataset.expanded = "false";

        showMoreBtn.addEventListener("click", (e) => {
          e.stopPropagation();
          const isExpanded = showMoreBtn.dataset.expanded === "true";

          // Mostrar/ocultar chats adicionales
          const hiddenChats = chatsContainer.querySelectorAll(
            '[data-hidden-chat="true"]',
          );
          hiddenChats.forEach((chatEl) => {
            chatEl.style.display = isExpanded ? "none" : "flex";
          });

          // Actualizar texto del botón
          showMoreBtn.dataset.expanded = isExpanded ? "false" : "true";
          showMoreBtn.textContent = isExpanded
            ? `▼ ${this.t("chat.show_more", { count: chatsInModel.length - maxVisible })}`
            : `▲ ${this.t("chat.show_less")}`;
        });

        chatsContainer.appendChild(showMoreBtn);
      }

      // Toggle del grupo completo y cambio automático de modelo
      modelHeader.addEventListener("click", () => {
        const isExpanded = arrowIcon.dataset.expanded === "true";
        arrowIcon.dataset.expanded = isExpanded ? "false" : "true";

        // Cambiar icono según estado
        arrowIcon.src = isExpanded
          ? "assets/contacts-window/38.png" // Gris (colapsado)
          : "assets/contacts-window/37.png"; // Verde (expandido)

        chatsContainer.style.display = isExpanded ? "none" : "block";

        // Cambiar automáticamente el modelo seleccionado
        if (
          this.settings.selectedModel !== modelName &&
          modelName !== "Sin modelo"
        ) {
          this.settings.selectedModel = modelName;
          this.saveSettings();
          this.updateModelSelect();
          this.updateModelStatus();

          // Actualizar visualmente todos los headers de modelo
          this.updateModelHeadersVisual();

          console.log(`🤖 Modelo cambiado automáticamente a: ${modelName}`);
        }
      });

      modelGroup.appendChild(modelHeader);
      modelGroup.appendChild(chatsContainer);
      chatList.appendChild(modelGroup);
    });
  }

  updateModelHeadersVisual() {
    // Actualizar todos los headers de modelo para reflejar el modelo seleccionado
    document.querySelectorAll(".model-header").forEach((header) => {
      const modelNameSpan = header.querySelector("span");
      if (modelNameSpan) {
        const modelNameMatch = modelNameSpan.textContent.match(/^(.+?)\s*\(/);
        const modelName = modelNameMatch
          ? modelNameMatch[1]
          : modelNameSpan.textContent;

        if (this.settings.selectedModel === modelName) {
          header.style.backgroundColor = "#d0e5f5";
          header.style.fontWeight = "900";
        } else {
          header.style.backgroundColor = "#e8f0f8";
          header.style.fontWeight = "bold";
        }
      }
    });
  }

  createChatElement(chat) {
    const chatElement = document.createElement("li");
    chatElement.className = "chat-item";
    chatElement.setAttribute("data-chat-id", chat.id);

    // Ícono de persona (avatar) para selección
    const avatarIcon = document.createElement("img");
    avatarIcon.className = "chat-select-avatar";
    avatarIcon.dataset.chatId = chat.id;
    avatarIcon.style.width = "14px";
    avatarIcon.style.height = "14px";
    avatarIcon.style.margin = "0 8px 0 5px";
    avatarIcon.style.cursor = "pointer";

    // Determinar si está seleccionado (por defecto no)
    const isSelected = chat.selected || false;
    avatarIcon.src = isSelected
      ? "assets/contacts-window/40.png"
      : "assets/contacts-window/39.png";

    // Toggle selección al hacer clic en el avatar
    avatarIcon.addEventListener("click", (e) => {
      e.stopPropagation();
      chat.selected = !chat.selected;
      avatarIcon.src = chat.selected
        ? "assets/contacts-window/40.png"
        : "assets/contacts-window/39.png";
      this.saveChats();
    });

    // Contenedor para el contenido del chat
    const contentDiv = document.createElement("div");
    contentDiv.style.flex = "1";
    contentDiv.style.minWidth = "0";
    contentDiv.style.padding = "0";
    contentDiv.style.display = "flex";
    contentDiv.style.flexDirection = "column";
    contentDiv.style.marginLeft = "8px";
    contentDiv.style.alignItems = "flex-start";

    const titleDiv = document.createElement("div");
    titleDiv.className = "chat-title";

    // Agregar icono especial para salas de expertos
    if (chat.isExpertRoom) {
      titleDiv.innerHTML = `🏢 ${chat.title}`;
    } else {
      titleDiv.textContent = chat.title;
    }

    // Agregar clase de parpadeo si la IA está respondiendo en este chat
    if (this.respondingChats.has(chat.id)) {
      titleDiv.classList.add("ai-responding");
    }

    // Resaltar en verde si no está leído
    if (this.unreadChats.has(chat.id)) {
      titleDiv.style.color = "#00aa00";
      titleDiv.style.fontWeight = "bold";
    }

    // Último mensaje o info de sala de expertos
    let lastMessage;
    if (chat.isExpertRoom) {
      const modelsCount = chat.models ? chat.models.length : 0;
      lastMessage = `${modelsCount} ${this.t("expert_room.models_label") || "expertos"} • ${chat.messages.length} mensajes`;
    } else {
      lastMessage =
        chat.messages.length > 0
          ? chat.messages[chat.messages.length - 1].content.substring(0, 50) +
            (chat.messages[chat.messages.length - 1].content.length > 50
              ? "..."
              : "")
          : "Sin mensajes";
    }

    const previewDiv = document.createElement("div");
    previewDiv.className = "chat-preview";
    previewDiv.textContent = lastMessage;

    // Estilo especial para preview de salas de expertos
    if (chat.isExpertRoom) {
      previewDiv.style.fontStyle = "italic";
      previewDiv.style.color = "#666";
    }

    // Fecha
    const date = new Date(chat.date).toLocaleDateString("es-ES", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
    });

    const dateDiv = document.createElement("div");
    dateDiv.className = "chat-date";
    dateDiv.textContent = date;

    contentDiv.appendChild(titleDiv);
    contentDiv.appendChild(previewDiv);
    contentDiv.appendChild(dateDiv);

    // Ensamblar el ítem
    chatElement.style.display = "flex";
    chatElement.style.flexDirection = "row";
    chatElement.style.alignItems = "flex-start";
    chatElement.style.padding = "5px 10px";
    chatElement.style.cursor = "pointer";
    chatElement.appendChild(avatarIcon);
    chatElement.appendChild(contentDiv);

    // Evento click para seleccionar chat
    chatElement.addEventListener("click", (e) => {
      // No activar si se hizo clic en el avatar
      if (!e.target.matches(".chat-select-avatar")) {
        this.selectChat(chat.id);
      }
    });

    // Evento contextmenu para eliminar chat
    chatElement.addEventListener("contextmenu", (e) => {
      this.showChatContextMenu(e, chat.id);
    });

    // Marcar como activo si es el chat actual
    if (this.currentChatId === chat.id) {
      chatElement.classList.add("active");
    }

    return chatElement;
  }

  // =================== SISTEMA DE STREAMING ASÍNCRONO ===================

  /**
   * Programa una actualización del último mensaje durante streaming
   * Usa requestAnimationFrame para actualizaciones fluidas sin bloquear
   */
  scheduleStreamUpdate(chat) {
    const chatId = chat.id;

    // VERIFICAR QUE ESTAMOS EN STREAMING
    if (!this.respondingChats.has(chatId)) {
      return;
    }

    // Si el usuario está interactuando, no programar actualización
    if (this.userInteracting) {
      return;
    }

    // Si ya se está procesando o hay un frame pendiente, saltar
    if (this.isProcessingStream[chatId] || this.pendingFrames[chatId]) {
      return;
    }

    // Usar requestAnimationFrame directamente para máxima fluidez
    this.pendingFrames[chatId] = requestAnimationFrame(() => {
      delete this.pendingFrames[chatId];

      // Verificación final antes de actualizar
      if (
        !this.userInteracting &&
        this.respondingChats.has(chatId) &&
        !this.isProcessingStream[chatId]
      ) {
        this.updateLastMessageStream(chat);
      }
    });
  }

  /**
   * Actualiza el último mensaje durante streaming con renderizado markdown en tiempo real
   */
  updateLastMessageStream(chat) {
    const chatId = chat.id;
    const updateStart = performance.now();

    // Throttling: no renderizar más de una vez cada 100ms por chat
    const now = performance.now();
    if (
      this.lastStreamRender[chatId] &&
      now - this.lastStreamRender[chatId] < 100
    ) {
      return;
    }
    this.lastStreamRender[chatId] = now;

    // Si ya se está procesando este chat, salir
    if (this.isProcessingStream[chatId]) {
      return;
    }

    // Marcar que se está procesando
    this.isProcessingStream[chatId] = true;

    try {
      const messagesArea = document.getElementById("messages-area");
      if (!messagesArea) {
        return;
      }

      const messageElements = messagesArea.querySelectorAll(".message");
      if (messageElements.length === 0) {
        this.renderMessages(chat);
        return;
      }

      const lastMessageElement = messageElements[messageElements.length - 1];
      const lastMessage = chat.messages[chat.messages.length - 1];

      if (!lastMessage) {
        return;
      }

      const contentDiv = lastMessageElement.querySelector(".message-content");
      if (!contentDiv) {
        return;
      }

      // Guardar posición del scroll
      const wasAtBottom =
        messagesArea.scrollHeight - messagesArea.scrollTop <=
        messagesArea.clientHeight + 50;

      // RENDERIZAR MARKDOWN EN TIEMPO REAL durante el streaming
      // Esto permite al usuario ver el formato mientras se genera la respuesta
      const contentLength = lastMessage.content.length;

      // Renderizar markdown de forma segura (sin caché durante streaming)
      const formattedContent = this.renderMarkdownSafe(
        lastMessage.content,
        false,
      );
      contentDiv.innerHTML = formattedContent;

      // Configurar botones de código después de actualizar el contenido
      this.setupCodeBlockButtons();

      // Scroll inteligente
      if (!this.userScrolledUp || wasAtBottom) {
        messagesArea.scrollTop = messagesArea.scrollHeight;
      }

      const totalTime = performance.now() - updateStart;

      if (totalTime > 50) {
        console.warn(
          `⚠️ [UI] Actualización lenta: ${totalTime.toFixed(2)}ms para ${contentLength} chars`,
        );
      }
    } finally {
      // Marcar que terminó el procesamiento
      this.isProcessingStream[chatId] = false;
    }
  }

  /**
   * Limpia todos los recursos de streaming para un chat
   */
  cleanupStreamResources(chatId) {
    console.log(
      `🧹 [Cleanup] Limpiando recursos de streaming para chat ${chatId}`,
    );

    // Cancelar frame pendiente
    if (this.pendingFrames[chatId]) {
      cancelAnimationFrame(this.pendingFrames[chatId]);
      delete this.pendingFrames[chatId];
      console.log(`🧹 [Cleanup] Frame cancelado`);
    }

    // Limpiar flags y timers
    delete this.isProcessingStream[chatId];
    delete this.streamingBuffers[chatId];
    delete this.lastStreamRender[chatId];
    console.log(`✅ [Cleanup] Recursos liberados`);
  }

  /**
   * Actualiza solo el último mensaje después de finalizar el streaming
   * Más eficiente que re-renderizar todos los mensajes
   */
  updateFinalMessage(chat) {
    const updateStart = performance.now();

    const messagesArea = document.getElementById("messages-area");
    if (!messagesArea) {
      return;
    }

    const messageElements = messagesArea.querySelectorAll(".message");
    if (messageElements.length === 0) {
      this.renderMessages(chat);
      return;
    }

    const lastMessageElement = messageElements[messageElements.length - 1];
    const lastMessage = chat.messages[chat.messages.length - 1];

    if (!lastMessage) {
      return;
    }

    const contentDiv = lastMessageElement.querySelector(".message-content");
    if (!contentDiv) {
      return;
    }

    // Guardar posición del scroll
    const wasAtBottom =
      messagesArea.scrollHeight - messagesArea.scrollTop <=
      messagesArea.clientHeight + 50;

    // Renderizar markdown final con caché activado
    const formattedContent = this.renderMarkdownSafe(lastMessage.content, true);
    contentDiv.innerHTML = formattedContent;

    // Configurar botones de código
    this.setupCodeBlockButtons();

    // Scroll al final si corresponde
    if (!this.userScrolledUp || wasAtBottom) {
      messagesArea.scrollTop = messagesArea.scrollHeight;
    }

    const totalTime = performance.now() - updateStart;
    console.log(
      `✅ [UpdateFinal] Último mensaje actualizado en ${totalTime.toFixed(2)}ms`,
    );
  }

  /**
   * Actualiza solo el contenido del último mensaje sin reconstruir todo el DOM
   */
  updateLastMessageOnly(chat) {
    console.log(`🔵 [Final] Actualizando mensaje final con formato completo`);
    const updateStart = performance.now();

    const messagesArea = document.getElementById("messages-area");
    if (!messagesArea) return;

    // Buscar el último elemento de mensaje en el DOM
    const messageElements = messagesArea.querySelectorAll(".message");
    if (messageElements.length === 0) {
      // Si no hay mensajes, hacer render completo
      console.log(`🔵 [Final] No hay mensajes, render completo`);
      this.renderMessages(chat);
      return;
    }

    const lastMessageElement = messageElements[messageElements.length - 1];
    const lastMessage = chat.messages[chat.messages.length - 1];

    if (!lastMessage) return;

    // Actualizar solo el contenido del mensaje
    const contentDiv = lastMessageElement.querySelector(".message-content");
    if (contentDiv) {
      // Guardar posición del scroll
      const wasAtBottom =
        messagesArea.scrollHeight - messagesArea.scrollTop <=
        messagesArea.clientHeight + 50;

      const formatStart = performance.now();
      contentDiv.innerHTML = this.formatMessage(lastMessage.content);
      const formatTime = performance.now() - formatStart;

      console.log(
        `🔵 [Final] Formato Markdown tomó ${formatTime.toFixed(2)}ms para ${lastMessage.content.length} caracteres`,
      );

      if (formatTime > 100) {
        console.warn(
          `⚠️ [Final] Formateo Markdown LENTO: ${formatTime.toFixed(2)}ms`,
        );
      }

      // Scroll inteligente
      if (!this.userScrolledUp || wasAtBottom) {
        messagesArea.scrollTop = messagesArea.scrollHeight;
      }

      // Re-configurar botones de código solo para este mensaje
      const buttonsStart = performance.now();
      this.setupCodeBlockButtonsForElement(lastMessageElement);
      const buttonsTime = performance.now() - buttonsStart;

      if (buttonsTime > 50) {
        console.warn(
          `⚠️ [Final] Setup de botones lento: ${buttonsTime.toFixed(2)}ms`,
        );
      }

      const totalTime = performance.now() - updateStart;
      console.log(
        `✅ [Final] Actualización final completada en ${totalTime.toFixed(2)}ms`,
      );
    }
  }

  /**
   * Configura botones de código para un elemento específico
   */
  setupCodeBlockButtonsForElement(element) {
    const codeBlocks = element.querySelectorAll("pre code");
    codeBlocks.forEach((block) => {
      const pre = block.parentElement;

      // Evitar duplicar botones
      if (pre.querySelector(".code-actions")) {
        return;
      }

      const actions = document.createElement("div");
      actions.className = "code-actions";
      actions.style.cssText =
        "position: absolute; top: 5px; right: 5px; display: flex; gap: 5px;";

      const copyBtn = document.createElement("button");
      copyBtn.textContent = this.t("buttons.copy");
      copyBtn.className = "code-btn";
      copyBtn.style.cssText =
        "background: #0066cc; color: white; border: none; padding: 3px 8px; border-radius: 3px; cursor: pointer; font-size: 7pt;";
      copyBtn.onclick = () => {
        navigator.clipboard
          .writeText(block.textContent)
          .then(() => {
            copyBtn.textContent = this.t("buttons.copied");
            setTimeout(
              () => (copyBtn.textContent = this.t("buttons.copy")),
              2000,
            );
          })
          .catch((err) => console.error("Error copiando:", err));
      };

      actions.appendChild(copyBtn);
      pre.style.position = "relative";
      pre.appendChild(actions);
    });
  }

  // =================== ACTUALIZACIÓN EN RENDERMESSAGES ===================
  renderMessages(chat) {
    // DETECTAR SI SE ESTÁ LLAMANDO DURANTE STREAMING (ESTO ES UN ERROR)
    if (this.respondingChats.has(chat.id)) {
      console.error(
        `❌❌❌ [RenderMessages] ERROR: Se está llamando renderMessages durante streaming para chat ${chat.id}`,
      );
      console.trace("Stack trace:");
    }

    console.log(
      `🔵 [RenderMessages] Iniciando render completo para chat ${chat.id} con ${chat.messages.length} mensajes`,
    );
    const renderStart = performance.now();

    const messagesArea = document.getElementById("messages-area");

    // Guardar posición del scroll antes de actualizar
    const wasAtBottom =
      messagesArea.scrollHeight - messagesArea.scrollTop <=
      messagesArea.clientHeight + 50;

    const clearStart = performance.now();
    messagesArea.innerHTML = "";
    const clearTime = performance.now() - clearStart;

    if (clearTime > 10) {
      console.warn(
        `⚠️ [RenderMessages] Limpieza del DOM lenta: ${clearTime.toFixed(2)}ms`,
      );
    }

    // Mostrar archivos adjuntos al inicio si existen
    if (chat.attachments && chat.attachments.length > 0) {
      const attachmentsContainer = document.createElement("div");
      attachmentsContainer.className = "attachments-container";
      attachmentsContainer.style.cssText =
        "padding: 10px; background: #f0f8ff; border-bottom: 1px solid #cce7ff; margin-bottom: 10px;";

      const attachmentsTitle = document.createElement("div");
      attachmentsTitle.style.cssText =
        "font-weight: bold; font-size: 8pt; color: #0066cc; margin-bottom: 5px;";
      attachmentsTitle.textContent = `📎 ${this.t("chat.attachments_title")} (${chat.attachments.length})`;
      attachmentsContainer.appendChild(attachmentsTitle);

      chat.attachments.forEach((attachment) => {
        const attachmentItem = document.createElement("div");
        attachmentItem.className = "attachment-item";
        attachmentItem.style.cssText =
          "display: flex; align-items: center; gap: 8px; padding: 5px; background: white; border: 1px solid #cce7ff; border-radius: 3px; margin-bottom: 4px; font-size: 7.5pt;";

        const icon = attachment.type === "application/pdf" ? "📄" : "📝";
        const sizeKB = (attachment.size / 1024).toFixed(1);
        const date = new Date(attachment.uploadDate).toLocaleDateString(
          "es-ES",
        );

        // Información adicional según tipo de archivo
        let extraInfo = "";
        if (attachment.pages) {
          extraInfo = `• ${attachment.pages} páginas`;
        } else if (attachment.chunks && attachment.chunks > 1) {
          extraInfo = `• ${attachment.chunks} fragmentos`;
        }

        // Determinar si tiene archivo binario disponible para descarga
        const hasFileAttachment = attachment.fileAttachmentKey ? true : false;

        // Usar tooltip genérico para todos los tipos de archivo
        let downloadBtnTooltip = this.t("tooltips.download_txt");
        if (attachment.type === "application/pdf") {
          downloadBtnTooltip = this.t("tooltips.download_pdf");
        } else if (attachment.type && attachment.type.startsWith("image/")) {
          downloadBtnTooltip = this.t("tooltips.download_image");
        }

        const downloadButton = hasFileAttachment
          ? `<button class="download-attachment-btn" data-attachment-key="${attachment.fileAttachmentKey}" data-attachment-name="${this.escapeHtml(attachment.name)}" style="background: #0066cc; color: white; border: none; padding: 3px 8px; border-radius: 3px; cursor: pointer; font-size: 7pt; margin-right: 4px;" title="${downloadBtnTooltip}">💾</button>`
          : "";

        attachmentItem.innerHTML = `
          <span style="font-size: 16px;">${icon}</span>
          <div style="flex: 1;">
            <div style="font-weight: bold; color: #333;">${this.escapeHtml(attachment.name)}</div>
            <div style="color: #666; font-size: 7pt;">${sizeKB} KB ${extraInfo} • ${date}</div>
          </div>
          <div style="display: flex; gap: 4px;">
            ${downloadButton}
            <button class="delete-attachment-btn" data-attachment-id="${attachment.id}" data-attachment-key="${attachment.fileAttachmentKey || ""}" style="background: #ff4444; color: white; border: none; padding: 3px 8px; border-radius: 3px; cursor: pointer; font-size: 7pt;" title="${this.t("tooltips.delete_attachment")}">🗑️</button>
          </div>
        `;

        attachmentsContainer.appendChild(attachmentItem);
      });

      messagesArea.appendChild(attachmentsContainer);

      // Actualizar tooltips dinámicos con traducciones inmediatamente
      this.updateDataI18nElements();

      // Forzar actualización adicional usando requestAnimationFrame
      requestAnimationFrame(() => {
        this.updateDataI18nElements();
        if (this.isEdgeBrowser) {
          this.forceUpdateTooltipsForEdge();
        }
      });

      // Timeouts adicionales específicos para Microsoft Edge con actualizaciones forzadas
      if (this.isEdgeBrowser) {
        // Múltiples intentos de actualización para asegurar que Edge procese las traducciones
        setTimeout(() => {
          this.updateDataI18nElements();
          this.forceUpdateTooltipsForEdge();
        }, 50);

        setTimeout(() => {
          this.updateDataI18nElements();
          this.forceUpdateTooltipsForEdge();
        }, 150);

        setTimeout(() => {
          this.updateDataI18nElements();
          this.forceUpdateTooltipsForEdge();
        }, 300);

        setTimeout(() => {
          this.updateDataI18nElements();
          this.forceUpdateTooltipsForEdge();
        }, 500);

        setTimeout(() => {
          this.forceUpdateTooltipsForEdge();
        }, 800);

        setTimeout(() => {
          this.forceUpdateTooltipsForEdge();
        }, 1200);
      }

      // Event listeners para descargar attachments
      attachmentsContainer
        .querySelectorAll(".download-attachment-btn")
        .forEach((btn) => {
          btn.addEventListener("click", async (e) => {
            const fileKey = e.target.dataset.attachmentKey;
            const fileName = e.target.dataset.attachmentName;

            try {
              const fileData = await this.getFileAttachment(fileKey);
              if (!fileData) {
                throw new Error("Archivo no encontrado");
              }

              // Crear blob y descargar
              const blob = new Blob([fileData.data], { type: fileData.type });
              const url = URL.createObjectURL(blob);
              const a = document.createElement("a");
              a.href = url;
              a.download = fileName;
              document.body.appendChild(a);
              a.click();
              document.body.removeChild(a);
              URL.revokeObjectURL(url);

              console.log(`💾 Archivo descargado: ${fileName}`);
            } catch (error) {
              console.error("Error descargando archivo:", error);
              alert(this.t("errors.download_file_failed"));
            }
          });
        });

      // Event listeners para eliminar attachments
      attachmentsContainer
        .querySelectorAll(".delete-attachment-btn")
        .forEach((btn) => {
          btn.addEventListener("click", async (e) => {
            const attachmentId = e.target.dataset.attachmentId;
            const fileKey = e.target.dataset.attachmentKey;

            if (
              confirm(
                this.t("confirm.delete_attachment") ||
                  "¿Eliminar este archivo adjunto?",
              )
            ) {
              try {
                // Eliminar attachment de texto/contenido
                await this.deleteAttachment(attachmentId);

                // Eliminar archivo binario si existe
                if (fileKey) {
                  await this.deleteFileAttachment(fileKey);
                }

                chat.attachments = chat.attachments.filter(
                  (a) => a.id !== attachmentId,
                );
                this.saveChats();
                this.renderMessages(chat);
                console.log(`🗑️ Archivo adjunto eliminado: ${attachmentId}`);
              } catch (error) {
                console.error("Error eliminando attachment:", error);
                alert(
                  this.t("errors.delete_attachment_failed") ||
                    "Error al eliminar el archivo",
                );
              }
            }
          });
        });
    }

    const messagesRenderStart = performance.now();
    let formatTotalTime = 0;

    chat.messages.forEach((message, index) => {
      const messageElement = document.createElement("div");
      messageElement.className = "message";

      const time = new Date(message.timestamp).toLocaleTimeString("es-ES", {
        hour: "2-digit",
        minute: "2-digit",
      });

      const senderClass =
        message.type === "user" ? "message-user" : "message-ai";
      let sender =
        message.type === "user" ? this.t("chat.you") : this.t("chat.ai");

      // Para salas de expertos, mostrar el nombre del modelo
      if (chat.isExpertRoom && message.type === "ai" && message.model) {
        sender = `${this.t("chat.ai")} (${message.model})`;
      }

      // Añadir indicador visual para mensajes de sistema
      const systemIndicator = message.isSystem
        ? `<span style="color: #999; font-size: 7pt; margin-left: 5px;">(${this.t("chat.system")})</span>`
        : "";

      const formatStart = performance.now();
      const formattedContent = this.formatMessage(message.content);
      const formatTime = performance.now() - formatStart;
      formatTotalTime += formatTime;

      if (formatTime > 50) {
        console.warn(
          `⚠️ [RenderMessages] Formato lento en mensaje ${index}: ${formatTime.toFixed(2)}ms para ${message.content.length} caracteres`,
        );
      }

      messageElement.innerHTML = `
      <span class="${senderClass}"><strong>${sender}</strong>${systemIndicator}</span>
      <span class="message-timestamp">${time}</span>
      <div class="message-content">${formattedContent}</div>
    `;

      messagesArea.appendChild(messageElement);
    });

    const messagesRenderTime = performance.now() - messagesRenderStart;
    console.log(
      `🔵 [RenderMessages] ${chat.messages.length} mensajes renderizados en ${messagesRenderTime.toFixed(2)}ms (formato total: ${formatTotalTime.toFixed(2)}ms)`,
    );

    if (messagesRenderTime > 200) {
      console.warn(
        `⚠️ [RenderMessages] Renderizado de mensajes LENTO: ${messagesRenderTime.toFixed(2)}ms`,
      );
    }

    // Scroll inteligente: solo auto-scroll si el usuario estaba al final o no ha scrolleado manualmente
    const scrollStart = performance.now();
    if (!this.userScrolledUp || wasAtBottom) {
      messagesArea.scrollTop = messagesArea.scrollHeight;
    }
    const scrollTime = performance.now() - scrollStart;

    // Configurar event listeners para botones de código
    const setupStart = performance.now();
    this.setupCodeBlockButtons();
    const setupTime = performance.now() - setupStart;

    if (setupTime > 50) {
      console.warn(
        `⚠️ [RenderMessages] Setup de botones lento: ${setupTime.toFixed(2)}ms`,
      );
    }

    const totalTime = performance.now() - renderStart;
    console.log(
      `✅ [RenderMessages] Render completo terminado en ${totalTime.toFixed(2)}ms`,
    );

    if (totalTime > 300) {
      console.warn(
        `⚠️ [RenderMessages] RENDER TOTAL MUY LENTO: ${totalTime.toFixed(2)}ms - ESTE ES EL PROBLEMA`,
      );
    }
  }

  /**
   * Muestra un botón flotante para volver al final del chat cuando hay nuevos mensajes
   */
  showScrollToBottomButton() {
    // Solo mostrar si el usuario ha scrolleado hacia arriba
    if (!this.userScrolledUp) return;

    let btn = document.getElementById("scroll-to-bottom-btn");
    if (!btn) {
      btn = document.createElement("button");
      btn.id = "scroll-to-bottom-btn";
      btn.className = "scroll-to-bottom-btn";
      btn.innerHTML = "↓ Nuevos mensajes";
      btn.title = "Ir al final del chat";

      btn.onclick = () => {
        const messagesArea = document.getElementById("messages-area");
        if (messagesArea) {
          messagesArea.scrollTop = messagesArea.scrollHeight;
          this.userScrolledUp = false;
          btn.remove();
        }
      };

      const chatWindow = document.getElementById("messages-area");
      if (chatWindow && chatWindow.parentElement) {
        chatWindow.parentElement.appendChild(btn);
      }
    }
  }

  /**
   * Configura los event listeners para los botones de copiar y descargar
   */
  setupCodeBlockButtons() {
    // Usar delegación de eventos para manejar botones dinámicos
    // Eliminar listener previo si existe
    if (this.codeBlockClickHandler) {
      document.removeEventListener("click", this.codeBlockClickHandler);
    }

    // Crear handler con delegación de eventos
    this.codeBlockClickHandler = (e) => {
      const btn = e.target.closest(".code-block-btn");
      if (!btn) return;

      e.preventDefault();
      e.stopPropagation();

      const code = btn.getAttribute("data-code");
      if (!code) return;

      // Botón copiar
      if (btn.innerHTML.includes("Copiar")) {
        navigator.clipboard
          .writeText(code)
          .then(() => {
            const originalText = btn.innerHTML;
            btn.innerHTML = "✅ Copiado";
            btn.style.backgroundColor = "#00aa00";
            setTimeout(() => {
              btn.innerHTML = originalText;
              btn.style.backgroundColor = "";
            }, 2000);
          })
          .catch((err) => {
            console.error("Error al copiar:", err);
            btn.innerHTML = "❌ Error";
            setTimeout(() => {
              btn.innerHTML = "📋 Copiar";
            }, 2000);
          });
      }

      // Botón descargar
      if (btn.innerHTML.includes("Descargar")) {
        const lang = btn.getAttribute("data-lang") || "txt";
        const blob = new Blob([code], { type: "text/plain;charset=utf-8" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `code_${Date.now()}.${lang}`;
        a.click();
        URL.revokeObjectURL(url);

        const originalText = btn.innerHTML;
        btn.innerHTML = "✅ Descargado";
        btn.style.backgroundColor = "#0066cc";
        setTimeout(() => {
          btn.innerHTML = originalText;
          btn.style.backgroundColor = "";
        }, 2000);
      }
    };

    // Agregar listener al document
    document.addEventListener("click", this.codeBlockClickHandler);
  }
  //-------------------------------------
  /**
   * Formatea el contenido del mensaje usando Markdown seguro
   * @param {string} content - Contenido del mensaje
   * @returns {string} HTML sanitizado
   */
  formatMessage(content) {
    // Usar el renderizador seguro de Markdown
    return this.renderMarkdownSafe(content);
  }

  showAIThinking(show) {
    const thinkingElement = document.getElementById("ai-thinking");
    if (show) {
      thinkingElement.style.display = "flex";
      this.startThinkingAnimation();
    } else {
      thinkingElement.style.display = "none";
      this.stopThinkingAnimation();
    }
  }

  startThinkingAnimation() {
    const dots = document.getElementById("dots");
    this.thinkingInterval = setInterval(() => {
      const current = dots.textContent;
      dots.textContent = current.length >= 3 ? "." : current + ".";
    }, 500);
  }

  stopThinkingAnimation() {
    if (this.thinkingInterval) {
      clearInterval(this.thinkingInterval);
      this.thinkingInterval = null;
    }
  }

  clearChatArea() {
    document.getElementById("chat-contact-name").textContent =
      this.t("chat.select_chat");
    document.getElementById("chat-status-message").textContent =
      this.t("app_title");
    document.getElementById("messages-area").innerHTML = `
            <div class="message">
                <span style="color: #666; font-size: 7pt; font-style: italic;">
                    ${this.t("chat.welcome_message")}
                </span>
            </div>
        `;
    document.getElementById("message-input").disabled = true;
    document.getElementById("send-button").disabled = true;
  }

  updateConnectionStatus(status) {
    const indicator = document.getElementById("connection-indicator");
    const text = document.getElementById("connection-text");
    switch (status) {
      case "connected":
        indicator.className = "connection-status status-connected";
        text.textContent = this.t("status.connected");
        break;
      case "connecting":
        indicator.className = "connection-status status-connecting";
        text.textContent = this.t("status.connecting");
        break;
      case "disconnected":
        indicator.className = "connection-status status-disconnected";
        text.textContent = this.t("status.disconnected");
        break;
    }
  }

  updateModelStatus() {
    const modelElement = document.getElementById("current-model");
    if (this.availableModels.length > 0) {
      const current = this.availableModels.find(
        (m) => m.name === this.settings.selectedModel,
      );
      if (current) {
        modelElement.textContent = `${current.name} (${(current.size / 1024 / 1024 / 1024).toFixed(1)}GB)`;
      } else {
        modelElement.textContent = this.t("connection.model_not_available", {
          model: this.settings.selectedModel,
        });
      }
    } else {
      modelElement.textContent = this.t("connection.no_models_available");
    }
  }
  //----------------------------------
  updateSettingsUI() {
    const soundsEnabledEl = document.getElementById("sounds-enabled");
    const ollamaServerEl = document.getElementById("ollama-server");
    const modelSelectEl = document.getElementById("model-select");
    const notifyStatusEl = document.getElementById("notify-status-changes");
    const groupChatSystemPromptEl = document.getElementById(
      "group-chat-system-prompt",
    );

    if (soundsEnabledEl) soundsEnabledEl.checked = this.settings.soundsEnabled;
    if (ollamaServerEl) ollamaServerEl.value = this.settings.ollamaServer;
    if (modelSelectEl) modelSelectEl.value = this.settings.selectedModel;
    if (notifyStatusEl)
      notifyStatusEl.checked = this.settings.notifyStatusChanges;

    // Cargar system prompt para salas de chat grupales
    if (groupChatSystemPromptEl) {
      // Cargar la traducción actual del system prompt
      const defaultPrompt =
        this.t("settings.default_group_chat_system_prompt") || "";

      // Si no hay system prompt configurado o es el default, usar el traducido
      if (
        !this.settings.groupChatSystemPrompt ||
        this.settings.groupChatSystemPrompt === defaultPrompt
      ) {
        this.settings.groupChatSystemPrompt = defaultPrompt;
      }

      groupChatSystemPromptEl.value = this.settings.groupChatSystemPrompt;
    }
  }
  //--------------------------------
  async exportChats() {
    try {
      // Verificar estado de IndexedDB
      if (!this.db) {
        console.warn(
          "⚠️ IndexedDB no está inicializada, esperando inicialización...",
        );
        await this.initAttachmentsDB();
      }

      // Exportar todos los archivos adjuntos de IndexedDB
      const attachments = await this.getAllAttachments();
      console.log(
        `📤 Exportando ${attachments.length} archivos adjuntos de IndexedDB`,
      );

      if (attachments.length > 0) {
        console.log(
          "📦 Primeros 3 attachments:",
          attachments.slice(0, 3).map((a) => ({
            id: a.id,
            name: a.name,
            type: a.type,
            hasContent: !!a.content,
            contentLength: a.content ? a.content.length : 0,
            hasChunks: !!a.chunks,
            chunksCount: Array.isArray(a.chunks) ? a.chunks.length : 0,
          })),
        );
      } else {
        console.log("ℹ️ No hay archivos adjuntos para exportar");
      }

      // Exportar archivos binarios
      const fileAttachments = await this.getAllFileAttachments();
      console.log(`📤 Exportando ${fileAttachments.length} archivos binarios`);

      // Convertir ArrayBuffers a Base64 para incluirlos en JSON
      const fileAttachmentsBase64 = fileAttachments.map((file) => ({
        key: file.key,
        data: this.arrayBufferToBase64(file.data),
        type: file.type,
        name: file.name,
        chatId: file.chatId,
      }));

      const data = {
        version: "2.1",
        exportDate: new Date().toISOString(),
        chats: this.chats,
        settings: this.settings,
        attachments: attachments,
        fileAttachments: fileAttachmentsBase64,
      };

      console.log(
        `📦 Tamaño total del JSON: ${JSON.stringify(data).length} caracteres`,
      );

      const blob = new Blob([JSON.stringify(data, null, 2)], {
        type: "application/json",
      });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `msn-ai-chats-${new Date().toISOString().split("T")[0]}.json`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      this.playSound("nudge");

      console.log("✅ Exportación completada exitosamente");
    } catch (error) {
      console.error("❌ Error exportando chats:", error);
      alert(this.t("errors.export_failed") || "Error al exportar chats");
    }
  }

  /**
   * Obtiene todos los archivos adjuntos de IndexedDB
   */
  async getAllAttachments() {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        resolve([]);
        return;
      }

      const transaction = this.db.transaction(["attachments"], "readonly");
      const objectStore = transaction.objectStore("attachments");
      const request = objectStore.getAll();

      request.onsuccess = () => {
        resolve(request.result || []);
      };

      request.onerror = () => {
        console.error("Error obteniendo attachments:", request.error);
        reject(request.error);
      };
    });
  }

  /**
   * Obtiene todos los archivos binarios de IndexedDB
   */
  async getAllFileAttachments() {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        resolve([]);
        return;
      }

      const transaction = this.db.transaction(["fileAttachments"], "readonly");
      const objectStore = transaction.objectStore("fileAttachments");
      const request = objectStore.getAll();

      request.onsuccess = () => {
        resolve(request.result || []);
      };

      request.onerror = () => {
        console.error("Error obteniendo fileAttachments:", request.error);
        reject(request.error);
      };
    });
  }

  /**
   * Convierte ArrayBuffer a Base64
   */
  arrayBufferToBase64(buffer) {
    let binary = "";
    const bytes = new Uint8Array(buffer);
    const len = bytes.byteLength;
    for (let i = 0; i < len; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary);
  }

  /**
   * Convierte Base64 a ArrayBuffer
   */
  base64ToArrayBuffer(base64) {
    const binaryString = atob(base64);
    const len = binaryString.length;
    const bytes = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes.buffer;
  }

  importChats(file) {
    const reader = new FileReader();
    reader.onload = async (e) => {
      try {
        const data = JSON.parse(e.target.result);
        if (data.chats && Array.isArray(data.chats)) {
          // Si hay archivos adjuntos en la exportación, importarlos primero
          if (data.attachments && Array.isArray(data.attachments)) {
            console.log(
              `📥 Importando ${data.attachments.length} archivos adjuntos`,
            );
            if (data.attachments.length > 0) {
              console.log(
                "📦 Primeros 3 attachments a importar:",
                data.attachments.slice(0, 3).map((a) => ({
                  id: a.id,
                  name: a.name,
                  type: a.type,
                  hasContent: !!a.content,
                  contentLength: a.content ? a.content.length : 0,
                })),
              );
            }
            await this.importAttachments(data.attachments);
          } else {
            console.log(
              "⚠️ No se encontraron archivos adjuntos en la importación",
            );
          }

          // Importar archivos binarios si existen
          if (data.fileAttachments && Array.isArray(data.fileAttachments)) {
            console.log(
              `📥 Importando ${data.fileAttachments.length} archivos binarios`,
            );
            await this.importFileAttachments(data.fileAttachments);
          } else {
            console.log(
              "⚠️ No se encontraron archivos binarios en la importación",
            );
          }

          this.processImportedChats(data.chats);
        } else {
          alert(this.t("errors.invalid_json"));
        }
      } catch (error) {
        console.error("Error importando chats:", error);
        alert(this.t("errors.invalid_file"));
      }
    };
    reader.readAsText(file);
  }

  /**
   * Importa los archivos adjuntos a IndexedDB
   */
  async importAttachments(attachments) {
    if (!this.db) {
      console.error(
        "❌ IndexedDB no está inicializada para importar attachments",
      );
      return;
    }

    if (!attachments || attachments.length === 0) {
      console.log("ℹ️ No hay archivos adjuntos para importar");
      return;
    }

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(["attachments"], "readwrite");
      const objectStore = transaction.objectStore("attachments");

      let completed = 0;
      let errors = 0;

      attachments.forEach((attachment) => {
        const request = objectStore.put(attachment);

        request.onsuccess = () => {
          completed++;
          console.log(
            `✅ Attachment importado (${completed}/${attachments.length}): ${attachment.name}`,
          );
          if (completed + errors === attachments.length) {
            console.log(
              `✅ Importación completada: ${completed} archivos adjuntos importados`,
            );
            if (errors > 0) {
              console.warn(`⚠️ ${errors} archivos adjuntos fallaron`);
            }
            resolve();
          }
        };

        request.onerror = () => {
          console.error(
            `❌ Error importando attachment: ${attachment.id} - ${attachment.name}`,
            request.error,
          );
          errors++;
          if (completed + errors === attachments.length) {
            if (completed > 0) {
              console.log(
                `⚠️ Importación parcial: ${completed} importados, ${errors} fallidos`,
              );
            } else {
              console.error(
                `❌ Importación fallida: todos los ${errors} archivos fallaron`,
              );
            }
            resolve();
          }
        };
      });
    });
  }

  /**
   * Importa los archivos binarios a IndexedDB
   */
  async importFileAttachments(fileAttachments) {
    if (!this.db) {
      console.error(
        "❌ IndexedDB no está inicializada para importar fileAttachments",
      );
      return;
    }

    if (!fileAttachments || fileAttachments.length === 0) {
      console.log("ℹ️ No hay archivos binarios para importar");
      return;
    }

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(["fileAttachments"], "readwrite");
      const objectStore = transaction.objectStore("fileAttachments");

      let completed = 0;
      let errors = 0;

      fileAttachments.forEach((file) => {
        try {
          // Convertir Base64 de vuelta a ArrayBuffer
          const arrayBuffer = this.base64ToArrayBuffer(file.data);

          const fileData = {
            key: file.key,
            data: arrayBuffer,
            type: file.type,
            name: file.name,
            chatId: file.chatId,
          };

          const request = objectStore.put(fileData);

          request.onsuccess = () => {
            completed++;
            console.log(
              `✅ Archivo binario importado (${completed}/${fileAttachments.length}): ${file.name}`,
            );
            if (completed + errors === fileAttachments.length) {
              console.log(
                `✅ Importación de archivos binarios completada: ${completed} archivos`,
              );
              if (errors > 0) {
                console.warn(`⚠️ ${errors} archivos binarios fallaron`);
              }
              resolve();
            }
          };

          request.onerror = () => {
            console.error(
              `❌ Error importando archivo binario: ${file.key} - ${file.name}`,
              request.error,
            );
            errors++;
            if (completed + errors === fileAttachments.length) {
              if (completed > 0) {
                console.log(
                  `⚠️ Importación parcial: ${completed} importados, ${errors} fallidos`,
                );
              } else {
                console.error(
                  `❌ Importación fallida: todos los ${errors} archivos fallaron`,
                );
              }
              resolve();
            }
          };
        } catch (error) {
          console.error(
            `❌ Error procesando archivo binario: ${file.name}`,
            error,
          );
          errors++;
          if (completed + errors === fileAttachments.length) {
            if (completed > 0) {
              console.log(
                `⚠️ Importación parcial: ${completed} importados, ${errors} fallidos`,
              );
            } else {
              console.error(
                `❌ Importación fallida: todos los ${errors} archivos fallaron`,
              );
            }
            resolve();
          }
        }
      });
    });
  }

  /**
   * Actualiza el chatId de todos los attachments de un chat específico
   * @param {string} oldChatId - ID antiguo del chat
   * @param {string} newChatId - ID nuevo del chat
   */
  async updateAttachmentsChatId(oldChatId, newChatId) {
    if (!this.db) {
      console.error("❌ IndexedDB no está inicializada");
      return;
    }

    // Actualizar tanto attachments como fileAttachments
    await this.updateTextAttachmentsChatId(oldChatId, newChatId);
    await this.updateFileAttachmentsChatId(oldChatId, newChatId);
  }

  /**
   * Actualiza el chatId de los attachments de texto
   * @param {string} oldChatId - ID antiguo del chat
   * @param {string} newChatId - ID nuevo del chat
   */
  async updateTextAttachmentsChatId(oldChatId, newChatId) {
    if (!this.db) {
      console.error("❌ IndexedDB no está inicializada");
      return;
    }

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(["attachments"], "readwrite");
      const objectStore = transaction.objectStore("attachments");
      const index = objectStore.index("chatId");
      const request = index.getAll(oldChatId);

      request.onsuccess = () => {
        const attachments = request.result;

        if (!attachments || attachments.length === 0) {
          console.log(
            `ℹ️ No se encontraron attachments para el chat ${oldChatId}`,
          );
          resolve();
          return;
        }

        let updated = 0;
        let errors = 0;

        attachments.forEach((attachment) => {
          // Crear nueva entrada con el nuevo chatId
          const oldId = attachment.id;
          const newId = oldId.replace(oldChatId, newChatId);

          const updatedAttachment = {
            ...attachment,
            id: newId,
            chatId: newChatId,
          };

          // Actualizar también el fileAttachmentKey si existe
          if (updatedAttachment.fileAttachmentKey) {
            const oldKey = updatedAttachment.fileAttachmentKey;
            updatedAttachment.fileAttachmentKey =
              updatedAttachment.fileAttachmentKey.replace(oldChatId, newChatId);
            console.log(
              `🔑 FileAttachmentKey actualizado: ${oldKey} -> ${updatedAttachment.fileAttachmentKey}`,
            );
          }

          // Eliminar la entrada antigua
          const deleteRequest = objectStore.delete(oldId);

          deleteRequest.onsuccess = () => {
            // Agregar la nueva entrada
            const putRequest = objectStore.put(updatedAttachment);

            putRequest.onsuccess = () => {
              updated++;
              if (updated + errors === attachments.length) {
                console.log(
                  `✅ ${updated} attachments actualizados de ${oldChatId} a ${newChatId}`,
                );
                resolve();
              }
            };

            putRequest.onerror = () => {
              console.error(
                `❌ Error actualizando attachment ${newId}:`,
                putRequest.error,
              );
              errors++;
              if (updated + errors === attachments.length) {
                resolve();
              }
            };
          };

          deleteRequest.onerror = () => {
            console.error(
              `❌ Error eliminando attachment ${oldId}:`,
              deleteRequest.error,
            );
            errors++;
            if (updated + errors === attachments.length) {
              resolve();
            }
          };
        });
      };

      request.onerror = () => {
        console.error("❌ Error obteniendo attachments:", request.error);
        reject(request.error);
      };
    });
  }

  /**
   * Actualiza el chatId de los archivos binarios
   * @param {string} oldChatId - ID antiguo del chat
   * @param {string} newChatId - ID nuevo del chat
   */
  async updateFileAttachmentsChatId(oldChatId, newChatId) {
    if (!this.db) {
      console.error("❌ IndexedDB no está inicializada");
      return;
    }

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(["fileAttachments"], "readwrite");
      const objectStore = transaction.objectStore("fileAttachments");
      const index = objectStore.index("chatId");
      const request = index.getAll(oldChatId);

      request.onsuccess = () => {
        const fileAttachments = request.result;

        if (!fileAttachments || fileAttachments.length === 0) {
          console.log(
            `ℹ️ No se encontraron fileAttachments para el chat ${oldChatId}`,
          );
          resolve();
          return;
        }

        let updated = 0;
        let errors = 0;

        fileAttachments.forEach((file) => {
          // Crear nueva clave con el nuevo chatId
          const oldKey = file.key;
          const newKey = oldKey.replace(oldChatId, newChatId);

          const updatedFile = {
            ...file,
            key: newKey,
            chatId: newChatId,
          };

          // Eliminar la entrada antigua
          const deleteRequest = objectStore.delete(oldKey);

          deleteRequest.onsuccess = () => {
            // Agregar la nueva entrada
            const putRequest = objectStore.put(updatedFile);

            putRequest.onsuccess = () => {
              updated++;
              if (updated + errors === fileAttachments.length) {
                console.log(
                  `✅ ${updated} archivos binarios actualizados de ${oldChatId} a ${newChatId}`,
                );
                resolve();
              }
            };

            putRequest.onerror = () => {
              console.error(
                `❌ Error actualizando archivo binario ${newKey}:`,
                putRequest.error,
              );
              errors++;
              if (updated + errors === fileAttachments.length) {
                resolve();
              }
            };
          };

          deleteRequest.onerror = () => {
            console.error(
              `❌ Error eliminando archivo binario ${oldKey}:`,
              deleteRequest.error,
            );
            errors++;
            if (updated + errors === fileAttachments.length) {
              resolve();
            }
          };
        });
      };

      request.onerror = () => {
        console.error("❌ Error obteniendo fileAttachments:", request.error);
        reject(request.error);
      };
    });
  }

  async processImportedChats(importedChats) {
    let imported = 0;
    let skipped = 0;
    let merged = 0;
    let replaced = 0;
    const conflicts = [];

    for (const importedChat of importedChats) {
      const duplicate = this.findDuplicateChat(importedChat);

      if (!duplicate) {
        // No existe, importar directamente
        const oldChatId = importedChat.id;
        const newChatId = "imported-" + Date.now() + "-" + Math.random();
        importedChat.id = newChatId;

        // Actualizar los IDs de los attachments para que coincidan con el nuevo chatId
        if (importedChat.attachments && importedChat.attachments.length > 0) {
          await this.updateAttachmentsChatId(oldChatId, newChatId);

          // Actualizar también los IDs en el array de attachments del chat
          importedChat.attachments = importedChat.attachments.map((att) => {
            const updatedAtt = {
              ...att,
              id: att.id.replace(oldChatId, newChatId),
            };

            // Actualizar también el fileAttachmentKey si existe
            if (updatedAtt.fileAttachmentKey) {
              updatedAtt.fileAttachmentKey =
                updatedAtt.fileAttachmentKey.replace(oldChatId, newChatId);
            }

            return updatedAtt;
          });

          console.log(
            `🔄 Actualizados ${importedChat.attachments.length} attachments del chat ${oldChatId} -> ${newChatId}`,
          );
        }

        this.chats.unshift(importedChat);
        imported++;
      } else {
        // Existe duplicado, agregar a la lista de conflictos
        conflicts.push({ imported: importedChat, existing: duplicate });
      }
    }

    // Si hay conflictos, mostrar modal de resolución
    if (conflicts.length > 0) {
      const result = await this.showImportConflictModal(conflicts);
      imported += result.imported;
      merged += result.merged;
      replaced += result.replaced;
      skipped += result.skipped;
    }

    this.saveChats();
    this.renderChatList();
    this.playSound("login");

    // Mostrar resumen en modal personalizado
    this.showImportSummary(imported, merged, replaced, skipped);
  }

  findDuplicateChat(importedChat) {
    return this.chats.find((existingChat) => {
      // Comparar por modelo y título similar
      if (existingChat.model !== importedChat.model) return false;

      // Comparar títulos (normalizado)
      const existingTitle = existingChat.title.trim().toLowerCase();
      const importedTitle = importedChat.title.trim().toLowerCase();

      if (existingTitle === importedTitle) return true;

      // También comparar por primer mensaje del usuario si existe
      const existingFirstMsg = existingChat.messages.find(
        (m) => m.type === "user",
      );
      const importedFirstMsg = importedChat.messages.find(
        (m) => m.type === "user",
      );

      if (existingFirstMsg && importedFirstMsg) {
        return (
          existingFirstMsg.content.substring(0, 100) ===
          importedFirstMsg.content.substring(0, 100)
        );
      }

      return false;
    });
  }

  async showImportConflictModal(conflicts) {
    return new Promise((resolve) => {
      let currentIndex = 0;
      let imported = 0,
        merged = 0,
        replaced = 0,
        skipped = 0;

      const modal = document.getElementById("import-conflict-modal");
      const titleEl = document.getElementById("conflict-title");
      const modelEl = document.getElementById("conflict-model");
      const existingCountEl = document.getElementById(
        "conflict-existing-count",
      );
      const importedCountEl = document.getElementById(
        "conflict-imported-count",
      );
      const warningEl = document.getElementById("conflict-warning");
      const counterEl = document.getElementById("conflict-counter");
      const applyBtn = document.getElementById("conflict-apply-btn");
      const replaceOption = document.getElementById("replace-option");

      const showConflict = () => {
        if (currentIndex >= conflicts.length) {
          modal.style.display = "none";
          resolve({ imported, merged, replaced, skipped });
          return;
        }

        const conflict = conflicts[currentIndex];
        const existingChat = conflict.existing;
        const importedChat = conflict.imported;

        // Comparar cantidad de información
        const existingMsgCount = existingChat.messages.length;
        const importedMsgCount = importedChat.messages.length;
        const wouldLoseInfo = importedMsgCount < existingMsgCount;

        // Actualizar contenido del modal
        titleEl.textContent = existingChat.title;
        modelEl.textContent = existingChat.model;
        existingCountEl.textContent = existingMsgCount;
        importedCountEl.textContent = importedMsgCount;
        counterEl.textContent = this.t("import_conflict.counter", {
          current: currentIndex + 1,
          total: conflicts.length,
        });

        // Mostrar/ocultar advertencia
        if (wouldLoseInfo) {
          warningEl.style.display = "block";
          replaceOption.style.opacity = "0.5";
          replaceOption.style.pointerEvents = "none";
          const replaceRadio = replaceOption.querySelector(
            'input[type="radio"]',
          );
          replaceRadio.disabled = true;
        } else {
          warningEl.style.display = "none";
          replaceOption.style.opacity = "1";
          replaceOption.style.pointerEvents = "auto";
          const replaceRadio = replaceOption.querySelector(
            'input[type="radio"]',
          );
          replaceRadio.disabled = false;
        }

        // Resetear selección a "Unir" por defecto
        document.querySelector(
          'input[name="conflict-action"][value="merge"]',
        ).checked = true;

        // Mostrar modal
        modal.style.display = "block";

        // Manejar clic en aplicar
        const handleApply = async () => {
          const selectedAction = document.querySelector(
            'input[name="conflict-action"]:checked',
          ).value;

          if (selectedAction === "skip-all") {
            skipped += conflicts.length - currentIndex;
            applyBtn.removeEventListener("click", handleApply);
            modal.style.display = "none";
            resolve({ imported, merged, replaced, skipped });
            return;
          }

          if (selectedAction === "replace") {
            if (wouldLoseInfo) {
              // Mostrar advertencia en el modal en lugar de alert
              const warningEl = document.getElementById("conflict-warning");
              const warningText = warningEl.querySelector("p");
              warningText.innerHTML =
                `⚠️ <strong>NO SE PUEDE REEMPLAZAR:</strong> Se perdería información.<br>` +
                `Chat existente: ${existingMsgCount} mensajes<br>` +
                `Chat a importar: ${importedMsgCount} mensajes<br><br>` +
                `Este chat será omitido automáticamente.`;
              warningEl.style.background = "#f8d7da";
              warningEl.style.display = "block";

              // Auto-omitir después de 2 segundos
              setTimeout(() => {
                warningEl.style.display = "none";
                warningText.innerHTML = this.t("import_conflict.warning");
                warningEl.style.background = "#fff3cd";
              }, 2000);

              skipped++;
            } else {
              const index = this.chats.indexOf(existingChat);
              const oldChatId = importedChat.id;
              const existingChatId = existingChat.id;

              // Actualizar IDs de attachments si existen
              if (
                importedChat.attachments &&
                importedChat.attachments.length > 0
              ) {
                // Eliminar attachments antiguos del chat existente
                if (
                  existingChat.attachments &&
                  existingChat.attachments.length > 0
                ) {
                  for (const att of existingChat.attachments) {
                    try {
                      await this.deleteAttachment(att.id);
                    } catch (error) {
                      console.error(
                        `Error eliminando attachment antiguo ${att.id}:`,
                        error,
                      );
                    }
                  }
                }

                // Actualizar IDs de attachments importados
                await this.updateAttachmentsChatId(oldChatId, existingChatId);
                importedChat.attachments = importedChat.attachments.map(
                  (att) => {
                    const updatedAtt = {
                      ...att,
                      id: att.id.replace(oldChatId, existingChatId),
                    };

                    // Actualizar también el fileAttachmentKey si existe
                    if (updatedAtt.fileAttachmentKey) {
                      updatedAtt.fileAttachmentKey =
                        updatedAtt.fileAttachmentKey.replace(
                          oldChatId,
                          existingChatId,
                        );
                    }

                    return updatedAtt;
                  },
                );
                console.log(
                  `🔄 Attachments actualizados para reemplazo: ${oldChatId} -> ${existingChatId}`,
                );
              }

              importedChat.id = existingChatId;
              this.chats[index] = importedChat;
              replaced++;
            }
          } else if (selectedAction === "merge") {
            await this.mergeChats(existingChat, importedChat);
            merged++;
          } else if (selectedAction === "skip") {
            skipped++;
          }

          currentIndex++;
          applyBtn.removeEventListener("click", handleApply);
          showConflict();
        };

        applyBtn.addEventListener("click", handleApply);
      };

      showConflict();
    });
  }

  async mergeChats(existingChat, importedChat) {
    // Primero, manejar los attachments
    if (importedChat.attachments && importedChat.attachments.length > 0) {
      const oldChatId = importedChat.id;
      const existingChatId = existingChat.id;

      // Actualizar IDs de attachments importados
      await this.updateAttachmentsChatId(oldChatId, existingChatId);

      // Actualizar referencias en el array
      const updatedImportedAttachments = importedChat.attachments.map((att) => {
        const updatedAtt = {
          ...att,
          id: att.id.replace(oldChatId, existingChatId),
        };

        // Actualizar también el fileAttachmentKey si existe
        if (updatedAtt.fileAttachmentKey) {
          updatedAtt.fileAttachmentKey = updatedAtt.fileAttachmentKey.replace(
            oldChatId,
            existingChatId,
          );
        }

        return updatedAtt;
      });

      // Combinar attachments (evitar duplicados por ID)
      if (!existingChat.attachments) {
        existingChat.attachments = [];
      }

      const existingAttachmentIds = new Set(
        existingChat.attachments.map((a) => a.id),
      );
      const newAttachments = updatedImportedAttachments.filter(
        (att) => !existingAttachmentIds.has(att.id),
      );

      existingChat.attachments.push(...newAttachments);
      console.log(
        `🔄 ${newAttachments.length} attachments nuevos agregados en merge`,
      );
    }

    // Unión inteligente: detectar mensajes parciales y completarlos
    const existingMsgMap = new Map();

    // Indexar mensajes existentes por timestamp y tipo
    existingChat.messages.forEach((msg, index) => {
      const key = `${msg.timestamp}-${msg.type}`;
      existingMsgMap.set(key, { msg, index });
    });

    let addedCount = 0;
    let updatedCount = 0;

    // Procesar mensajes importados
    importedChat.messages.forEach((importedMsg) => {
      const key = `${importedMsg.timestamp}-${importedMsg.type}`;

      if (existingMsgMap.has(key)) {
        // Existe un mensaje con mismo timestamp y tipo
        const existing = existingMsgMap.get(key);
        const existingContent = existing.msg.content;
        const importedContent = importedMsg.content;

        // Verificar si el contenido importado es una extensión del existente
        if (
          importedContent.length > existingContent.length &&
          importedContent.startsWith(existingContent)
        ) {
          // El mensaje importado contiene más información
          existing.msg.content = importedContent;
          updatedCount++;
          console.log(`✅ Mensaje actualizado con contenido extendido`);
        } else if (
          existingContent.length > importedContent.length &&
          existingContent.startsWith(importedContent)
        ) {
          // El mensaje existente ya tiene más información, no hacer nada
          console.log(
            `ℹ️ Mensaje existente ya tiene más contenido, no se actualiza`,
          );
        } else if (existingContent !== importedContent) {
          // Contenidos diferentes, verificar si uno contiene al otro parcialmente
          // o si son completamente diferentes
          if (
            !existingContent.includes(importedContent) &&
            !importedContent.includes(existingContent)
          ) {
            // Son diferentes, agregar el importado como nuevo mensaje
            existingChat.messages.push(importedMsg);
            addedCount++;
          }
        }
        // Si son idénticos, no hacer nada
      } else {
        // No existe, agregarlo como nuevo mensaje
        existingChat.messages.push(importedMsg);
        addedCount++;
      }
    });

    // Ordenar mensajes por timestamp
    existingChat.messages.sort(
      (a, b) => new Date(a.timestamp) - new Date(b.timestamp),
    );

    // Actualizar fecha si el chat importado es más reciente
    const existingDate = new Date(existingChat.date);
    const importedDate = new Date(importedChat.date);
    if (importedDate > existingDate) {
      existingChat.date = importedChat.date;
    }

    console.log(
      `✅ Chat unido: ${addedCount} mensaje(s) nuevo(s), ${updatedCount} mensaje(s) actualizado(s)`,
    );
  }

  showImportSummary(imported, merged, replaced, skipped) {
    const modal = document.getElementById("import-summary-modal");
    const content = document.getElementById("import-summary-content");

    let html = '<div style="line-height: 1.8;">';

    if (imported > 0) {
      html += `<p style="margin: 8px 0;">✅ <strong>${imported}</strong> chat(s) importado(s)</p>`;
    }
    if (merged > 0) {
      html += `<p style="margin: 8px 0;">🔀 <strong>${merged}</strong> chat(s) unido(s)</p>`;
    }
    if (replaced > 0) {
      html += `<p style="margin: 8px 0;">♻️ <strong>${replaced}</strong> chat(s) reemplazado(s)</p>`;
    }
    if (skipped > 0) {
      html += `<p style="margin: 8px 0;">⏭️ <strong>${skipped}</strong> chat(s) omitido(s)</p>`;
    }

    if (imported === 0 && merged === 0 && replaced === 0 && skipped === 0) {
      html +=
        '<p style="margin: 8px 0; color: #666;">No se realizaron cambios.</p>';
    }

    html += "</div>";
    content.innerHTML = html;
    modal.style.display = "block";
  }
  //---------------------------
  // Helper para registrar event listeners con verificacion
  addEventListenerSafe(elementId, event, handler) {
    const element = document.getElementById(elementId);
    if (element) {
      element.addEventListener(event, handler);
      console.log(`✅ Event listener registrado: ${elementId}`);
      return true;
    } else {
      console.warn(`⚠️ Elemento no encontrado: ${elementId}`);
      return false;
    }
  }

  //---------------------------
  setupEventListeners() {
    // Eventos existentes
    document
      .getElementById("send-button")
      .addEventListener("click", () => this.sendMessage());
    // Manejo mejorado del teclado en el input de mensajes
    // Soporte para Shift+Enter (nueva línea) y Enter (enviar)
    const messageInput = document.getElementById("message-input");
    messageInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        this.sendMessage();
      }
      // Shift+Enter permite nueva línea (comportamiento por defecto)
    });

    // Soporte para pegar imágenes directamente desde el portapapeles
    messageInput.addEventListener("paste", async (e) => {
      const items = e.clipboardData?.items;
      if (!items) return;

      for (let i = 0; i < items.length; i++) {
        const item = items[i];

        // Verificar si el item es una imagen
        if (item.type.indexOf("image") !== -1) {
          e.preventDefault();

          const file = item.getAsFile();
          if (!file) continue;

          // Usar el método existente para procesar la imagen
          try {
            await this.uploadImageFile(file);

            // Mostrar notificación de éxito
            this.showNotification(
              this.t("messages.image_pasted") || "Imagen pegada correctamente",
              "success",
            );
          } catch (error) {
            console.error("Error al pegar imagen:", error);
            this.showNotification(
              this.t("errors.image_paste_failed") || "Error al pegar la imagen",
              "error",
            );
          }

          break; // Solo procesar la primera imagen
        }
      }
    });

    // Navegación entre chats con Ctrl+K o Cmd+K
    document.addEventListener("keydown", (e) => {
      const isMac = navigator.platform.toUpperCase().indexOf("MAC") >= 0;
      const ctrlOrCmd = isMac ? e.metaKey : e.ctrlKey;

      if (ctrlOrCmd && e.key.toLowerCase() === "k") {
        e.preventDefault();
        const searchInput = document.getElementById("chat-search-input");
        if (searchInput) {
          searchInput.focus();
          searchInput.select();
        }
      }
    });

    // Detectar scroll manual del usuario en el área de mensajes
    const messagesArea = document.getElementById("messages-area");
    if (messagesArea) {
      messagesArea.addEventListener("scroll", () => {
        const isAtBottom =
          messagesArea.scrollHeight - messagesArea.scrollTop <=
          messagesArea.clientHeight + 50;
        this.userScrolledUp = !isAtBottom;

        // Ocultar el botón "nuevos mensajes" si el usuario vuelve al final
        if (isAtBottom) {
          const btn = document.getElementById("scroll-to-bottom-btn");
          if (btn) btn.remove();
        } else {
          // Mostrar botón si hay mensajes nuevos y el usuario está arriba
          if (
            this.respondingChats.size > 0 ||
            this.accumulatedResponses[this.currentChatId]
          ) {
            this.showScrollToBottomButton();
          }
        }
      });
    }

    document
      .getElementById("new-chat-btn")
      .addEventListener("click", () => this.createNewChat());

    // Botón crear sala de expertos
    this.addEventListenerSafe("new-room-btn", "click", () => {
      this.showExpertRoomModal();
    });

    // Botón detener respuesta IA
    document
      .getElementById("detener-respuesta-ia-btn")
      .addEventListener("click", () => this.stopAIResponse());
    document.getElementById("export-btn").addEventListener("click", () => {
      console.log("📤 Abriendo modal de exportación...");
      const exportModal = document.getElementById("export-modal");
      if (exportModal) {
        exportModal.style.display = "block";
        console.log("✅ Modal de exportación abierto");
      } else {
        console.error("❌ Modal de exportación no encontrado");
      }
    });
    document.getElementById("import-btn").addEventListener("click", () => {
      console.log("📥 Abriendo modal de importación...");
      const importModal = document.getElementById("import-modal");
      if (importModal) {
        importModal.style.display = "block";
        console.log("✅ Modal de importación abierto");
      } else {
        console.error("❌ Modal de importación no encontrado");
      }
    });

    // Event listeners para los botones dentro de los modales de import/export
    // Usar setTimeout para asegurar que los elementos del modal esten disponibles
    setTimeout(() => {
      this.addEventListenerSafe("download-chats", "click", () => {
        console.log("🔽 Exportando chats...");
        this.exportChats();
        const exportModal = document.getElementById("export-modal");
        if (exportModal) exportModal.style.display = "none";
      });

      this.addEventListenerSafe("import-chats-btn", "click", () => {
        console.log("🔼 Importando chats...");
        const fileInput = document.getElementById("import-file");
        if (!fileInput) {
          console.error("❌ import-file element not found");
          alert(this.t("errors.file_not_found"));
          return;
        }
        const file = fileInput.files[0];
        if (!file) {
          alert(this.t("errors.select_file_first"));
          return;
        }
        if (!file.name.endsWith(".json")) {
          alert(this.t("errors.select_valid_json"));
          return;
        }
        this.importChats(file);
        const importModal = document.getElementById("import-modal");
        if (importModal) importModal.style.display = "none";
        fileInput.value = "";
      });
    }, 100);

    // Botón de configuración (abrir modal)--------------------
    // En setupEventListeners(), reemplaza/añade estos eventos:
    document.getElementById("settings-btn").addEventListener("click", () => {
      // Actualizar el system prompt con la traducción actual antes de abrir el modal
      this.updateGroupChatSystemPrompt();
      this.updateSettingsUI();
      document.getElementById("settings-modal").style.display = "block";
    });

    // AÑADE ESTOS EVENTOS SI NO EXISTEN:
    document
      .getElementById("test-connection")
      .addEventListener("click", async () => {
        const btn = document.getElementById("test-connection");
        btn.textContent = this.t("settings.testing_connection");
        btn.disabled = true;

        const connected = await this.checkConnection();

        if (connected) {
          alert(
            this.t("settings.connection_success", {
              count: this.availableModels.length,
              server: this.settings.ollamaServer,
            }),
          );
        } else {
          alert(this.t("settings.connection_failed"));
        }

        btn.textContent = "🔌 " + this.t("buttons.test_connection");
        btn.disabled = false;
      });

    // Botón de reset para system prompt
    document
      .getElementById("reset-system-prompt-btn")
      .addEventListener("click", () => {
        const groupChatSystemPromptEl = document.getElementById(
          "group-chat-system-prompt",
        );
        if (groupChatSystemPromptEl) {
          // Obtener el system prompt por defecto del idioma actual
          const defaultPrompt =
            this.t("settings.default_group_chat_system_prompt") || "";

          // Actualizar el campo y el setting
          groupChatSystemPromptEl.value = defaultPrompt;
          this.settings.groupChatSystemPrompt = defaultPrompt;

          console.log(
            `🔄 System prompt restaurado al valor predeterminado para idioma: ${this.currentLanguage}`,
          );
        }
      });

    document.getElementById("save-settings").addEventListener("click", () => {
      this.settings.soundsEnabled =
        document.getElementById("sounds-enabled").checked;
      this.settings.ollamaServer = document
        .getElementById("ollama-server")
        .value.trim();
      this.settings.selectedModel =
        document.getElementById("model-select").value;
      this.settings.notifyStatusChanges = document.getElementById(
        "notify-status-changes",
      ).checked;

      // Guardar system prompt para salas de chat grupales
      const groupChatSystemPromptEl = document.getElementById(
        "group-chat-system-prompt",
      );
      if (groupChatSystemPromptEl) {
        this.settings.groupChatSystemPrompt =
          groupChatSystemPromptEl.value.trim();
      }

      // Guardar idioma seleccionado
      const selectedLang = document.getElementById("language-select").value;
      if (selectedLang && selectedLang !== this.currentLanguage) {
        this.setLanguage(selectedLang);
      }

      this.saveSettings();
      this.updateModelStatus();

      alert(this.t("settings.settings_saved"));
      document.getElementById("settings-modal").style.display = "none";
    });

    document.getElementById("model-select").addEventListener("change", (e) => {
      this.settings.selectedModel = e.target.value;
    });

    // Event listener para cambio de idioma
    document
      .getElementById("language-select")
      .addEventListener("change", (e) => {
        const newLang = e.target.value;
        if (newLang && newLang !== this.currentLanguage) {
          this.setLanguage(newLang);
        }
      });
    //--------------------------------------------------------------
    document
      .getElementById("chat-search-input")
      .addEventListener("input", (e) => this.filterChats(e.target.value));
    document
      .getElementById("clear-search-btn")
      .addEventListener("click", () => {
        document.getElementById("chat-search-input").value = "";
        this.filterChats("");
      });

    // === NUEVOS EVENTOS ===
    document
      .getElementById("order-history-btn")
      .addEventListener("click", () => this.orderChatHistory());
    document
      .getElementById("export-selected-chats-btn")
      .addEventListener("click", () => this.exportSelectedChats());
    document
      .getElementById("enviar-sumbido-btn")
      .addEventListener("click", () => this.sendNudge());
    document
      .getElementById("texto-por-voz-btn")
      .addEventListener("click", () => this.startVoiceInput());
    document
      .getElementById("clear-current-chat-btn")
      .addEventListener("click", () => {
        const chat = this.chats.find((c) => c.id === this.currentChatId);
        if (chat) {
          chat.messages = [];
          this.renderMessages(chat);
          this.saveChats();
        }
      });
    document
      .getElementById("increase-font-size-btn")
      .addEventListener("click", () => this.increaseFontSize());
    document
      .getElementById("decrease-font-size-btn")
      .addEventListener("click", () => this.decreaseFontSize());
    document
      .getElementById("upload-text-file-btn")
      .addEventListener("click", () => this.uploadTextFile());
    document
      .getElementById("upload-pdf-file-btn")
      .addEventListener("click", () => this.uploadPdfFile());
    document
      .getElementById("upload-image-file-btn")
      .addEventListener("click", () => this.uploadImageFile());
    document
      .getElementById("export-current-chat-btn")
      .addEventListener("click", () => this.exportCurrentChat());
    document
      .getElementById("print-current-chat-btn")
      .addEventListener("click", () => this.printCurrentChat());
    document
      .getElementById("search-current-chat-btn")
      .addEventListener("click", () => this.openSearchModal());
    document
      .getElementById("close-current-chat-btn")
      .addEventListener("click", () => this.closeCurrentChat());
    document
      .getElementById("info-btn")
      .addEventListener("click", () => this.showInfo());

    // === MODAL DE BÚSQUEDA ===
    document.getElementById("do-search-btn").addEventListener("click", () => {
      const term = document.getElementById("search-term-input").value.trim();
      this.highlightSearchResults(term);
    });
    document
      .getElementById("clear-search-highlight")
      .addEventListener("click", () => {
        this.highlightSearchResults("");
        document.getElementById("search-term-input").value = "";
      });
    document
      .querySelector("#search-chat-modal .modal-close")
      .addEventListener("click", () => {
        document.getElementById("search-chat-modal").style.display = "none";
        this.highlightSearchResults("");
      });

    // === PICKER DE FORMATO ===
    this.setupTextFormatPicker();

    // Modales
    // Cerrar cualquier modal al hacer clic en la "X" o en el fondo
    document.querySelectorAll(".modal").forEach((modal) => {
      modal.addEventListener("click", (e) => {
        if (e.target === modal || e.target.classList.contains("modal-close")) {
          // Cerrar todos los modales
          document
            .querySelectorAll(".modal")
            .forEach((m) => (m.style.display = "none"));
          // Limpiar el chat pendiente de eliminar (si existe)
          if (window.msnai) {
            window.msnai.chatToDelete = null;
          }
        }
      });
    });

    // Inicializar pickers
    this.setupEmoticonPickers();

    // Reconexión automática
    setInterval(() => {
      if (!this.isConnected) this.checkConnection();
    }, 30000);
    setInterval(() => {
      if (this.isConnected) this.updateAvailableModels();
    }, 60000);
    // Confirmar o cancelar eliminación de chat
    document
      .getElementById("confirm-delete-btn")
      .addEventListener("click", () => {
        if (this.chatToDelete) {
          this.deleteChat(this.chatToDelete);
          this.chatToDelete = null;
        }
        document.getElementById("delete-chat-modal").style.display = "none";
      });

    document
      .getElementById("cancel-delete-btn")
      .addEventListener("click", () => {
        this.chatToDelete = null;
        document.getElementById("delete-chat-modal").style.display = "none";
      });

    // Cerrar modal con la "X"
    document
      .querySelector("#delete-chat-modal .modal-close")
      .addEventListener("click", () => {
        this.chatToDelete = null;
        document.getElementById("delete-chat-modal").style.display = "none";
      });

    // Cerrar modal de resumen de importación
    document
      .getElementById("close-summary-btn")
      .addEventListener("click", () => {
        document.getElementById("import-summary-modal").style.display = "none";
      });

    // Event listeners para el menú contextual de chats
    document
      .getElementById("context-edit-title")
      .addEventListener("click", () => {
        this.hideContextMenu();
        this.showEditTitleModal(this.contextMenuChatId);
      });

    document
      .getElementById("context-export-chat")
      .addEventListener("click", () => {
        this.hideContextMenu();
        this.exportSingleChat(this.contextMenuChatId);
      });

    document
      .getElementById("context-delete-chat")
      .addEventListener("click", () => {
        this.hideContextMenu();
        this.chatToDelete = this.contextMenuChatId;
        document.getElementById("delete-chat-modal").style.display = "block";
      });

    // Cerrar menú contextual al hacer clic fuera de él
    document.addEventListener("click", (e) => {
      const contextMenu = document.getElementById("chat-context-menu");
      if (contextMenu && !contextMenu.contains(e.target)) {
        this.hideContextMenu();
      }
    });

    // Event listeners para el modal de editar título
    document
      .getElementById("confirm-edit-title-btn")
      .addEventListener("click", () => {
        const input = document.getElementById("new-title-input");
        const success = this.editChatTitle(this.chatToEdit, input.value);
        if (success) {
          document.getElementById("edit-title-modal").style.display = "none";
          this.chatToEdit = null;
        }
      });

    document
      .getElementById("cancel-edit-title-btn")
      .addEventListener("click", () => {
        this.chatToEdit = null;
        document.getElementById("edit-title-modal").style.display = "none";
      });

    // Cerrar modal de editar título con la "X"
    document
      .querySelector("#edit-title-modal .modal-close")
      .addEventListener("click", () => {
        this.chatToEdit = null;
        document.getElementById("edit-title-modal").style.display = "none";
      });

    // Permitir guardar con Enter en el input de editar título
    document
      .getElementById("new-title-input")
      .addEventListener("keypress", (e) => {
        if (e.key === "Enter") {
          e.preventDefault();
          document.getElementById("confirm-edit-title-btn").click();
        }
      });

    // =================== EVENT LISTENERS PARA GENERADOR Y GESTOR DE PROMPTS ===================

    // Abrir modal generador de prompts
    document
      .getElementById("generador-promt-btn")
      .addEventListener("click", () => {
        document.getElementById("prompt-generator-modal").style.display =
          "block";
      });

    // Abrir modal gestor de prompts
    document
      .getElementById("gestor-prompts-btn")
      .addEventListener("click", () => {
        this.loadSavedPrompts();
        document.getElementById("prompt-manager-modal").style.display = "block";
      });

    // Cerrar modales de prompts con la X
    document
      .querySelectorAll(
        "#prompt-generator-modal .modal-close, #prompt-manager-modal .modal-close, #prompt-result-modal .modal-close, #save-prompt-modal .modal-close, #prompt-details-modal .modal-close, #expert-room-modal .modal-close",
      )
      .forEach((closeBtn) => {
        closeBtn.addEventListener("click", (e) => {
          e.target.closest(".modal").style.display = "none";
        });
      });

    // Event listeners para modal de sala de expertos
    this.addEventListenerSafe("cancel-expert-room-btn", "click", () => {
      document.getElementById("expert-room-modal").style.display = "none";
    });

    this.addEventListenerSafe("create-expert-room-btn", "click", () => {
      this.createExpertRoom();
    });

    // Cerrar modales con overlay
    document.getElementById("modal-overlay")?.addEventListener("click", () => {
      this.hideAllModals();
    });

    // Generar prompt
    document
      .getElementById("generate-prompt-btn")
      .addEventListener("click", () => {
        this.generatePrompt();
      });

    // Copiar prompt al chat
    document
      .getElementById("copyMarkdownButton")
      .addEventListener("click", () => {
        const markdownContent =
          document.getElementById("markdownEditor").textContent;
        const messageInput = document.getElementById("message-input");
        messageInput.value = markdownContent;
        messageInput.focus();

        // Mostrar notificación visible
        const notification = document.createElement("div");
        notification.className = "notification success show";
        notification.innerHTML = `
          <div class="notification-content">
            <span class="notification-icon">✅</span>
            <span class="notification-text">${this.t("prompt_generator.copy_success")}</span>
            <button class="notification-close">×</button>
          </div>
        `;

        const container = document.getElementById("notification-container");
        if (container) {
          container.appendChild(notification);

          // Auto-eliminar después de 3 segundos
          setTimeout(() => {
            notification.classList.remove("show");
            setTimeout(() => notification.remove(), 300);
          }, 3000);

          // Botón de cerrar
          notification
            .querySelector(".notification-close")
            .addEventListener("click", () => {
              notification.classList.remove("show");
              setTimeout(() => notification.remove(), 300);
            });
        }
      });

    // Mostrar modal de guardar prompt
    document.getElementById("save-prompt-btn").addEventListener("click", () => {
      if (!this.isEditMode) {
        this.showSavePromptModal();
      }
    });

    // Botones de modo edición
    document
      .getElementById("confirm-save-edit")
      ?.addEventListener("click", () => {
        this.generatePrompt();
        // Después de generar, mostrar modal de guardar en modo edición
        setTimeout(() => {
          this.showSavePromptModal();
        }, 100);
      });

    document.getElementById("cancel-edit")?.addEventListener("click", () => {
      this.cancelEditMode();
    });

    // Confirmar guardar prompt
    document
      .getElementById("confirm-save-prompt")
      .addEventListener("click", () => {
        this.saveCurrentPrompt();
      });

    // Cancelar guardar prompt
    document
      .getElementById("cancel-save-prompt")
      .addEventListener("click", () => {
        document.getElementById("save-prompt-modal").style.display = "none";
      });

    // Gestor de prompts - botones
    document.getElementById("refresh-prompts").addEventListener("click", () => {
      this.loadSavedPrompts();
    });

    document
      .getElementById("export-all-prompts")
      .addEventListener("click", () => {
        this.exportAllPrompts();
      });

    document.getElementById("import-prompts").addEventListener("click", () => {
      document.getElementById("import-prompts-file").click();
    });

    document
      .getElementById("import-prompts-file")
      .addEventListener("change", (e) => {
        this.importPrompts(e.target.files[0]);
      });

    document
      .getElementById("delete-all-prompts")
      .addEventListener("click", () => {
        if (confirm(this.t("prompt_manager.delete_all_confirm"))) {
          this.deleteAllPrompts();
        }
      });

    // Búsqueda de prompts
    document.getElementById("prompt-search").addEventListener("input", (e) => {
      this.searchPrompts(e.target.value);
    });

    // Filtro de categorías
    document
      .getElementById("category-filter")
      ?.addEventListener("change", (e) => {
        this.filterByCategory(e.target.value);
      });

    // Botones del modal de detalles
    document
      .getElementById("load-prompt-to-form")
      ?.addEventListener("click", () => {
        this.loadPromptToForm();
      });

    document
      .getElementById("edit-prompt-details")
      ?.addEventListener("click", () => {
        this.editPromptFromDetails();
      });

    document
      .getElementById("delete-prompt-from-details")
      ?.addEventListener("click", () => {
        this.deletePromptFromDetails();
      });

    // Actualizar tooltips específicamente para Microsoft Edge
    if (this.isEdgeBrowser) {
      setTimeout(() => {
        this.forceUpdateTooltipsForEdge();
      }, 100);

      setTimeout(() => {
        this.forceUpdateTooltipsForEdge();
      }, 500);

      setTimeout(() => {
        this.forceUpdateTooltipsForEdge();
      }, 1000);

      setTimeout(() => {
        this.forceUpdateTooltipsForEdge();
      }, 1500);
    }
  }
  //-----------------------------------------------
  async updateAvailableModels() {
    try {
      // Usar el rate limiter para actualizar modelos
      const response = await this.rateLimiter.makeRequest(
        async () => {
          return await fetch(`${this.settings.ollamaServer}/api/tags`);
        },
        { priority: "low", skipQueue: false },
      );

      if (response.ok) {
        const data = await response.json();
        this.availableModels = data.models || [];
        this.updateModelStatus();
        this.updateModelSelect();
      }
    } catch (error) {
      console.error("Error actualizando modelos:", error);
    }
  }

  updateModelSelect() {
    const select = document.getElementById("model-select");
    if (!select) return;
    const currentValue = this.settings.selectedModel;
    select.innerHTML = "";
    if (this.availableModels.length === 0) {
      const option = document.createElement("option");
      option.value = "";
      option.textContent = this.isConnected
        ? this.t("settings.no_models")
        : this.t("settings.no_connection");
      option.disabled = true;
      select.appendChild(option);
      return;
    }
    this.availableModels.forEach((model) => {
      const option = document.createElement("option");
      option.value = model.name;
      const sizeGB = (model.size / 1024 / 1024 / 1024).toFixed(1);
      option.textContent = `${model.name} (${sizeGB}GB)`;
      select.appendChild(option);
    });
    if (this.availableModels.some((m) => m.name === currentValue)) {
      select.value = currentValue;
    } else if (this.availableModels.length > 0) {
      select.value = this.availableModels[0].name;
      this.settings.selectedModel = this.availableModels[0].name;
      this.saveSettings();
    }
  }

  filterChats(query) {
    const searchTerm = query.toLowerCase();
    const chatItems = document.querySelectorAll(".chat-item");
    const modelGroups = document.querySelectorAll(".model-group");

    if (!searchTerm) {
      // Si no hay búsqueda, mostrar todos los chats y grupos
      chatItems.forEach((item) => {
        item.style.display = "flex";
      });
      modelGroups.forEach((group) => {
        group.style.display = "block";
      });
      return;
    }

    // Filtrar chats individuales
    const visibleModels = new Set();
    chatItems.forEach((item) => {
      const title = item.querySelector(".chat-title").textContent.toLowerCase();
      const preview = item
        .querySelector(".chat-preview")
        .textContent.toLowerCase();
      const matches =
        title.includes(searchTerm) || preview.includes(searchTerm);

      item.style.display = matches ? "flex" : "none";

      // Si el chat coincide, marcar su grupo de modelo como visible
      if (matches) {
        const modelGroup = item.closest(".model-group");
        if (modelGroup) {
          visibleModels.add(modelGroup);
        }
      }
    });

    // Ocultar grupos de modelos sin chats visibles
    modelGroups.forEach((group) => {
      if (visibleModels.has(group)) {
        group.style.display = "block";
        // Expandir el grupo si está colapsado
        const chatsContainer = group.querySelector(".model-chats-container");
        const arrowIcon = group.querySelector(".model-header span");
        if (chatsContainer && arrowIcon) {
          chatsContainer.style.display = "block";
          arrowIcon.dataset.expanded = "true";
          arrowIcon.style.transform = "rotate(0deg)";
        }
      } else {
        group.style.display = "none";
      }
    });
  }

  showChatContextMenu(event, chatId) {
    event.preventDefault(); // Evitar el menú contextual nativo

    // Guardar el ID del chat actual para las acciones del menú
    this.contextMenuChatId = chatId;

    // Obtener el menú contextual
    const contextMenu = document.getElementById("chat-context-menu");

    // Aplicar traducciones directamente
    const editTitleSpan = contextMenu.querySelector("#context-edit-title span");
    const exportChatSpan = contextMenu.querySelector(
      "#context-export-chat span",
    );
    const deleteChatSpan = contextMenu.querySelector(
      "#context-delete-chat span",
    );

    console.log("🔍 DEBUG - Translations object:", this.translations);
    console.log("🔍 DEBUG - context_menu:", this.translations?.context_menu);

    // Verificar que translations esté cargado
    if (this.translations && this.translations.context_menu) {
      if (editTitleSpan)
        editTitleSpan.textContent =
          this.translations.context_menu.edit_title || "Editar título";
      if (exportChatSpan)
        exportChatSpan.textContent =
          this.translations.context_menu.export_chat || "Exportar chat";
      if (deleteChatSpan)
        deleteChatSpan.textContent =
          this.translations.context_menu.delete_chat || "Eliminar chat";
    } else {
      // Fallback si translations no está cargado
      if (editTitleSpan) editTitleSpan.textContent = "Editar título";
      if (exportChatSpan) exportChatSpan.textContent = "Exportar chat";
      if (deleteChatSpan) deleteChatSpan.textContent = "Eliminar chat";
    }

    // Posicionar el menú en la posición del clic
    contextMenu.style.left = event.pageX + "px";
    contextMenu.style.top = event.pageY + "px";
    contextMenu.style.display = "block";

    console.log("📋 Menú contextual mostrado para chat:", chatId);
  }

  hideContextMenu() {
    const contextMenu = document.getElementById("chat-context-menu");
    if (contextMenu) {
      contextMenu.style.display = "none";
    }
  }

  showEditTitleModal(chatId) {
    const chat = this.chats.find((c) => c.id === chatId);
    if (!chat) return;

    this.chatToEdit = chatId;
    const input = document.getElementById("new-title-input");
    input.value = chat.title;

    // Aplicar traducciones directamente al modal
    const modal = document.getElementById("edit-title-modal");
    const titleH3 = document.getElementById("edit-title-modal-title");
    const label = document.getElementById("edit-title-modal-label");
    const cancelBtn = document.querySelector("#cancel-edit-title-btn span");
    const confirmBtn = document.querySelector("#confirm-edit-title-btn span");

    console.log("🔍 DEBUG Modal - Translations:", this.translations);
    console.log("🔍 DEBUG Modal - edit_title:", this.translations?.edit_title);
    console.log("🔍 DEBUG Modal - buttons:", this.translations?.buttons);

    // Verificar que translations esté cargado
    if (
      this.translations &&
      this.translations.edit_title &&
      this.translations.buttons
    ) {
      if (titleH3)
        titleH3.textContent =
          this.translations.edit_title.title || "Editar título del chat";
      if (label)
        label.textContent =
          this.translations.edit_title.label || "Nuevo título:";
      if (cancelBtn)
        cancelBtn.textContent = this.translations.buttons.cancel || "Cancelar";
      if (confirmBtn)
        confirmBtn.textContent = this.translations.buttons.save || "Guardar";
    } else {
      // Fallback si translations no está cargado
      if (titleH3) titleH3.textContent = "Editar título del chat";
      if (label) label.textContent = "Nuevo título:";
      if (cancelBtn) cancelBtn.textContent = "Cancelar";
      if (confirmBtn) confirmBtn.textContent = "Guardar";
    }

    modal.style.display = "block";

    // Enfocar y seleccionar el texto
    setTimeout(() => {
      input.focus();
      input.select();
    }, 100);

    console.log("✏️ Modal de edición abierto para:", chat.title);
  }

  editChatTitle(chatId, newTitle) {
    const chat = this.chats.find((c) => c.id === chatId);
    if (!chat) return;

    const trimmedTitle = newTitle.trim();
    if (!trimmedTitle) {
      alert(this.t("edit_title.error"));
      return false;
    }

    chat.title = trimmedTitle;
    this.saveChats();
    this.renderChatList();

    // Si es el chat actual, actualizar también el nombre en el header
    if (this.currentChatId === chatId) {
      document.getElementById("chat-contact-name").textContent = trimmedTitle;
    }

    console.log("✅ Título actualizado:", trimmedTitle);
    return true;
  }

  exportSingleChat(chatId) {
    const chat = this.chats.find((c) => c.id === chatId);
    if (!chat) return;

    // Exportar como JSON (formato completo)
    const data = {
      version: "1.0",
      exportDate: new Date().toISOString(),
      chats: [chat],
    };

    const json = JSON.stringify(data, null, 2);
    const blob = new Blob([json], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `chat-${chat.title.replace(/\s+/g, "_")}-${Date.now()}.json`;
    a.click();
    URL.revokeObjectURL(url);

    console.log("📤 Chat exportado:", chat.title);
    this.playSound("message-out");
  }
  /////---------------------------------------------
  async init() {
    console.log("🚀 Iniciando MSN-AI...");
    console.log("=".repeat(80));
    console.log("🔍 SISTEMA DE DIAGNÓSTICO ACTIVADO");
    console.log("   - Monitor de hilo principal: ACTIVO");
    console.log("   - Logs de streaming: ACTIVO");
    console.log("   - Logs de renderizado: ACTIVO");
    console.log("   - Logs de formateo Markdown: ACTIVO");
    console.log("=".repeat(80));

    // ==================================================================================
    // INICIALIZACIÓN DEL RATE LIMITER - CONFIGURACIÓN CRÍTICA PARA EVITAR ERROR 429
    // ==================================================================================
    //
    // CONFIGURACIÓN BALANCEADA:
    // - Intervalo base de 1 segundo para buena experiencia de usuario
    // - Sistema de ajuste dinámico que aumenta el intervalo si detecta errores 429
    // - Máximo 1 solicitud concurrente para evitar saturación
    // - El sistema se adapta automáticamente a las limitaciones del servidor
    //
    // SOLUCIÓN IMPLEMENTADA:
    // - maxRequestsPerMinute: 30 (conservador pero razonable)
    // - minRequestInterval: 1000ms (1 segundo base - buena UX)
    // - maxConcurrentRequests: 1 (SOLO UNA solicitud a la vez)
    // - Ajuste dinámico: si hay errores 429, aumenta hasta 15s automáticamente
    // - Ejecución ESTRICTAMENTE SECUENCIAL
    //
    // IMPACTO:
    // - Las salas de expertos con N modelos tardarán mínimo N * 1 segundo
    // - Ejemplo: 3 modelos = mínimo 3 segundos (en lugar de 15s)
    // - Si hay errores 429, el sistema ajusta automáticamente el intervalo
    // - Los archivos grandes se envían completos sin pérdida de información
    //
    // NOTA: El sistema aumentará el intervalo dinámicamente si detecta errores 429
    // ==================================================================================
    this.rateLimiter = new OllamaRateLimiter({
      maxRequestsPerMinute: 30, // 30 req/min = 1 cada 2 segundos en promedio
      minRequestInterval: 1000, // 1 segundo entre solicitudes (buena UX)
      maxRetries: 3,
      baseRetryDelay: 3000, // 3s antes del primer reintento
      maxRetryDelay: 60000,
      maxConcurrentRequests: 1, // CRÍTICO: Solo UNA solicitud a la vez
    });

    // Inicializar IndexedDB para archivos adjuntos
    await this.initAttachmentsDB();

    // ✅ CARGAR EL ESTADO GUARDADO PRIMERO (antes de cargar idiomas)
    // Esto evita que updateUI() sobrescriba el estado durante loadLanguages()
    const savedStatus = localStorage.getItem("msnai-current-status");
    console.log(`📊 Estado guardado en localStorage: "${savedStatus}"`);
    if (
      savedStatus &&
      ["online", "away", "busy", "invisible"].includes(savedStatus)
    ) {
      this.currentStatus = savedStatus;
      console.log(`✅ Estado restaurado: ${savedStatus}`);
    } else {
      // Si no hay estado guardado, establecer online por defecto
      console.log(
        `⚠️ No hay estado guardado o no es válido, usando "online" por defecto`,
      );
      this.currentStatus = "online";
    }

    // Cargar idiomas (esto llamará a updateUI que ahora usará el currentStatus correcto)
    await this.loadLanguages();

    this.loadSettings();

    // Actualizar la UI con el estado correcto después de cargar idiomas
    this.updateStatusDisplay(this.currentStatus, true);

    console.log(`🔍 Verificando elementos del DOM:`);
    const statusIcon = document.getElementById("status-icon");
    const statusText = document.getElementById("ai-connection-status");
    console.log(
      `   status-icon: ${statusIcon ? statusIcon.src : "NO ENCONTRADO"}`,
    );
    console.log(
      `   ai-connection-status: ${statusText ? statusText.textContent : "NO ENCONTRADO"}`,
    );

    // Inicializar renderizador de Markdown
    this.initMarkdownRenderer();

    this.loadChats();
    this.initSounds();
    this.setupEventListeners();
    this.setupUserInteractionDetection();
    await this.autoConfigureConnection();
    this.renderChatList();
    this.createNewChat();
    this.playSound("login");

    console.log("✅ MSN-AI iniciado correctamente");
  }
  ////------------------------------
  async autoConfigureConnection() {
    console.log(`🔧 Configurando conexión automática...`);
    const connected = await this.checkConnection();
    if (connected && this.availableModels.length > 0) {
      if (!this.settings.selectedModel) {
        const firstModel = this.availableModels[0].name;
        console.log(`🤖 Auto-seleccionando modelo: ${firstModel}`);
        this.settings.selectedModel = firstModel;
        this.saveSettings();
      }
      this.updateModelSelect();
    }
    return connected;
  }
}
// Inicialización
// =================== INICIALIZACIÓN ===================
document.addEventListener("DOMContentLoaded", () => {
  console.log("🔧 Inicializando MSN-AI...");

  // Crear instancia de MSN-AI
  window.msnai = new MSNAI();

  // ===== CONFIGURAR MENÚ DE ESTADOS =====
  console.log("📋 Configurando menú de estados...");

  const statusBtn = document.getElementById("ai-status-btn");
  const statusMenu = document.getElementById("status-menu");

  if (!statusBtn || !statusMenu) {
    console.error("❌ ERROR: No se encontró el botón o menú de estados");
    console.log("Botón:", statusBtn);
    console.log("Menú:", statusMenu);
    return;
  }

  console.log("✅ Elementos encontrados correctamente");

  // Click en el botón de estado
  statusBtn.addEventListener("click", (e) => {
    console.log("🖱️ Click en botón de estado");
    e.stopPropagation();
    e.preventDefault();

    const isVisible = statusMenu.style.display === "block";
    console.log("Menú visible:", isVisible);

    // Cerrar otros pickers primero
    document.querySelectorAll(".emoticon-picker").forEach((picker) => {
      if (picker.id !== "status-menu") {
        picker.style.display = "none";
      }
    });

    // Toggle del menú de estados
    if (isVisible) {
      statusMenu.style.display = "none";
      console.log("🔽 Menú cerrado");
    } else {
      statusMenu.style.display = "block";
      console.log("🔼 Menú abierto");
    }
  });

  // Click en cada opción de estado
  document.querySelectorAll(".status-option").forEach((option) => {
    option.addEventListener("click", (e) => {
      console.log("🖱️ Click en opción de estado");
      e.stopPropagation();

      const status = option.getAttribute("data-status");
      console.log("Estado seleccionado:", status);

      if (window.msnai && window.msnai.updateStatusDisplay) {
        window.msnai.updateStatusDisplay(status);
        statusMenu.style.display = "none";
        console.log("✅ Estado actualizado");
      } else {
        console.error("❌ No se pudo actualizar el estado");
      }
    });
  });

  // Cerrar menú al hacer click fuera
  document.addEventListener("click", (e) => {
    if (
      !e.target.closest("#ai-status-btn") &&
      !e.target.closest("#status-menu")
    ) {
      if (statusMenu.style.display === "block") {
        statusMenu.style.display = "none";
        console.log("🔽 Menú cerrado (click fuera)");
      }
    }
  });

  console.log("✅ Menú de estados configurado correctamente");
});

// Manejo de errores globales
window.addEventListener("error", (e) => {
  console.error("❌ Error global:", e.error);
});

// Confirmación antes de cerrar
window.addEventListener("beforeunload", (e) => {
  if (window.msnai && window.msnai.chats.length > 1) {
    e.preventDefault();
    e.returnValue =
      "¿Estás seguro de que quieres salir? Los chats se guardarán automáticamente.";
  }
});

// =================== EXTENSIÓN DE LA CLASE MSNAI PARA PROMPTS ===================

// Agregar funciones al prototipo de MSNAI
MSNAI.prototype.generatePrompt = function () {
  const role = document
    .getElementById("role")
    .value.trim()
    .split("\n")
    .filter((l) => l);
  const context = document
    .getElementById("context")
    .value.trim()
    .split("\n")
    .filter((l) => l);
  const audience = document
    .getElementById("audience")
    .value.trim()
    .split("\n")
    .filter((l) => l);
  const tasks = document
    .getElementById("tasks")
    .value.trim()
    .split("\n")
    .filter((l) => l);
  const instructions = document
    .getElementById("instructions")
    .value.trim()
    .split("\n")
    .filter((l) => l);
  const empathy = document
    .getElementById("empathy")
    .value.trim()
    .split("\n")
    .filter((l) => l);
  const clarification = document
    .getElementById("clarification")
    .value.trim()
    .split("\n")
    .filter((l) => l);
  const refinement = document
    .getElementById("refinement")
    .value.trim()
    .split("\n")
    .filter((l) => l);
  const boundaries = document
    .getElementById("boundaries")
    .value.trim()
    .split("\n")
    .filter((l) => l);
  const consequences = document
    .getElementById("consequences")
    .value.trim()
    .split("\n")
    .filter((l) => l);
  const example = document
    .getElementById("example")
    .value.trim()
    .split("\n")
    .filter((l) => l);

  const escapeHtml = (text) => {
    const map = {
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#039;",
    };
    return text.replace(/[&<>"']/g, (m) => map[m]);
  };

  let markdownOutput = `[PROMPT]`;
  if (role.length)
    markdownOutput += `\n  ROLE:\n    ${role.map((r) => `- ${escapeHtml(r)}`).join("\n    ")}`;
  if (context.length)
    markdownOutput += `\n  CONTEXT:\n    ${context.map((c) => `- ${escapeHtml(c)}`).join("\n    ")}`;
  if (audience.length)
    markdownOutput += `\n  AUDIENCE:\n    ${audience.map((a) => `- ${escapeHtml(a)}`).join("\n    ")}`;
  if (tasks.length)
    markdownOutput += `\n  TASKS:\n    ${tasks.map((t, i) => `${i + 1}. ${escapeHtml(t)}`).join("\n    ")}`;
  if (instructions.length)
    markdownOutput += `\n  INSTRUCTIONS:\n    ${instructions.map((i) => `- ${escapeHtml(i)}`).join("\n    ")}`;
  if (empathy.length)
    markdownOutput += `\n  EMPATHY:\n    ${empathy.map((e) => `- ${escapeHtml(e)}`).join("\n    ")}`;
  if (clarification.length)
    markdownOutput += `\n  CLARIFICATION:\n    ${clarification.map((c) => `- ${escapeHtml(c)}`).join("\n    ")}`;
  if (refinement.length)
    markdownOutput += `\n  REFINEMENT:\n    ${refinement.map((r) => `- ${escapeHtml(r)}`).join("\n    ")}`;
  if (boundaries.length)
    markdownOutput += `\n  BOUNDARIES:\n    ${boundaries.map((b) => `- ${escapeHtml(b)}`).join("\n    ")}`;
  if (consequences.length)
    markdownOutput += `\n  CONSEQUENCES:\n    ${consequences.map((c) => `- ${escapeHtml(c)}`).join("\n    ")}`;
  if (example.length)
    markdownOutput += `\n  EXAMPLE:\n    ${example.map((e) => `- ${escapeHtml(e)}`).join("\n    ")}`;

  document.getElementById("markdownEditor").textContent = markdownOutput;
  document.getElementById("prompt-result-modal").style.display = "block";

  this.currentGeneratedPrompt = {
    role: role.join("\n"),
    context: context.join("\n"),
    audience: audience.join("\n"),
    tasks: tasks.join("\n"),
    instructions: instructions.join("\n"),
    empathy: empathy.join("\n"),
    clarification: clarification.join("\n"),
    refinement: refinement.join("\n"),
    boundaries: boundaries.join("\n"),
    consequences: consequences.join("\n"),
    example: example.join("\n"),
    markdown: markdownOutput,
    date: new Date().toISOString(),
  };
};

MSNAI.prototype.showSavePromptModal = function () {
  if (!this.currentGeneratedPrompt) return;

  // Si estamos en modo edición, cargar los datos existentes
  if (this.isEditMode && this.currentPromptId) {
    const prompts = JSON.parse(
      localStorage.getItem("msnai-saved-prompts") || "[]",
    );
    const prompt = prompts.find(
      (p) => String(p.id) === String(this.currentPromptId),
    );

    if (prompt) {
      document.getElementById("prompt-name").value = prompt.name || "";
      document.getElementById("prompt-description").value =
        prompt.description || "";
      document.getElementById("prompt-category").value = prompt.category || "";
      document.getElementById("prompt-tags").value =
        prompt.tags?.join(", ") || "";
    }

    // Cambiar texto del botón
    const saveBtn = document.getElementById("confirm-save-prompt");
    if (saveBtn) {
      const textSpan = saveBtn.querySelector("span");
      if (textSpan) {
        textSpan.textContent =
          "✏️ " + (this.t("buttons.update") || "Actualizar");
      }
    }
  } else {
    // Modo nuevo: limpiar campos
    document.getElementById("prompt-name").value = "";
    document.getElementById("prompt-description").value = "";
    document.getElementById("prompt-category").value = "";
    document.getElementById("prompt-tags").value = "";

    // Restaurar texto del botón
    const saveBtn = document.getElementById("confirm-save-prompt");
    if (saveBtn) {
      const textSpan = saveBtn.querySelector("span");
      if (textSpan) {
        textSpan.textContent = "💾 " + (this.t("buttons.save") || "Guardar");
      }
    }
  }

  document.getElementById("save-prompt-modal").style.display = "block";
  document.getElementById("prompt-name").focus();
};

MSNAI.prototype.saveCurrentPrompt = function () {
  if (!this.currentGeneratedPrompt) return;

  const name = document.getElementById("prompt-name").value.trim();
  if (!name) {
    const notification = document.createElement("div");
    notification.className = "notification error show";
    notification.innerHTML = `
      <div class="notification-content">
        <span class="notification-icon">❌</span>
        <span class="notification-text">${this.t("prompt_generator.name_required") || "El nombre del prompt es requerido"}</span>
        <button class="notification-close">×</button>
      </div>
    `;

    const container = document.getElementById("notification-container");
    if (container) {
      container.appendChild(notification);
      setTimeout(() => {
        notification.classList.remove("show");
        setTimeout(() => notification.remove(), 300);
      }, 3000);
      notification
        .querySelector(".notification-close")
        .addEventListener("click", () => {
          notification.classList.remove("show");
          setTimeout(() => notification.remove(), 300);
        });
    }
    return;
  }

  let prompts = JSON.parse(localStorage.getItem("msnai-saved-prompts") || "[]");

  if (this.isEditMode && this.currentPromptId) {
    // Modo edición: actualizar prompt existente
    const index = prompts.findIndex(
      (p) => String(p.id) === String(this.currentPromptId),
    );
    if (index !== -1) {
      prompts[index] = {
        ...prompts[index],
        ...this.currentGeneratedPrompt,
        name: name,
        description: document.getElementById("prompt-description").value.trim(),
        category: document.getElementById("prompt-category").value.trim(),
        tags: document
          .getElementById("prompt-tags")
          .value.split(",")
          .map((tag) => tag.trim())
          .filter((tag) => tag.length > 0),
        date: prompts[index].date || prompts[index].createdAt, // Mantener fecha de creación
        createdAt: prompts[index].createdAt || prompts[index].date,
        updatedAt: new Date().toISOString(),
        version: prompts[index].version || "1.0",
      };
    }
  } else {
    // Modo nuevo: crear prompt
    const now = new Date().toISOString();
    const promptToSave = {
      id: "prompt-" + Date.now(),
      ...this.currentGeneratedPrompt,
      name: name,
      description: document.getElementById("prompt-description").value.trim(),
      category: document.getElementById("prompt-category").value.trim(),
      tags: document
        .getElementById("prompt-tags")
        .value.split(",")
        .map((tag) => tag.trim())
        .filter((tag) => tag.length > 0),
      createdAt: now,
      updatedAt: now,
      date: now,
      version: "1.0",
    };
    prompts.unshift(promptToSave);
  }

  localStorage.setItem("msnai-saved-prompts", JSON.stringify(prompts));

  document.getElementById("save-prompt-modal").style.display = "none";

  // Mostrar notificación visible
  const successMsg = this.isEditMode
    ? this.t("prompt_generator.updated_success") ||
      "Prompt actualizado correctamente"
    : this.t("prompt_generator.saved_success") ||
      "Prompt guardado correctamente";

  const notification = document.createElement("div");
  notification.className = "notification success show";
  notification.innerHTML = `
    <div class="notification-content">
      <span class="notification-icon">✅</span>
      <span class="notification-text">${successMsg}</span>
      <button class="notification-close">×</button>
    </div>
  `;

  const container = document.getElementById("notification-container");
  if (container) {
    container.appendChild(notification);
    setTimeout(() => {
      notification.classList.remove("show");
      setTimeout(() => notification.remove(), 300);
    }, 3000);
    notification
      .querySelector(".notification-close")
      .addEventListener("click", () => {
        notification.classList.remove("show");
        setTimeout(() => notification.remove(), 300);
      });
  }

  // Resetear modo edición
  this.isEditMode = false;
  this.currentPromptId = null;

  // Ocultar indicador de modo edición
  const editIndicator = document.getElementById("edit-mode-indicator");
  if (editIndicator) {
    editIndicator.style.display = "none";
  }

  // Recargar lista de prompts si está abierta
  if (
    document.getElementById("prompt-manager-modal").style.display === "block"
  ) {
    this.loadSavedPrompts();
  }
};

MSNAI.prototype.loadSavedPrompts = function () {
  const prompts = JSON.parse(
    localStorage.getItem("msnai-saved-prompts") || "[]",
  );
  const container = document.getElementById("saved-prompts-list");
  const countEl = document.getElementById("prompts-count");

  const countText =
    this.t("prompt_manager.prompts_count") || "{count} prompts guardados";
  countEl.textContent = countText.replace("{count}", prompts.length);

  this.updateCategoryFilter(prompts);

  if (prompts.length === 0) {
    container.innerHTML = `
      <div style="grid-column: 1/-1; text-align: center; padding: 40px; color: #666;">
        <h4>${this.t("prompt_manager.no_prompts_title")}</h4>
        <p>${this.t("prompt_manager.no_prompts_message")}</p>
      </div>`;
    return;
  }

  container.innerHTML = prompts
    .map((prompt) => this.createPromptCard(prompt))
    .join("");
};

MSNAI.prototype.createPromptCard = function (prompt) {
  const date = new Date(prompt.date || prompt.createdAt).toLocaleDateString();
  const categoryHtml = prompt.category
    ? `<span class="prompt-card-category">${this.escapeHtml(prompt.category)}</span>`
    : "";
  const tagsHtml = prompt.tags?.length
    ? prompt.tags
        .slice(0, 3)
        .map(
          (tag) =>
            `<span class="prompt-card-tag">${this.escapeHtml(tag)}</span>`,
        )
        .join("")
    : "";
  const descHtml = prompt.description
    ? `<p class="prompt-card-description">${this.escapeHtml(prompt.description)}</p>`
    : "";

  const escapedId = String(prompt.id).replace(/'/g, "\\'");

  return `
    <div class="prompt-card" onclick="msnai.showPromptDetails('${escapedId}')">
      <h4>${this.escapeHtml(prompt.name)}</h4>
      <p style="margin: 0 0 8px 0; font-size: 7pt; color: #666;">${date}</p>
      ${descHtml}
      <div class="prompt-card-meta">
        ${categoryHtml}
        ${tagsHtml}
      </div>
      <div class="prompt-card-actions" onclick="event.stopPropagation()">
        <button class="aerobutton" onclick="msnai.usePrompt('${escapedId}')" style="font-size: 7pt; padding: 4px 8px;">
          ${this.t("prompt_manager.use_prompt")}
        </button>
        <button class="aerobutton" onclick="msnai.showPromptDetails('${escapedId}')" style="font-size: 7pt; padding: 4px 8px;">
          ${this.t("prompt_manager.view_prompt")}
        </button>
        <button class="aerobutton" onclick="msnai.exportSinglePrompt('${escapedId}')" style="font-size: 7pt; padding: 4px 8px;">
          💾 Exportar
        </button>
        <button class="aerobutton" onclick="msnai.deletePrompt('${escapedId}')" style="font-size: 7pt; padding: 4px 8px;">
          ${this.t("prompt_manager.delete_prompt")}
        </button>
      </div>
    </div>
  `;
};

MSNAI.prototype.updateCategoryFilter = function (prompts) {
  const categories = [
    ...new Set(
      prompts.map((p) => p.category).filter((c) => c && c.trim() !== ""),
    ),
  ].sort();
  const filterSelect = document.getElementById("category-filter");

  if (filterSelect) {
    const currentValue = filterSelect.value;
    filterSelect.innerHTML = `<option value="">${this.t("prompt_manager.all_categories")}</option>`;

    categories.forEach((category) => {
      const option = document.createElement("option");
      option.value = category;
      option.textContent = category;
      filterSelect.appendChild(option);
    });

    filterSelect.value = currentValue;
  }
};

MSNAI.prototype.showPromptDetails = function (promptId) {
  const prompts = JSON.parse(
    localStorage.getItem("msnai-saved-prompts") || "[]",
  );
  const prompt = prompts.find((p) => String(p.id) === String(promptId));

  if (!prompt) return;

  this.currentPromptId = promptId;
  document.getElementById("details-prompt-name").textContent = prompt.name;

  const t = (key) => {
    return this.translations?.[key.split(".")[0]]?.[key.split(".")[1]] || key;
  };

  let detailsHtml = `
    <div class="detail-section">
      <h4>📝 ${t("prompt_manager.general_info")}</h4>
      <p><strong>${t("prompt_generator.prompt_name")}:</strong> ${this.escapeHtml(prompt.name)}</p>
      ${prompt.description ? `<p><strong>${t("prompt_generator.prompt_description")}:</strong> ${this.escapeHtml(prompt.description)}</p>` : ""}
      ${prompt.category ? `<p><strong>${t("prompt_generator.prompt_category")}:</strong> ${this.escapeHtml(prompt.category)}</p>` : ""}
      ${prompt.tags?.length ? `<p><strong>${t("prompt_generator.prompt_tags")}:</strong> ${prompt.tags.map((tag) => this.escapeHtml(tag)).join(", ")}</p>` : ""}
      <p><strong>${t("prompt_manager.date")}:</strong> ${new Date(prompt.date).toLocaleString()}</p>
    </div>
  `;

  const sections = [
    {
      key: "role",
      title: "👤 " + t("prompt_generator.role"),
      value: prompt.role,
    },
    {
      key: "context",
      title: "📝 " + t("prompt_generator.context"),
      value: prompt.context,
    },
    {
      key: "audience",
      title: "👥 " + t("prompt_generator.audience"),
      value: prompt.audience,
    },
    {
      key: "tasks",
      title: "📋 " + t("prompt_generator.tasks"),
      value: prompt.tasks,
    },
    {
      key: "instructions",
      title: "ℹ️ " + t("prompt_generator.instructions"),
      value: prompt.instructions,
    },
    {
      key: "empathy",
      title: "💬 " + t("prompt_generator.empathy"),
      value: prompt.empathy,
    },
    {
      key: "clarification",
      title: "❓ " + t("prompt_generator.clarification"),
      value: prompt.clarification,
    },
    {
      key: "refinement",
      title: "🔄 " + t("prompt_generator.refinement"),
      value: prompt.refinement,
    },
    {
      key: "boundaries",
      title: "🚫 " + t("prompt_generator.boundaries"),
      value: prompt.boundaries,
    },
    {
      key: "consequences",
      title: "⚠️ " + t("prompt_generator.consequences"),
      value: prompt.consequences,
    },
    {
      key: "example",
      title: "💡 " + t("prompt_generator.example"),
      value: prompt.example,
    },
  ];

  sections.forEach((section) => {
    if (section.value && section.value.trim()) {
      detailsHtml += `
        <div class="detail-section">
          <h4>${section.title}</h4>
          <p>${this.escapeHtml(section.value).replace(/\n/g, "<br>")}</p>
        </div>
      `;
    }
  });

  document.getElementById("prompt-details-content").innerHTML = detailsHtml;
  document.getElementById("prompt-details-modal").style.display = "block";
};

MSNAI.prototype.loadPromptToForm = function () {
  if (!this.currentPromptId) return;

  const prompts = JSON.parse(
    localStorage.getItem("msnai-saved-prompts") || "[]",
  );
  const prompt = prompts.find(
    (p) => String(p.id) === String(this.currentPromptId),
  );

  if (prompt) {
    const fields = [
      "role",
      "context",
      "audience",
      "tasks",
      "instructions",
      "empathy",
      "clarification",
      "refinement",
      "boundaries",
      "consequences",
      "example",
    ];
    fields.forEach((field) => {
      const element = document.getElementById(field);
      if (element) {
        element.value = prompt[field] || "";
      }
    });

    document.getElementById("prompt-details-modal").style.display = "none";
    document.getElementById("prompt-manager-modal").style.display = "none";
    document.getElementById("prompt-generator-modal").style.display = "block";
    this.showNotification(
      this.t("prompt_manager.loaded_to_form") ||
        "Prompt cargado en el formulario",
      "success",
    );
  }
};

MSNAI.prototype.editPromptFromDetails = function () {
  if (!this.currentPromptId) return;

  const prompts = JSON.parse(
    localStorage.getItem("msnai-saved-prompts") || "[]",
  );
  const prompt = prompts.find(
    (p) => String(p.id) === String(this.currentPromptId),
  );

  if (prompt) {
    // Cargar datos al formulario
    const fields = [
      "role",
      "context",
      "audience",
      "tasks",
      "instructions",
      "empathy",
      "clarification",
      "refinement",
      "boundaries",
      "consequences",
      "example",
    ];
    fields.forEach((field) => {
      const element = document.getElementById(field);
      if (element) {
        element.value = prompt[field] || "";
      }
    });

    // Configurar currentGeneratedPrompt para poder guardar
    this.currentGeneratedPrompt = {
      role: prompt.role || "",
      context: prompt.context || "",
      audience: prompt.audience || "",
      tasks: prompt.tasks || "",
      instructions: prompt.instructions || "",
      empathy: prompt.empathy || "",
      clarification: prompt.clarification || "",
      refinement: prompt.refinement || "",
      boundaries: prompt.boundaries || "",
      consequences: prompt.consequences || "",
      example: prompt.example || "",
      markdown: prompt.markdown || this.generateMarkdownFromPrompt(prompt),
      date: prompt.date,
    };

    // Activar modo edición
    this.isEditMode = true;

    // Mostrar indicador de modo edición
    const editIndicator = document.getElementById("edit-mode-indicator");
    const editingName = document.getElementById("editing-prompt-name");
    if (editIndicator && editingName) {
      editingName.textContent = prompt.name;
      editIndicator.style.display = "block";
    }

    // Cerrar modales y abrir generador
    document.getElementById("prompt-details-modal").style.display = "none";
    document.getElementById("prompt-manager-modal").style.display = "none";
    document.getElementById("prompt-generator-modal").style.display = "block";

    // Scroll al top del modal
    const modalContent = document.querySelector(
      "#prompt-generator-modal .modal-content",
    );
    if (modalContent) modalContent.scrollTop = 0;
  }
};

MSNAI.prototype.cancelEditMode = function () {
  this.isEditMode = false;
  this.currentPromptId = null;

  // Ocultar indicador de modo edición
  const editIndicator = document.getElementById("edit-mode-indicator");
  if (editIndicator) {
    editIndicator.style.display = "none";
  }

  // Limpiar formulario
  const fields = [
    "role",
    "context",
    "audience",
    "tasks",
    "instructions",
    "empathy",
    "clarification",
    "refinement",
    "boundaries",
    "consequences",
    "example",
  ];
  fields.forEach((field) => {
    const element = document.getElementById(field);
    if (element) {
      element.value = "";
    }
  });

  // Notificación
  const notification = document.createElement("div");
  notification.className = "notification info show";
  notification.innerHTML = `
    <div class="notification-content">
      <span class="notification-icon">ℹ️</span>
      <span class="notification-text">${this.t("prompt_manager.edit_cancelled") || "Edición cancelada"}</span>
      <button class="notification-close">×</button>
    </div>
  `;

  const container = document.getElementById("notification-container");
  if (container) {
    container.appendChild(notification);
    setTimeout(() => {
      notification.classList.remove("show");
      setTimeout(() => notification.remove(), 300);
    }, 2000);
    notification
      .querySelector(".notification-close")
      .addEventListener("click", () => {
        notification.classList.remove("show");
        setTimeout(() => notification.remove(), 300);
      });
  }
};

MSNAI.prototype.deletePromptFromDetails = function () {
  if (!this.currentPromptId) return;

  if (!confirm(this.t("prompt_manager.delete_confirm"))) return;

  let prompts = JSON.parse(localStorage.getItem("msnai-saved-prompts") || "[]");
  prompts = prompts.filter(
    (p) => String(p.id) !== String(this.currentPromptId),
  );
  localStorage.setItem("msnai-saved-prompts", JSON.stringify(prompts));

  document.getElementById("prompt-details-modal").style.display = "none";
  this.loadSavedPrompts();
  this.showNotification(this.t("prompt_manager.delete_success"), "success");
  this.currentPromptId = null;
};

MSNAI.prototype.usePrompt = function (promptId) {
  const prompts = JSON.parse(
    localStorage.getItem("msnai-saved-prompts") || "[]",
  );
  const prompt = prompts.find((p) => String(p.id) === String(promptId));

  if (prompt) {
    // Si no existe markdown, generarlo a partir de los campos
    let markdownText = prompt.markdown;
    if (!markdownText) {
      markdownText = this.generateMarkdownFromPrompt(prompt);
    }

    const messageInput = document.getElementById("message-input");
    messageInput.value = markdownText;
    messageInput.focus();
    document.getElementById("prompt-manager-modal").style.display = "none";
    this.showNotification(this.t("prompt_generator.copy_success"), "success");
  }
};

MSNAI.prototype.generateMarkdownFromPrompt = function (prompt) {
  const escapeHtml = (text) => {
    const map = {
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#039;",
    };
    return text.replace(/[&<>"']/g, (m) => map[m]);
  };

  const formatField = (content) => {
    if (!content) return [];
    return content.split("\n").filter((l) => l.trim());
  };

  let markdownOutput = `[PROMPT]`;

  const role = formatField(prompt.role);
  if (role.length)
    markdownOutput += `\n  ROLE:\n    ${role.map((r) => `- ${escapeHtml(r)}`).join("\n    ")}`;

  const context = formatField(prompt.context);
  if (context.length)
    markdownOutput += `\n  CONTEXT:\n    ${context.map((c) => `- ${escapeHtml(c)}`).join("\n    ")}`;

  const audience = formatField(prompt.audience);
  if (audience.length)
    markdownOutput += `\n  AUDIENCE:\n    ${audience.map((a) => `- ${escapeHtml(a)}`).join("\n    ")}`;

  const tasks = formatField(prompt.tasks);
  if (tasks.length)
    markdownOutput += `\n  TASKS:\n    ${tasks.map((t, i) => `${i + 1}. ${escapeHtml(t)}`).join("\n    ")}`;

  const instructions = formatField(prompt.instructions);
  if (instructions.length)
    markdownOutput += `\n  INSTRUCTIONS:\n    ${instructions.map((i) => `- ${escapeHtml(i)}`).join("\n    ")}`;

  const empathy = formatField(prompt.empathy);
  if (empathy.length)
    markdownOutput += `\n  EMPATHY:\n    ${empathy.map((e) => `- ${escapeHtml(e)}`).join("\n    ")}`;

  const clarification = formatField(prompt.clarification);
  if (clarification.length)
    markdownOutput += `\n  CLARIFICATION:\n    ${clarification.map((c) => `- ${escapeHtml(c)}`).join("\n    ")}`;

  const refinement = formatField(prompt.refinement);
  if (refinement.length)
    markdownOutput += `\n  REFINEMENT:\n    ${refinement.map((r) => `- ${escapeHtml(r)}`).join("\n    ")}`;

  const boundaries = formatField(prompt.boundaries);
  if (boundaries.length)
    markdownOutput += `\n  BOUNDARIES:\n    ${boundaries.map((b) => `- ${escapeHtml(b)}`).join("\n    ")}`;

  const consequences = formatField(prompt.consequences);
  if (consequences.length)
    markdownOutput += `\n  CONSEQUENCES:\n    ${consequences.map((c) => `- ${escapeHtml(c)}`).join("\n    ")}`;

  const example = formatField(prompt.example);
  if (example.length)
    markdownOutput += `\n  EXAMPLE:\n    ${example.map((e) => `- ${escapeHtml(e)}`).join("\n    ")}`;

  return markdownOutput;
};

MSNAI.prototype.deletePrompt = function (promptId) {
  if (!confirm(this.t("prompt_manager.delete_confirm"))) return;

  let prompts = JSON.parse(localStorage.getItem("msnai-saved-prompts") || "[]");
  prompts = prompts.filter((p) => String(p.id) !== String(promptId));
  localStorage.setItem("msnai-saved-prompts", JSON.stringify(prompts));
  this.loadSavedPrompts();
  this.showNotification(this.t("prompt_manager.delete_success"), "success");
};

MSNAI.prototype.exportAllPrompts = function () {
  const prompts = JSON.parse(
    localStorage.getItem("msnai-saved-prompts") || "[]",
  );

  if (prompts.length === 0) {
    this.showNotification(this.t("prompt_manager.no_export"), "info");
    return;
  }

  // Formatear prompts según el formato del ejemplo
  const formattedPrompts = prompts.map((prompt) => ({
    role: prompt.role || "",
    context: prompt.context || "",
    audience: prompt.audience || "",
    tasks: prompt.tasks || "",
    instructions: prompt.instructions || "",
    empathy: prompt.empathy || "",
    clarification: prompt.clarification || "",
    refinement: prompt.refinement || "",
    boundaries: prompt.boundaries || "",
    consequences: prompt.consequences || "",
    example: prompt.example || "",
    name: prompt.name || "",
    description: prompt.description || "",
    category: prompt.category || "",
    tags: prompt.tags || [],
    createdAt: prompt.createdAt || prompt.date || new Date().toISOString(),
    updatedAt: prompt.updatedAt || prompt.date || new Date().toISOString(),
    version: prompt.version || "1.0",
    id: isNaN(prompt.id) ? prompt.id : Number(prompt.id),
  }));

  const blob = new Blob([JSON.stringify(formattedPrompts, null, 2)], {
    type: "application/json",
  });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `all-prompts-${Date.now()}.json`;
  a.click();
  URL.revokeObjectURL(url);
  this.showNotification(this.t("prompt_manager.export_success"), "success");
};

MSNAI.prototype.importPrompts = function (file) {
  if (!file) return;

  const reader = new FileReader();
  reader.onload = (e) => {
    try {
      const importedPrompts = JSON.parse(e.target.result);
      let existingPrompts = JSON.parse(
        localStorage.getItem("msnai-saved-prompts") || "[]",
      );

      // Normalizar los prompts importados al formato interno
      const normalizedPrompts = importedPrompts.map((prompt, index) => {
        const now = new Date().toISOString();
        // Normalizar ID a string para compatibilidad
        const promptId = prompt.id
          ? String(prompt.id)
          : "prompt-" + Date.now() + "-" + index;

        const normalized = {
          id: promptId,
          role: prompt.role || "",
          context: prompt.context || "",
          audience: prompt.audience || "",
          tasks: prompt.tasks || "",
          instructions: prompt.instructions || "",
          empathy: prompt.empathy || "",
          clarification: prompt.clarification || "",
          refinement: prompt.refinement || "",
          boundaries: prompt.boundaries || "",
          consequences: prompt.consequences || "",
          example: prompt.example || "",
          name: prompt.name || "",
          description: prompt.description || "",
          category: prompt.category || "",
          tags: prompt.tags || [],
          markdown: prompt.markdown || "",
          createdAt: prompt.createdAt || now,
          updatedAt: prompt.updatedAt || now,
          date: prompt.createdAt || prompt.date || now,
          version: prompt.version || "1.0",
        };
        return normalized;
      });

      existingPrompts = existingPrompts.concat(normalizedPrompts);
      localStorage.setItem(
        "msnai-saved-prompts",
        JSON.stringify(existingPrompts),
      );

      this.loadSavedPrompts();
      this.showNotification(this.t("prompt_manager.import_success"), "success");
    } catch (error) {
      console.error("Error al importar prompts:", error);
      this.showNotification("Error al importar prompts", "error");
    }
  };
  reader.readAsText(file);
};

MSNAI.prototype.exportSinglePrompt = function (promptId) {
  const prompts = JSON.parse(
    localStorage.getItem("msnai-saved-prompts") || "[]",
  );
  const prompt = prompts.find((p) => String(p.id) === String(promptId));

  if (!prompt) {
    this.showNotification("Prompt no encontrado", "error");
    return;
  }

  // Formatear el prompt según el formato del ejemplo
  const formattedPrompt = [
    {
      role: prompt.role || "",
      context: prompt.context || "",
      audience: prompt.audience || "",
      tasks: prompt.tasks || "",
      instructions: prompt.instructions || "",
      empathy: prompt.empathy || "",
      clarification: prompt.clarification || "",
      refinement: prompt.refinement || "",
      boundaries: prompt.boundaries || "",
      consequences: prompt.consequences || "",
      example: prompt.example || "",
      name: prompt.name || "",
      description: prompt.description || "",
      category: prompt.category || "",
      tags: prompt.tags || [],
      createdAt: prompt.createdAt || prompt.date || new Date().toISOString(),
      updatedAt: prompt.updatedAt || prompt.date || new Date().toISOString(),
      version: prompt.version || "1.0",
      id: isNaN(prompt.id) ? prompt.id : Number(prompt.id),
    },
  ];

  const blob = new Blob([JSON.stringify(formattedPrompt, null, 2)], {
    type: "application/json",
  });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;

  // Nombre de archivo basado en el nombre del prompt
  const fileName = prompt.name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  a.download = `prompt-${fileName}-${Date.now()}.json`;

  a.click();
  URL.revokeObjectURL(url);
  this.showNotification("Prompt exportado correctamente", "success");
};

MSNAI.prototype.deleteAllPrompts = function () {
  localStorage.removeItem("msnai-saved-prompts");
  this.loadSavedPrompts();
  this.showNotification("Todos los prompts han sido eliminados", "success");
};

MSNAI.prototype.searchPrompts = function (query) {
  const prompts = JSON.parse(
    localStorage.getItem("msnai-saved-prompts") || "[]",
  );
  const filtered = query
    ? prompts.filter(
        (p) =>
          p.name.toLowerCase().includes(query.toLowerCase()) ||
          p.description?.toLowerCase().includes(query.toLowerCase()) ||
          p.category?.toLowerCase().includes(query.toLowerCase()),
      )
    : prompts;

  const container = document.getElementById("saved-prompts-list");
  const countEl = document.getElementById("prompts-count");

  const countText =
    this.t("prompt_manager.prompts_found") || "{count} prompts encontrados";
  countEl.textContent = countText.replace("{count}", filtered.length);

  if (filtered.length === 0) {
    container.innerHTML = `
      <div style="grid-column: 1/-1; text-align: center; padding: 40px; color: #666;">
        <h4>${this.t("prompt_manager.no_results")}</h4>
        <p>${this.t("prompt_manager.try_another_search")}</p>
      </div>`;
    return;
  }

  container.innerHTML = filtered
    .map((prompt) => this.createPromptCard(prompt))
    .join("");
};

MSNAI.prototype.filterByCategory = function (category) {
  const prompts = JSON.parse(
    localStorage.getItem("msnai-saved-prompts") || "[]",
  );
  const filtered = category
    ? prompts.filter((p) => p.category === category)
    : prompts;

  const container = document.getElementById("saved-prompts-list");
  const countEl = document.getElementById("prompts-count");

  const countText =
    this.t("prompt_manager.prompts_in_category") ||
    "{count} prompts en esta categoría";
  countEl.textContent = countText.replace("{count}", filtered.length);

  if (filtered.length === 0) {
    container.innerHTML = `
      <div style="grid-column: 1/-1; text-align: center; padding: 40px; color: #666;">
        <h4>${this.t("prompt_manager.no_prompts_in_category")}</h4>
      </div>`;
    return;
  }

  container.innerHTML = filtered
    .map((prompt) => this.createPromptCard(prompt))
    .join("");
};

MSNAI.prototype.hideAllModals = function () {
  const modals = document.querySelectorAll(".modal");
  modals.forEach((modal) => {
    modal.style.display = "none";
  });
};

/**
 * Muestra una notificación temporal en pantalla
 * @param {string} message - Mensaje a mostrar
 * @param {string} type - Tipo de notificación: 'success', 'error', 'info', 'warning'
 * @param {number} duration - Duración en milisegundos (por defecto 3000)
 */
MSNAI.prototype.showNotification = function (
  message,
  type = "info",
  duration = 3000,
) {
  const iconMap = {
    success: "✅",
    error: "❌",
    info: "ℹ️",
    warning: "⚠️",
  };

  const notification = document.createElement("div");
  notification.className = `notification ${type} show`;
  notification.innerHTML = `
    <div class="notification-content">
      <span class="notification-icon">${iconMap[type] || iconMap.info}</span>
      <span class="notification-text">${message}</span>
      <button class="notification-close">×</button>
    </div>
  `;

  const container = document.getElementById("notification-container");
  if (container) {
    container.appendChild(notification);

    // Auto-eliminar después de la duración especificada
    const autoRemoveTimeout = setTimeout(() => {
      notification.classList.remove("show");
      setTimeout(() => notification.remove(), 300);
    }, duration);

    // Botón de cerrar
    notification
      .querySelector(".notification-close")
      .addEventListener("click", () => {
        clearTimeout(autoRemoveTimeout);
        notification.classList.remove("show");
        setTimeout(() => notification.remove(), 300);
      });
  }
};

// =================== SALAS DE EXPERTOS (CHAT GRUPAL CON MÚLTIPLES IAs) ===================

/**
 * Abre el modal para seleccionar modelos y crear una sala de expertos
 */
MSNAI.prototype.showExpertRoomModal = function () {
  const modal = document.getElementById("expert-room-modal");
  const modelsList = document.getElementById("expert-room-models-list");
  const roomTitleInput = document.getElementById("room-title-input");

  if (!modal || !modelsList || !roomTitleInput) {
    console.error(
      "❌ Error: No se encontraron elementos del modal de sala de expertos",
    );
    this.showNotification(
      "Error al abrir el modal de sala de expertos",
      "error",
    );
    return;
  }

  // Limpiar lista anterior
  modelsList.innerHTML = "";

  // Verificar que hay modelos disponibles
  if (!this.availableModels || this.availableModels.length === 0) {
    modelsList.innerHTML =
      '<p style="color: #999; text-align: center; padding: 20px;">⚠️ No hay modelos disponibles.<br><br>Por favor, verifica la conexión con Ollama y asegúrate de tener al menos un modelo instalado.</p>';
    modal.style.display = "block";
    this.showNotification(
      "No hay modelos disponibles para crear una sala",
      "warning",
    );
    return;
  }

  console.log(
    `🏢 Abriendo modal de sala de expertos con ${this.availableModels.length} modelos`,
  );

  // Actualizar traducciones del modal antes de mostrarlo
  this.updateDataI18nElements();

  // Generar checkboxes para cada modelo
  this.availableModels.forEach((model) => {
    const modelName = model.name || model;

    const label = document.createElement("label");
    label.style.display = "block";
    label.style.padding = "8px";
    label.style.cursor = "pointer";
    label.style.borderRadius = "4px";
    label.style.transition = "background-color 0.2s";

    label.addEventListener("mouseenter", function () {
      this.style.backgroundColor = "#e8f0ff";
    });

    label.addEventListener("mouseleave", function () {
      this.style.backgroundColor = "transparent";
    });

    const checkbox = document.createElement("input");
    checkbox.type = "checkbox";
    checkbox.value = modelName;
    checkbox.className = "expert-room-model-checkbox";
    checkbox.style.marginRight = "8px";

    const text = document.createTextNode(modelName);

    label.appendChild(checkbox);
    label.appendChild(text);
    modelsList.appendChild(label);
  });

  // Limpiar campo de título y poner nombre por defecto
  roomTitleInput.value =
    this.t("expert_room.default_name") || "Sala de Expertos";

  // Mostrar modal
  modal.style.display = "block";

  // Forzar actualización de traducciones después de mostrar el modal
  setTimeout(() => {
    this.updateDataI18nElements();
  }, 50);
};

/**
 * Crea una nueva sala de expertos con los modelos seleccionados
 */
MSNAI.prototype.createExpertRoom = function () {
  const checkboxes = document.querySelectorAll(
    ".expert-room-model-checkbox:checked",
  );
  const selectedModels = Array.from(checkboxes).map((cb) => cb.value);
  const roomTitle = document.getElementById("room-title-input").value.trim();

  // Validar que se hayan seleccionado al menos 2 modelos
  if (selectedModels.length < 2) {
    this.showNotification(
      this.t("expert_room.select_min_models") ||
        "Por favor selecciona al menos 2 modelos",
      "warning",
    );
    return;
  }

  // Crear el chat grupal
  const chatId = "room-" + Date.now();
  const newRoom = {
    id: chatId,
    type: "expert-room",
    isExpertRoom: true,
    title:
      roomTitle || this.t("expert_room.default_name") || "Sala de Expertos",
    date: new Date().toISOString(),
    models: selectedModels,
    model: selectedModels[0], // Modelo principal (por compatibilidad)
    messages: [],
    attachments: [],
  };

  this.chats.unshift(newRoom);
  this.saveChats();
  this.renderChatList();
  this.selectChat(chatId);
  this.playSound("nudge");

  // Cerrar modal
  document.getElementById("expert-room-modal").style.display = "none";

  // Mostrar notificación de éxito
  const successMessage = this.t("expert_room.created", {
    count: selectedModels.length,
  });
  this.showNotification(
    successMessage || `Sala creada con ${selectedModels.length} expertos`,
    "success",
  );

  console.log(
    `🏢 Sala de expertos creada: ${chatId} con modelos:`,
    selectedModels,
  );
};

/**
 * Envía un mensaje a todos los modelos de una sala de expertos
 * Las respuestas se muestran conforme van llegando
 */
MSNAI.prototype.sendExpertRoomMessage = async function () {
  const input = document.getElementById("message-input");
  const message = input.value.trim();

  if (!message || !this.currentChatId) return;

  const chat = this.chats.find((c) => c.id === this.currentChatId);
  if (!chat || !chat.isExpertRoom) {
    // Si no es una sala de expertos, usar el método normal
    return this.sendMessage();
  }

  // Inicializar array de controladores de abort para esta sala
  this.expertRoomAbortControllers[chat.id] = [];

  // Construir mensaje completo con contextos de adjuntos
  let displayedMessage = message;
  let fileContent = "";
  let pdfContext = null;
  let imageContext = null;

  // Manejar archivo de texto adjunto
  if (this.pendingFileAttachment) {
    const match = message.match(/^(.*?)\s*\[Archivo adjunto: [^\]]+\]$/);
    if (match) {
      displayedMessage = match[1] || "";
    }
    fileContent = this.pendingFileAttachment.content;
  }

  // Manejar contexto PDF
  if (this.pendingPdfContext) {
    const pdfMatch = message.match(/^(.*?)\s*\[PDF: [^\]]+\]$/);
    if (pdfMatch) {
      displayedMessage = pdfMatch[1] || "";
    }
    pdfContext = this.pendingPdfContext;
  }

  // Manejar contexto de imagen
  if (this.pendingImageContext) {
    const imageMatch = message.match(/^(.*?)\s*\[.+?: [^\]]+\]$/);
    if (imageMatch) {
      displayedMessage = imageMatch[1] || "";
    }
    imageContext = this.pendingImageContext;
  }

  // Limpiar input y contextos
  input.value = "";
  const originalAttachment = this.pendingFileAttachment;
  this.pendingFileAttachment = null;
  this.pendingPdfContext = null;
  this.pendingImageContext = null;

  // Agregar mensaje del usuario
  const userMessage = {
    type: "user",
    content: message,
    timestamp: new Date().toISOString(),
  };
  chat.messages.push(userMessage);
  this.renderMessages(chat);
  this.playSound("message-out");

  // NO deshabilitar input - permitir nuevos mensajes
  // input.disabled = false;
  // document.getElementById("send-button").disabled = false;

  // Marcar sala como respondiendo
  this.respondingChats.add(chat.id);

  // Mostrar botón de detener
  this.updateStopButtonVisibility();

  // Mostrar indicador de procesamiento
  this.showAIThinking(true);

  // Actualizar lista de chats para mostrar indicador visual
  this.renderChatList();

  console.log(
    `🏢 [ExpertRoom] Enviando mensaje a ${chat.models.length} modelos...`,
  );

  // Construir mensaje con contextos
  let actualMessageToSend = displayedMessage;

  if (fileContent) {
    // IMPORTANTE: Enviar el contenido COMPLETO del archivo a TODOS los modelos de la sala
    // El rate limiter (20 req/min, 1000ms intervalo, máx 2 concurrentes) espaciará
    // automáticamente las solicitudes para evitar errores 429
    let textContent = fileContent;

    // Advertencia si el archivo es muy grande
    if (textContent.length > 50000) {
      console.warn(
        `⚠️ [ExpertRoom] Enviando archivo grande (${Math.round(textContent.length / 1000)}KB) a múltiples modelos. Esto puede aumentar significativamente el tiempo de respuesta.`,
      );
    }

    actualMessageToSend = `[Archivo: ${originalAttachment.name}]\n${textContent}\n\nMensaje del usuario: ${displayedMessage || "(sin mensaje adicional)"}`;
  }

  let pdfContextText = null;
  if (pdfContext) {
    // IMPORTANTE: Enviar el contenido COMPLETO del PDF a TODOS los modelos de la sala
    // El rate limiter espaciará automáticamente las solicitudes para evitar errores 429

    // Advertencia si el PDF es muy grande
    if (pdfContext.text.length > 50000) {
      console.warn(
        `⚠️ [ExpertRoom] Enviando PDF grande (${Math.round(pdfContext.text.length / 1000)}KB, ${pdfContext.pages} páginas) a múltiples modelos. Esto puede aumentar significativamente el tiempo de respuesta.`,
      );
    }

    pdfContextText = `[Contexto PDF: ${pdfContext.name} - ${pdfContext.pages} páginas]\n\n${pdfContext.text}`;
  }

  // Procesar cada modelo con el sistema de rate limiting
  const results = [];

  for (let i = 0; i < chat.models.length; i++) {
    const model = chat.models[i];

    // Verificar si se abortó el procesamiento
    if (!this.respondingChats.has(chat.id)) {
      console.log("🛑 [ExpertRoom] Procesamiento abortado por el usuario");
      break;
    }

    try {
      console.log(
        `🤖 [ExpertRoom] Consultando a ${model}... (${i + 1}/${chat.models.length})`,
      );

      // El rate limiter manejará automáticamente el espaciado y los reintentos
      const response = await this.sendToAIWithRetry(
        actualMessageToSend,
        chat.id,
        model,
        pdfContextText,
        imageContext,
        3, // máximo 3 intentos
      );

      // Agregar respuesta inmediatamente cuando llega
      const aiMessage = {
        type: "ai",
        content: response,
        model: model,
        timestamp: new Date().toISOString(),
      };
      chat.messages.push(aiMessage);

      // Renderizar inmediatamente si es el chat actual
      if (this.currentChatId === chat.id) {
        this.renderMessages(chat);
        this.saveChats();
      }

      console.log(`✅ [ExpertRoom] Respuesta de ${model} recibida`);

      results.push({ model, success: true });
    } catch (error) {
      console.error(`❌ [ExpertRoom] Error con ${model}:`, error);

      // Si fue abortado, no agregar mensaje de error
      if (error.name === "AbortError" || !this.respondingChats.has(chat.id)) {
        console.log(`🛑 [ExpertRoom] Solicitud a ${model} abortada`);
        continue;
      }

      // Crear mensaje de error amigable para el usuario usando traducciones
      let errorContent = "";
      const errorMessage = error.message || "";

      if (
        errorMessage.includes("TimeoutError") ||
        errorMessage.includes("timed out")
      ) {
        errorContent = this.t("expert_room.error_timeout", { model });
      } else if (
        errorMessage.includes("HTTP 401") ||
        errorMessage.includes("Unauthorized")
      ) {
        errorContent = this.t("expert_room.error_http_401", { model });
        // Fallback si la traducción no está disponible
        if (!errorContent || errorContent.includes("expert_room.error_")) {
          errorContent = `🔐 ${model}: Este modelo requiere autenticación. Por favor, ejecuta 'ollama signin' en tu terminal.`;
        }
      } else if (
        errorMessage.includes("HTTP 429") ||
        errorMessage.includes("Too Many Requests")
      ) {
        errorContent = this.t("expert_room.error_http_429", { model });
      } else if (errorMessage.includes("HTTP 500")) {
        errorContent = this.t("expert_room.error_http_500", { model });
      } else if (errorMessage.includes("HTTP 404")) {
        errorContent = this.t("expert_room.error_http_404", { model });
      } else if (errorMessage.includes("HTTP 503")) {
        errorContent = this.t("expert_room.error_http_503", { model });
      } else if (
        errorMessage.includes("network") ||
        errorMessage.includes("fetch")
      ) {
        errorContent = this.t("expert_room.error_network", { model });
      } else {
        errorContent = this.t("expert_room.error_generic", { model });
      }

      // Fallback si la traducción no está disponible (solo para errores que no sean 401)
      if (!errorContent || errorContent.includes("expert_room.error_")) {
        errorContent = `⚠️ ${model}: No se pudo obtener respuesta en este momento.`;
      }

      const errorMsg = {
        type: "ai",
        content: errorContent,
        model: model,
        timestamp: new Date().toISOString(),
      };
      chat.messages.push(errorMsg);

      // Renderizar inmediatamente si es el chat actual
      if (this.currentChatId === chat.id) {
        this.renderMessages(chat);
        this.saveChats();
      }

      results.push({ model, success: false });
    }

    // El rate limiter maneja automáticamente el espaciado entre solicitudes
  }

  // Marcar sala como NO respondiendo y agregar a no leídos si no es el chat actual
  this.respondingChats.delete(chat.id);

  // Limpiar controladores de abort
  delete this.expertRoomAbortControllers[chat.id];

  // Ocultar botón de detener
  this.updateStopButtonVisibility();

  if (this.currentChatId !== chat.id) {
    this.unreadChats.add(chat.id);
  }

  // Ocultar indicador de procesamiento
  this.showAIThinking(false);

  // Actualizar título del chat si es necesario
  if (chat.messages.length <= chat.models.length + 1) {
    chat.title = this.generateChatTitle(chat);
  }

  // Renderizar una vez más para asegurar todo está actualizado
  if (this.currentChatId === chat.id) {
    this.renderMessages(chat);
  }

  this.saveChats();

  // Actualizar lista de chats para quitar indicador de respondiendo
  this.renderChatList();

  this.playSound("message-in");

  // Input ya está habilitado - solo dar foco
  input.focus();

  console.log(`✅ [ExpertRoom] Todas las respuestas procesadas`);
};

/**
 * Envía un mensaje a Ollama sin streaming (para salas de expertos)
 * @param {string} message - Mensaje del usuario
 * @param {string} chatId - ID del chat
 * @param {string} model - Modelo a usar
 * @param {string} pdfContext - Contexto PDF opcional
 * @param {object} imageContext - Contexto de imagen opcional
 * @returns {Promise<string>} - Respuesta completa del modelo
 */
MSNAI.prototype.sendToAIWithoutStreaming = async function (
  message,
  chatId,
  model,
  pdfContext = null,
  imageContext = null,
) {
  const chat = this.chats.find((c) => c.id === chatId);
  if (!chat) throw new Error("Chat no encontrado");

  // Crear un AbortController para esta solicitud específica
  const abortController = new AbortController();

  // Si es una sala de expertos, agregar el controlador al array
  if (chat.isExpertRoom && this.expertRoomAbortControllers[chatId]) {
    this.expertRoomAbortControllers[chatId].push(abortController);
  }

  // Construir historial de mensajes (solo del usuario y este modelo específico)
  const history = chat.messages
    .filter((m) => m.type === "user" || (m.type === "ai" && m.model === model))
    .map((m) => ({
      role: m.type === "user" ? "user" : "assistant",
      content: m.content,
    }));

  // Cargar todos los archivos adjuntos del chat desde IndexedDB
  // NOTA: En salas de expertos, cada modelo recibirá el contenido completo de los attachments
  // El rate limiter gestiona automáticamente el flujo para evitar errores 429
  let attachmentsContext = "";
  let attachmentImages = []; // Array para almacenar imágenes de attachments
  if (chat.attachments && chat.attachments.length > 0) {
    const attachmentsData = [];
    for (const attachmentMeta of chat.attachments) {
      try {
        const attachment = await this.getAttachment(attachmentMeta.id);
        if (attachment) {
          if (attachment.type === "text/plain") {
            // IMPORTANTE: Enviar contenido COMPLETO a cada modelo de la sala
            // El rate limiter evita saturar el servidor con múltiples solicitudes simultáneas
            let textContent = attachment.content;
            attachmentsData.push(
              `[Archivo TXT: ${attachment.name}]\n${textContent}\n`,
            );
          } else if (attachment.type === "application/pdf") {
            // IMPORTANTE: Enviar contenido COMPLETO a cada modelo de la sala
            // El rate limiter evita saturar el servidor con múltiples solicitudes simultáneas
            attachmentsData.push(
              `[Archivo PDF: ${attachment.name} - ${attachment.pages} páginas]\n${attachment.content}\n`,
            );
          } else if (attachment.type && attachment.type.startsWith("image/")) {
            // Para imágenes, agregar al array de imágenes (no al contexto de texto)
            if (attachment.base64Data) {
              attachmentImages.push(attachment.base64Data);
              attachmentsData.push(`[Imagen: ${attachment.name}]\n`);
            }
          }
        }
      } catch (error) {
        console.error(`Error cargando attachment ${attachmentMeta.id}:`, error);
      }
    }
    if (attachmentsData.length > 0) {
      attachmentsContext = `\n\n=== ${this.t("chat.attachments_context_header")} ===\n${attachmentsData.join("\n---\n")}\n=== ${this.t("chat.attachments_context_footer")} ===\n\n`;
    }
  }

  // Construir mensaje final con contextos
  let finalMessage = message;

  if (attachmentsContext || pdfContext) {
    finalMessage = `${attachmentsContext}${pdfContext ? pdfContext + "\n\n---\n\n" : ""}${message}`;
  } else if (pdfContext) {
    finalMessage = `${pdfContext}\n\nConsulta del usuario: ${message}`;
  }

  // Preparar array de mensajes
  const messages = [];

  // Si es una sala de expertos, agregar system prompt al inicio
  if (chat.isExpertRoom) {
    // Obtener el system prompt configurado o el por defecto
    let systemPrompt =
      this.settings.groupChatSystemPrompt ||
      this.t("settings.default_group_chat_system_prompt") ||
      "";

    if (systemPrompt) {
      // Reemplazar variables en el system prompt
      const modelName = model;
      const participantList = chat.models.join(", ");

      systemPrompt = systemPrompt
        .replace(/\{\{MODEL_NAME\}\}/g, modelName)
        .replace(/\{\{PARTICIPANT_LIST\}\}/g, participantList);

      // Agregar como primer mensaje del sistema
      messages.push({
        role: "system",
        content: systemPrompt,
      });

      console.log(
        `🔧 [ExpertRoom] System prompt inyectado para ${model} en sala ${chat.title}`,
      );
    }
  }

  // Agregar historial y mensaje actual
  messages.push(...history);
  messages.push({
    role: "user",
    content: finalMessage,
  });

  // Preparar payload base según documentación de Ollama API
  const payload = {
    model: model,
    messages: messages,
    stream: false,
    options: {
      temperature: parseFloat(this.settings.temperature) || 0.7,
      top_k: parseInt(this.settings.topK) || 40,
      top_p: parseFloat(this.settings.topP) || 0.9,
      num_predict: parseInt(this.settings.maxTokens) || 2000,
    },
    keep_alive: "5m", // Mantener modelo en memoria por 5 minutos
  };

  // Agregar imagen si existe (temporal o de attachments)
  if (imageContext && imageContext.base64Data) {
    payload.messages[payload.messages.length - 1].images = [
      imageContext.base64Data,
    ];
  } else if (attachmentImages.length > 0) {
    // Usar solo la primera imagen de los attachments para no saturar
    payload.messages[payload.messages.length - 1].images = [
      attachmentImages[0],
    ];
  }

  console.log(`📤 [ExpertRoom] Enviando a ${model}`);

  // Combinar señales de timeout y abort manual
  const timeoutSignal = AbortSignal.timeout(parseInt(this.settings.apiTimeout));

  // Crear una promesa que se resuelve cuando cualquiera de las señales aborta
  const combinedAbort = new Promise((_, reject) => {
    abortController.signal.addEventListener("abort", () => {
      reject(new DOMException("Request aborted by user", "AbortError"));
    });
    timeoutSignal.addEventListener("abort", () => {
      reject(new DOMException("Request timeout", "TimeoutError"));
    });
  });

  // Usar el rate limiter para la solicitud
  const fetchPromise = this.rateLimiter.makeRequest(
    async () => {
      return await fetch(`${this.settings.ollamaServer}/api/chat`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
        signal: abortController.signal,
      });
    },
    { priority: "high", model: model, chatId: chatId },
  );

  const response = await Promise.race([fetchPromise, combinedAbort]);

  if (!response.ok) {
    // Manejar error 401 específicamente
    if (response.status === 401) {
      const error = new Error(`HTTP 401: Unauthorized`);
      error.statusCode = 401;
      throw error;
    }
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }

  const data = await response.json();
  console.log(`✅ [ExpertRoom] Respuesta de ${model} recibida`);

  return data.message?.content || data.response || "";
};

/**
 * Envía un mensaje a Ollama con reintentos automáticos en caso de error 429
 * @param {string} message - Mensaje del usuario
 * @param {string} chatId - ID del chat
 * @param {string} model - Modelo a usar
 * @param {string} pdfContext - Contexto PDF opcional
 * @param {object} imageContext - Contexto de imagen opcional
 * @param {number} maxRetries - Número máximo de reintentos (default: 3)
 * @returns {Promise<string>} - Respuesta completa del modelo
 */
MSNAI.prototype.sendToAIWithRetry = async function (
  message,
  chatId,
  model,
  pdfContext = null,
  imageContext = null,
  maxRetries = 3,
) {
  // El rate limiter ahora maneja automáticamente los reintentos con backoff exponencial
  // Solo necesitamos hacer la llamada una vez
  try {
    const response = await this.sendToAIWithoutStreaming(
      message,
      chatId,
      model,
      pdfContext,
      imageContext,
    );
    return response;
  } catch (error) {
    const errorMessage = error.message || "";

    // Registrar eventos de rate limit para monitoreo
    if (
      errorMessage.includes("HTTP 429") ||
      errorMessage.includes("Too Many Requests")
    ) {
      this.rateLimiter.logRateLimitEvent(model, chatId);
      console.error(
        `❌ [ExpertRoom] Error 429 persistente para ${model} después de reintentos automáticos`,
      );
    }

    throw error;
  }
};

/**
 * Modifica selectChat para manejar salas de expertos
 */
const originalSelectChat = MSNAI.prototype.selectChat;
MSNAI.prototype.selectChat = function (chatId) {
  originalSelectChat.call(this, chatId);

  const chat = this.chats.find((c) => c.id === chatId);
  if (chat && chat.isExpertRoom) {
    // Marcar como leído
    this.unreadChats.delete(chatId);

    // Actualizar información de la sala en el header
    const modelsInfo = chat.models.join(", ");
    const modelsLabel = this.t("expert_room.models_label");
    const labelText =
      modelsLabel && !modelsLabel.includes("expert_room.")
        ? modelsLabel
        : "Expertos";
    document.getElementById("chat-status-message").textContent =
      `🏢 ${labelText}: ${modelsInfo}`;

    // Asegurar que los botones de adjuntos funcionen en salas
    document.getElementById("message-input").disabled = false;
    document.getElementById("send-button").disabled = false;

    // Actualizar lista para quitar indicador de no leído
    this.renderChatList();
  }
};

/**
 * Modifica sendMessage para detectar salas de expertos
 */
const originalSendMessage = MSNAI.prototype.sendMessage;
MSNAI.prototype.sendMessage = async function () {
  const chat = this.chats.find((c) => c.id === this.currentChatId);

  if (chat && chat.isExpertRoom) {
    return this.sendExpertRoomMessage();
  }

  return originalSendMessage.call(this);
};

/**
 * Modifica createNewChat para crear chats independientes (no dentro de salas)
 */
const originalCreateNewChat = MSNAI.prototype.createNewChat;
MSNAI.prototype.createNewChat = function () {
  // Crear un chat normal independiente, no vinculado a ninguna sala
  return originalCreateNewChat.call(this);
};

// ===================
// SISTEMA DE RATE LIMITING PARA OLLAMA
// ===================

/**
 * Gestor de rate limiting para solicitudes a Ollama API
 * Implementa:
 * - Cola de solicitudes con prioridades
 * - Espaciado automático entre solicitudes
 * - Backoff exponencial con jitter para errores 429
 * - Monitoreo de eventos de rate limit
 * - Límite de solicitudes concurrentes
 */
/**
 * Gestor de Rate Limiting para Ollama API
 *
 * CONFIGURACIÓN ULTRA-CONSERVADORA implementada después de análisis de logs HAR
 * que mostraron solicitudes enviadas con solo 2ms de diferencia causando error 429.
 *
 * La API de Ollama en localhost tiene límites de rate muy estrictos que no están
 * documentados claramente. Esta clase implementa:
 *
 * 1. Cola de prioridades con ejecución ESTRICTAMENTE SECUENCIAL
 * 2. Espera mínima de 2.5 segundos entre CADA solicitud
 * 3. Solo 1 solicitud concurrente (sin paralelismo)
 * 4. Reintentos automáticos con backoff exponencial
 * 5. Logging detallado para monitoreo y debugging
 *
 * IMPORTANTE: Modificar estos valores puede resultar en error 429 persistente.
 */
class OllamaRateLimiter {
  constructor(config = {}) {
    // Configuración balanceada con ajuste dinámico para evitar errores 429 (Too Many Requests)
    // El sistema aumenta el intervalo automáticamente si detecta errores 429
    this.maxRequestsPerMinute = config.maxRequestsPerMinute || 30; // 30 req/min razonable
    this.minRequestInterval = config.minRequestInterval || 1000; // 1 segundo base (buena UX)
    this.maxRetries = config.maxRetries || 3; // Reintentos automáticos con backoff exponencial
    this.baseRetryDelay = config.baseRetryDelay || 3000; // ms - 3s antes del primer reintento
    this.maxRetryDelay = config.maxRetryDelay || 60000; // ms - Espera máxima entre reintentos
    this.maxConcurrentRequests = config.maxConcurrentRequests || 1; // CRÍTICO: Solo 1 solicitud a la vez

    // Estado interno
    this.requestQueue = [];
    this.requestTimestamps = [];
    this.activeRequests = 0;
    this.rateLimitEvents = [];
    this.lastRequestTime = 0;
    this.isProcessingQueue = false;
    this.consecutive429Errors = 0; // Contador de errores 429 consecutivos
    this.originalMinInterval = this.minRequestInterval; // Guardar intervalo original

    console.log("🔧 [RateLimiter] Inicializado con configuración:", {
      maxRequestsPerMinute: this.maxRequestsPerMinute,
      minRequestInterval: this.minRequestInterval,
      maxRetries: this.maxRetries,
      maxConcurrentRequests: this.maxConcurrentRequests,
    });
  }

  /**
   * Realiza una solicitud con rate limiting automático
   * @param {Function} requestFn - Función que realiza la solicitud (debe retornar Promise)
   * @param {Object} options - Opciones de la solicitud (priority, chatId, model, skipQueue)
   * @returns {Promise} - Resultado de la solicitud
   */
  async makeRequest(requestFn, options = {}) {
    const priority = options.priority || "normal"; // 'high', 'normal', 'low'
    const skipQueue = options.skipQueue || false;

    // Si skipQueue es true, ejecutar inmediatamente sin cola (para verificaciones de conexión)
    if (skipQueue) {
      return await this._executeRequest(requestFn, options, 0);
    }

    // Agregar a la cola con prioridad
    return new Promise((resolve, reject) => {
      const queueItem = {
        requestFn,
        options,
        priority: this._getPriorityValue(priority),
        resolve,
        reject,
        timestamp: Date.now(),
      };

      this.requestQueue.push(queueItem);

      // Ordenar cola por prioridad (mayor prioridad primero)
      this.requestQueue.sort((a, b) => b.priority - a.priority);

      console.log(
        `📋 [RateLimiter] Solicitud agregada a cola (prioridad: ${priority}, cola: ${this.requestQueue.length})`,
      );

      // Procesar cola
      this._processQueue();
    });
  }

  /**
   * Procesa la cola de solicitudes respetando límites
   */
  async _processQueue() {
    // Evitar procesamiento concurrente de la cola
    if (this.isProcessingQueue) {
      return;
    }

    this.isProcessingQueue = true;

    try {
      while (this.requestQueue.length > 0) {
        // Verificar límite de solicitudes concurrentes
        if (this.activeRequests >= this.maxConcurrentRequests) {
          console.log(
            `⏸️ [RateLimiter] Esperando: ${this.activeRequests} solicitudes activas (máx: ${this.maxConcurrentRequests})`,
          );
          await new Promise((resolve) => setTimeout(resolve, 100));
          continue;
        }

        // Verificar límite de solicitudes por minuto
        const now = Date.now();
        this._cleanOldTimestamps(now);

        if (this.requestTimestamps.length >= this.maxRequestsPerMinute) {
          const oldestTimestamp = this.requestTimestamps[0];
          const waitTime = 60000 - (now - oldestTimestamp);

          if (waitTime > 0) {
            console.log(
              `⏳ [RateLimiter] Límite de ${this.maxRequestsPerMinute} req/min alcanzado. Esperando ${Math.ceil(waitTime / 1000)}s`,
            );
            await new Promise((resolve) => setTimeout(resolve, waitTime));
            continue;
          }
        }

        // CRÍTICO: Forzar espera del intervalo mínimo ANTES de cada solicitud
        // Recalcular now para tener el tiempo actual después de posibles esperas anteriores
        const currentTime = Date.now();
        const timeSinceLastRequest = currentTime - this.lastRequestTime;
        if (
          this.lastRequestTime > 0 &&
          timeSinceLastRequest < this.minRequestInterval
        ) {
          const waitTime = this.minRequestInterval - timeSinceLastRequest;
          console.log(
            `⏱️ [RateLimiter] Esperando ${waitTime}ms para respetar intervalo mínimo`,
          );
          await new Promise((resolve) => setTimeout(resolve, waitTime));
        }

        // Obtener siguiente solicitud de la cola
        const queueItem = this.requestQueue.shift();

        if (!queueItem) {
          break;
        }

        // CRÍTICO: ESPERAR a que la solicitud termine antes de continuar
        // Esto asegura ejecución ESTRICTAMENTE SECUENCIAL
        const requestStartTime = Date.now();
        console.log(
          `🔵 [RateLimiter] Iniciando solicitud secuencial (cola restante: ${this.requestQueue.length})`,
        );

        try {
          const result = await this._executeRequest(
            queueItem.requestFn,
            queueItem.options,
            0,
          );
          queueItem.resolve(result);

          const requestDuration = Date.now() - requestStartTime;
          console.log(
            `✅ [RateLimiter] Solicitud completada en ${requestDuration}ms`,
          );
        } catch (error) {
          const requestDuration = Date.now() - requestStartTime;
          console.error(
            `❌ [RateLimiter] Solicitud falló después de ${requestDuration}ms: ${error.message}`,
          );
          queueItem.reject(error);
        }

        // Actualizar timestamp DESPUÉS de que la solicitud termine
        this.lastRequestTime = Date.now();
        this.requestTimestamps.push(this.lastRequestTime);

        console.log(
          `⏱️ [RateLimiter] Próxima solicitud en mínimo ${this.minRequestInterval}ms`,
        );
      }
    } finally {
      this.isProcessingQueue = false;
    }
  }

  /**
   * Ejecuta una solicitud con reintentos automáticos en caso de error 429
   */
  async _executeRequest(requestFn, options, attempt) {
    // Solo incrementar activeRequests en el primer intento
    const isFirstAttempt = attempt === 0;
    if (isFirstAttempt) {
      this.activeRequests++;
    }

    try {
      const execStartTime = Date.now();
      console.log(
        `🚀 [RateLimiter] Ejecutando solicitud (activas: ${this.activeRequests}, intento: ${attempt + 1})`,
      );

      const response = await requestFn();

      const execDuration = Date.now() - execStartTime;
      console.log(
        `📊 [RateLimiter] Respuesta recibida en ${execDuration}ms - Status: ${response.status}`,
      );

      // Verificar si es un error 429
      if (response.status === 429) {
        this.consecutive429Errors++;

        // Si hay muchos errores 429 consecutivos, aumentar el intervalo
        if (this.consecutive429Errors >= 3) {
          const newInterval = Math.min(
            this.minRequestInterval * 1.5,
            15000, // Máximo 15 segundos
          );
          if (newInterval > this.minRequestInterval) {
            console.warn(
              `⚠️ [RateLimiter] Demasiados errores 429 (${this.consecutive429Errors}). Aumentando intervalo de ${this.minRequestInterval}ms a ${newInterval}ms`,
            );
            this.minRequestInterval = newInterval;
          }
        }

        throw new Error("HTTP 429: Too Many Requests");
      }

      // Resetear contador de errores 429 en caso de éxito
      if (response.status === 200) {
        if (this.consecutive429Errors > 0) {
          console.log(
            `✅ [RateLimiter] Solicitud exitosa después de ${this.consecutive429Errors} errores 429. Reseteando contador.`,
          );
          this.consecutive429Errors = 0;

          // Reducir gradualmente el intervalo de vuelta al original si fue aumentado
          if (this.minRequestInterval > this.originalMinInterval) {
            const newInterval = Math.max(
              this.minRequestInterval * 0.9,
              this.originalMinInterval,
            );
            if (newInterval < this.minRequestInterval) {
              console.log(
                `📉 [RateLimiter] Reduciendo intervalo de ${this.minRequestInterval}ms a ${newInterval}ms`,
              );
              this.minRequestInterval = newInterval;
            }
          }
        }
      }

      return response;
    } catch (error) {
      const errorMessage = error.message || "";

      // Si es error 429 y quedan reintentos
      if (
        (errorMessage.includes("429") ||
          errorMessage.includes("Too Many Requests")) &&
        attempt < this.maxRetries
      ) {
        // Calcular delay con backoff exponencial y jitter
        const exponentialDelay = Math.min(
          this.baseRetryDelay * Math.pow(2, attempt),
          this.maxRetryDelay,
        );

        // Agregar jitter aleatorio (0-25% del delay)
        const jitter = Math.random() * exponentialDelay * 0.25;
        const totalDelay = exponentialDelay + jitter;

        console.warn(
          `⚠️ [RateLimiter] Error 429 detectado. Reintentando en ${Math.ceil(totalDelay / 1000)}s (intento ${attempt + 1}/${this.maxRetries})`,
        );

        // Registrar evento de rate limit
        this.rateLimitEvents.push({
          timestamp: Date.now(),
          attempt: attempt + 1,
          delay: totalDelay,
          options: options,
        });

        // Esperar antes de reintentar
        await new Promise((resolve) => setTimeout(resolve, totalDelay));

        // Reintentar (sin incrementar activeRequests nuevamente)
        return await this._executeRequest(requestFn, options, attempt + 1);
      }

      // Si no es 429 o se agotaron los reintentos, lanzar error
      throw error;
    } finally {
      // Solo decrementar activeRequests en el primer intento
      if (isFirstAttempt) {
        this.activeRequests--;

        // Si hay solicitudes en cola, continuar procesando
        if (this.requestQueue.length > 0) {
          setTimeout(() => this._processQueue(), 0);
        }
      }
    }
  }

  /**
   * Limpia timestamps antiguos (más de 1 minuto)
   */
  _cleanOldTimestamps(now) {
    const oneMinuteAgo = now - 60000;
    this.requestTimestamps = this.requestTimestamps.filter(
      (timestamp) => timestamp > oneMinuteAgo,
    );
  }

  /**
   * Convierte prioridad textual a valor numérico
   */
  _getPriorityValue(priority) {
    const priorities = {
      high: 3,
      normal: 2,
      low: 1,
    };
    return priorities[priority] || 2;
  }

  /**
   * Registra un evento de rate limit para monitoreo
   */
  logRateLimitEvent(model, chatId) {
    this.rateLimitEvents.push({
      timestamp: Date.now(),
      model: model,
      chatId: chatId,
      type: "persistent_429",
    });

    // Mantener solo los últimos 100 eventos
    if (this.rateLimitEvents.length > 100) {
      this.rateLimitEvents = this.rateLimitEvents.slice(-100);
    }

    // Verificar si hay demasiados eventos recientes
    this._checkRateLimitFrequency();
  }

  /**
   * Verifica la frecuencia de eventos de rate limit
   */
  _checkRateLimitFrequency() {
    const now = Date.now();
    const recentEvents = this.rateLimitEvents.filter(
      (event) => now - event.timestamp < 600000, // Últimos 10 minutos
    );

    if (recentEvents.length > 10) {
      console.error(
        `❌❌❌ [RateLimiter] ALTA FRECUENCIA DE RATE LIMITS: ${recentEvents.length} eventos en 10 minutos`,
      );
      console.error(
        `💡 [RateLimiter] Considere reducir maxRequestsPerMinute o aumentar minRequestInterval`,
      );
    }
  }

  /**
   * Obtiene estadísticas del rate limiter
   */
  getStats() {
    const now = Date.now();
    const recentEvents = this.rateLimitEvents.filter(
      (event) => now - event.timestamp < 3600000, // Última hora
    );

    return {
      queueSize: this.requestQueue.length,
      activeRequests: this.activeRequests,
      requestsLastMinute: this.requestTimestamps.length,
      rateLimitEventsLastHour: recentEvents.length,
      lastRequestTime: this.lastRequestTime,
    };
  }
}
