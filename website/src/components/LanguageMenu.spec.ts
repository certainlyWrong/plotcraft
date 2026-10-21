import { mount } from '@vue/test-utils'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import { nextTick } from 'vue'
import { createI18n } from 'vue-i18n'
import en from '../i18n/en'
import es from '../i18n/es'
import pt from '../i18n/pt'
import LanguageMenu from './LanguageMenu.vue'

function mountMenu(locale = 'en') {
  const i18n = createI18n({ legacy: false, locale, messages: { en, pt, es } })
  const wrapper = mount(LanguageMenu, { global: { plugins: [i18n] }, attachTo: document.body })
  return { wrapper, i18n }
}

describe('LanguageMenu', () => {
  beforeEach(() => localStorage.clear())
  afterEach(() => (document.body.innerHTML = ''))

  it('starts closed and shows the current language', () => {
    const { wrapper } = mountMenu('pt')
    expect(wrapper.find('[role="listbox"]').exists()).toBe(false)
    expect(wrapper.find('button').text()).toContain('Português')
    expect(wrapper.find('button').attributes('aria-expanded')).toBe('false')
  })

  it('opens a list with the three languages and marks the current one', async () => {
    const { wrapper } = mountMenu('es')
    await wrapper.find('button').trigger('click')
    const items = wrapper.findAll('[role="option"]')
    expect(items.map((item) => item.text())).toEqual(['English', 'Português', 'Español'])
    expect(items.map((item) => item.attributes('aria-selected'))).toEqual(['false', 'false', 'true'])
    expect(wrapper.find('button').attributes('aria-expanded')).toBe('true')
  })

  it('moves focus to the current language when it opens', async () => {
    const { wrapper } = mountMenu('pt')
    await wrapper.find('button').trigger('click')
    await nextTick()
    expect(document.activeElement?.textContent).toContain('Português')
  })

  it('changes the language, remembers it and closes', async () => {
    const { wrapper, i18n } = mountMenu('en')
    await wrapper.find('button').trigger('click')
    await wrapper.findAll('[role="option"]')[2].trigger('click')
    expect(i18n.global.locale.value).toBe('es')
    expect(localStorage.getItem('plotcraft-lang')).toBe('es')
    expect(wrapper.find('[role="listbox"]').exists()).toBe(false)
    expect(document.activeElement).toBe(wrapper.find('button').element)
  })

  it('is driven by the keyboard', async () => {
    const { wrapper, i18n } = mountMenu('en')
    await wrapper.find('button').trigger('keydown', { key: 'ArrowDown' })
    await nextTick()
    const menu = wrapper.find('[role="listbox"]')
    expect(menu.exists()).toBe(true)
    await menu.trigger('keydown', { key: 'ArrowDown' })
    expect(document.activeElement?.textContent).toContain('Português')
    await menu.trigger('keydown', { key: 'End' })
    expect(document.activeElement?.textContent).toContain('Español')
    await menu.trigger('keydown', { key: 'ArrowDown' })
    expect(document.activeElement?.textContent).toContain('English')
    await menu.trigger('keydown', { key: 'ArrowDown' })
    await wrapper.findAll('[role="option"]')[1].trigger('keydown', { key: 'Enter' })
    expect(i18n.global.locale.value).toBe('pt')
  })

  it('closes with Escape, giving focus back to the button', async () => {
    const { wrapper } = mountMenu('en')
    await wrapper.find('button').trigger('click')
    await wrapper.find('[role="listbox"]').trigger('keydown', { key: 'Escape' })
    expect(wrapper.find('[role="listbox"]').exists()).toBe(false)
    expect(document.activeElement).toBe(wrapper.find('button').element)
  })

  it('closes when the page is clicked elsewhere', async () => {
    const { wrapper } = mountMenu('en')
    await wrapper.find('button').trigger('click')
    document.body.dispatchEvent(new Event('pointerdown', { bubbles: true }))
    await nextTick()
    expect(wrapper.find('[role="listbox"]').exists()).toBe(false)
  })
})
