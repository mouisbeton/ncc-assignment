# Stage 1: Build dependencies
FROM node:18-alpine AS builder

WORKDIR /app

COPY src/package*.json ./

RUN npm ci --omit=dev && \
    npm cache clean --force

# Stage 2: Runtime
FROM node:18-alpine

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules

COPY src/ ./

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)}).on('error', (e) => {throw e})" || exit 1

CMD ["node", "server.js"]
