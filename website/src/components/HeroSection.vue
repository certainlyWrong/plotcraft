<script setup lang="ts">
import { computed } from 'vue'
import { Download } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'
import { detectPlatform, groupAssets } from '../lib/releases'
import { useLatestRelease } from '../lib/useLatestRelease'
import AppFrame from './AppFrame.vue'

const { t } = useI18n()
const { release, state } = useLatestRelease()

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
      <AppFrame class="shot" src="screenshots/personagem.png" :alt="t('hero.imageAlt')" eager />
    </div>
  </section>
</template>

<style scoped>
.hero {
  padding: 72px 0 40px;
  background: radial-gradient(
    ellipse 80% 60% at 50% 0%,
    color-mix(in srgb, var(--accent) 16%, transparent),
    transparent 70%
  );
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
.shot {
  max-width: 1000px;
  margin: 0 auto;
}
</style>
