import crypto from 'node:crypto';

import type { CodefApprovalItem } from '../codef/codef-types.js';
import type { CardConnection, CardTransaction } from './cards-types.js';

function parseNumber(input: string | number | undefined): number {
  if (typeof input === 'number') {
    return input;
  }
  if (!input) {
    return 0;
  }
  const normalized = input.replace(/[^\d.-]/g, '');
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : 0;
}

function pickFirstString(
  item: CodefApprovalItem,
  keys: Array<keyof CodefApprovalItem>,
): string {
  for (const key of keys) {
    const value = item[key];
    if (typeof value === 'string' && value.trim().length > 0) {
      return value.trim();
    }
  }
  return '';
}

function pickFirstNumber(
  item: CodefApprovalItem,
  keys: Array<keyof CodefApprovalItem>,
): number {
  for (const key of keys) {
    const value = item[key];
    const parsed =
      typeof value === 'number'
        ? value
        : (typeof value === 'string' ? parseNumber(value) : 0);
    if (parsed !== 0) {
      return parsed;
    }
  }
  return 0;
}

function normalizeDateTime(item: CodefApprovalItem): string {
  const date = pickFirstString(item, ['approvalDate', 'approvalDay', 'resUsedDate']);
  const rawTime = pickFirstString(item, ['approvalTime', 'resUsedTime']);
  const time = (rawTime || '000000').padEnd(6, '0').slice(0, 6);
  if (!/^\d{8}$/.test(date)) {
    return new Date().toISOString();
  }

  const iso = `${date.slice(0, 4)}-${date.slice(4, 6)}-${date.slice(6, 8)}T${time.slice(0, 2)}:${time.slice(2, 4)}:${time.slice(4, 6)}+09:00`;
  return new Date(iso).toISOString();
}

function buildDedupeKey(
  connectionId: string,
  approvedAt: string,
  merchantName: string,
  approvalAmount: number,
  cardNoMasked: string,
) {
  return crypto
    .createHash('sha256')
    .update(
      JSON.stringify({
        connectionId,
        approvedAt,
        merchantName,
        approvalAmount,
        cardNoMasked,
      }),
    )
    .digest('hex');
}

export function normalizeApprovalItems(params: {
  connection: CardConnection;
  items: CodefApprovalItem[];
}) {
  return params.items.map<CardTransaction>((item) => {
    const approvedAt = normalizeDateTime(item);
    const approvalAmount = pickFirstNumber(item, [
      'approvalAmount',
      'resUsedAmount',
      'billingAmount',
    ]);
    const cardNoMasked = pickFirstString(item, ['resCardNo', 'cardNo']);
    const merchantName =
      pickFirstString(item, ['merchantName', 'resMemberStoreName']) || '알 수 없는 가맹점';
    const dedupeKey = buildDedupeKey(
      params.connection.id,
      approvedAt,
      merchantName,
      approvalAmount,
      cardNoMasked,
    );
    const now = new Date().toISOString();

    return {
      id: crypto.randomUUID(),
      userId: params.connection.userId,
      connectionId: params.connection.id,
      organization: params.connection.organization,
      organizationName: params.connection.organizationName,
      approvedAt,
      merchantName,
      amountKrw:
        pickFirstNumber(item, ['billingAmount', 'approvalAmount', 'resUsedAmount']) ||
        approvalAmount,
      approvalAmount,
      approvalStatus:
        pickFirstString(item, ['approvalStatus', 'resApprovalStatus', 'resCancelYN']) ||
        'UNKNOWN',
      cardName: pickFirstString(item, ['cardName', 'resCardName']),
      cardNoMasked,
      approvalNo: pickFirstString(item, ['approvalNo', 'resApprovalNo']) || undefined,
      originAmount: pickFirstNumber(item, ['originAmount']) || undefined,
      originCurrency: item.originCurrency || undefined,
      billingAmountKrw: pickFirstNumber(item, ['billingAmount', 'resUsedAmount']) || undefined,
      billingCurrency: item.billingCurrency || undefined,
      paymentType: pickFirstString(item, ['paymentType', 'resPaymentType']) || undefined,
      installmentMonths:
        pickFirstNumber(item, ['installmentMonths', 'resInstallmentMonth']) || undefined,
      dedupeKey,
      rawPayload: item as Record<string, unknown>,
      createdAt: now,
      updatedAt: now,
    };
  });
}
