<script setup lang="ts">
import { computed } from 'vue'
import { Download, Laptop, Monitor, Terminal } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'
import { DOCS_URL, RELEASES_URL } from '../config'
import {
  PLATFORMS,
  checksumsOf,
  detectPlatform,
  formatSize,
  groupAssets,
  type PlatformId,
} from '../lib/releases'
import { useLatestRelease } from '../lib/useLatestRelease'

const { t, locale } = useI18n()
const { release, state } = useLatestRelease()

const icons = { macos: Laptop, windows: Monitor, linux: Terminal } as const

const detected = computed(() =>
  typeof navigator === 'undefined'
    ? undefined
    : detectPlatform(navigator.userAgent, navigator.platform),
)

/** The visitor's system first. */
const order = computed<PlatformId[]>(() =>
  detected.value
    ? [detected.value, ...PLATFORMS.filter((platform) => platform !== detected.value)]
    : PLATFORMS,
)

const grouped = computed(() => (release.value ? groupAssets(release.value) : undefined))
const checksums = computed(() => (release.value ? checksumsOf(release.value) : undefined))

const published = computed(() => {
  const when = release.value?.publishedAt
  if (!when) return ''
  return t('download.published', {
    date: new Date(when).toLocaleDateString(locale.value, { dateStyle: 'long' }),
  })
})

const quarantine = 'xattr -dr com.apple.quarantine /Applications/Plotcraft.app'
</script>

<template>
  <section id="download" class="section">
    <div class="container">
      <div class="section-head">
        <h2>{{ t('download.title') }}</h2>
        <p>{{ t('download.intro') }}</p>
      </div>

      <p v-if="state === 'loading'" class="status" role="status">{{ t('download.loading') }}</p>

      <div v-else-if="state !== 'ready'" class="empty">
        <h3>{{ t(state === 'none' ? 'download.none.title' : 'download.error.title') }}</h3>
        <p>{{ t(state === 'none' ? 'download.none.text' : 'download.error.text') }}</p>
        <div class="links">
          <a class="btn btn-primary" :href="RELEASES_URL" target="_blank" rel="noopener">
            {{ t('download.allReleases') }}
          </a>
          <a class="btn btn-ghost" :href="DOCS_URL" target="_blank" rel="noopener">
            {{ t('download.fromSource') }}
          </a>
        </div>
      </div>

      <template v-else-if="release && grouped">
        <p class="latest">
          <strong>{{ t('download.latest') }}: {{ release.version }}</strong>
          <span v-if="release.prerelease" class="tag">{{ t('download.prerelease') }}</span>
          <span v-if="published"> · {{ published }}</span>
        </p>

        <ul class="cards">
          <li
            v-for="platform in order"
            :key="platform"
            class="card"
            :class="{ pick: platform === detected }"
          >
            <p v-if="platform === detected" class="rec">{{ t('download.recommended') }}</p>
            <h3>
              <component :is="icons[platform]" :size="22" />
              {{ t(`platforms.${platform}`) }}
            </h3>

            <a v-if="grouped[platform].app" class="btn btn-primary" :href="grouped[platform].app!.url">
              <Download :size="18" />
              {{ t('download.button') }}
              <small>{{ formatSize(grouped[platform].app!.size) }}</small>
            </a>
            <p v-else class="missing">{{ t('download.notAvailable') }}</p>
            <p v-if="grouped[platform].app" class="file">{{ grouped[platform].app!.name }}</p>

            <div class="mcp">
              <p class="mcp-title">{{ t('download.mcp') }}</p>
              <p class="hint">{{ t('download.mcpHint') }}</p>
              <a v-if="grouped[platform].mcp" :href="grouped[platform].mcp!.url">
                {{ grouped[platform].mcp!.name }}
                ({{ formatSize(grouped[platform].mcp!.size) }})
              </a>
              <span v-else class="missing">{{ t('download.notAvailable') }}</span>
            </div>
          </li>
        </ul>

        <p class="links">
          <a :href="release.url" target="_blank" rel="noopener">{{ t('download.releaseNotes') }}</a>
          <a v-if="checksums" :href="checksums.url">{{ t('download.checksums') }}</a>
          <a :href="RELEASES_URL" target="_blank" rel="noopener">{{ t('download.allReleases') }}</a>
        </p>
      </template>

      <aside class="notes">
        <h3>{{ t('download.notes.title') }}</h3>
        <p>{{ t('download.notes.unsigned') }}</p>
        <ul>
          <li>{{ t('download.notes.macos') }}</li>
          <li><code>{{ quarantine }}</code></li>
          <li>{{ t('download.notes.windows') }}</li>
          <li>{{ t('download.notes.linux') }}</li>
        </ul>
      </aside>
    </div>
  </section>
</template>

<style scoped>
.status,
.latest {
  color: var(--muted);
}
.latest {
  margin-bottom: 20px;
}
.latest strong {
  color: var(--fg);
}
.tag {
  margin-left: 8px;
  padding: 2px 8px;
  border-radius: 999px;
  border: 1px solid var(--border);
  font-size: 0.8rem;
}
.cards {
  list-style: none;
  padding: 0;
  margin: 0 0 24px;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(290px, 1fr));
  gap: 18px;
}
.card {
  padding: 24px;
  border-radius: var(--radius);
  background: var(--surface);
  border: 1px solid var(--border);
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.card.pick {
  border-color: var(--accent);
  box-shadow: 0 0 0 1px var(--accent);
}
.rec {
  color: var(--accent);
  font-size: 0.78rem;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}
h3 {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 1.3rem;
}
.btn small {
  opacity: 0.75;
  font-size: 0.8rem;
}
.btn {
  justify-content: center;
}
.file {
  font-size: 0.8rem;
  color: var(--muted);
  word-break: break-all;
}
.mcp {
  margin-top: 6px;
  padding-top: 14px;
  border-top: 1px solid var(--border);
  display: grid;
  gap: 4px;
  font-size: 0.9rem;
}
.mcp-title {
  font-weight: 500;
}
.hint,
.missing {
  color: var(--muted);
  font-size: 0.85rem;
}
.mcp a {
  word-break: break-all;
}
.links {
  display: flex;
  gap: 8px 24px;
  flex-wrap: wrap;
  margin: 0;
}
.empty {
  padding: 28px;
  border-radius: var(--radius);
  border: 1px dashed var(--border);
  display: grid;
  gap: 12px;
  justify-items: start;
}
.empty p {
  color: var(--muted);
}
.notes {
  margin-top: 40px;
  padding: 22px 24px;
  border-radius: var(--radius);
  background: var(--surface);
  border: 1px solid var(--border);
  font-size: 0.93rem;
}
.notes h3 {
  font-size: 1.1rem;
  margin-bottom: 8px;
}
.notes p,
.notes li {
  color: var(--muted);
}
.notes ul {
  margin: 10px 0 0;
  padding-left: 20px;
  display: grid;
  gap: 6px;
}
code {
  display: inline-block;
  padding: 3px 8px;
  border-radius: 6px;
  background: var(--bg);
  border: 1px solid var(--border);
  color: var(--fg);
  font-size: 0.82rem;
  user-select: all;
}
</style>
