<script setup lang="ts">
import OrbitRings from './OrbitRings.vue'
import ArchBridge from './ArchBridge.vue'
import { computed, onMounted, ref } from 'vue'
import { Download } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'
import { detectPlatform, groupAssets } from '../lib/releases'
import { useLatestRelease } from '../lib/useLatestRelease'
import AppFrame from './AppFrame.vue'

const { t } = useI18n()
const { release, state } = useLatestRelease()

// Like the game, the page opens without colour and is given it back.
const colored = ref(false)
onMounted(() => setTimeout(() => (colored.value = true), 700))

const platform = computed(() =>
  typeof navigator === 'undefined'
    ? undefined
    : detectPlatform(navigator.userAgent, navigator.platform),
)

/** A direct link when we know the system and the release has its file. */
const direct = computed(() => {
  if (!release.value || !platform.value) return undefined
  return groupAssets(release.value)[platform.value].app?.url
})
</script>

<template>
  <section id="top" class="hero">
    <OrbitRings class="deco hero-rings" :size="980" />
    <div class="container">
      <div class="copy">
        <p class="eyebrow">{{ t('hero.eyebrow') }}</p>
        <h1>{{ t('hero.title') }}</h1>
        <p class="lead">{{ t('hero.subtitle') }}</p>
        <div class="actions">
          <a v-if="direct && platform" class="btn btn-primary" :href="direct">
            <Download :size="18" />
            {{ t('hero.download', { platform: t(`platforms.${platform}`) }) }}
          </a>
          <a v-else class="btn btn-primary" href="#download">
            <Download :size="18" />
            {{ t('nav.download') }}
          </a>
          <a class="btn btn-ghost" href="#features">{{ t('hero.seeFeatures') }}</a>
        </div>
        <p class="meta">
          <template v-if="state === 'ready' && release">
            {{ t('hero.version', { version: release.version }) }} ·
          </template>
          {{ t('hero.early') }}
        </p>
      </div>
      <AppFrame class="shot" :class="{ colored }" src="screenshots/personagem.png" :alt="t('hero.imageAlt')" eager />
    </div>
    <ArchBridge class="deco hero-bridge" />
  </section>
</template>

<style scoped>
.hero {
  padding: 96px 0 56px;
}
.shot :deep(img) {
  filter: grayscale(1);
}
.shot.colored :deep(img) {
  filter: none;
}
@media (prefers-reduced-motion: no-preference) {
  .shot :deep(img) {
    transition: filter 3.2s ease;
  }
  .copy > * {
    animation: rise 1.4s cubic-bezier(0.22, 0.61, 0.36, 1) both;
  }
  .copy > :nth-child(2) { animation-delay: 0.15s; }
  .copy > :nth-child(3) { animation-delay: 0.3s; }
  .copy > :nth-child(4) { animation-delay: 0.45s; }
  .copy > :nth-child(5) { animation-delay: 0.6s; }
}
@media (prefers-reduced-motion: reduce) {
  .shot :deep(img) {
    filter: none;
  }
}
@keyframes rise {
  from {
    opacity: 0;
    transform: translateY(20px);
    filter: blur(6px);
  }
}
.copy {
  max-width: 760px;
  margin: 0 auto 48px;
  text-align: center;
}
.eyebrow {
  color: var(--accent);
  font-size: 0.85rem;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  margin-bottom: 18px;
}
h1 {
  font-size: clamp(2.2rem, 5.4vw, 3.8rem);
  letter-spacing: -0.02em;
  font-weight: 400;
}
.lead {
  margin: 20px auto 0;
  color: var(--muted);
  font-size: 1.2rem;
  max-width: 600px;
}
.actions {
  margin-top: 32px;
  display: flex;
  gap: 12px;
  justify-content: center;
  flex-wrap: wrap;
}
.meta {
  margin-top: 18px;
  font-size: 0.88rem;
  color: var(--muted);
}
.hero-rings {
  left: 50%;
  top: 340px;
  translate: -50% -50%;
}
.hero-bridge {
  left: 0;
  bottom: -1px;
}
.shot {
  max-width: 1000px;
  margin: 0 auto;
}
</style>
