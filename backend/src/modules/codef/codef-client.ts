import { Buffer } from 'node:buffer';

import { appEnv } from '../../config/env.js';
import { AppError } from '../../utils/app-error.js';
import { encryptForCodef } from '../../utils/codef-rsa.js';
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
  birthDate: string;
  inquiryType: string;
  orderBy: string;
  cardNo?: string;
}

export class CodefClient {
  private accessTokenCache?: AccessTokenCache;

  async createConnection(input: CreateConnectionInput) {
    const encryptedPassword = encryptForCodef(input.credentials.password);
    const body = {
      accountList: [
        {
          countryCode: 'KR',
          businessType: 'CD',
          clientType: 'P',
          organization: input.organization,
          loginType: input.loginType,
          id: input.credentials.id,
          password: encryptedPassword,
        },
      ],
    };

    return this.post<CodefAccountCreateData>('/v1/account/create', body);
  }

  async fetchCardList(params: {
    connectedId: string;
    organization: string;
    birthDate: string;
    inquiryType: string;
  }) {
    return this.post<CodefCardListData>('/v1/kr/card/p/account/card-list', {
      connectedId: params.connectedId,
      organization: params.organization,
      birthDate: params.birthDate,
      inquiryType: params.inquiryType,
    });
  }

  async fetchApprovalList(input: FetchApprovalListInput) {
    return this.post<CodefApprovalListData>('/v1/kr/card/p/account/approval-list', {
      connectedId: input.connectedId,
      organization: input.organization,
      birthDate: input.birthDate,
      inquiryType: input.inquiryType,
      orderBy: input.orderBy,
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
    const json = (await this.parseCodefResponse<T>(response)) as CodefResponse<T>;
    const code = json.result?.code;
    const message = json.result?.message ?? 'CODEF request failed';
    const extraMessage = json.result?.extraMessage;
    const combinedMessage =
      extraMessage && extraMessage.trim().length > 0
        ? `${message} - ${extraMessage}`
        : message;

    if (!response.ok) {
      throw new AppError(
        response.status,
        'CODEF_HTTP_ERROR',
        combinedMessage,
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

      throw new AppError(400, mappedCode, combinedMessage, json);
    }

    return json;
  }

  private async parseCodefResponse<T>(response: Response): Promise<CodefResponse<T>> {
    const rawText = await response.text();
    const normalizedText = this.normalizeCodefBody(rawText);

    try {
      return JSON.parse(normalizedText) as CodefResponse<T>;
    } catch (error) {
      throw new AppError(
        502,
        'CODEF_RESPONSE_PARSE_FAILED',
        'Failed to parse CODEF response body',
        {
          rawText,
          normalizedText,
          parseError: error instanceof Error ? error.message : String(error),
        },
      );
    }
  }

  private normalizeCodefBody(rawText: string): string {
    const trimmed = rawText.trim();
    if (!trimmed) {
      return '{}';
    }

    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return trimmed;
    }

    // Some CODEF environments return percent-encoded JSON.
    if (trimmed.startsWith('%7B') || trimmed.startsWith('%5B')) {
      return decodeURIComponent(trimmed);
    }

    // Some responses are wrapped as urlencoded payloads like data=%7B...%7D
    if (trimmed.includes('=')) {
      const params = new URLSearchParams(trimmed);
      const candidate =
        params.get('data') ??
        params.get('result') ??
        [...params.values()][0];
      if (candidate) {
        return decodeURIComponent(candidate);
      }
    }

    return trimmed;
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
      throw new AppError(
        502,
        'CODEF_OAUTH_FAILED',
        'Failed to get CODEF access token. Check CODEF_CLIENT_ID, CODEF_CLIENT_SECRET, and CODEF_ENV in backend/.env.',
        text,
      );
    }

    const json = (await response.json()) as {
      access_token?: string;
      expires_in?: number;
    };

    if (!json.access_token) {
      throw new AppError(
        502,
        'CODEF_OAUTH_FAILED',
        'CODEF access token missing from response',
        json,
      );
    }

    const expiresInMs = (json.expires_in ?? 60 * 60 * 24 * 7) * 1000;
    this.accessTokenCache = {
      accessToken: json.access_token,
      expiresAt: now + expiresInMs,
    };

    return json.access_token;
  }
}
