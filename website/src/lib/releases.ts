export type PlatformId = 'macos' | 'windows' | 'linux'

export const PLATFORMS: PlatformId[] = ['macos', 'windows', 'linux']

export interface ReleaseAsset {
  name: string
  url: string
  size: number
}

export interface Release {
  tag: string
  /** The tag without the leading "v". */
  version: string
  url: string
  publishedAt: string
  prerelease: boolean
  assets: ReleaseAsset[]
}

export interface Downloads {
  app?: ReleaseAsset
  mcp?: ReleaseAsset
}

const APP_FILE = /^plotcraft-(?!mcp-).+-(macos\.dmg|windows-x64\.zip|linux-x64\.tar\.gz)$/
const MCP_FILE = /^plotcraft-mcp-.+-(macos|windows|linux)-(?:arm64|x64)\.(?:tar\.gz|exe)$/

/** The system a release file is for, and whether it is the app or the MCP server. */
export function classifyAsset(
  name: string,
): { platform: PlatformId; kind: 'app' | 'mcp' } | undefined {
  const mcp = MCP_FILE.exec(name)
  if (mcp) return { platform: mcp[1] as PlatformId, kind: 'mcp' }
  const app = APP_FILE.exec(name)
  if (!app) return undefined
  const platform = app[1].startsWith('macos')
    ? 'macos'
    : app[1].startsWith('windows')
      ? 'windows'
      : 'linux'
  return { platform, kind: 'app' }
}

/** The app and the MCP server files of each system in a release. */
export function groupAssets(release: Release): Record<PlatformId, Downloads> {
  const grouped: Record<PlatformId, Downloads> = { macos: {}, windows: {}, linux: {} }
  for (const asset of release.assets) {
    const found = classifyAsset(asset.name)
    if (found) grouped[found.platform][found.kind] ??= asset
  }
  return grouped
}

export function checksumsOf(release: Release): ReleaseAsset | undefined {
  return release.assets.find((asset) => asset.name === 'SHA256SUMS.txt')
}

/** Guesses the visitor's desktop system; undefined on phones and unknown systems. */
export function detectPlatform(userAgent: string, platform = ''): PlatformId | undefined {
  const text = `${userAgent} ${platform}`.toLowerCase()
  if (/android|iphone|ipad|ipod/.test(text)) return undefined
  if (/win/.test(text) && !/darwin/.test(text)) return 'windows'
  if (/mac/.test(text)) return 'macos'
  if (/linux|x11|cros/.test(text)) return 'linux'
  return undefined
}

export function formatSize(bytes: number): string {
  if (bytes >= 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(bytes >= 100 * 1024 * 1024 ? 0 : 1)} MB`
  return `${Math.max(1, Math.round(bytes / 1024))} KB`
}

interface ApiAsset {
  name: string
  browser_download_url: string
  size: number
}

interface ApiRelease {
  tag_name: string
  html_url: string
  published_at: string | null
  draft: boolean
  prerelease: boolean
  assets: ApiAsset[]
}

export function parseRelease(raw: ApiRelease): Release {
  return {
    tag: raw.tag_name,
    version: raw.tag_name.replace(/^v/, ''),
    url: raw.html_url,
    publishedAt: raw.published_at ?? '',
    prerelease: raw.prerelease,
    assets: raw.assets.map((asset) => ({
      name: asset.name,
      url: asset.browser_download_url,
      size: asset.size,
    })),
  }
}

/**
 * The newest published release (a stable one when there is one) or null when
 * there is none. Throws when GitHub cannot be reached or refuses the request,
 * which is what happens while the repository is private.
 */
export async function fetchLatestRelease(
  owner: string,
  name: string,
  fetchImpl: typeof fetch = fetch,
): Promise<Release | null> {
  const response = await fetchImpl(
    `https://api.github.com/repos/${owner}/${name}/releases?per_page=10`,
    { headers: { Accept: 'application/vnd.github+json' } },
  )
  if (!response.ok) throw new Error(`GitHub answered ${response.status}`)
  const releases = ((await response.json()) as ApiRelease[]).filter((release) => !release.draft)
  const chosen = releases.find((release) => !release.prerelease) ?? releases[0]
  return chosen ? parseRelease(chosen) : null
}
