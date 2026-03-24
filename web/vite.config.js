import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  server: {
    // 本地开发时将 /v1 请求代理到 Go 后端
    proxy: {
      '/v1': {
        target: 'http://localhost:4000',
        changeOrigin: true,
      }
    }
  }
})