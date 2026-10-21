import { ref } from 'vue'
import { REPO } from '../config'
import { fetchLatestRelease, type Release } from './releases'

export type ReleaseState = 'loading' | 'ready' | 'none' | 'error'

const release = ref<Release | null>(null)
const state = ref<ReleaseState>('loading')
let started = false

/** One request for the whole page, shared by every component that needs it. */
export function useLatestRelease(load: () => Promise<Release | null> = () =>
  fetchLatestRelease(REPO.owner, REPO.name)) {
  if (!started) {
    started = true
    load().then(
      (found) => {
        release.value = found
        state.value = found ? 'ready' : 'none'
      },
      () => {
        state.value = 'error'
      },
    )
  }
  return { release, state }
}

/** For tests: forget the shared request. */
export function resetLatestRelease(): void {
  started = false
  release.value = null
  state.value = 'loading'
}
