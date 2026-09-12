import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  base: '/Safe-Spit-useless-projects/', // Required for GitHub Pages hosting under a repo name
})
