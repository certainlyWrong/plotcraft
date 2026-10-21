<script setup lang="ts">
import { asset } from '../config'

defineProps<{ src: string; alt: string; eager?: boolean }>()
</script>

<template>
  <figure class="frame">
    <div class="bar" aria-hidden="true">
      <span /><span /><span />
      <b>Plotcraft</b>
    </div>
    <img
      :src="asset(src)"
      :alt="alt"
      width="1800"
      height="1125"
      :loading="eager ? 'eager' : 'lazy'"
      decoding="async"
    />
  </figure>
</template>

<style scoped>
.frame {
  margin: 0;
  border-radius: var(--radius);
  overflow: hidden;
  background: var(--surface);
  border: 1px solid var(--border);
  box-shadow: var(--shadow);
}
.bar {
  display: flex;
  align-items: center;
  gap: 7px;
  padding: 10px 14px;
  background: var(--surface-raised);
  border-bottom: 1px solid var(--border);
}
.bar span {
  width: 11px;
  height: 11px;
  border-radius: 50%;
  background: var(--border);
}
.bar b {
  margin-left: 10px;
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--muted);
}
img {
  width: 100%;
  height: auto;
}
</style>
