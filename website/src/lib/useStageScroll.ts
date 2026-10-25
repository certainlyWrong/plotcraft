import { onBeforeUnmount, onMounted } from 'vue'

const REVEAL = '.section-head, .section .card, .section figure, .section .panel, .split > *'

/**
 * Drives the Gris-style journey. As each section crosses the middle of the
 * viewport it sets `data-stage` on <html> (the CSS then bleeds the colour
 * across) and softly reveals the elements inside it.
 */
export function useStageScroll() {
  let stages: IntersectionObserver | undefined
  let reveals: IntersectionObserver | undefined

  onMounted(() => {
    if (typeof IntersectionObserver === 'undefined') return
    const root = document.documentElement

    stages = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (!entry.isIntersecting) continue
          const stage = (entry.target as HTMLElement).dataset.stage
          if (stage) root.dataset.stage = stage
        }
      },
      { rootMargin: '-45% 0px -50% 0px' },
    )
    document.querySelectorAll<HTMLElement>('[data-stage]').forEach((el) => stages!.observe(el))

    reveals = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (!entry.isIntersecting) continue
          entry.target.classList.add('is-in')
          reveals!.unobserve(entry.target)
        }
      },
      { rootMargin: '0px 0px -8% 0px', threshold: 0.08 },
    )
    document.querySelectorAll<HTMLElement>(REVEAL).forEach((el, i) => {
      el.classList.add('reveal')
      el.style.setProperty('--d', `${(i % 4) * 90}ms`)
      reveals!.observe(el)
    })
  })

  onBeforeUnmount(() => {
    stages?.disconnect()
    reveals?.disconnect()
  })
}
