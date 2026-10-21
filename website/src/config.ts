/** The GitHub repository whose releases the site offers for download. */
export const REPO = { owner: 'certainlyWrong', name: 'plotcraft' } as const

export const REPO_URL = `https://github.com/${REPO.owner}/${REPO.name}`
export const RELEASES_URL = `${REPO_URL}/releases`
export const DOCS_URL = `${REPO_URL}/tree/main/docs`

/** A file of the site's public/ folder, respecting the base path. */
export function asset(path: string): string {
  return `${import.meta.env.BASE_URL}${path.replace(/^\//, '')}`
}
