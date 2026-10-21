<script setup lang="ts">
import { Moon, Sun } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'
import { REPO_URL, asset } from '../config'
import { LOCALES, rememberLocale, type LocaleCode } from '../i18n'
import { theme, toggleTheme } from '../lib/useTheme'

const { t, locale } = useI18n()

function onLocale(event: Event) {
  const code = (event.target as HTMLSelectElement).value as LocaleCode
  locale.value = code
  rememberLocale(code)
}
</script>

<template>
  <header class="header">
    <div class="container row">
      <a class="brand" href="#top" aria-label="Plotcraft">
        <img :src="asset('favicon.svg')" alt="" width="28" height="28" />
        <span>plotcraft</span>
      </a>
      <nav class="links" aria-label="Main">
        <a href="#features">{{ t('nav.features') }}</a>
        <a href="#tour">{{ t('nav.showcase') }}</a>
        <a href="#sample">{{ t('nav.sample') }}</a>
        <a href="#ai">{{ t('nav.mcp') }}</a>
        <a :href="REPO_URL" target="_blank" rel="noopener">{{ t('nav.github') }}</a>
      </nav>
      <div class="tools">
        <label class="lang">
          <span class="sr">{{ t('nav.language') }}</span>
          <select :value="locale" @change="onLocale">
            <option v-for="item in LOCALES" :key="item.code" :value="item.code">
              {{ item.label }}
            </option>
          </select>
        </label>
        <button class="icon" type="button" :aria-label="t('nav.theme')" @click="toggleTheme">
          <Sun v-if="theme === 'dark'" :size="18" />
          <Moon v-else :size="18" />
        </button>
        <a class="btn btn-primary cta" href="#download">{{ t('nav.download') }}</a>
      </div>
    </div>
  </header>
</template>

<style scoped>
.header {
  position: sticky;
  top: 0;
  z-index: 10;
  background: color-mix(in srgb, var(--bg) 82%, transparent);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--border);
}
.row {
  display: flex;
  align-items: center;
  gap: 24px;
  height: 64px;
}
.brand {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  color: var(--fg);
  text-decoration: none;
  font: 500 1.35rem var(--serif);
}
.links {
  display: flex;
  gap: 22px;
  margin-left: 12px;
}
.links a {
  color: var(--muted);
  text-decoration: none;
  font-size: 0.95rem;
}
.links a:hover {
  color: var(--fg);
}
.tools {
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 10px;
}
select,
.icon {
  height: 38px;
  border-radius: 9px;
  border: 1px solid var(--border);
  background: var(--surface);
  color: var(--fg);
  font: 0.9rem var(--sans);
  cursor: pointer;
}
select {
  padding: 0 10px;
}
.icon {
  width: 38px;
  display: grid;
  place-items: center;
}
.cta {
  padding: 8px 16px;
}
.sr {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
}
@media (max-width: 860px) {
  .links {
    display: none;
  }
}
@media (max-width: 520px) {
  .cta {
    display: none;
  }
}
</style>
