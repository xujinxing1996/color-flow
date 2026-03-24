# BCMS 项目骨架搭建完成

## 🎯 搭建状态

✅ **所有核心任务已完成**

### 已完成的内容

#### 后端（Go）
- ✅ go.mod 已初始化（module: `github.com/xujinxing1996/bcms`）
- ✅ 所有主要依赖已配置：
  - `github.com/julienschmidt/httprouter v1.3.0` - HTTP 路由
  - `github.com/jackc/pgx/v5` - PostgreSQL 驱动
  - `github.com/golang-jwt/jwt/v5` - JWT认证
  - `golang.org/x/crypto` - 密码加密
  - `github.com/golang-migrate/migrate/v4` - 数据库迁移
- ✅ 后端目录结构已创建
  - `cmd/api/` - 应用入口
  - `internal/data/` - 数据层（ORM models）
  - `internal/validator/` - 验证器
  - `internal/mailer/` - 邮件服务
  - `services/` - 业务逻辑层
- ✅ `cmd/api/main.go` 实现完整，包含：
  - flag 参数解析（port、db-dsn、env、jwt-secret）
  - pgx/v5 数据库连接池配置
  - 符合《Let's Go Further》风格的 `application` struct
  - slog 日志系统集成
  - 优雅关闭机制
  - **健康检查端点** `GET /v1/healthcheck`
- ✅ 后端已成功编译（11MB 二进制文件）

#### 前端（Vue 3）
- ✅ `web/` 目录已初始化为 Vite + Vue 3 项目
- ✅ 依赖已安装（43 packages）
  - `vue@^3.5.30` - Vue 框架
  - `vue-router@^4.2.0` - 路由管理
  - `pinia@^2.1.0` - 状态管理
  - `pdfjs-dist@^4.0.0` - PDF 渲染
  - `vite@^8.0.1` - 构建工具
- ✅ 前端项目结构已创建
  - `src/main.js` - 应用入口
  - `src/App.vue` - 根组件
  - `src/router/index.js` - 路由配置
  - `src/stores/auth.js` - 认证 Pinia store
  - `src/views/LoginView.vue` - 登录页（完整UI）
  - `src/views/DashboardView.vue` - 仪表板页
  - `src/layouts/MainLayout.vue` - 主布局
  - `src/style.css` - 全局样式
- ✅ 前端已成功构建（生成 dist/）

#### 数据库
- ✅ 迁移文件已创建
  - `db/migrations/20260323_120000_create_users_table.up.sql` - 创建 users 表
  - `db/migrations/20260323_120000_create_users_table.down.sql` - 回滚脚本
- ✅ users 表设计（符合 @docs/architecture.md）
  - `id` BIGSERIAL PRIMARY KEY
  - `name` TEXT
  - `email` TEXT UNIQUE（创建索引）
  - `password_hash` BYTEA
  - `role` TEXT (sales|tech|admin)
  - `activated` BOOLEAN
  - `created_at`, `updated_at` TIMESTAMPTZ（带索引）

---

## 🚀 快速开始

### 前置环境要求
```bash
# 已验证的版本
Go 1.24
Node.js 24.13.0+
npm 11.11.0+
PostgreSQL 12+ (需单独部署)
```

### 安装和运行

#### 1. 配置环境
```bash
# 复制示例配置
cp .env.example .env

# 编辑 .env 设置数据库连接
# DATABASE_URL=postgresql://bcms:bcms_dev@localhost:5432/bcms
# JWT_SECRET=your-secret-key
```

#### 2. 后端启动

##### 构建后端（使用正确的环境变量）
```bash
export GOROOT=/usr/lib/go 
export GOCACHE=/tmp/go-cache 
export GOMODCACHE=/tmp/go-mod 
export GOSUMDB=off

cd /workspaces/color-flow
go build -o api ./cmd/api
```

##### 运行后端
```bash
# 需要 PostgreSQL 环境
export DATABASE_URL="postgresql://user:password@localhost:5432/dbname"
./api -port=4000 -env=development
```

**预期输出：**
```
{"level":"INFO","msg":"starting application","version":"1.0.0","env":"development","port":4000}
{"level":"INFO","msg":"database connection pool established"}
{"level":"INFO","msg":"starting server","addr":":4000"}
```

**验证健康检查：**
```bash
curl http://localhost:4000/v1/healthcheck
# 返回: {"status":"ok","environment":"development","version":"1.0.0"}
```

#### 3. 前端启动

```bash
cd /workspaces/color-flow/web

# 安装依赖（如需重装）
sudo npm install --unsafe-perm

# 开发服务器
npm run dev
# 访问: http://localhost:5173

# 生产构建
npm run build
# 生成: dist/
```

#### 4. 数据库迁移

```bash
# 需要安装 golang-migrate CLI
# https://github.com/golang-migrate/migrate

# 执行迁移
migrate -path ./db/migrations -database $DATABASE_URL up

# 检查迁移状态  
migrate -path ./db/migrations -database $DATABASE_URL version

# 回滚最后一次迁移
migrate -path ./db/migrations -database $DATABASE_URL down 1
```

---

## 📁 项目结构总览

