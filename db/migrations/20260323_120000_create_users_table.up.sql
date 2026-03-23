-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash BYTEA NOT NULL,
    role TEXT NOT NULL DEFAULT 'sales' CHECK (role IN ('sales', 'tech', 'admin')),
    activated BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);

-- Create index on created_at for efficient pagination
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users (created_at);
