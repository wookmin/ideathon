import { loadEnvFile } from 'node:process';
import { spawn } from 'node:child_process';

try {
  loadEnvFile(new URL('../.env.local', import.meta.url));
} catch (error) {
  if (error.code !== 'ENOENT') {
    throw error;
  }
}

const apiKey = process.env.AIT_CONSOLE_API_KEY?.trim();

if (!apiKey) {
  console.error(
    'AIT_CONSOLE_API_KEY가 비어 있습니다. ait/.env.local에 콘솔 API 키를 입력하세요.',
  );
  process.exit(1);
}

const child = spawn('npx', ['ait', 'deploy', '--api-key', apiKey], {
  cwd: new URL('..', import.meta.url),
  stdio: 'inherit',
});

child.on('exit', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
  }
  process.exit(code ?? 1);
});
