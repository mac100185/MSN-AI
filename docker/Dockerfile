# MSN-AI - Docker Image
# Version: 1.0.0
# Author: Alan Mac-Arthur García Díaz
# License: GNU General Public License v3.0
# Description: Complete MSN-AI environment with intelligent hardware detection

FROM python:3.11-slim

# Metadata
LABEL maintainer="alan.mac.arthur.garcia.diaz@gmail.com"
LABEL version="1.0.0"
LABEL description="MSN-AI - Windows Live Messenger with Local AI"
LABEL license="GPL-3.0"

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive
ENV MSN_AI_VERSION=1.0.0
ENV MSN_AI_PORT=8000
ENV OLLAMA_HOST=ollama:11434

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    lsb-release \
    pciutils \
    procps \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Create non-root user for security
RUN groupadd -r msnai && useradd -r -g msnai -d /app -s /bin/bash msnai

# Copy application files
COPY --chown=msnai:msnai . .

# Set executable permissions for scripts
RUN chmod +x /app/*.sh 2>/dev/null || true

# Create directories for data persistence
RUN mkdir -p /app/data/chats /app/data/logs /app/data/config \
    && chown -R msnai:msnai /app/data

# Copy Docker-specific scripts
COPY --chown=msnai:msnai docker/scripts/ /app/docker/scripts/
RUN chmod +x /app/docker/scripts/*.sh

# Install Node.js as backup web server (lightweight alternative)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g http-server \
    && rm -rf /var/lib/apt/lists/*

# Health check script
COPY docker/healthcheck.sh /app/healthcheck.sh
RUN chmod +x /app/healthcheck.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /app/healthcheck.sh

# Switch to non-root user
USER msnai

# Expose port
EXPOSE 8000

# Volume for persistent data
VOLUME ["/app/data"]

# Startup script
COPY docker/docker-entrypoint.sh /app/docker-entrypoint.sh
USER root
RUN chmod +x /app/docker-entrypoint.sh
USER msnai

# Default command
CMD ["/app/docker-entrypoint.sh"]
