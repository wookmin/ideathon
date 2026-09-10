import { cp, mkdir, rm } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const aitDirectory = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const projectRoot = resolve(aitDirectory, '..');
const flutterOutput = resolve(projectRoot, 'build', 'web');
const aitOutput = resolve(aitDirectory, 'dist');

await new Promise((resolvePromise, reject) => {
  const child = spawn('flutter', ['build', 'web', '--release'], {
    cwd: projectRoot,
    stdio: 'inherit',
  });

  child.once('error', reject);
  child.once('exit', (code) => {
    if (code === 0) resolvePromise();
    else reject(new Error(`flutter build web failed with exit code ${code}`));
  });
});

await rm(aitOutput, { recursive: true, force: true });
await mkdir(aitOutput, { recursive: true });
await cp(flutterOutput, aitOutput, { recursive: true });
