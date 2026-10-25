<script setup lang="ts">
/** Concentric rings, arcs and orbiting dots that turn slowly, after Gris's
 *  circular motifs. Each ring rotates at its own speed and direction. */
defineProps<{ size?: number }>()
</script>

<template>
  <svg
    class="orbit"
    :style="{ '--size': `${size ?? 640}px` }"
    viewBox="-200 -200 400 400"
    aria-hidden="true"
    focusable="false"
  >
    <circle class="fixed" r="22" />
    <g class="ring r1">
      <circle r="62" />
      <circle class="dot" cx="62" cy="0" r="5" />
    </g>
    <g class="ring r2">
      <circle r="98" stroke-dasharray="2 9" />
      <path d="M -98 0 A 98 98 0 0 1 98 0" class="arc" />
      <circle class="dot" cx="0" cy="-98" r="4" />
    </g>
    <g class="ring r3">
      <circle r="136" stroke-dasharray="40 14 4 14" />
      <circle class="dot" cx="-96" cy="96" r="6" />
      <circle class="dot hollow" cx="136" cy="0" r="7" />
    </g>
    <g class="ring r4">
      <path d="M 0 -184 A 184 184 0 0 1 184 0" class="arc" />
      <path d="M 0 184 A 184 184 0 0 1 -184 0" class="arc" />
      <circle class="dot" cx="130" cy="-130" r="4" />
    </g>
  </svg>
</template>

<style scoped>
.orbit {
  width: var(--size);
  height: var(--size);
  overflow: visible;
  fill: none;
  stroke: var(--stage-ink);
  stroke-width: 1.2;
  opacity: 0.5;
  pointer-events: none;
}
.fixed {
  fill: color-mix(in srgb, var(--stage) 35%, transparent);
  stroke: none;
}
.arc {
  stroke-width: 2.4;
  stroke-linecap: round;
}
.dot {
  fill: var(--stage-ink);
  stroke: none;
}
.dot.hollow {
  fill: none;
  stroke: var(--stage-ink);
  stroke-width: 1.4;
}
.ring {
  transform-box: view-box;
  transform-origin: 0 0;
}

@media (prefers-reduced-motion: no-preference) {
  .ring {
    animation: spin var(--t, 60s) linear infinite var(--dir, normal);
  }
  .r1 { --t: 24s; }
  .r2 { --t: 46s; --dir: reverse; }
  .r3 { --t: 80s; }
  .r4 { --t: 120s; --dir: reverse; }

  /* Where supported, scrolling also turns the rings, like a mechanism. */
  @supports (animation-timeline: scroll()) {
    .orbit {
      animation: spin 1s linear both;
      animation-timeline: scroll(root);
      animation-range: 0 100%;
    }
  }
}
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
