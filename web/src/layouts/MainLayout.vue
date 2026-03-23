<template>
  <div class="main-layout">
    <header class="navbar">
      <div class="navbar-content">
        <div class="logo">BCMS</div>
        <nav class="nav-menu">
          <RouterLink to="/">首页</RouterLink>
        </nav>
        <div class="user-options">
          <button @click="handleLogout" class="logout-btn">登出</button>
        </div>
      </div>
    </header>
    
    <div class="layout-body">
      <RouterView />
    </div>
  </div>
</template>

<script setup>
import { RouterLink, RouterView, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const handleLogout = () => {
  authStore.logout()
  router.push({ name: 'Login' })
}
</script>

<style scoped>
.main-layout {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.navbar {
  background: white;
  border-bottom: 1px solid #e0e0e0;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.navbar-content {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 1.5rem;
  height: 3.5rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.logo {
  font-weight: bold;
  font-size: 1.5rem;
  color: #667eea;
}

.nav-menu {
  display: flex;
  gap: 2rem;
}

.nav-menu a {
  color: #555;
  font-weight: 500;
  transition: color 0.3s;
}

.nav-menu a:hover {
  color: #667eea;
}

.user-options {
  display: flex;
  gap: 1rem;
}

.logout-btn {
  background: #e74c3c;
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 0.375rem;
  font-weight: 500;
  transition: opacity 0.3s;
}

.logout-btn:hover {
  opacity: 0.9;
}

.layout-body {
  flex: 1;
  background: #f5f5f5;
}
</style>
