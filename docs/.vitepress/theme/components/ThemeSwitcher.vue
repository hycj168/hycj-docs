<!--
  Copyright 2024 Kapok Docs Contributors

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->

<template>
  <div class="theme-switcher">
    <!-- Logo切换器 -->
    <div class="switcher-section">
      <h3>Logo 样式</h3>
      <div class="switcher-grid">
        <button
            v-for="(logo, index) in logos"
            :key="logo.name"
            :class="['switcher-btn', { active: currentLogo === LOGO_OPTIONS[index].path }]"
            @click="switchLogo(LOGO_OPTIONS[index].path)"
        >
          <img :src="logo.path" :alt="logo.name" class="logo-preview"/>
          <span>{{ logo.name }}</span>
        </button>
      </div>
    </div>

    <!-- 背景切换器 -->
    <div class="switcher-section">
      <h3>背景动画</h3>
      <div class="switcher-grid">
        <button
            v-for="(bg, index) in backgrounds"
            :key="bg.name"
            :class="['switcher-btn', { active: currentBackground === BACKGROUND_OPTIONS[index].path }]"
            @click="switchBackground(BACKGROUND_OPTIONS[index].path)"
        >
          <div class="bg-preview">
            <img :src="bg.path" :alt="bg.name"/>
          </div>
          <span>{{ bg.name }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import {onMounted, computed} from 'vue'
import {withBase} from 'vitepress'
import {useTheme} from '../composables/useTheme'
import {LOGO_OPTIONS, BACKGROUND_OPTIONS} from '../config/paths'

const {currentLogo, currentBackground, switchLogo, switchBackground, initTheme} = useTheme()

// 使用withBase处理路径配置
const logos = computed(() =>
    LOGO_OPTIONS.map(logo => ({
      ...logo,
      path: withBase(logo.path)
    }))
)

const backgrounds = computed(() =>
    BACKGROUND_OPTIONS.map(bg => ({
      ...bg,
      path: withBase(bg.path)
    }))
)

onMounted(() => {
  initTheme()
})
</script>

<style scoped>
.theme-switcher {
  padding: 2rem;
  max-width: 800px;
  margin: 0 auto;
}

.switcher-section {
  margin-bottom: 3rem;
}

.switcher-section h3 {
  font-size: 1.5rem;
  font-weight: 600;
  margin-bottom: 1rem;
  background: linear-gradient(135deg, #ff6b35, #f7931e, #ffb347);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
}

.switcher-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 1rem;
}

.switcher-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 1rem;
  border: 2px solid var(--vp-c-border);
  border-radius: 12px;
  background: var(--vp-c-bg-soft);
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.switcher-btn::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 107, 53, 0.1), transparent);
  transition: left 0.6s;
}

.switcher-btn:hover::before {
  left: 100%;
}

.switcher-btn:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px rgba(255, 107, 53, 0.15);
  border-color: rgba(255, 107, 53, 0.3);
}

.switcher-btn.active {
  border-color: #ff6b35;
  background: linear-gradient(135deg, rgba(255, 107, 53, 0.1), rgba(247, 147, 30, 0.1));
  box-shadow: 0 8px 16px rgba(255, 107, 53, 0.2);
}

.logo-preview {
  width: 60px;
  height: 20px;
  object-fit: contain;
  margin-bottom: 0.5rem;
}

.bg-preview {
  width: 80px;
  height: 60px;
  border-radius: 8px;
  overflow: hidden;
  margin-bottom: 0.5rem;
  background: var(--vp-c-bg-alt);
}

.bg-preview img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.switcher-btn span {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--vp-c-text-1);
}

.switcher-btn.active span {
  color: #ff6b35;
  font-weight: 600;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .theme-switcher {
    padding: 1rem;
  }

  .switcher-grid {
    grid-template-columns: repeat(auto-fit, minmax(100px, 1fr));
    gap: 0.75rem;
  }

  .switcher-btn {
    padding: 0.75rem;
  }

  .logo-preview {
    width: 50px;
    height: 16px;
  }

  .bg-preview {
    width: 60px;
    height: 45px;
  }
}

/* 动画增强 */
.switcher-btn {
  animation: fadeInUp 0.6s ease-out;
}

.switcher-btn:nth-child(1) {
  animation-delay: 0.1s;
}

.switcher-btn:nth-child(2) {
  animation-delay: 0.2s;
}

.switcher-btn:nth-child(3) {
  animation-delay: 0.3s;
}

.switcher-btn:nth-child(4) {
  animation-delay: 0.4s;
}

.switcher-btn:nth-child(5) {
  animation-delay: 0.5s;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>