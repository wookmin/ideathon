import type { CardTransaction } from '../modules/cards/cards-types.js';

export interface CardTransactionRepository {
  upsertMany(transactions: CardTransaction[]): Promise<{ inserted: number; updated: number }>;
  findAllByUserId(params: {
    userId: string;
    startDate?: string;
    endDate?: string;
    organization?: string;
  }): Promise<CardTransaction[]>;
  deleteByConnectionId(userId: string, connectionId: string): Promise<void>;
}

export class InMemoryCardTransactionRepository implements CardTransactionRepository {
  private readonly transactionsByDedupeKey = new Map<string, CardTransaction>();

  async upsertMany(
    transactions: CardTransaction[],
  ): Promise<{ inserted: number; updated: number }> {
    let inserted = 0;
    let updated = 0;

    for (const transaction of transactions) {
      const existing = this.transactionsByDedupeKey.get(transaction.dedupeKey);
      if (existing) {
        this.transactionsByDedupeKey.set(transaction.dedupeKey, {
          ...existing,
          ...transaction,
          id: existing.id,
          createdAt: existing.createdAt,
          updatedAt: new Date().toISOString(),
        });
        updated += 1;
      } else {
        this.transactionsByDedupeKey.set(transaction.dedupeKey, transaction);
        inserted += 1;
      }
    }

    return { inserted, updated };
  }

  async findAllByUserId(params: {
    userId: string;
    startDate?: string;
    endDate?: string;
    organization?: string;
  }): Promise<CardTransaction[]> {
    return [...this.transactionsByDedupeKey.values()]
      .filter((transaction) => {
        if (transaction.userId !== params.userId) {
          return false;
        }

        const compactDate = transaction.approvedAt.slice(0, 10).replaceAll('-', '');
        if (params.startDate && compactDate < params.startDate) {
          return false;
        }
        if (params.endDate && compactDate > params.endDate) {
          return false;
        }
        if (params.organization && transaction.organization !== params.organization) {
          return false;
        }
        return true;
      })
      .sort((a, b) => b.approvedAt.localeCompare(a.approvedAt));
  }

  async deleteByConnectionId(userId: string, connectionId: string): Promise<void> {
    for (const [key, transaction] of this.transactionsByDedupeKey.entries()) {
      if (transaction.userId === userId && transaction.connectionId === connectionId) {
        this.transactionsByDedupeKey.delete(key);
      }
    }
  }
}
