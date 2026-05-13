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

function normalizeDateTime(item: CodefApprovalItem): string {
  const date = item.approvalDate ?? item.approvalDay ?? '';
  const time = (item.approvalTime ?? '000000').padEnd(6, '0').slice(0, 6);
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
    const approvalAmount = parseNumber(item.approvalAmount);
    const cardNoMasked = item.resCardNo ?? item.cardNo ?? '';
    const merchantName = item.merchantName?.trim() || '알 수 없는 가맹점';
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
      amountKrw: parseNumber(item.billingAmount) || approvalAmount,
      approvalAmount,
      approvalStatus: item.approvalStatus ?? 'UNKNOWN',
      cardName: item.cardName ?? '',
      cardNoMasked,
      approvalNo: item.approvalNo,
      originAmount: parseNumber(item.originAmount) || undefined,
      originCurrency: item.originCurrency || undefined,
      billingAmountKrw: parseNumber(item.billingAmount) || undefined,
      billingCurrency: item.billingCurrency || undefined,
      paymentType: item.paymentType || undefined,
      installmentMonths: parseNumber(item.installmentMonths) || undefined,
      dedupeKey,
      rawPayload: item as Record<string, unknown>,
      createdAt: now,
      updatedAt: now,
    };
  });
}
