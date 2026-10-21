// Copies what the site shares with the app into public/, so the screenshots
// and the fonts have a single source of truth:
//   ../docs/screenshots -> public/screenshots
//   ../assets/fonts     -> public/fonts (the families the site uses, with their licenses)
import { cpSync, existsSync, mkdirSync, rmSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')
const repo = join(root, '..')

const fonts = [
  'Lora-Regular.ttf',
  'Lora-Medium.ttf',
  'Lora-OFL.txt',
  'DMSans-Regular.ttf',
  'DMSans-Medium.ttf',
  'DM-Sans-OFL.txt',
]

function reset(dir) {
  rmSync(dir, { recursive: true, force: true })
  mkdirSync(dir, { recursive: true })
}

const screenshots = join(repo, 'docs', 'screenshots')
if (!existsSync(screenshots)) throw new Error(`Missing ${screenshots}`)
reset(join(root, 'public', 'screenshots'))
cpSync(screenshots, join(root, 'public', 'screenshots'), { recursive: true })

reset(join(root, 'public', 'fonts'))
for (const file of fonts) {
  const from = join(repo, 'assets', 'fonts', file)
  if (!existsSync(from)) throw new Error(`Missing ${from}`)
  cpSync(from, join(root, 'public', 'fonts', file))
}
console.log('Synced screenshots and fonts into public/')
