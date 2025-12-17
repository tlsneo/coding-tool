# Coding-Tool Docker Image
# Claude Code / Codex / Gemini CLI Enhancement Tool

FROM node:18-alpine

LABEL maintainer="CooperJiang"
LABEL description="Vibe Coding Enhancement Tool - Session Management, Channel Switching, Token Monitoring"

# Install dependencies for native modules and PM2
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git \
    bash

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies using npm (more compatible than pnpm in Docker)
RUN npm install -g pm2 && \
    npm install

# Copy web package files and install
COPY src/web/package*.json ./src/web/
RUN cd src/web && npm install

# Copy source code
COPY . .

# Build web frontend (vite outputs to ../../dist/web relative to src/web)
RUN cd src/web && npm run build

# Create data directory
RUN mkdir -p /data/.claude/cc-tool && \
    mkdir -p /data/.claude/logs && \
    mkdir -p /data/.claude/projects

# Environment variables
ENV NODE_ENV=production
ENV HOME=/data

# Default ports
ENV CT_WEB_PORT=10099
ENV CT_CLAUDE_PROXY_PORT=10088
ENV CT_CODEX_PROXY_PORT=10089
ENV CT_GEMINI_PROXY_PORT=10090

# Expose ports
EXPOSE 10099 10088 10089 10090

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:${CT_WEB_PORT:-10099}/api/version || exit 1

# Create startup script
RUN echo '#!/bin/bash' > /app/docker-entrypoint.sh && \
    echo 'set -e' >> /app/docker-entrypoint.sh && \
    echo '' >> /app/docker-entrypoint.sh && \
    echo '# Ensure data directories exist' >> /app/docker-entrypoint.sh && \
    echo 'mkdir -p /data/.claude/cc-tool' >> /app/docker-entrypoint.sh && \
    echo 'mkdir -p /data/.claude/logs' >> /app/docker-entrypoint.sh && \
    echo 'mkdir -p /data/.claude/projects' >> /app/docker-entrypoint.sh && \
    echo '' >> /app/docker-entrypoint.sh && \
    echo '# Start the server' >> /app/docker-entrypoint.sh && \
    echo 'exec node /app/docker-start.js' >> /app/docker-entrypoint.sh && \
    chmod +x /app/docker-entrypoint.sh

# Start server directly (not using PM2 in container)
ENTRYPOINT ["/app/docker-entrypoint.sh"]
