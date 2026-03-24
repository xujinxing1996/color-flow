-- 初始化脚本：创建 bcms 用户、数据库和扩展
-- 由 docker-entrypoint-initdb.d 自动执行（仅首次启动时）

CREATE USER bcms WITH PASSWORD 'bcms_dev';
CREATE DATABASE bcms OWNER bcms;

\connect bcms

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

GRANT ALL PRIVILEGES ON DATABASE bcms TO bcms;