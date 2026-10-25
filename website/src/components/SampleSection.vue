<script setup lang="ts">
import OrbitRings from './OrbitRings.vue'
import { useI18n } from 'vue-i18n'
import AppFrame from './AppFrame.vue'

const { t } = useI18n()

const stats = [
  { key: 'chapters', value: 12 },
  { key: 'elements', value: 25 },
  { key: 'plots', value: 2 },
  { key: 'images', value: 30 },
] as const
</script>

<template>
  <section id="sample" class="section">
    <OrbitRings class="deco rings" :size="520" />
    <div class="container split">
      <div class="copy">
        <h2>{{ t('sample.title') }}</h2>
        <p>{{ t('sample.text') }}</p>
        <p class="story">{{ t('sample.story') }}</p>
        <dl class="stats">
          <div v-for="stat in stats" :key="stat.key">
            <dt>{{ stat.value }}</dt>
            <dd>{{ t(`sample.stats.${stat.key}`) }}</dd>
          </div>
        </dl>
      </div>
      <AppFrame src="screenshots/biblioteca.png" :alt="t('sample.imageAlt')" />
    </div>
  </section>
</template>

<style scoped>
.split {
  display: grid;
  grid-template-columns: 1fr 1.1fr;
  gap: 48px;
  align-items: center;
}
h2 {
  font-size: clamp(1.8rem, 3.2vw, 2.5rem);
}
.copy p {
  margin-top: 16px;
  color: var(--muted);
}
.copy .story {
  font-family: var(--serif);
  font-style: italic;
  color: var(--fg);
  border-left: 3px solid var(--accent);
  padding-left: 16px;
}
.stats {
  margin: 28px 0 0;
  display: grid;
  grid-template-columns: repeat(4, auto);
  gap: 20px;
  justify-content: start;
}
.stats dt {
  font: 500 2rem var(--serif);
  color: var(--accent);
}
.stats dd {
  margin: 0;
  color: var(--muted);
  font-size: 0.85rem;
}
@media (max-width: 860px) {
  .split {
    grid-template-columns: 1fr;
  }
}
.rings {
  left: -240px;
  bottom: -120px;
}
</style>
