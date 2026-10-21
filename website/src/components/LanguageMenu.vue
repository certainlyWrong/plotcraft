<script setup lang="ts">
import { Check, ChevronDown, Globe } from 'lucide-vue-next'
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { LOCALES, rememberLocale, type LocaleCode } from '../i18n'

const { t, locale } = useI18n()

const root = ref<HTMLElement>()
const button = ref<HTMLButtonElement>()
const options = ref<HTMLElement[]>([])
const open = ref(false)

const current = computed(() => LOCALES.find((item) => item.code === locale.value) ?? LOCALES[0])

function setOption(el: unknown, index: number) {
  if (el) options.value[index] = el as HTMLElement
}

function optionAt(index: number) {
  options.value[(index + LOCALES.length) % LOCALES.length]?.focus()
}

async function show() {
  open.value = true
  await nextTick()
  optionAt(LOCALES.findIndex((item) => item.code === locale.value))
}

function hide(returnFocus = false) {
  open.value = false
  if (returnFocus) button.value?.focus()
}

function choose(code: LocaleCode) {
  locale.value = code
  rememberLocale(code)
  hide(true)
}

function onButtonKey(event: KeyboardEvent) {
  if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
    event.preventDefault()
    void show()
  }
}

function onMenuKey(event: KeyboardEvent) {
  const index = options.value.findIndex((option) => option === document.activeElement)
  switch (event.key) {
    case 'ArrowDown':
      event.preventDefault()
      optionAt(index + 1)
      break
    case 'ArrowUp':
      event.preventDefault()
      optionAt(index - 1)
      break
    case 'Home':
      event.preventDefault()
      optionAt(0)
      break
    case 'End':
      event.preventDefault()
      optionAt(LOCALES.length - 1)
      break
    case 'Escape':
      event.preventDefault()
      hide(true)
      break
    case 'Tab':
      hide()
      break
  }
}

function onPointerDown(event: Event) {
  if (open.value && root.value && !root.value.contains(event.target as Node)) hide()
}

onMounted(() => document.addEventListener('pointerdown', onPointerDown))
onBeforeUnmount(() => document.removeEventListener('pointerdown', onPointerDown))
</script>

<template>
  <div ref="root" class="lang">
    <button
      ref="button"
      class="trigger"
      type="button"
      aria-haspopup="listbox"
      :aria-expanded="open"
      :aria-label="`${t('nav.language')}: ${current.label}`"
      @click="open ? hide() : show()"
      @keydown="onButtonKey"
    >
      <Globe :size="17" aria-hidden="true" />
      <span class="name">{{ current.label }}</span>
      <span class="short">{{ current.code.toUpperCase() }}</span>
      <ChevronDown :size="15" class="chevron" :class="{ up: open }" aria-hidden="true" />
    </button>

    <ul
      v-if="open"
      class="menu"
      role="listbox"
      :aria-label="t('nav.language')"
      @keydown="onMenuKey"
    >
      <li
        v-for="(item, index) in LOCALES"
        :key="item.code"
        :ref="(el) => setOption(el, index)"
        role="option"
        tabindex="-1"
        :lang="item.code"
        :aria-selected="item.code === locale"
        :class="{ on: item.code === locale }"
        @click="choose(item.code)"
        @keydown.enter.prevent="choose(item.code)"
        @keydown.space.prevent="choose(item.code)"
      >
        <span>{{ item.label }}</span>
        <Check v-if="item.code === locale" :size="16" aria-hidden="true" />
      </li>
    </ul>
  </div>
</template>

<style scoped>
.lang {
  position: relative;
}
.trigger {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 38px;
  padding: 0 12px;
  border-radius: 9px;
  border: 1px solid var(--border);
  background: var(--surface);
  color: var(--fg);
  font: 500 0.9rem var(--sans);
  cursor: pointer;
}
.trigger:hover {
  background: var(--surface-raised);
}
.trigger svg:first-child {
  color: var(--muted);
}
.short {
  display: none;
}
.chevron {
  color: var(--muted);
  transition: transform 0.15s ease;
}
.chevron.up {
  transform: rotate(180deg);
}
.menu {
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  z-index: 20;
  min-width: 176px;
  margin: 0;
  padding: 6px;
  list-style: none;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: var(--surface-raised);
  box-shadow: var(--shadow);
}
.menu li {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 9px 12px;
  border-radius: 8px;
  font-size: 0.93rem;
  cursor: pointer;
  outline: none;
}
.menu li:hover,
.menu li:focus-visible {
  background: color-mix(in srgb, var(--accent) 16%, transparent);
}
.menu li.on {
  color: var(--accent);
  font-weight: 500;
}
@media (max-width: 640px) {
  .name {
    display: none;
  }
  .short {
    display: inline;
  }
  .trigger {
    padding: 0 10px;
  }
}
@media (prefers-reduced-motion: reduce) {
  .chevron {
    transition: none;
  }
}
</style>
