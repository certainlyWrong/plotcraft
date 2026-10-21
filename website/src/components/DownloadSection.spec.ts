import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it } from 'vitest'
import { createI18n } from 'vue-i18n'
import en from '../i18n/en'
import { resetLatestRelease, useLatestRelease } from '../lib/useLatestRelease'
import type { Release } from '../lib/releases'
import DownloadSection from './DownloadSection.vue'

const release: Release = {
  tag: 'v1.2.0',
  version: '1.2.0',
  url: 'https://github.com/o/r/releases/tag/v1.2.0',
  publishedAt: '2026-10-21T10:00:00Z',
  prerelease: false,
  assets: [
    { name: 'plotcraft-1.2.0-macos.dmg', url: 'https://x/mac.dmg', size: 37_000_000 },
    { name: 'plotcraft-1.2.0-linux-x64.tar.gz', url: 'https://x/linux.tgz', size: 20_000_000 },
    { name: 'plotcraft-mcp-1.2.0-macos-arm64.tar.gz', url: 'https://x/mcp-mac.tgz', size: 3_000_000 },
    { name: 'SHA256SUMS.txt', url: 'https://x/sums', size: 400 },
  ],
}

function mountSection() {
  const i18n = createI18n({ legacy: false, locale: 'en', messages: { en } })
  return mount(DownloadSection, { global: { plugins: [i18n] } })
}

describe('DownloadSection', () => {
  beforeEach(() => resetLatestRelease())

  it('lists the files of the latest release for each system', async () => {
    useLatestRelease(async () => release)
    const wrapper = mountSection()
    await flushPromises()
    const links = wrapper.findAll('a').map((a) => a.attributes('href'))
    expect(links).toContain('https://x/mac.dmg')
    expect(links).toContain('https://x/linux.tgz')
    expect(links).toContain('https://x/mcp-mac.tgz')
    expect(links).toContain('https://x/sums')
    expect(wrapper.text()).toContain('1.2.0')
    // Windows has no file in this release.
    expect(wrapper.text()).toContain(en.download.notAvailable)
  })

  it('shows the way to the releases page when GitHub cannot be reached', async () => {
    useLatestRelease(async () => {
      throw new Error('GitHub answered 404')
    })
    const wrapper = mountSection()
    await flushPromises()
    expect(wrapper.text()).toContain(en.download.error.title)
    expect(wrapper.find('a[href$="/releases"]').exists()).toBe(true)
  })

  it('says so when there is no release yet', async () => {
    useLatestRelease(async () => null)
    const wrapper = mountSection()
    await flushPromises()
    expect(wrapper.text()).toContain(en.download.none.title)
  })
})
