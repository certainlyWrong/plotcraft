<script setup lang="ts">
import {
  Bot,
  BookOpen,
  Clock,
  FolderOpen,
  Image,
  Layers,
  Network,
  PenLine,
  Users,
} from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'

const { t } = useI18n()

const items = [
  { key: 'elements', icon: Users },
  { key: 'phases', icon: Layers },
  { key: 'map', icon: Network },
  { key: 'timeline', icon: Clock },
  { key: 'writing', icon: PenLine },
  { key: 'reading', icon: BookOpen },
  { key: 'gallery', icon: Image },
  { key: 'files', icon: FolderOpen },
  { key: 'ai', icon: Bot },
] as const
</script>

<template>
  <section id="features" class="section">
    <div class="container">
      <div class="section-head">
        <h2>{{ t('features.title') }}</h2>
        <p>{{ t('features.intro') }}</p>
      </div>
      <ul class="grid">
        <li v-for="item in items" :key="item.key" class="card">
          <span class="badge"><component :is="item.icon" :size="20" /></span>
          <h3>{{ t(`features.items.${item.key}.title`) }}</h3>
          <p>{{ t(`features.items.${item.key}.text`) }}</p>
        </li>
      </ul>
    </div>
  </section>
</template>

<style scoped>
.grid {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 18px;
}
.card {
  padding: 24px;
  border-radius: var(--radius);
  background: var(--surface);
  border: 1px solid var(--border);
}
.badge {
  display: inline-grid;
  place-items: center;
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: color-mix(in srgb, var(--accent) 18%, transparent);
  color: var(--accent);
  margin-bottom: 16px;
}
h3 {
  font-size: 1.2rem;
  margin-bottom: 8px;
}
.card p {
  color: var(--muted);
  font-size: 0.97rem;
}
</style>
