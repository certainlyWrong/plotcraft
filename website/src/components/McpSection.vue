<script setup lang="ts">
import Constellation from './Constellation.vue'
import { Check } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'
import { REPO_URL } from '../config'

const { t } = useI18n()
const points = ['revisions', 'confirm', 'readOnly'] as const
</script>

<template>
  <section id="ai" class="section alt">
    <Constellation class="deco stars" />
    <div class="container split">
      <div>
        <h2>{{ t('mcp.title') }}</h2>
        <p class="lead">{{ t('mcp.text') }}</p>
        <ul>
          <li v-for="point in points" :key="point">
            <Check :size="18" />
            <span>{{ t(`mcp.points.${point}`) }}</span>
          </li>
        </ul>
        <a
          class="btn btn-ghost"
          :href="`${REPO_URL}/blob/main/packages/plotcraft_mcp/README.md`"
          target="_blank"
          rel="noopener"
        >
          {{ t('mcp.docs') }}
        </a>
      </div>
      <pre class="code" aria-label="Claude Code"><code><span class="c"># Claude Code</span>
claude mcp add plotcraft -- \
  /path/to/plotcraft-mcp \
  --root ~/Documents/Plotcraft

<span class="c"># then, in plain language</span>
"Create a mystery novel called
 The Salt Road, with three characters
 and a first chapter."</code></pre>
    </div>
  </section>
</template>

<style scoped>
.stars {
  left: 3%;
  bottom: 24px;
}
.alt {
  background: color-mix(in srgb, var(--surface) 38%, transparent);
  border-block: 1px solid var(--border);
}
.split {
  display: grid;
  grid-template-columns: 1.1fr 1fr;
  gap: 48px;
  align-items: center;
}
h2 {
  font-size: clamp(1.8rem, 3.2vw, 2.5rem);
}
.lead {
  margin-top: 16px;
  color: var(--muted);
}
ul {
  list-style: none;
  padding: 0;
  margin: 24px 0 28px;
  display: grid;
  gap: 12px;
}
li {
  display: flex;
  gap: 10px;
  align-items: flex-start;
}
li svg {
  color: var(--accent);
  flex: none;
  margin-top: 4px;
}
.code {
  margin: 0;
  padding: 22px;
  border-radius: var(--radius);
  background: #151a1b;
  color: #dfe6e2;
  border: 1px solid var(--border);
  font: 0.9rem/1.7 ui-monospace, 'SF Mono', Menlo, Consolas, monospace;
  overflow-x: auto;
}
.c {
  color: #7f918a;
}
@media (max-width: 860px) {
  .split {
    grid-template-columns: 1fr;
  }
}
</style>
