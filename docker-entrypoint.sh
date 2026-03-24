#!/bin/bash
set -e

echo "⏳ 等待数据库就绪..."
until pg_isready -h db -U bcms -d bcms -q; do
  echo "  数据库未就绪，1秒后重试..."
  sleep 1
done
echo "✅ 数据库已就绪"

echo "🔄 运行数据库迁移..."
migrate -path=/app/db/migrations -database="$DATABASE_URL" up
echo "✅ 迁移完成"

echo "🚀 启动 API 服务..."
exec ./api -port=4000 -env="${ENV:-development}"