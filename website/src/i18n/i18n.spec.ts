import { describe, expect, it } from 'vitest'
import en from './en'
import es from './es'
import { initialLocale } from './index'
import pt from './pt'

function keys(value: unknown, prefix = ''): string[] {
  if (typeof value !== 'object' || value === null) return [prefix]
  return Object.entries(value).flatMap(([key, child]) =>
    keys(child, prefix ? `${prefix}.${key}` : key),
  )
}

describe('translations', () => {
  it('have the same keys in every language', () => {
    expect(keys(pt)).toEqual(keys(en))
    expect(keys(es)).toEqual(keys(en))
  })

  it('keep the placeholders of each text', () => {
    const placeholders = (text: string) => [...text.matchAll(/\{(\w+)\}/g)].map((m) => m[1]).sort()
    const flat = (value: unknown, prefix = ''): [string, string][] =>
      typeof value === 'string'
        ? [[prefix, value]]
        : Object.entries(value as object).flatMap(([key, child]) =>
            flat(child, prefix ? `${prefix}.${key}` : key),
          )
    const english = new Map(flat(en))
    for (const [key, text] of [...flat(pt), ...flat(es)]) {
      expect(placeholders(text), key).toEqual(placeholders(english.get(key)!))
    }
  })
})

describe('initialLocale', () => {
  it('uses a saved choice first', () => {
    expect(initialLocale('es', ['pt-BR'])).toBe('es')
  })

  it('then the browser language, ignoring the region', () => {
    expect(initialLocale(null, ['fr-FR', 'pt-BR', 'en'])).toBe('pt')
    expect(initialLocale(null, ['ES'])).toBe('es')
  })

  it('and falls back to English', () => {
    expect(initialLocale(null, ['de', 'ja'])).toBe('en')
    expect(initialLocale('xx', [])).toBe('en')
  })
})
