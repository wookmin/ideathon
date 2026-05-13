import { Buffer } from 'node:buffer';

import { appEnv } from '../../config/env.js';
import { AppError } from '../../utils/app-error.js';
import type {
  CodefAccountCreateData,
  CodefApprovalListData,
  CodefCardListData,
  CodefLoginType,
  CodefResponse,
} from './codef-types.js';

interface AccessTokenCache {
  accessToken: string;
  expiresAt: number;
}

interface CreateConnectionInput {
  organization: string;
  loginType: CodefLoginType;
  credentials: {
    id: string;
    password: string;
  };
}

interface FetchApprovalListInput {
  connectedId: string;
  organization: string;
  startDate: string;
  endDate: string;
  cardNo?: string;
}

export class CodefClient {
  private accessTokenCache?: AccessTokenCache;

  async createConnection(input: CreateConnectionInput) {
    const body = {
      accountList: [
        {
          countryCode: 'KR',
          businessType: 'CARD',
          clientType: 'P',
          organization: input.organization,
          loginType: input.loginType,
          id: input.credentials.id,
          password: input.credentials.password,
        },
      ],
    };

    return this.post<CodefAccountCreateData>('/v1/account/create', body);
  }

  async fetchCardList(connectedId: string, organization: string) {
    return this.post<CodefCardListData>('/v1/kr/card/p/account/card-list', {
      connectedId,
      organization,
    });
  }

  async fetchApprovalList(input: FetchApprovalListInput) {
    return this.post<CodefApprovalListData>('/v1/kr/card/p/account/approval-list', {
      connectedId: input.connectedId,
      organization: input.organization,
      startDate: input.startDate,
      endDate: input.endDate,
      ...(input.cardNo ? { cardNo: input.cardNo } : {}),
    });
  }

  private async post<T>(path: string, body: Record<string, unknown>): Promise<CodefResponse<T>> {
    const token = await this.getAccessToken();
    const response = await fetch(`${appEnv.codefApiBaseUrl}${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(body),
    });

    if (response.status === 401) {
      this.accessTokenCache = undefined;
      const refreshedToken = await this.getAccessToken();
      const retryResponse = await fetch(`${appEnv.codefApiBaseUrl}${path}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${refreshedToken}`,
        },
        body: JSON.stringify(body),
      });
      return this.handleResponse<T>(retryResponse);
    }

    return this.handleResponse<T>(response);
  }

  private async handleResponse<T>(response: Response): Promise<CodefResponse<T>> {
    const json = (await response.json()) as CodefResponse<T>;
    const code = json.result?.code;

    if (!response.ok) {
      throw new AppError(
        response.status,
        'CODEF_HTTP_ERROR',
        json.result?.message ?? 'CODEF request failed',
        json,
      );
    }

    if (code && code !== 'CF-00000') {
      const mappedCode =
        code === 'CF-00401'
          ? 'INVALID_CREDENTIALS'
          : code.startsWith('CF-')
            ? 'CODEF_REQUEST_FAILED'
            : code;

      throw new AppError(400, mappedCode, json.result?.message ?? 'CODEF request failed', json);
    }

    return json;
  }

  private async getAccessToken(): Promise<string> {
    const now = Date.now();
    if (this.accessTokenCache && this.accessTokenCache.expiresAt > now + 60_000) {
      return this.accessTokenCache.accessToken;
    }

    const response = await fetch(`${appEnv.codefOauthBaseUrl}/oauth/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        Authorization: `Basic ${Buffer.from(
          `${appEnv.CODEF_CLIENT_ID}:${appEnv.CODEF_CLIENT_SECRET}`,
        ).toString('base64')}`,
      },
      body: new URLSearchParams({
        grant_type: 'client_credentials',
        scope: 'read',
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new AppError(502, 'CODEF_OAUTH_FAILED', 'Failed to get CODEF access token', text);
    }

    const json = (await response.json()) as {
      access_token?: string;
      expires_in?: number;
    };

    if (!json.access_token) {
      throw new AppError(502, 'CODEF_OAUTH_FAILED', 'CODEF access token missing from response');
    }

    const expiresInMs = (json.expires_in ?? 60 * 60 * 24 * 7) * 1000;
    this.accessTokenCache = {
      accessToken: json.access_token,
      expiresAt: now + expiresInMs,
    };

    return json.access_token;
  }
}
