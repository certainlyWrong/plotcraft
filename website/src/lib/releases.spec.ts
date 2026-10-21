import { describe, expect, it, vi } from 'vitest'
import {
  checksumsOf,
  classifyAsset,
  detectPlatform,
  fetchLatestRelease,
  formatSize,
  groupAssets,
  parseRelease,
} from './releases'

const files = [
  'plotcraft-1.2.0-macos.dmg',
  'plotcraft-1.2.0-windows-x64.zip',
  'plotcraft-1.2.0-linux-x64.tar.gz',
  'plotcraft-mcp-1.2.0-macos-arm64.tar.gz',
  'plotcraft-mcp-1.2.0-windows-x64.exe',
  'plotcraft-mcp-1.2.0-linux-x64.tar.gz',
  'SHA256SUMS.txt',
]

function apiRelease(overrides: Record<string, unknown> = {}) {
  return {
    tag_name: 'v1.2.0',
    html_url: 'https://github.com/o/r/releases/tag/v1.2.0',
    published_at: '2026-10-21T10:00:00Z',
    draft: false,
    prerelease: false,
    assets: files.map((name, index) => ({
      name,
      browser_download_url: `https://example.test/${name}`,
      size: 1000 * (index + 1),
    })),
    ...overrides,
  }
}

describe('classifyAsset', () => {
  it('tells the app from the MCP server, for each system', () => {
    expect(classifyAsset('plotcraft-1.2.0-macos.dmg')).toEqual({ platform: 'macos', kind: 'app' })
    expect(classifyAsset('plotcraft-1.2.0-windows-x64.zip')).toEqual({
      platform: 'windows',
      kind: 'app',
    })
    expect(classifyAsset('plotcraft-1.2.0-linux-x64.tar.gz')).toEqual({
      platform: 'linux',
      kind: 'app',
    })
    expect(classifyAsset('plotcraft-mcp-1.2.0-macos-arm64.tar.gz')).toEqual({
      platform: 'macos',
      kind: 'mcp',
    })
    expect(classifyAsset('plotcraft-mcp-1.2.0-windows-x64.exe')).toEqual({
      platform: 'windows',
      kind: 'mcp',
    })
  })

  it('handles pre-release versions', () => {
    expect(classifyAsset('plotcraft-1.0.0-beta.1-macos.dmg')?.platform).toBe('macos')
    expect(classifyAsset('plotcraft-mcp-1.0.0-beta.1-linux-x64.tar.gz')?.kind).toBe('mcp')
  })

  it('ignores other files', () => {
    expect(classifyAsset('SHA256SUMS.txt')).toBeUndefined()
    expect(classifyAsset('Source code (zip)')).toBeUndefined()
  })
})

describe('groupAssets', () => {
  it('collects the app and the MCP server of each system', () => {
    const grouped = groupAssets(parseRelease(apiRelease()))
    expect(grouped.macos.app?.name).toBe('plotcraft-1.2.0-macos.dmg')
    expect(grouped.macos.mcp?.name).toBe('plotcraft-mcp-1.2.0-macos-arm64.tar.gz')
    expect(grouped.windows.app?.url).toBe('https://example.test/plotcraft-1.2.0-windows-x64.zip')
    expect(grouped.linux.mcp?.name).toBe('plotcraft-mcp-1.2.0-linux-x64.tar.gz')
  })

  it('leaves out what a release does not have', () => {
    const release = parseRelease(
      apiRelease({ assets: [{ name: 'plotcraft-1.2.0-macos.dmg', browser_download_url: 'u', size: 1 }] }),
    )
    const grouped = groupAssets(release)
    expect(grouped.macos.app).toBeDefined()
    expect(grouped.windows).toEqual({})
    expect(checksumsOf(release)).toBeUndefined()
  })

  it('finds the checksums file', () => {
    expect(checksumsOf(parseRelease(apiRelease()))?.name).toBe('SHA256SUMS.txt')
  })
})

describe('detectPlatform', () => {
  it('recognizes the desktop systems', () => {
    expect(detectPlatform('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', 'MacIntel')).toBe('macos')
    expect(detectPlatform('Mozilla/5.0 (Windows NT 10.0; Win64; x64)', 'Win32')).toBe('windows')
    expect(detectPlatform('Mozilla/5.0 (X11; Linux x86_64)', 'Linux x86_64')).toBe('linux')
  })

  it('does not guess for phones and tablets', () => {
    expect(detectPlatform('Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)', 'iPhone')).toBeUndefined()
    expect(detectPlatform('Mozilla/5.0 (Linux; Android 14)', 'Linux armv8l')).toBeUndefined()
    expect(detectPlatform('')).toBeUndefined()
  })
})

describe('formatSize', () => {
  it('uses KB and MB', () => {
    expect(formatSize(300)).toBe('1 KB')
    expect(formatSize(2048)).toBe('2 KB')
    expect(formatSize(37_671_387)).toBe('35.9 MB')
    expect(formatSize(150 * 1024 * 1024)).toBe('150 MB')
  })
})

describe('parseRelease', () => {
  it('drops the v from the tag', () => {
    const release = parseRelease(apiRelease())
    expect(release.version).toBe('1.2.0')
    expect(release.tag).toBe('v1.2.0')
    expect(release.assets).toHaveLength(files.length)
  })
})

describe('fetchLatestRelease', () => {
  const answer = (body: unknown, ok = true, status = 200) =>
    vi.fn(async (_url: RequestInfo | URL, _init?: RequestInit) => ({ ok, status, json: async () => body }) as Response)

  it('prefers the newest stable release over a newer pre-release', async () => {
    const fetchImpl = answer([
      apiRelease({ tag_name: 'v2.0.0-beta.1', prerelease: true }),
      apiRelease({ tag_name: 'v1.2.0' }),
    ])
    expect((await fetchLatestRelease('o', 'r', fetchImpl))?.tag).toBe('v1.2.0')
  })

  it('takes a pre-release when it is all there is, and skips drafts', async () => {
    const fetchImpl = answer([
      apiRelease({ tag_name: 'v3.0.0', draft: true }),
      apiRelease({ tag_name: 'v1.0.0-beta.1', prerelease: true }),
    ])
    expect((await fetchLatestRelease('o', 'r', fetchImpl))?.tag).toBe('v1.0.0-beta.1')
  })

  it('returns null when there are no releases', async () => {
    expect(await fetchLatestRelease('o', 'r', answer([]))).toBeNull()
  })

  it('throws when GitHub refuses, as it does for a private repository', async () => {
    await expect(fetchLatestRelease('o', 'r', answer({}, false, 404))).rejects.toThrow('404')
  })

  it('asks for the right repository', async () => {
    const fetchImpl = answer([])
    await fetchLatestRelease('certainlyWrong', 'plotcraft', fetchImpl)
    expect(fetchImpl.mock.calls[0][0]).toContain('/repos/certainlyWrong/plotcraft/releases')
  })
})
