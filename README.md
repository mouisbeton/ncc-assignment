# Health Check Service - Laporan Teknis

## 1. Deskripsi Singkat Service

**Health Check Service** adalah aplikasi Node.js sederhana yang menyediakan endpoint untuk monitoring kesehatan aplikasi. Service ini dibangun menggunakan Express.js dan dikonfigurasi untuk deployment menggunakan Docker dan Docker Compose.

**Fitur utama:**
- Rest API untuk health check
- Endpoint informasi service
- CORS support
- Graceful shutdown handling
- Multi-stage Docker build untuk image yang optimal
- Environment variable configuration

## 2. Penjelasan Endpoint /health

### Request
```
GET /health
```

### Response (Status 200 OK)
```json
{
  "status": "OK",
  "timestamp": "2026-04-13T15:30:45.123Z",
  "uptime": 1234.567,
  "message": "Service is running and healthy"
}
```

**Penjelasan:**
- `status`: Status kesehatan service ("OK" jika berjalan normal)
- `timestamp`: Waktu saat endpoint diakses dalam format ISO 8601
- `uptime`: Waktu service berjalan dalam detik (sejak startup)
- `message`: Pesan deskriptif status service

**Endpoint tambahan:**
- `GET /`: Welcome message dengan list endpoint
- `GET /info`: Informasi service (nama, versi, pembuat)

## 3. Bukti Endpoint Dapat Diakses

### Testing dengan curl
```bash
curl http://localhost:3000/health
```

Endpoint akan merespons dengan status 200 OK dan JSON data kesehatan service. Dapat diakses melalui:
- Browser: `http://localhost:3000/health`
- Postman/Insomnia: GET request ke `http://localhost:3000/health`
- Docker container: Health check running every 30 seconds

## 4. Proses Build dan Run Docker

### Multi-Stage Build Explanation

**Dockerfile Structure:**
```dockerfile
# Stage 1: Builder
FROM node:18-alpine AS builder
- Install dependencies hanya di stage ini
- Node modules disimpan untuk stage berikutnya

# Stage 2: Runtime  
FROM node:18-alpine
- Copy node_modules dari builder
- Copy source code
- Jalankan application
```

### Build Image
```bash
# Build dari Dockerfile lokal
docker build -t yourusername/health-check-service:latest .

# Push ke Docker Hub
docker login
docker push yourusername/health-check-service:latest
```

### Run dengan Docker Compose
```bash
# Development
docker-compose up

# Production (background)
docker-compose up -d

# Cek logs
docker-compose logs -f health-check-service

# Stop service
docker-compose down
```

### Run dengan Docker CLI
```bash
docker run -d \
  --name health-check-service \
  -p 3000:3000 \
  -e NODE_ENV=production \
  yourusername/health-check-service:latest
```

**Konfigurasi:**
- Port: 3000 (container) → 3000 (host)
- Environment: NODE_ENV=production
- Restart policy: unless-stopped
- Health check: Every 30 seconds
- Network: health-check-network (bridge)

## 5. Proses Deployment ke VPS

### Option A: Deployment dengan Docker Compose (Recommended)

**Step 1: SSH ke VPS**
```bash
ssh user@your-vps-ip
```

**Step 2: Install Docker**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

**Step 3: Clone/Upload Project**
```bash
git clone <repository-url>
cd ncc-assignment
```

**Step 4: Update docker-compose.yml**
```yaml
services:
  health-check-service:
    image: yourusername/health-check-service:latest  # Dari Docker Hub
    ports:
      - "3000:3000"
    restart: unless-stopped
```

**Step 5: Deploy**
```bash
docker-compose up -d
```

### Option B: Deployment dengan Nginx (Production)

**Step 1: Install Nginx**
```bash
sudo apt update && sudo apt install nginx -y
```

**Step 2: Konfigurasi Nginx**
Buat file `/etc/nginx/sites-available/health-check`:
```nginx
server {
    listen 80;
    server_name your-vps-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**Step 3: Enable Configuration**
```bash
sudo ln -s /etc/nginx/sites-available/health-check /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

**Step 4: Deploy Docker**
```bash
docker-compose up -d
```

Sekarang service dapat diakses via `http://your-vps-domain.com/health` (port 80)

### Monitoring di VPS
```bash
# Cek container running
docker ps

# Cek logs
docker-compose logs -f health-check-service

# Cek resource usage
docker stats health-check-service

# Health check status
curl http://localhost:3000/health
```
