import { defineConfig } from 'vite';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const directory = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  build: {
    emptyOutDir: true,
    outDir: resolve(directory, 'bridge-dist'),
    lib: {
      entry: resolve(directory, 'src/ait-bridge.ts'),
      formats: ['es'],
      fileName: () => 'ait-bridge.js',
    },
  },
});
