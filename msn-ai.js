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
    };
    this.currentStatus = "online"; // Estado inicial
    this.init();
  }

  // =================== FUNCIONES NUEVAS ===================
  updateStatusDisplay(status) {
    const statusIcon = document.getElementById("status-icon");
    const statusText = document.getElementById("ai-connection-status");

    // Mapear el estado a la ruta del ícono
    const iconPath = `assets/status/${status}.png`;
    statusIcon.src = iconPath;

    // Actualizar el texto
    statusText.textContent = `(${status.charAt(0).toUpperCase() + status.slice(1)})`;

    // Guardar el estado
    this.currentStatus = status;
    localStorage.setItem("msnai-current-status", status); // Persistir en localStorage
  }
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

  sendNudge() {
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

    setTimeout(() => {
      const aiResponse = {
        type: "ai",
        content: "¡Sí! Estoy aquí. ¿En qué puedo ayudarte?",
        timestamp: new Date().toISOString(),
      };
      chat.messages.push(aiResponse);
      this.renderMessages(chat);
      this.saveChats();
      this.playSound("message-in");
    }, 800);
  }

  startVoiceInput() {
    if (
      !("SpeechRecognition" in window || "webkitSpeechRecognition" in window)
    ) {
      alert("Tu navegador no soporta reconocimiento de voz.");
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
        alert("Solo se permiten archivos .txt");
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
          alert("Selecciona texto para formatear");
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
      alert("No hay chats seleccionados para exportar.");
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
    if (confirm("¿Cerrar este chat y crear uno nuevo?")) {
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
    this.showAIThinking(true);

    try {
      let actualMessageToSend = displayedMessage;
      if (fileContent) {
        actualMessageToSend = `[Archivo: ${originalAttachment.name}]\n${fileContent}\n\nMensaje del usuario: ${displayedMessage || "(sin mensaje adicional)"}`;
      }

      const onToken = (token) => {
        aiMessage.content += token;
        this.renderMessages(chat);
      };

      await this.sendToAI(actualMessageToSend, this.currentChatId, onToken);
      this.playSound("message-in");
    } catch (error) {
      console.error("Error enviando mensaje:", error);
      aiMessage.content = `Error: ${error.message}. Verifica que Ollama esté ejecutándose.`;
      this.renderMessages(chat);
    } finally {
      this.showAIThinking(false);
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
    if (!this.isConnected) throw new Error("No hay conexión con Ollama");
    const chat = this.chats.find((c) => c.id === chatId);
    if (!chat) throw new Error("Chat no encontrado");
    const context = chat.messages
      .slice(-10)
      .map(
        (msg) =>
          `${msg.type === "user" ? "Usuario" : "Asistente"}: ${msg.content}`,
      )
      .join("\n");
    const prompt = context ? `${context}\nUsuario: ${message}` : message;
    const response = await fetch(`${this.settings.ollamaServer}/api/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: chat.model,
        prompt: prompt,
        stream: true,
        options: { temperature: 0.7, max_tokens: 2000 },
      }),
    });
    if (!response.ok) throw new Error(`Error del servidor: ${response.status}`);
    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let fullResponse = "";
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
  }

  createNewChat() {
    const chatId = "chat-" + Date.now();
    const newChat = {
      id: chatId,
      title: `Nuevo chat ${this.chats.length + 1}`,
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
    document
      .querySelectorAll(".chat-item")
      .forEach((item) => item.classList.remove("active"));
    const chatElement = document.querySelector(`[data-chat-id="${chatId}"]`);
    if (chatElement) chatElement.classList.add("active");
    document.getElementById("chat-contact-name").textContent = chat.title;
    document.getElementById("chat-status-message").textContent =
      `Modelo: ${chat.model} - ${chat.messages.length} mensajes`;
    this.renderMessages(chat);
    document.getElementById("message-input").disabled = false;
    document.getElementById("send-button").disabled = false;
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
    if (this.chats.length === 0) {
      chatList.innerHTML =
        '<li style="padding: 20px; text-align: center; color: #666;">No hay chats. Crea uno nuevo.</li>';
      return;
    }
    this.chats.forEach((chat) => {
      const chatElement = document.createElement("li");
      chatElement.className = "chat-item";
      chatElement.setAttribute("data-chat-id", chat.id);

      const lastMessage =
        chat.messages.length > 0
          ? chat.messages[chat.messages.length - 1].content.substring(0, 60) +
            "..."
          : "Sin mensajes";
      const date = new Date(chat.date).toLocaleDateString("es-ES", {
        day: "2-digit",
        month: "2-digit",
        year: "2-digit",
      });

      // Ícono de persona (avatar) para selección
      const avatarIcon = document.createElement("img");
      avatarIcon.className = "chat-select-avatar";
      avatarIcon.dataset.chatId = chat.id;
      avatarIcon.style.width = "14px";
      avatarIcon.style.height = "14px";
      avatarIcon.style.margin = "0 8px 0 5px"; // Margen izquierdo para alinear
      avatarIcon.style.cursor = "pointer";

      // Determinar si está seleccionado (por defecto no)
      const isSelected = chat.selected || false;
      avatarIcon.src = isSelected
        ? "assets/contacts-window/37.png" // Verde (conectado) - Ajusta la ruta si es necesario
        : "assets/contacts-window/38.png"; // Gris (no conectado) - Ajusta la ruta si es necesario

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

      const previewDiv = document.createElement("div");
      previewDiv.className = "chat-preview";
      previewDiv.textContent = lastMessage;

      const dateDiv = document.createElement("div");
      dateDiv.className = "chat-date";
      dateDiv.textContent = date;

      contentDiv.appendChild(titleDiv);
      contentDiv.appendChild(previewDiv);
      contentDiv.appendChild(dateDiv);

      // Ensamblar el ítem
      chatElement.style.display = "flex";
      chatElement.style.alignItems = "flex-start"; // Centrar verticalmente todo
      chatElement.style.padding = "5px 10px";
      chatElement.style.cursor = "pointer";
      chatElement.appendChild(avatarIcon);
      chatElement.appendChild(contentDiv);

      // Eventos
      chatElement.addEventListener("click", (e) => {
        if (!e.target.matches(".chat-select-avatar")) {
          this.selectChat(chat.id);
        }
      });
      chatElement.addEventListener("contextmenu", (e) => {
        e.preventDefault();
        this.showChatContextMenu(e, chat.id);
      });

      // Evento click en el avatar para alternar selección
      avatarIcon.addEventListener("click", (e) => {
        e.stopPropagation(); // Evitar que se seleccione el chat
        chat.selected = !chat.selected; // Alternar estado
        avatarIcon.src = chat.selected
          ? "assets/contacts-window/37.png" // Verde
          : "assets/contacts-window/38.png"; // Gris
      });

      chatList.appendChild(chatElement);
    });
  }

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
      const sender = message.type === "user" ? "Tú" : "IA";
      messageElement.innerHTML = `
                <span class="${senderClass}"><strong>${sender}</strong></span>
                <span class="message-timestamp">${time}</span>
                <div class="message-content">${this.formatMessage(message.content)}</div>
            `;
      messagesArea.appendChild(messageElement);
    });
    messagesArea.scrollTop = messagesArea.scrollHeight;
  }

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
      "Selecciona un chat";
    document.getElementById("chat-status-message").textContent =
      "Bienvenido a MSN-AI";
    document.getElementById("messages-area").innerHTML = `
            <div class="message">
                <span style="color: #666; font-size: 7pt; font-style: italic;">
                    Selecciona un chat de la lista o crea uno nuevo para comenzar.
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
        text.textContent = "Conectado";
        aiStatus.textContent = "(Online)";
        break;
      case "connecting":
        indicator.className = "connection-status status-connecting";
        text.textContent = "Conectando...";
        aiStatus.textContent = "(Conectando...)";
        break;
      case "disconnected":
        indicator.className = "connection-status status-disconnected";
        text.textContent = "Desconectado";
        aiStatus.textContent = "(Sin conexión)";
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

  updateSettingsUI() {
    const soundsEnabledEl = document.getElementById("sounds-enabled");
    const ollamaServerEl = document.getElementById("ollama-server");
    const modelSelectEl = document.getElementById("model-select");
    if (soundsEnabledEl) soundsEnabledEl.checked = this.settings.soundsEnabled;
    if (ollamaServerEl) ollamaServerEl.value = this.settings.ollamaServer;
    if (modelSelectEl) modelSelectEl.value = this.settings.selectedModel;
  }

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
          if (
            confirm(
              `¿Importar ${data.chats.length} chats? Esto se agregará a tus chats existentes.`,
            )
          ) {
            data.chats.forEach((chat) => {
              chat.id = "imported-" + Date.now() + "-" + Math.random();
            });
            this.chats = [...data.chats, ...this.chats];
            this.saveChats();
            this.renderChatList();
            this.playSound("login");
            alert(`¡${data.chats.length} chats importados exitosamente!`);
          }
        } else {
          alert("Archivo JSON inválido o sin chats.");
        }
      } catch (error) {
        console.error("Error importando chats:", error);
        alert("Error al leer el archivo. Verifica que sea un JSON válido.");
      }
    };
    reader.readAsText(file);
  }

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
    document
      .getElementById("export-btn")
      .addEventListener(
        "click",
        () => (document.getElementById("export-modal").style.display = "block"),
      );
    document
      .getElementById("import-btn")
      .addEventListener(
        "click",
        () => (document.getElementById("import-modal").style.display = "block"),
      );
    document
      .getElementById("settings-btn")
      .addEventListener(
        "click",
        () =>
          (document.getElementById("settings-modal").style.display = "block"),
      );
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
  }

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
    const chatItems = document.querySelectorAll(".chat-item");
    const searchTerm = query.toLowerCase();
    chatItems.forEach((item) => {
      const title = item.querySelector(".chat-title").textContent.toLowerCase();
      const preview = item
        .querySelector(".chat-preview")
        .textContent.toLowerCase();
      item.style.display =
        title.includes(searchTerm) || preview.includes(searchTerm)
          ? "flex"
          : "none";
    });
  }

  showChatContextMenu(event, chatId) {
    event.preventDefault(); // Evitar el menú contextual nativo
    this.chatToDelete = chatId; // Guardar temporalmente el ID del chat a eliminar
    document.getElementById("delete-chat-modal").style.display = "block";
  }

  async init() {
    console.log("🚀 Iniciando MSN-AI...");
    this.loadSettings();
    // Cargar el estado guardado
    const savedStatus = localStorage.getItem("msnai-current-status");
    if (
      savedStatus &&
      ["online", "away", "busy", "invisible"].includes(savedStatus)
    ) {
      this.currentStatus = savedStatus;
      this.updateStatusDisplay(savedStatus);
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
