import { cp, readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const aitDirectory = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const outputDirectory = resolve(aitDirectory, 'dist');
const bridgeFile = resolve(aitDirectory, 'bridge-dist', 'ait-bridge.js');
const outputIndex = resolve(outputDirectory, 'index.html');

await cp(bridgeFile, resolve(outputDirectory, 'ait-bridge.js'));

const index = await readFile(outputIndex, 'utf8');
const bridgeTag = '<script type="module" src="ait-bridge.js"></script>';

if (!index.includes(bridgeTag)) {
  await writeFile(
    outputIndex,
    index.replace('</head>', `  ${bridgeTag}\n</head>`),
  );
}
