import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(4000),
  ALLOWED_ORIGINS: z.string().default(''),

  CODEF_ENV: z.enum(['sandbox', 'development', 'production']).default('sandbox'),
  CODEF_CLIENT_ID: z.string().min(1, 'CODEF_CLIENT_ID is required'),
  CODEF_CLIENT_SECRET: z.string().min(1, 'CODEF_CLIENT_SECRET is required'),
  CODEF_PUBLIC_KEY: z.string().optional().default(''),

  APP_ENCRYPTION_SECRET: z
    .string()
    .min(16, 'APP_ENCRYPTION_SECRET must be at least 16 chars'),

  // 추가
  GOOGLE_PLACES_API_KEY: z.string().min(1, 'GOOGLE_PLACES_API_KEY is required'),

  // Apps in Toss mTLS credentials. Keep the files outside the repository.
  TOSS_MTLS_CERT_PATH: z.string().default(''),
  TOSS_MTLS_KEY_PATH: z.string().default(''),
  TOSS_PAY_BASE_URL: z
    .string()
    .url()
    .default('https://pay-apps-in-toss-api.toss.im'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error(
    'Invalid environment variables',
    parsed.error.flatten().fieldErrors,
  );
  process.exit(1);
}

const env = parsed.data;

const codefApiBaseUrlByEnv = {
  sandbox: 'https://sandbox.codef.io',
  development: 'https://development.codef.io',
  production: 'https://api.codef.io',
} as const;

const codefOauthBaseUrlByEnv = {
  sandbox: 'https://oauth.codef.io',
  development: 'https://oauth.codef.io',
  production: 'https://oauth.codef.io',
} as const;

export const appEnv = {
  ...env,
  allowedOrigins: env.ALLOWED_ORIGINS
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
  codefApiBaseUrl: codefApiBaseUrlByEnv[env.CODEF_ENV],
  codefOauthBaseUrl: codefOauthBaseUrlByEnv[env.CODEF_ENV],
  tossPayBaseUrl: env.TOSS_PAY_BASE_URL.replace(/\/$/, ''),
};
