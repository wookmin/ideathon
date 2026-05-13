import { z } from 'zod';

export const createConnectionSchema = z.object({
  organization: z.string().min(1),
  organizationName: z.string().min(1).optional(),
  loginType: z.enum(['0', '1']).default('1'),
  credentials: z.object({
    id: z.string().min(1),
    password: z.string().min(1),
  }),
});

export const syncTransactionsSchema = z.object({
  startDate: z.string().regex(/^\d{8}$/, 'Use YYYYMMDD format'),
  endDate: z.string().regex(/^\d{8}$/, 'Use YYYYMMDD format'),
  cardNo: z.string().min(1).optional(),
});

export const listTransactionsSchema = z.object({
  startDate: z.string().regex(/^\d{8}$/).optional(),
  endDate: z.string().regex(/^\d{8}$/).optional(),
  organization: z.string().optional(),
});

export type CreateConnectionInput = z.infer<typeof createConnectionSchema>;
export type SyncTransactionsInput = z.infer<typeof syncTransactionsSchema>;
export type ListTransactionsInput = z.infer<typeof listTransactionsSchema>;

export interface CardConnection {
  id: string;
  userId: string;
  organization: string;
  organizationName: string;
  loginType: '0' | '1';
  encryptedConnectedId: string;
  status: 'ACTIVE' | 'REAUTH_REQUIRED' | 'DISCONNECTED';
  createdAt: string;
  updatedAt: string;
  lastSyncedAt?: string;
}

export interface CardTransaction {
  id: string;
  userId: string;
  connectionId: string;
  organization: string;
  organizationName: string;
  approvedAt: string;
  merchantName: string;
  amountKrw: number;
  approvalAmount: number;
  approvalStatus: string;
  cardName: string;
  cardNoMasked: string;
  approvalNo?: string;
  originAmount?: number;
  originCurrency?: string;
  billingAmountKrw?: number;
  billingCurrency?: string;
  paymentType?: string;
  installmentMonths?: number;
  dedupeKey: string;
  rawPayload: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}
