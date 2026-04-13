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

CMD ["node", "server.js"]
