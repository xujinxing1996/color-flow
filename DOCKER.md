# 📚 Docker Compose 使用指南

## ✅ 准备工作

确保已安装：
- Docker（包含 docker-compose）
- Go 1.24
- Node.js 24+
- golang-migrate CLI

## 🚀 快速启动

### 方案 1: 自动初始化（推荐）

```bash
# 一键启动所有服务
bash init.sh
```

这将：
- ✅ 启动 PostgreSQL 容器
- ✅ 创建数据库和用户（bcms/bcms_dev）
- ✅ 创建 .env 文件
- ✅ 初始化上传目录

### 方案 2: 手动步骤

```bash
# 终端 1: 启动数据库容器
docker-compose up -d db

# 等待数据库就绪
docker-compose exec -T db pg_isready -U postgres

# 初始化数据库
docker-compose exec db psql -U postgres -c "CREATE USER bcms WITH PASSWORD 'bcms_dev';"
docker-compose exec db psql -U postgres -c "CREATE DATABASE bcms OWNER bcms;"
docker-compose exec db psql -U postgres -d bcms -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
docker-compose exec db psql -U postgres -d bcms -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"
```

## 🏃 启动应用

### 终端 1: 设置环境 & 运行迁移

```bash
# 设置环境变量
export GOROOT=/usr/lib/go
export GOCACHE=/tmp/go-cache
export GOMODCACHE=/tmp/go-mod
export GOSUMDB=off
export DATABASE_URL="postgresql://bcms:bcms_dev@localhost:5432/bcms"

mkdir -p /tmp/go-cache /tmp/go-mod

# 运行数据库迁移
migrate -path ./db/migrations -database "$DATABASE_URL" up
```

### 终端 2: 启动后端

```bash
bash dev-backend.sh
```

预期输出：
```
🚀 启动后端服务...
   后端运行于: http://localhost:4000
   健康检查: curl http://localhost:4000/v1/healthcheck
```

### 终端 3: 启动前端

```bash
bash dev-frontend.sh
```

预期输出：
```
🚀 启动前端服务...
   前端运行于: http://localhost:5173
```

## 🧪 验证应用

```bash
# 后端健康检查
curl http://localhost:4000/v1/healthcheck

# 前端
# 打开浏览器: http://localhost:5173
```

## 📦 Docker Compose 常用命令

```bash
# 查看容器状态
docker-compose ps

# 查看日志
docker-compose logs -f db

# 进入 PostgreSQL 命令行
docker-compose exec db psql -U postgres -d bcms

# 停止容器
docker-compose stop

# 重启容器
docker-compose restart db

# 停止并移除容器（保留数据）
docker-compose down

# 停止并完全清除（包括数据卷）
docker-compose down -v

# 重建容器
docker-compose up -d --build
```

## 🔧 故障排查

### PostgreSQL 连接失败

```bash
# 检查容器状态
docker-compose ps

# 查看详细日志
docker-compose logs db

# 重启数据库
docker-compose restart db
```

### 端口被占用

修改 `docker-compose.yml`，将 `5432:5432` 改为其他端口，例如 `5433:5432`

```yml
services:
  db:
    ports:
      - "5433:5432"  # 改这里
```

然后更新 DATABASE_URL：
```bash
export DATABASE_URL="postgresql://bcms:bcms_dev@localhost:5433/bcms"
```

### 完全重置

```bash
# 停止并清除所有数据
docker-compose down -v

# 重新初始化
bash init.sh
```

## 📋 环境配置

应用使用以下环境变量（从 `.env` 文件读取）：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `DATABASE_URL` | `postgresql://bcms:bcms_dev@db:5432/bcms` | 数据库连接字符串 |
| `PORT` | `4000` | 后端服务端口 |
| `ENV` | `development` | 环境标识 |
| `JWT_SECRET` | `change-me-in-production` | JWT 密钥 |

## 💡 开发工作流

```bash
# 1. 初始化（首次）
bash init.sh

# 2. 开发时启动三个终端

# 终端 A: 后端开发
export GOROOT=/usr/lib/go GOCACHE=/tmp/go-cache GOMODCACHE=/tmp/go-mod GOSUMDB=off
export DATABASE_URL="postgresql://bcms:bcms_dev@localhost:5432/bcms"
bash dev-backend.sh

# 终端 B: 前端开发
bash dev-frontend.sh

# 终端 C: 监控数据库
docker-compose logs -f db

# 修改代码时，后端和前端会自动重启（如配置了热重载）
```

## 🎓 进阶主题

### 导入本地数据

```bash
docker-compose exec db psql -U bcms -d bcms < data-dump.sql
```

### 导出数据

```bash
docker-compose exec db pg_dump -U bcms -d bcms > data-dump.sql
```

### 在容器内运行命令

```bash
docker-compose exec db <command>
docker-compose exec app go test ./...
```

---

**最后修改:** 2026-03-23
