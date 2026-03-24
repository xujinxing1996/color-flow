# BCMS 本地启动指南

## 前置需求

- Docker & Docker Compose（[安装文档](https://docs.docker.com/get-docker/)）

就这些。不需要在本机安装 Go、Node.js 或 PostgreSQL。

---

## 首次启动

```bash
# 1. 复制环境变量文件
cp .env.example .env

# 2. 一键启动所有服务
docker compose up --build
```

启动完成后：

| 服务 | 地址 |
|------|------|
| 前端 | http://localhost:5173 |
| 后端 API | http://localhost:4000 |
| 健康检查 | http://localhost:4000/v1/healthcheck |
| PostgreSQL | localhost:5432（用户 bcms / bcms_dev）|

数据库迁移由 `migrate` 服务自动执行，无需手动操作。

---

## 日常开发

```bash
# 启动（后台运行）
docker compose up -d

# 查看所有服务日志
docker compose logs -f

# 只看某个服务的日志
docker compose logs -f api
docker compose logs -f web
docker compose logs -f db

# 停止
docker compose down
```

---

## 修改代码后重建

```bash
# 重建并重启某个服务（不影响其他服务）
docker compose up -d --build api
docker compose up -d --build web

# 重建全部
docker compose up -d --build
```

---

## 数据库操作

```bash
# 进入 PostgreSQL 命令行
docker compose exec db psql -U bcms -d bcms

# 手动执行迁移（通常自动完成，无需手动）
docker compose run --rm migrate

# 查看迁移状态
docker compose run --rm migrate -path=/migrations -database=postgresql://bcms:bcms_dev@db:5432/bcms?sslmode=disable version
```

---

## 完全重置

```bash
# 停止并删除所有数据（含数据库 volume）
docker compose down -v

# 重新启动
docker compose up --build
```

---

## 常见问题

**Q: 端口被占用**

修改 `docker-compose.yml` 中对应服务的端口映射，例如将 `"4000:4000"` 改为 `"4001:4000"`。

**Q: 数据库迁移失败**

```bash
docker compose logs migrate
```

查看错误原因，通常是迁移文件语法问题。

**Q: 前端请求 API 报错**

确认后端正常运行：`curl http://localhost:4000/v1/healthcheck`
