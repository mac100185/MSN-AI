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
    this.abortControllers = {}; // Mapa de controladores por chatId
    this.respondingChats = new Set(); // Set de chatIds que están recibiendo respuesta
    this.wasAborted = false; // Flag para saber si se abortó la última respuesta
    this.accumulatedResponses = {}; // Mapa de respuestas acumuladas por chatId
    this.unreadChats = new Set(); // Set de chatIds con mensajes no leídos
    this.translations = {}; // Diccionario de traducciones
    this.availableLanguages = []; // Idiomas disponibles
    this.currentLanguage = "es"; // Idioma por defecto
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
    };
    this.currentStatus = "online"; // Estado inicial
    this.init();
  }

  // =================== SISTEMA DE TRADUCCIÓN ===================
  async loadLanguages() {
    const languages = ["es", "en", "de"];
    for (const lang of languages) {
      try {
        const response = await fetch(`lang/${lang}.json`);
        if (response.ok) {
          const translations = await response.json();
          this.availableLanguages.push({
            code: lang,
            name: translations.language_name,
            data: translations,
          });
          console.log(
            `✅ Idioma cargado: ${translations.language_name} (${lang})`,
          );
        }
      } catch (error) {
        console.warn(`⚠️ No se pudo cargar idioma: ${lang}`, error);
      }
    }

    // Cargar idioma guardado o español por defecto
    const savedLang = localStorage.getItem("msnai-language") || "es";
    await this.setLanguage(savedLang);
    this.updateLanguageSelect();
  }

  async setLanguage(langCode) {
    const langData = this.availableLanguages.find((l) => l.code === langCode);
    if (langData) {
      this.currentLanguage = langCode;
      this.translations = langData.data;
      this.settings.language = langCode;
      localStorage.setItem("msnai-language", langCode);
      console.log(`🌍 Idioma establecido: ${langData.name}`);

      // Actualizar toda la interfaz
      this.updateUI();
    } else {
      console.warn(`⚠️ Idioma no disponible: ${langCode}, usando español`);
      this.currentLanguage = "es";
    }
  }

  t(key, replacements = {}) {
    // Obtener traducción por clave (soporta notación de punto)
    const keys = key.split(".");
    let value = this.translations;

    for (const k of keys) {
      if (value && typeof value === "object") {
        value = value[k];
      } else {
        return key; // Retornar la clave si no se encuentra traducción
      }
    }

    // Reemplazar variables {variable}
    if (typeof value === "string" && Object.keys(replacements).length > 0) {
      return value.replace(/\{(\w+)\}/g, (match, key) => {
        return replacements[key] !== undefined ? replacements[key] : match;
      });
    }

    return value || key;
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
    this.updateStaticTexts();
    this.updateButtons();
    this.updateModals();
    this.updatePlaceholders();
    this.renderChatList();
    if (this.currentChatId) {
      const chat = this.chats.find((c) => c.id === this.currentChatId);
      if (chat) {
        this.renderMessages(chat);
      }
    }
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
    // Actualizar textos de botones
    const buttonMap = {
      "send-button": "buttons.send",
      "test-connection": "buttons.test_connection",
      "save-settings": "buttons.save",
      "confirm-delete-btn": "buttons.delete",
      "cancel-delete-btn": "buttons.cancel",
      "conflict-apply-btn": "buttons.apply",
      "close-summary-btn": "buttons.close",
      "do-search-btn": "buttons.search",
      "clear-search-highlight": "buttons.clear",
      "import-chats-btn": "buttons.import",
      "download-chats": "buttons.export",
    };

    Object.keys(buttonMap).forEach((id) => {
      const el = document.getElementById(id);
      if (el) {
        const text = this.t(buttonMap[id]);
        // Mantener iconos si existen
        const icon = el.innerHTML.match(/^[^\w\s]+\s*/);
        if (icon) {
          el.textContent = icon[0] + text;
        } else {
          el.textContent = text;
        }
      }
    });
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
    const modal = document.getElementById("settings-modal");
    if (!modal) return;

    // Actualizar labels
    const labels = modal.querySelectorAll("label");
    labels.forEach((label) => {
      const checkbox = label.querySelector('input[type="checkbox"]');
      if (checkbox) {
        const span = label.querySelector("span");
        if (span) {
          if (checkbox.id === "sounds-enabled") {
            span.textContent = this.t("settings.sounds_enabled");
          } else if (checkbox.id === "notify-status-changes") {
            span.textContent = this.t("settings.notify_status_changes");
          }
        }
      }
    });

    // Actualizar labels de campos
    const serverLabel = modal.querySelector(
      'label[style*="font-weight: bold"]',
    );
    if (serverLabel && serverLabel.textContent.includes("Ollama")) {
      serverLabel.childNodes[0].textContent =
        this.t("settings.ollama_server") + ":";
    }
  }

  updateDeleteModal() {
    const modal = document.getElementById("delete-chat-modal");
    if (!modal) return;

    const p = modal.querySelector("p");
    if (p) p.textContent = this.t("delete_chat.message");
  }

  updateSearchModal() {
    const modal = document.getElementById("search-chat-modal");
    if (!modal) return;

    const input = modal.querySelector("#search-term-input");
    if (input) input.placeholder = this.t("search_chat.placeholder");
  }

  updateExportImportModal() {
    const exportModal = document.getElementById("export-modal");
    if (exportModal) {
      const p = exportModal.querySelector("p");
      if (p) p.textContent = this.t("export_import.export_description");
    }

    const importModal = document.getElementById("import-modal");
    if (importModal) {
      const p = importModal.querySelector("p");
      if (p) p.textContent = this.t("export_import.import_description");
    }
  }

  updatePlaceholders() {
    const input = document.getElementById("message-input");
    if (input) {
      input.placeholder = this.t("chat.search_placeholder");
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

    // Mapear el estado a la ruta del ícono
    const iconPath = `assets/status/${status}.png`;
    statusIcon.src = iconPath;

    // Actualizar el texto
    const statusNames = {
      online: "Online",
      away: "Away",
      busy: "Busy",
      invisible: "Invisible",
    };

    statusText.textContent = `(${statusNames[status] || status})`;

    // Guardar el estado anterior para comparar
    const previousStatus = this.currentStatus;
    this.currentStatus = status;
    localStorage.setItem("msnai-current-status", status);

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

    // Mensajes personalizados según el estado
    const statusMessages = {
      online:
        "He cambiado mi estado a Online. Estoy disponible para conversar.",
      away: "He cambiado mi estado a Away. Estoy ausente pero puedes dejarme un mensaje.",
      busy: "He cambiado mi estado a Busy. Estoy ocupado pero responderé cuando pueda.",
      invisible:
        "He cambiado mi estado a Invisible. Prefiero no ser visto en este momento.",
    };

    const userMessage =
      statusMessages[newStatus] || `He cambiado mi estado a ${newStatus}.`;

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
      const contextPrompt = `El usuario ha cambiado su estado de "${oldStatus}" a "${newStatus}". ${userMessage} Responde de manera breve y amigable reconociendo este cambio de estado.`;

      const onToken = (token) => {
        // Acumular en el sistema de respuestas
        this.accumulatedResponses[chat.id] += token;
        aiMessage.content = this.accumulatedResponses[chat.id];

        // Solo renderizar si es el chat actual
        if (this.currentChatId === chat.id) {
          this.renderMessages(chat);
        }
      };

      await this.sendToAI(contextPrompt, chat.id, onToken);

      this.playSound("message-in");
    } catch (error) {
      console.error("Error notificando cambio de estado:", error);

      // No mostrar error si fue un abort intencional
      if (error.name === "AbortError") {
        if (aiMessage.content) {
          aiMessage.content += "\n\n[⏹️ Respuesta detenida por el usuario]";
        } else {
          aiMessage.content = `He notado tu cambio de estado a ${newStatus}.`;
        }
      } else {
        aiMessage.content = `He notado tu cambio de estado a ${newStatus}. ¿En qué puedo ayudarte?`;
      }
      if (this.currentChatId === chat.id) {
        this.renderMessages(chat);
      }
    } finally {
      // Verificar si fue abortado y añadir marcador SIEMPRE
      if (this.wasAborted) {
        if (
          aiMessage.content &&
          !aiMessage.content.includes("[⏹️ Respuesta detenida")
        ) {
          aiMessage.content += "\n\n[⏹️ Respuesta detenida por el usuario]";
        } else if (!aiMessage.content) {
          aiMessage.content = "[⏹️ Respuesta detenida]";
        }
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
    const createPicker = (id, emojis) => {
      const picker = document.getElementById(id);
      picker.innerHTML = "";
      emojis.forEach((e) => {
        const span = document.createElement("span");
        span.textContent = e;
        span.addEventListener("click", () => {
          this.insertEmojiAtCursor(e);
          picker.style.display = "none";
        });
        picker.appendChild(span);
      });
    };
    createPicker("emoticon-natural-picker", naturalEmojis);
    createPicker("emoticon-amor-picker", amorEmojis);
    const showPicker = (btn, pickerId) => {
      const btnRect = btn.getBoundingClientRect();
      const picker = document.getElementById(pickerId);
      picker.style.top = btnRect.bottom + "px";
      picker.style.left = btnRect.left + "px";
      picker.style.display = picker.style.display === "none" ? "flex" : "none";
    };
    document
      .getElementById("emoticon-natural-btn")
      .addEventListener("click", (e) => {
        showPicker(e.currentTarget, "emoticon-natural-picker");
      });
    document
      .getElementById("emoticon-amor-btn")
      .addEventListener("click", (e) => {
        showPicker(e.currentTarget, "emoticon-amor-picker");
      });
    document.addEventListener("click", (e) => {
      if (
        !e.target.closest(".emoticon-picker") &&
        !e.target.closest('[id$="-btn"]')
      ) {
        document.getElementById("emoticon-natural-picker").style.display =
          "none";
        document.getElementById("emoticon-amor-picker").style.display = "none";
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
      content: "¿Estás allí?",
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

        // Solo renderizar si es el chat actual
        if (this.currentChatId === chat.id) {
          this.renderMessages(chat);
        }
      };

      await this.sendToAI("¿Estás allí?", chat.id, onToken);

      this.playSound("message-in");
    } catch (error) {
      console.error("Error enviando sumbido:", error);

      // No mostrar error si fue un abort intencional
      if (error.name === "AbortError") {
        if (aiMessage.content) {
          aiMessage.content += "\n\n[⏹️ Respuesta detenida por el usuario]";
        } else {
          aiMessage.content = "Sumbido enviado (respuesta detenida)";
        }
      } else {
        aiMessage.content = `Error: ${error.message}. Verifica que Ollama esté ejecutándose.`;
      }
      if (this.currentChatId === chat.id) {
        this.renderMessages(chat);
      }
    } finally {
      // Verificar si fue abortado y añadir marcador SIEMPRE
      if (this.wasAborted) {
        if (
          aiMessage.content &&
          !aiMessage.content.includes("[⏹️ Respuesta detenida")
        ) {
          aiMessage.content += "\n\n[⏹️ Respuesta detenida por el usuario]";
        } else if (!aiMessage.content) {
          aiMessage.content = "[⏹️ Respuesta detenida]";
        }
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
    if (
      !("SpeechRecognition" in window || "webkitSpeechRecognition" in window)
    ) {
      alert(this.t("errors.voice_not_supported"));
      return;
    }
    const recognition = new (window.SpeechRecognition ||
      window.webkitSpeechRecognition)();
    recognition.lang = "es-ES";
    recognition.interimResults = false;
    recognition.maxAlternatives = 1;
    recognition.start();
    recognition.onresult = (event) => {
      const transcript = event.results[0][0].transcript;
      const input = document.getElementById("message-input");
      input.value += transcript + " ";
      input.focus();
    };
    recognition.onerror = (event) =>
      console.error("Speech error:", event.error);
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

  uploadTextFile() {
    const input = document.createElement("input");
    input.type = "file";
    input.accept = ".txt,text/plain";
    input.onchange = (e) => {
      const file = e.target.files[0];
      if (!file) return;
      if (!file.name.endsWith(".txt") || file.type !== "text/plain") {
        alert(this.t("errors.only_txt_files"));
        return;
      }
      const reader = new FileReader();
      reader.onload = (ev) => {
        const content = ev.target.result;
        const inputEl = document.getElementById("message-input");
        this.pendingFileAttachment = {
          name: file.name,
          content: content,
        };
        const currentMsg = inputEl.value.trim();
        inputEl.value = `${currentMsg ? currentMsg + " " : ""}[Archivo adjunto: ${file.name}]`;
        inputEl.focus();
      };
      reader.readAsText(file);
    };
    input.click();
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
  exportSelectedChats() {
    const selectedChats = this.chats.filter((chat) => chat.selected);

    if (selectedChats.length === 0) {
      alert(this.t("export_import.no_selected"));
      return;
    }

    const data = {
      version: "1.0",
      exportDate: new Date().toISOString(),
      chats: selectedChats,
    };
    const blob = new Blob([JSON.stringify(data, null, 2)], {
      type: "application/json",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `msn-ai-selected-chats-${new Date().toISOString().split("T")[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
    this.playSound("nudge");
  }

  exportCurrentChat() {
    const chat = this.chats.find((c) => c.id === this.currentChatId);
    if (!chat) return;
    const content = chat.messages
      .map((m) => `${m.type === "user" ? "Tú" : "IA"}: ${m.content}`)
      .join("\n");
    const blob = new Blob([content], { type: "text/plain" });
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
    const printContent = `<html><head><title>Chat</title><style>body{font-family:Tahoma;font-size:9pt;}</style></head><body><pre>${chat.messages.map((m) => `${m.type === "user" ? "Tú" : "IA"}: ${m.content}`).join("\n")}</pre></body></html>`;
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

  // =================== ENVÍO DE MENSAJE CON ARCHIVO ===================

  async sendMessage() {
    const input = document.getElementById("message-input");
    const message = input.value.trim();
    if (!message || !this.currentChatId) return;
    const chat = this.chats.find((c) => c.id === this.currentChatId);
    if (!chat) return;

    let displayedMessage = message;
    let fileContent = "";
    if (this.pendingFileAttachment) {
      const match = message.match(/^(.*?)\s*\[Archivo adjunto: [^\]]+\]$/);
      if (match) {
        displayedMessage = match[1] || "";
      }
      fileContent = this.pendingFileAttachment.content;
    }

    input.value = "";
    const originalAttachment = this.pendingFileAttachment;
    this.pendingFileAttachment = null;

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
      if (fileContent) {
        actualMessageToSend = `[Archivo: ${originalAttachment.name}]\n${fileContent}\n\nMensaje del usuario: ${displayedMessage || "(sin mensaje adicional)"}`;
      }

      const onToken = (token) => {
        // Acumular en el sistema de respuestas
        this.accumulatedResponses[chat.id] += token;
        aiMessage.content = this.accumulatedResponses[chat.id];

        // Solo renderizar si es el chat actual
        if (this.currentChatId === chat.id) {
          this.renderMessages(chat);
        }
      };

      const response = await this.sendToAI(
        actualMessageToSend,
        chat.id,
        onToken,
      );

      this.playSound("message-in");
    } catch (error) {
      console.error("Error enviando mensaje:", error);

      // No mostrar error si fue un abort intencional
      if (error.name === "AbortError") {
        // La respuesta parcial ya está en aiMessage.content
        if (aiMessage.content) {
          aiMessage.content += "\n\n[⏹️ Respuesta detenida por el usuario]";
        } else {
          aiMessage.content = "[⏹️ Respuesta detenida]";
        }
      } else {
        aiMessage.content = `${this.t("errors.server_error", { status: error.message })}. ${this.t("errors.verify_ollama")}`;
      }
      if (this.currentChatId === chat.id) {
        this.renderMessages(chat);
      }
    } finally {
      // Verificar si fue abortado y añadir marcador SIEMPRE
      if (this.wasAborted) {
        if (
          aiMessage.content &&
          !aiMessage.content.includes("[⏹️ Respuesta detenida")
        ) {
          aiMessage.content += "\n\n[⏹️ Respuesta detenida por el usuario]";
        } else if (!aiMessage.content) {
          aiMessage.content = "[⏹️ Respuesta detenida antes de comenzar]";
        }
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
      this.settings = { ...this.settings, ...savedSettings };
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
    } else {
      this.chats = [
        {
          id: "welcome-" + Date.now(),
          title: "Bienvenida a MSN-AI",
          date: new Date().toISOString(),
          model: this.settings.selectedModel,
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
      const response = await fetch(`${this.settings.ollamaServer}/api/tags`, {
        method: "GET",
        signal: controller.signal,
        headers: { Accept: "application/json" },
      });
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

  async sendToAI(message, chatId, onToken) {
    if (!this.isConnected) throw new Error(this.t("errors.no_connection"));
    const chat = this.chats.find((c) => c.id === chatId);
    if (!chat) throw new Error(this.t("errors.chat_not_found"));

    // Crear nuevo AbortController para este chat específico
    this.abortControllers[chatId] = new AbortController();
    this.respondingChats.add(chatId);

    // Inicializar acumulador de respuesta para este chat
    this.accumulatedResponses[chatId] = "";

    // Mostrar botón de detener solo si estamos en este chat
    this.updateStopButtonVisibility();

    const context = chat.messages
      .slice(-10)
      .map(
        (msg) =>
          `${msg.type === "user" ? "Usuario" : "Asistente"}: ${msg.content}`,
      )
      .join("\n");
    const prompt = context ? `${context}\nUsuario: ${message}` : message;

    let fullResponse = ""; // Mover fuera del try para que sea accesible en catch

    try {
      const response = await fetch(
        `${this.settings.ollamaServer}/api/generate`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            model: chat.model,
            prompt: prompt,
            stream: true,
            options: { temperature: 0.7, max_tokens: 2000 },
          }),
          signal: this.abortControllers[chatId].signal, // Añadir señal de aborto específica del chat
        },
      );

      if (!response.ok)
        throw new Error(
          this.t("errors.server_error", { status: response.status }),
        );

      const reader = response.body.getReader();
      const decoder = new TextDecoder();

      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          const chunk = decoder.decode(value, { stream: true });
          const lines = chunk.split("\n").filter((line) => line.trim() !== "");

          for (const line of lines) {
            try {
              const json = JSON.parse(line);
              if (json.response) {
                fullResponse += json.response;
                // Llamar onToken que ya maneja la acumulación
                onToken(json.response);
              }
              if (json.done) break;
            } catch (e) {
              console.warn("Línea no JSON:", line);
            }
          }
        }
      } finally {
        reader.releaseLock();
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
      throw error;
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

  stopAIResponse() {
    // Detener la respuesta del chat actual si está respondiendo
    if (this.currentChatId && this.respondingChats.has(this.currentChatId)) {
      const abortController = this.abortControllers[this.currentChatId];
      if (abortController) {
        console.log("🛑 Deteniendo respuesta de IA...");
        abortController.abort();
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

  deleteChat(chatId) {
    // Ya no se necesita confirm() aquí: la confirmación se hizo en el modal
    this.chats = this.chats.filter((c) => c.id !== chatId);
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

    // Agrupar chats por modelo
    const chatsByModel = {};
    this.chats.forEach((chat) => {
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
        showMoreBtn.textContent = `▼ Ver ${chatsInModel.length - maxVisible} más...`;
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
            ? `▼ Ver ${chatsInModel.length - maxVisible} más...`
            : `▲ Ver menos`;
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
    titleDiv.textContent = chat.title;

    // Resaltar en verde si no está leído
    if (this.unreadChats.has(chat.id)) {
      titleDiv.style.color = "#00aa00";
      titleDiv.style.fontWeight = "bold";
    }

    // Último mensaje
    const lastMessage =
      chat.messages.length > 0
        ? chat.messages[chat.messages.length - 1].content.substring(0, 50) +
          (chat.messages[chat.messages.length - 1].content.length > 50
            ? "..."
            : "")
        : "Sin mensajes";

    const previewDiv = document.createElement("div");
    previewDiv.className = "chat-preview";
    previewDiv.textContent = lastMessage;

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
    chatElement.style.alignItems = "flex-start";
    chatElement.style.padding = "5px 10px";
    chatElement.style.cursor = "pointer";
    chatElement.appendChild(avatarIcon);
    chatElement.appendChild(contentDiv);

    // Evento click para seleccionar chat
    chatElement.addEventListener("click", (e) => {
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

  // =================== ACTUALIZACIÓN EN RENDERMESSAGES ===================
  renderMessages(chat) {
    const messagesArea = document.getElementById("messages-area");
    messagesArea.innerHTML = "";

    chat.messages.forEach((message) => {
      const messageElement = document.createElement("div");
      messageElement.className = "message";

      const time = new Date(message.timestamp).toLocaleTimeString("es-ES", {
        hour: "2-digit",
        minute: "2-digit",
      });

      const senderClass =
        message.type === "user" ? "message-user" : "message-ai";
      const sender =
        message.type === "user" ? this.t("chat.you") : this.t("chat.ai");

      // Añadir indicador visual para mensajes de sistema
      const systemIndicator = message.isSystem
        ? `<span style="color: #999; font-size: 7pt; margin-left: 5px;">(${this.t("chat.system")})</span>`
        : "";

      messageElement.innerHTML = `
      <span class="${senderClass}"><strong>${sender}</strong>${systemIndicator}</span>
      <span class="message-timestamp">${time}</span>
      <div class="message-content">${this.formatMessage(message.content)}</div>
    `;

      messagesArea.appendChild(messageElement);
    });

    messagesArea.scrollTop = messagesArea.scrollHeight;
  }
  //-------------------------------------
  formatMessage(content) {
    return content
      .replace(/\n/g, "<br>")
      .replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>")
      .replace(/\*(.*?)\*/g, "<em>$1</em>")
      .replace(
        /`(.*?)`/g,
        '<code style="background: #f0f0f0; padding: 2px 4px; border-radius: 2px;">$1</code>',
      );
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
    const aiStatus = document.getElementById("ai-connection-status");
    switch (status) {
      case "connected":
        indicator.className = "connection-status status-connected";
        text.textContent = this.t("status.connected");
        aiStatus.textContent = `(${this.t("status.online")})`;
        break;
      case "connecting":
        indicator.className = "connection-status status-connecting";
        text.textContent = this.t("status.connecting");
        aiStatus.textContent = `(${this.t("status.connecting")})`;
        break;
      case "disconnected":
        indicator.className = "connection-status status-disconnected";
        text.textContent = this.t("status.disconnected");
        aiStatus.textContent = `(${this.t("connection.no_models_available")})`;
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
        modelElement.textContent = `${this.settings.selectedModel} (No disponible)`;
      }
    } else {
      modelElement.textContent = "No hay modelos disponibles";
    }
  }
  //----------------------------------
  updateSettingsUI() {
    const soundsEnabledEl = document.getElementById("sounds-enabled");
    const ollamaServerEl = document.getElementById("ollama-server");
    const modelSelectEl = document.getElementById("model-select");
    const notifyStatusEl = document.getElementById("notify-status-changes"); // ✅ NUEVO

    if (soundsEnabledEl) soundsEnabledEl.checked = this.settings.soundsEnabled;
    if (ollamaServerEl) ollamaServerEl.value = this.settings.ollamaServer;
    if (modelSelectEl) modelSelectEl.value = this.settings.selectedModel;
    if (notifyStatusEl)
      notifyStatusEl.checked = this.settings.notifyStatusChanges; // ✅ NUEVO
  }
  //--------------------------------
  exportChats() {
    const data = {
      version: "1.0",
      exportDate: new Date().toISOString(),
      chats: this.chats,
      settings: this.settings,
    };
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
  }

  importChats(file) {
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = JSON.parse(e.target.result);
        if (data.chats && Array.isArray(data.chats)) {
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
        importedChat.id = "imported-" + Date.now() + "-" + Math.random();
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
        counterEl.textContent = `Conflicto ${currentIndex + 1} de ${conflicts.length}`;

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
        const handleApply = () => {
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
                warningText.innerHTML = `⚠️ <strong>ADVERTENCIA:</strong> El chat a importar tiene MENOS mensajes. Reemplazar causaría pérdida de información.`;
                warningEl.style.background = "#fff3cd";
              }, 2000);

              skipped++;
            } else {
              const index = this.chats.indexOf(existingChat);
              importedChat.id = existingChat.id;
              this.chats[index] = importedChat;
              replaced++;
            }
          } else if (selectedAction === "merge") {
            this.mergeChats(existingChat, importedChat);
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

  mergeChats(existingChat, importedChat) {
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
    document
      .getElementById("message-input")
      .addEventListener("keypress", (e) => {
        if (e.key === "Enter" && !e.shiftKey) {
          e.preventDefault();
          this.sendMessage();
        }
      });
    document
      .getElementById("new-chat-btn")
      .addEventListener("click", () => this.createNewChat());

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
      document.getElementById("settings-modal").style.display = "block";
    });

    // AÑADE ESTOS EVENTOS SI NO EXISTEN:
    document
      .getElementById("test-connection")
      .addEventListener("click", async () => {
        const btn = document.getElementById("test-connection");
        btn.textContent = "Probando...";
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

        btn.textContent = "🔌 Probar Conexión";
        btn.disabled = false;
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
  }
  //-----------------------------------------------
  async updateAvailableModels() {
    try {
      const response = await fetch(`${this.settings.ollamaServer}/api/tags`);
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
        ? "No hay modelos instalados"
        : "Sin conexión - Verifica configuración";
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
    this.chatToDelete = chatId; // Guardar temporalmente el ID del chat a eliminar
    document.getElementById("delete-chat-modal").style.display = "block";
  }
  /////---------------------------------------------
  async init() {
    console.log("🚀 Iniciando MSN-AI...");

    // Cargar idiomas primero
    await this.loadLanguages();

    this.loadSettings();

    // ✅ CARGAR Y APLICAR EL ESTADO GUARDADO
    const savedStatus = localStorage.getItem("msnai-current-status");
    if (
      savedStatus &&
      ["online", "away", "busy", "invisible"].includes(savedStatus)
    ) {
      this.currentStatus = savedStatus;
      // ✅ IMPORTANTE: Actualizar la UI inmediatamente sin notificar
      this.updateStatusDisplay(savedStatus, true);
    } else {
      // Si no hay estado guardado, establecer online por defecto
      this.currentStatus = "online";
      this.updateStatusDisplay("online", true);
    }

    this.loadChats();
    this.initSounds();
    this.setupEventListeners();
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
