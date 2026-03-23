<template>
  <div class="dashboard">
    <div class="header">
      <h1>配色管理系统</h1>
      <p>欢迎回来，{{ authStore.user?.name || '用户' }}</p>
    </div>
    
    <div class="content">
      <div class="card">
        <h2>功能模块</h2>
        <div class="features">
          <div class="feature-item">
            <span class="icon">📄</span>
            <p>PDF 提取</p>
          </div>
          <div class="feature-item">
            <span class="icon">🎨</span>
            <p>配色表管理</p>
          </div>
          <div class="feature-item">
            <span class="icon">📊</span>
            <p>数据分析</p>
          </div>
          <div class="feature-item">
            <span class="icon">🖨️</span>
            <p>打印输出</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useAuthStore } from '../stores/auth'

const authStore = useAuthStore()
</script>

<style scoped>
.dashboard {
  padding: 2rem;
}

.header {
  margin-bottom: 2rem;
}

.header h1 {
  font-size: 2rem;
  color: #333;
  margin-bottom: 0.5rem;
}

.header p {
  color: #777;
}

.content {
  max-width: 1200px;
}

.card {
  background: white;
  padding: 2rem;
  border-radius: 0.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.card h2 {
  font-size: 1.25rem;
  margin-bottom: 1.5rem;
  color: #333;
}

.features {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1.5rem;
}

.feature-item {
  text-align: center;
  padding: 1.5rem;
  border-radius: 0.375rem;
  background: #f9f9f9;
  cursor: pointer;
  transition: all 0.3s;
}

.feature-item:hover {
  background: #f0f0f0;
  transform: translateY(-2px);
}

.icon {
  font-size: 2rem;
  display: block;
  margin-bottom: 0.5rem;
}

.feature-item p {
  font-weight: 500;
  color: #333;
}
</style>
