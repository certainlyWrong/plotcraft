import { ref } from 'vue'

export type ThemeName = 'dark' | 'light'

const STORAGE_KEY = 'plotcraft-theme'

function saved(): ThemeName | null {
  try {
    const value = localStorage.getItem(STORAGE_KEY)
    return value === 'dark' || value === 'light' ? value : null
  } catch {
    return null
  }
}

function preferred(): ThemeName {
  return typeof matchMedia !== 'undefined' && matchMedia('(prefers-color-scheme: light)').matches
    ? 'light'
    : 'dark'
}

export const theme = ref<ThemeName>(saved() ?? preferred())

export function applyTheme(): void {
  document.documentElement.dataset.theme = theme.value
}

export function toggleTheme(): void {
  theme.value = theme.value === 'dark' ? 'light' : 'dark'
  applyTheme()
  try {
    localStorage.setItem(STORAGE_KEY, theme.value)
  } catch {
    // The choice is just not kept.
  }
}
