<template>
  <img
      :src="currentBackground"
      :alt="imageAlt"
      class="hero-image"
      @load="onImageLoad"
  />
</template>

<script setup lang="ts">
import {computed} from 'vue'
import {useTheme} from '../composables/useTheme'

interface Props {
  src?: string
  alt?: string
}

const props = withDefaults(defineProps<Props>(), {
  src: '/hero-animation.svg',
  alt: 'Hero Animation'
})

const {currentBackground} = useTheme()

const imageAlt = computed(() => props.alt)

const onImageLoad = () => {
  console.log(`Hero image loaded: ${currentBackground.value}`)
}
</script>

<style scoped>
.hero-image {
  width: 100%;
  height: auto;
  max-width: 400px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
</style>