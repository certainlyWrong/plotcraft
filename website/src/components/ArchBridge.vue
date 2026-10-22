<script setup lang="ts">
/** A row of stone arches, like the bridges and ruins in Gris. */
</script>

<template>
  <svg class="bridge" viewBox="0 0 1200 90" preserveAspectRatio="none" aria-hidden="true" focusable="false">
    <path class="deck" d="M0 24 H1200" pathLength="1" />
    <path
      v-for="i in 8"
      :key="i"
      class="arch"
      :style="{ '--i': i }"
      :d="`M ${(i - 1) * 150 + 10} 24 V 44 A 65 46 0 0 1 ${i * 150 - 10} 44 V 24`"
      pathLength="1"
    />
  </svg>
</template>

<style scoped>
.bridge {
  display: block;
  width: 100%;
  height: 90px;
  fill: none;
  stroke: var(--stage-ink);
  stroke-width: 1.4;
  opacity: 0.5;
  pointer-events: none;
}
.deck,
.arch {
  stroke-dasharray: 1;
  vector-effect: non-scaling-stroke;
}
@media (prefers-reduced-motion: no-preference) {
  .deck,
  .arch {
    animation: draw 2.6s cubic-bezier(0.22, 0.61, 0.36, 1) both;
    animation-delay: calc(var(--i, 0) * 0.18s);
    animation-timeline: view();
    animation-range: entry 0% cover 45%;
  }
}
@keyframes draw {
  from {
    stroke-dashoffset: 1;
  }
  to {
    stroke-dashoffset: 0;
  }
}
</style>
