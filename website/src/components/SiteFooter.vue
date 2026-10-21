<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { DOCS_URL, RELEASES_URL, REPO_URL } from '../config'

const { t } = useI18n()
</script>

<template>
  <footer class="footer">
    <div class="container row">
      <p>{{ t('footer.tagline') }}</p>
      <nav aria-label="Footer">
        <a :href="DOCS_URL" target="_blank" rel="noopener">{{ t('footer.docs') }}</a>
        <a :href="REPO_URL" target="_blank" rel="noopener">{{ t('footer.source') }}</a>
        <a :href="RELEASES_URL" target="_blank" rel="noopener">{{ t('footer.releases') }}</a>
      </nav>
      <p class="built">{{ t('footer.built') }}</p>
    </div>
  </footer>
</template>

<style scoped>
.footer {
  padding: 40px 0;
  border-top: 1px solid var(--border);
  color: var(--muted);
  font-size: 0.92rem;
}
.row {
  display: flex;
  flex-wrap: wrap;
  gap: 16px 32px;
  align-items: center;
  justify-content: space-between;
}
nav {
  display: flex;
  gap: 22px;
}
nav a {
  color: var(--muted);
  text-decoration: none;
}
nav a:hover {
  color: var(--fg);
}
.built {
  opacity: 0.8;
}
</style>
