import crypto from 'node:crypto';

import { appEnv } from '../config/env.js';
import { AppError } from './app-error.js';

function normalizePublicKey(input: string) {
  const trimmed = input.trim();
  if (trimmed.startsWith('-----BEGIN PUBLIC KEY-----')) {
    return trimmed;
  }

  const sanitized = trimmed.replace(/\s+/g, '');
  const chunks = sanitized.match(/.{1,64}/g) ?? [sanitized];
  return [
    '-----BEGIN PUBLIC KEY-----',
    ...chunks,
    '-----END PUBLIC KEY-----',
  ].join('\n');
}

export function encryptForCodef(plainText: string) {
  if (!appEnv.CODEF_PUBLIC_KEY.trim()) {
    throw new AppError(
      500,
      'CODEF_PUBLIC_KEY_MISSING',
      'CODEF_PUBLIC_KEY is missing. Add the demo public_key to backend/.env before creating a card connection.',
    );
  }

  const publicKey = normalizePublicKey(appEnv.CODEF_PUBLIC_KEY);
  const encrypted = crypto.publicEncrypt(
    {
      key: publicKey,
      padding: crypto.constants.RSA_PKCS1_PADDING,
    },
    Buffer.from(plainText, 'utf8'),
  );

  return encrypted.toString('base64');
}
