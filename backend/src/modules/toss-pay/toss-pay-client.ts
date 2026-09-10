import { readFileSync } from 'node:fs';
import https from 'node:https';

import { appEnv } from '../../config/env.js';

export interface TossPayRequestOptions {
  method?: 'GET' | 'POST';
  path: string;
  body?: Record<string, unknown>;
  headers?: Record<string, string>;
}

export interface TossPayResponse<T = unknown> {
  statusCode: number;
  headers: Record<string, string | string[] | undefined>;
  body: T | string;
}

/**
 * HTTPS client for Apps in Toss server APIs.
 *
 * The certificate and private key are loaded only on the backend. They are
 * never bundled into Flutter Web or the .ait artifact.
 */
export class TossPayClient {
  private readonly agent: https.Agent;

  constructor() {
    if (!appEnv.TOSS_MTLS_CERT_PATH || !appEnv.TOSS_MTLS_KEY_PATH) {
      throw new Error(
        'TOSS_MTLS_CERT_PATH and TOSS_MTLS_KEY_PATH must be configured',
      );
    }

    this.agent = new https.Agent({
      cert: readFileSync(appEnv.TOSS_MTLS_CERT_PATH),
      key: readFileSync(appEnv.TOSS_MTLS_KEY_PATH),
      keepAlive: true,
    });
  }

  async request<T = unknown>(
    options: TossPayRequestOptions,
  ): Promise<TossPayResponse<T>> {
    const url = new URL(options.path, `${appEnv.tossPayBaseUrl}/`);
    const body = options.body ? JSON.stringify(options.body) : undefined;
    const requestHeaders: Record<string, string> = {
      Accept: 'application/json',
      ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...(body ? { 'Content-Length': Buffer.byteLength(body).toString() } : {}),
      ...(options.headers ?? {}),
    };

    return new Promise((resolve, reject) => {
      const request = https.request(
        url,
        {
          agent: this.agent,
          method: options.method ?? 'GET',
          headers: requestHeaders,
        },
        (response) => {
          const chunks: Buffer[] = [];

          response.on('data', (chunk: Buffer) => chunks.push(chunk));
          response.on('end', () => {
            const rawBody = Buffer.concat(chunks).toString('utf8');
            let parsedBody: T | string = rawBody;

            if (rawBody.trim()) {
              try {
                parsedBody = JSON.parse(rawBody) as T;
              } catch {
                // Keep non-JSON error bodies available to the caller.
              }
            }

            resolve({
              statusCode: response.statusCode ?? 0,
              headers: response.headers,
              body: parsedBody,
            });
          });
        },
      );

      request.on('error', reject);
      if (body) {
        request.write(body);
      }
      request.end();
    });
  }
}
