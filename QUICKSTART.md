# 🚀 BCMS 项目快速启动指南

## 前置需求

- Docker & Docker Compose
- Go 1.25+
- Node.js 24+
- npm 11+

## 📋 启动步骤

### 1️⃣ 初始化环境（首次）

```bash
bash init.sh
```

这会：
- ✅ 启动 PostgreSQL Docker 容器
- ✅ 创建数据库和用户
- ✅ 初始化扩展

### 2️⃣ 设置环境变量

```bash
export GOROOT=/usr/lib/go
export GOCACHE=/tmp/go-cache
export GOMODCACHE=/tmp/go-mod
export GOSUMDB=off
export DATABASE_URL="postgresql://bcms:bcms_dev@localhost:5432/bcms"
```

或一次性设置：

```bash
source <(cat <<'EOF'
export GOROOT=/usr/lib/go
export GOCACHE=/tmp/go-cache
export GOMODCACHE=/tmp/go-mod
export GOSUMDB=off
export DATABASE_URL="postgresql://bcms:bcms_dev@localhost:5432/bcms"
EOF
)
```

### 3️⃣ 运行数据库迁移（首次或更新后）

```bash
migrate -path ./db/migrations -database "$DATABASE_URL" up
```

### 4️⃣ 启动后端（新终端）

```bash
bash dev-backend.sh
```

预期输出：
```
🚀 启动后端服务...
   后端运行于: http://localhost:4000
   健康检查: curl http://localhost:4000/v1/healthcheck
```

### 5️⃣ 启动前端（新终端）

```bash
bash dev-frontend.sh
```

预期输出：
```
🚀 启动前端服务...
   前端运行于: http://localhost:5173
```

## 🧪 验证

```bash
# 后端健康检查
curl http://localhost:4000/v1/healthcheck
# 返回: {"status":"ok","environment":"development","version":"1.0.0"}

# 前端
# 打开浏览器访问 http://localhost:5173
```

## 📦 Docker 命令

```bash
# 查看容器状态
docker-compose ps

# 查看数据库日志
docker-compose logs -f db

# 进入数据库命令行
docker-compose exec db psql -U postgres -d bcms

# 停止所有容器
docker-compose down

# 清除所有数据（包含数据库）
docker-compose down -v

# 重启数据库
docker-compose restart db
```

## 🔄 完整工作流

```bash
# 终端 1: 初始化（首次）
bash init.sh

# 终端 1: 设置环境变量
export GOROOT=/usr/lib/go GOCACHE=/tmp/go-cache GOMODCACHE=/tmp/go-mod GOSUMDB=off
export DATABASE_URL="postgresql://bcms:bcms_dev@localhost:5432/bcms"

# 终端 1: 运行迁移
migrate -path ./db/migrations -database "$DATABASE_URL" up

# 终端 2: 启动后端
bash dev-backend.sh

# 终端 3: 启动前端
bash dev-frontend.sh

# 终端 4: (可选) 监控容器
docker-compose logs -f db
```

## 📚 相关文档

- [完整设置指南](SETUP.md)
- [架构设计](docs/architecture.md)
- [领域模型](docs/domain-model.md)
- [项目规范](CLAUDE.md)

## 🛠 常见问题

### Q: PostgreSQL 连接失败
```bash
# 检查容器状态
docker-compose ps

# 查看日志
docker-compose logs db

# 重启数据库
docker-compose restart db
```

### Q: 端口已占用
```bash
# 修改 docker-compose.yml 中的端口
# 比如将 "5432:5432" 改为 "5433:5432"
```

### Q: 清除一切重新开始
```bash
docker-compose down -v
bash init.sh
```

---

**最后修改时间:** 2026-03-23
