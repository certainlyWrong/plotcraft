<script setup lang="ts">
/** Points joined by thin lines that draw themselves in, then twinkle. */
const pts = [
  [30, 150], [120, 70], [230, 110], [330, 40], [420, 120], [350, 210], [210, 190], [120, 240],
] as const
const links = [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [2, 6], [1, 7]] as const
</script>

<template>
  <svg class="stars" viewBox="0 0 450 280" aria-hidden="true" focusable="false">
    <line
      v-for="([a, b], i) in links"
      :key="i"
      class="link"
      :style="{ '--i': i }"
      :x1="pts[a][0]"
      :y1="pts[a][1]"
      :x2="pts[b][0]"
      :y2="pts[b][1]"
      pathLength="1"
    />
    <circle
      v-for="([x, y], i) in pts"
      :key="i"
      class="pt"
      :style="{ '--i': i }"
      :cx="x"
      :cy="y"
      :r="i % 3 === 0 ? 6 : 4"
    />
  </svg>
</template>

<style scoped>
.stars {
  width: 450px;
  max-width: 100%;
  stroke: var(--stage-ink);
  fill: var(--stage-ink);
  opacity: 0.55;
  pointer-events: none;
}
.link {
  stroke-width: 1.1;
  stroke-dasharray: 1;
}
@media (prefers-reduced-motion: no-preference) {
  .link {
    animation: draw 2.4s cubic-bezier(0.22, 0.61, 0.36, 1) both;
    animation-delay: calc(var(--i) * 0.25s);
    animation-timeline: view();
    animation-range: entry 0% cover 40%;
  }
  .pt {
    animation: twinkle 4s ease-in-out infinite;
    animation-delay: calc(var(--i) * -0.7s);
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
@keyframes twinkle {
  50% {
    opacity: 0.25;
  }
}
</style>