```
color-flow/
├── cmd/
│   └── api/
│       ├── main.go                 # 应用入口
│       ├── handlers.go             # HTTP 处理器（待完成）
│       └── models.go               # 数据模型
│
├── internal/                       # 不对外暴露的包
│   ├── data/                       # 数据访问层（models）
│   ├── validator/                  # 验证逻辑
│   └── mailer/                     # 邮件服务
│
├── services/                       # 业务逻辑
│   ├── extraction/                 # PDF 提取
│   ├── cascade/                    # 颜色引用解析
│   └── print/                      # 打印输出
│
├── db/
│   ├── migrations/                 # SQL 迁移文件
│   │   ├── 20260323_120000_create_users_table.up.sql
│   │   └── 20260323_120000_create_users_table.down.sql
│   └── seeds/                      # 初始化数据
│
├── web/                            # 前端项目
│   ├── src/
│   │   ├── main.js
│   │   ├── App.vue
│   │   ├── style.css
│   │   ├── router/
│   │   │   └── index.js           # 路由配置
│   │   ├── stores/
│   │   │   └── auth.js            # Pinia 认证 store
│   │   ├── views/
│   │   │   ├── LoginView.vue      # 登录页
│   │   │   └── DashboardView.vue  # 仪表板
│   │   ├── layouts/
│   │   │   └── MainLayout.vue     # 主布局
│   │   └── components/             # Vue 组件（待扩展）
│   ├── public/
│   ├── package.json
│   └── vite.config.js
│
├── .devcontainer/                  # VS Code 开发容器配置
│   ├── devcontainer.json
│   └── setup.sh
│
├── docs/
│   ├── architecture.md             # 系统架构
│   ├── domain-model.md             # 领域模型
│   └── prd.md                      # 产品需求
│
├── CLAUDE.md                       # 项目规范和技术栈指南
├── go.mod                          # Go 模块定义
├── go.sum                          # Go 依赖校验和
└── README.md
```

---

## ⚙️ 关键配置说明

### Go 环境变量设置（Alpine Linux 特殊处理）
当在容器中工作时，需要设置：
```bash
export GOROOT=/usr/lib/go
export GOCACHE=/tmp/go-cache
export GOMODCACHE=/tmp/go-mod
export GOSUMDB=off  # 禁用 checksum 验证
```

建议添加到 `~/.bashrc` 或 `~/.zshrc`：
```bash
if [ -f /usr/lib/go/bin/go ]; then
  export GOROOT=/usr/lib/go
  export GOCACHE=/tmp/go-cache
  export GOMODCACHE=/tmp/go-mod
  export GOSUMDB=off
fi
```

### PostgreSQL 连接字符串格式
```
postgresql://[user[:password]@][netloc][:port][/dbname][?param1=value1&...]

示例:
postgresql://bcms:bcms_dev@localhost:5432/bcms?sslmode=disable
```

### 环境变量要求
**必需：**
- `DATABASE_URL` - PostgreSQL 连接字符串
- `JWT_SECRET` - JWT 签名密钥（建议 32+ 字符）

**可选：**
- `PORT` - 服务端口（默认 4000）
- `ENV` - 环境（development/staging/production，默认 development）

---

## 📝 下一步任务

### 短期（第一周）
1. [ ] 连接到实际 PostgreSQL 数据库
2. [ ] 实现认证 endpoints (`POST /v1/auth/login`, `POST /v1/auth/register`)
3. [ ] 完成登录页前端交互
4. [ ] 添加用户会话管理

### 中期（第二~三周）
1. [ ] 实现颜色变体和配色表核心数据模型
2. [ ] 创建 PDF 提取服务（使用 pdfjs）
3. [ ] 实现配色表 CRUD endpoints
4. [ ] 前端仪表板完成功能模块

### 长期（第四周+）
1. [ ] 集成 AI 提取（阿里百炼 Qwen-VL）
2. [ ] 颜色引用解析和置信度计算
3. [ ] 打印输出功能（Chromedp）
4. [ ] 完整测试覆盖和 CI/CD

---

## 🔗 参考资源

- 📖 **项目文档**
  - [架构设计](docs/architecture.md)
  - [领域模型](docs/domain-model.md)
  - [产品需求](prd.md)
  - [规范指南](CLAUDE.md)

- 🛠 **技术栈文档**
  - [Go httpRouter](https://github.com/julienschmidt/httprouter)
  - [pgx 教程](https://github.com/jackc/pgx)
  - [Vue 3 官方文档](https://vuejs.org/)
  - [Pinia 状态管理](https://pinia.vuejs.org/)
  - [golang-migrate](https://github.com/golang-migrate/migrate)

- 🎓 **参考书籍**
  - Alex Edwards - *Let's Go Further* (Go Web 开发最佳实践)

---

## ✨ 项目特色

1. **规范化架构** - 遵循《Let's Go Further》风格的分层设计
2. **类型安全** - 使用 pgx 原生查询，避免 ORM 的黑魔法
3. **现代前端** - Vue 3 Composition API + Vite 快速开发
4. **AI 就绪** - 预留 AI 提取和置信度计算接口
5. **企业级运维** - 完整的日志、健康检查、优雅关闭

---

**搭建日期：** 2026-03-23
**搭建者：** GitHub Copilot
**备注：** 所有核心文件已就位，可立即开始功能开发。
