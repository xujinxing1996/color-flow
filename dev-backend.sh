#!/bin/bash

# 快速启动脚本：设置环境并启动后端

if [ ! -f ".devcontainer/setup.sh" ]; then
  echo "❌ 请从项目根目录运行此脚本"
  exit 1
fi

# 设置 Go 环境
export GOROOT=/usr/lib/go
export GOCACHE=/tmp/go-cache
export GOMODCACHE=/tmp/go-mod
export GOSUMDB=off
export DATABASE_URL="postgresql://bcms:bcms_dev@localhost:5432/bcms"

mkdir -p /tmp/go-cache /tmp/go-mod

# 检查 Docker PostgreSQL 是否运行
if ! docker-compose ps db 2>/dev/null | grep -q "Up"; then
  echo "❌ PostgreSQL 容器未运行"
  echo "   请先运行: bash init.sh"
  exit 1
fi

# 检查数据库连接
if ! pg_isready -h localhost -U postgres 2>/dev/null; then
  echo "❌ PostgreSQL 连接失败"
  exit 1
fi

# 检查迁移是否已执行
if ! psql -h localhost -U bcms -d bcms -c "SELECT 1" 2>/dev/null; then
  echo "⚠️  未运行迁移，正在运行..."
  migrate -path ./db/migrations -database "$DATABASE_URL" up || true
fi

# 启动后端
echo "🚀 启动后端服务..."
echo "   后端运行于: http://localhost:4000"
echo "   健康检查: curl http://localhost:4000/v1/healthcheck"
echo ""
echo "按 Ctrl+C 停止服务"
echo ""

go run ./cmd/api -port=4000 -env=development
