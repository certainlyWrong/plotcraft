import vue from '@vitejs/plugin-vue'
import { defineConfig } from 'vitest/config'

// The site is served from https://<user>.github.io/<repo>/, so the base path
// comes from the environment (the workflow sets it); locally it is "/".
export default defineConfig({
  base: process.env.VITE_BASE ?? '/',
  plugins: [vue()],
  test: {
    environment: 'jsdom',
    include: ['src/**/*.spec.ts'],
  },
})
