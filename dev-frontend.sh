#!/bin/bash

# 前端启动脚本

cd "$(dirname "$0")/web" || exit 1

echo "🚀 启动前端服务..."
echo "   前端运行于: http://localhost:5173"
echo ""
echo "按 Ctrl+C 停止服务"
echo ""

npm run dev
