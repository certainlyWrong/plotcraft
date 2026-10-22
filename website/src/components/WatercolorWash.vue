<template>
  <svg class="wash" aria-hidden="true" focusable="false" preserveAspectRatio="xMidYMid slice" viewBox="0 0 1000 800">
    <defs>
      <!-- Ragged, bleeding edges, like pigment spreading into wet paper. -->
      <filter id="bleed" x="-20%" y="-20%" width="140%" height="140%">
        <feTurbulence type="fractalNoise" baseFrequency="0.006 0.009" numOctaves="3" seed="7" result="n" />
        <feDisplacementMap in="SourceGraphic" in2="n" scale="140" />
        <feGaussianBlur stdDeviation="22" />
      </filter>
    </defs>
    <g filter="url(#bleed)">
      <circle class="blob b1" cx="230" cy="190" r="260" />
      <circle class="blob b2" cx="800" cy="330" r="220" />
      <circle class="blob b3" cx="520" cy="660" r="270" />
    </g>
  </svg>
</template>

<style scoped>
.wash {
  position: fixed;
  inset: 0;
  z-index: -1;
  width: 100vw;
  height: 100vh;
  pointer-events: none;
  opacity: var(--wash-opacity);
}
.blob {
  fill: var(--stage);
}
.b2 {
  fill: color-mix(in srgb, var(--stage) 60%, var(--stage-ink));
}
.b3 {
  fill: color-mix(in srgb, var(--stage) 70%, var(--fg));
  opacity: 0.7;
}

@media (prefers-reduced-motion: no-preference) {
  .blob {
    transform-box: fill-box;
    transform-origin: center;
    animation: drift 22s ease-in-out infinite alternate;
  }
  .b2 {
    animation-duration: 28s;
    animation-delay: -9s;
  }
  .b3 {
    animation-duration: 34s;
    animation-delay: -16s;
  }
}

@keyframes drift {
  from {
    transform: translate(-3%, -2%) scale(0.94);
  }
  to {
    transform: translate(4%, 3%) scale(1.08);
  }
}
</style>
