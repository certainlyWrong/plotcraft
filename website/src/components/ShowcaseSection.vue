<script setup lang="ts">
import Constellation from './Constellation.vue'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import AppFrame from './AppFrame.vue'

const { t } = useI18n()

const tabs = [
  { key: 'map', image: 'screenshots/mapa-da-historia.png' },
  { key: 'timeline', image: 'screenshots/linha-do-tempo.png' },
  { key: 'reading', image: 'screenshots/modo-leitura.png' },
  { key: 'editor', image: 'screenshots/editor.png' },
  { key: 'gallery', image: 'screenshots/galeria.png' },
  { key: 'theme', image: 'screenshots/tema-claro.png' },
] as const

type TabKey = (typeof tabs)[number]['key']

const current = ref<TabKey>('map')

/** Arrow keys move between tabs, as in the WAI-ARIA tabs pattern. */
function onKey(event: KeyboardEvent) {
  const index = tabs.findIndex((tab) => tab.key === current.value)
  const step = event.key === 'ArrowRight' ? 1 : event.key === 'ArrowLeft' ? -1 : 0
  if (!step) return
  event.preventDefault()
  const next = tabs[(index + step + tabs.length) % tabs.length]
  current.value = next.key
  document.getElementById(`tab-${next.key}`)?.focus()
}
</script>

<template>
  <section id="tour" class="section alt">
    <Constellation class="deco stars" />
    <div class="container">
      <div class="section-head">
        <h2>{{ t('showcase.title') }}</h2>
        <p>{{ t('showcase.intro') }}</p>
      </div>
      <div class="tabs" role="tablist" @keydown="onKey">
        <button
          v-for="tab in tabs"
          :id="`tab-${tab.key}`"
          :key="tab.key"
          role="tab"
          type="button"
          :aria-selected="current === tab.key"
          :aria-controls="`panel-${tab.key}`"
          :tabindex="current === tab.key ? 0 : -1"
          :class="{ on: current === tab.key }"
          @click="current = tab.key"
        >
          {{ t(`showcase.tabs.${tab.key}.label`) }}
        </button>
      </div>
      <div
        v-for="tab in tabs"
        v-show="current === tab.key"
        :id="`panel-${tab.key}`"
        :key="tab.key"
        role="tabpanel"
        :aria-labelledby="`tab-${tab.key}`"
        class="panel"
      >
        <div class="caption">
          <h3>{{ t(`showcase.tabs.${tab.key}.title`) }}</h3>
          <p>{{ t(`showcase.tabs.${tab.key}.text`) }}</p>
        </div>
        <AppFrame :src="tab.image" :alt="t(`showcase.tabs.${tab.key}.title`)" />
      </div>
    </div>
  </section>
</template>

<style scoped>
.stars {
  right: 4%;
  top: 48px;
}
.alt {
  background: color-mix(in srgb, var(--surface) 38%, transparent);
  border-block: 1px solid var(--border);
}
.tabs {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 32px;
}
.tabs button {
  padding: 9px 16px;
  border-radius: 999px;
  border: 1px solid var(--border);
  background: transparent;
  color: var(--muted);
  font: 500 0.95rem var(--sans);
  cursor: pointer;
}
.tabs button:hover {
  color: var(--fg);
}
.tabs button.on {
  background: var(--accent);
  border-color: var(--accent);
  color: var(--on-accent);
}
.panel {
  display: grid;
  gap: 28px;
}
.caption {
  max-width: 640px;
}
.caption h3 {
  font-size: 1.5rem;
}
.caption p {
  margin-top: 8px;
  color: var(--muted);
}
</style>
