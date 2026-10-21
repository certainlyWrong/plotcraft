import { createI18n } from 'vue-i18n'
import en from './en'
import es from './es'
import pt from './pt'

export const LOCALES = [
  { code: 'en', label: 'English' },
  { code: 'pt', label: 'Português' },
  { code: 'es', label: 'Español' },
] as const

export type LocaleCode = (typeof LOCALES)[number]['code']

const STORAGE_KEY = 'plotcraft-lang'

function isLocale(value: string | null | undefined): value is LocaleCode {
  return LOCALES.some((locale) => locale.code === value)
}

/** The saved choice, else the browser's language, else English. */
export function initialLocale(
  saved: string | null = safeGet(),
  browser: readonly string[] = typeof navigator === 'undefined' ? [] : navigator.languages,
): LocaleCode {
  if (isLocale(saved)) return saved
  for (const language of browser) {
    const code = language.toLowerCase().split('-')[0]
    if (isLocale(code)) return code
  }
  return 'en'
}

function safeGet(): string | null {
  try {
    return localStorage.getItem(STORAGE_KEY)
  } catch {
    return null
  }
}

export function rememberLocale(code: LocaleCode): void {
  try {
    localStorage.setItem(STORAGE_KEY, code)
  } catch {
    // Private mode: the choice just is not kept.
  }
}

export const i18n = createI18n({
  legacy: false,
  locale: initialLocale(),
  fallbackLocale: 'en',
  messages: { en, pt, es },
})
