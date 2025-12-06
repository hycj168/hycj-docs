<template>
  <DefaultTheme.Layout>
    <template #home-hero-image>
      <div class="custom-hero-image">
        <img
            :src="backgroundSrc"
            :alt="'Kapok Docs Animation'"
            class="hero-bg-image"
            :key="currentBackground"
        />
      </div>
    </template>
  </DefaultTheme.Layout>
</template>

<script setup lang="ts">
import {onMounted, computed} from 'vue'
import DefaultTheme from 'vitepress/theme'
import {withBase} from 'vitepress'
import {useTheme} from '../composables/useTheme'

const {currentBackground, initTheme} = useTheme()

// 使用computed和withBase处理动态背景路径
const backgroundSrc = computed(() => {
  return withBase(currentBackground.value)
})

onMounted(() => {
  initTheme()
})
</script>

<style scoped>
.custom-hero-image {
  display: flex;
  justify-content: center;
  align-items: center;
}

.hero-bg-image {
  max-width: 400px;
  width: 100%;
  height: auto;
  animation: float 6s ease-in-out infinite;
  filter: drop-shadow(0 10px 30px rgba(255, 107, 53, 0.2));
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.hero-bg-image:hover {
  transform: scale(1.05);
  filter: drop-shadow(0 15px 40px rgba(255, 107, 53, 0.3));
}

@keyframes float {
  0%, 100% {
    transform: translateY(0px) rotate(0deg) translateZ(0);
  }
  33% {
    transform: translateY(-10px) rotate(1deg) translateZ(0);
  }
  66% {
    transform: translateY(-5px) rotate(-1deg) translateZ(0);
  }
}
</style>