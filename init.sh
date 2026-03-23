#!/bin/bash
set -e

echo "🚀 BCMS 项目初始化（Docker Compose）"
echo "=========================================="

# 检查 Docker Compose
if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
  echo "❌ Docker 或 docker-compose 未安装"
  echo "   请访问: https://docs.docker.com/get-docker/"
  exit 1
fi

# 确定使用的命令
if command -v docker-compose &> /dev/null; then
  DC="docker-compose"
else
  DC="docker compose"
fi

echo "📦 使用命令: $DC"
echo ""

# 启动数据库
echo "📦 启动 PostgreSQL 容器..."
$DC up -d db

# 等待数据库就绪
echo "⏳ 等待数据库就绪..."
MAX_ATTEMPTS=30
ATTEMPT=0
until $DC exec -T db pg_isready -U postgres 2>/dev/null; do
  ATTEMPT=$((ATTEMPT+1))
  if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
    echo "❌ PostgreSQL 启动失败"
    $DC logs db | tail -20
    exit 1
  fi
  echo "  尝试连接... ($ATTEMPT/$MAX_ATTEMPTS)"
  sleep 1
done

echo "✅ PostgreSQL 已就绪"
echo ""

# 创建数据库和用户
echo "🔧 初始化数据库..."
$DC exec -T db psql -U postgres -tc "SELECT 1 FROM pg_roles WHERE rolname='bcms'" | grep -q 1 || \
  $DC exec -T db psql -U postgres -c "CREATE USER bcms WITH PASSWORD 'bcms_dev';"

$DC exec -T db psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname='bcms'" | grep -q 1 || \
  $DC exec -T db psql -U postgres -c "CREATE DATABASE bcms OWNER bcms;"

$DC exec -T db psql -U postgres -d bcms -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" 2>/dev/null || true
$DC exec -T db psql -U postgres -d bcms -c "CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";" 2>/dev/null || true

echo "✅ 数据库初始化完成"
echo ""

# 创建目录
echo "📁 创建上传目录..."
mkdir -p uploads/pdfs
echo "✅ 目录创建完成"
echo ""

# 配置 .env
if [ ! -f .env ]; then
  echo "📋 创建 .env 文件..."
  cp .env.example .env
  echo "✅ .env 已创建（使用默认配置）"
  echo ""
fi

# 显示状态
echo "📊 容器状态："
$DC ps

echo ""
echo "=========================================="
echo "✅ 环境初始化完成！"
echo ""
echo "🎯 后续步骤："
echo ""
echo "1️⃣  设置环境变量（在新终端）："
echo "   export GOROOT=/usr/lib/go"
echo "   export GOCACHE=/tmp/go-cache"
echo "   export GOMODCACHE=/tmp/go-mod"
echo "   export GOSUMDB=off"
echo "   export DATABASE_URL='postgresql://bcms:bcms_dev@localhost:5432/bcms'"
echo ""
echo "2️⃣  运行数据库迁移："
echo "   migrate -path ./db/migrations -database \$DATABASE_URL up"
echo ""
echo "3️⃣  启动后端（新终端）："
echo "   bash dev-backend.sh"
echo ""
echo "4️⃣  启动前端（新终端）："
echo "   bash dev-frontend.sh"
echo ""
echo "💡 常用命令："
echo "   查看日志: $DC logs -f db"
echo "   进入数据库: $DC exec db psql -U postgres -d bcms"
echo "   停止容器: $DC down"
echo "   清除所有: $DC down -v"
echo ""
echo "   cd web && npm run dev"
echo ""
echo "5️⃣  (可选) 查看数据库日志："
echo "   docker-compose logs -f db"
echo ""
