<script setup lang="ts">
import { watchEffect } from 'vue'
import { useI18n } from 'vue-i18n'
import DownloadSection from './components/DownloadSection.vue'
import FeaturesSection from './components/FeaturesSection.vue'
import HeroSection from './components/HeroSection.vue'
import McpSection from './components/McpSection.vue'
import SampleSection from './components/SampleSection.vue'
import ShowcaseSection from './components/ShowcaseSection.vue'
import SiteFooter from './components/SiteFooter.vue'
import SiteHeader from './components/SiteHeader.vue'
import WatercolorWash from './components/WatercolorWash.vue'
import { useStageScroll } from './lib/useStageScroll'

const { t, locale } = useI18n()

useStageScroll()

// Keep the page's language, title and description in step with the choice.
watchEffect(() => {
  document.documentElement.lang = locale.value
  document.title = t('meta.title')
  document
    .querySelector('meta[name="description"]')
    ?.setAttribute('content', t('meta.description'))
})
</script>

<template>
  <WatercolorWash />
  <SiteHeader />
  <main>
    <HeroSection data-stage="0" />
    <FeaturesSection data-stage="1" />
    <ShowcaseSection data-stage="2" />
    <SampleSection data-stage="3" />
    <McpSection data-stage="3" />
    <DownloadSection data-stage="4" />
  </main>
  <SiteFooter />
</template>
