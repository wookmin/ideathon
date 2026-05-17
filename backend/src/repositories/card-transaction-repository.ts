import type { CollectionReference, QueryDocumentSnapshot } from '@google-cloud/firestore';

import type { CardTransaction } from '../modules/cards/cards-types.js';
import { getFirestoreClient } from './firestore-client.js';

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

export class FirestoreCardTransactionRepository
  implements CardTransactionRepository {
  private readonly collection: CollectionReference<CardTransaction>;

  constructor() {
    this.collection = getFirestoreClient().collection(
      'cardTransactions',
    ) as CollectionReference<CardTransaction>;
  }

  async upsertMany(
    transactions: CardTransaction[],
  ): Promise<{ inserted: number; updated: number }> {
    if (transactions.length === 0) {
      return { inserted: 0, updated: 0 };
    }

    let inserted = 0;
    let updated = 0;
    const firestore = getFirestoreClient();

    for (let index = 0; index < transactions.length; index += 250) {
      const chunk = transactions.slice(index, index + 250);
      const refs = chunk.map((transaction) =>
        this.collection.doc(transaction.dedupeKey),
      );
      const snapshots = await firestore.getAll(...refs);
      const batch = firestore.batch();

      chunk.forEach((transaction, offset) => {
        const existing = snapshots[offset];
        if (existing?.exists) {
          const current = existing.data() as CardTransaction;
          batch.set(this.collection.doc(transaction.dedupeKey), {
            ...current,
            ...transaction,
            id: current.id,
            createdAt: current.createdAt,
            updatedAt: new Date().toISOString(),
          });
          updated += 1;
          return;
        }

        batch.set(this.collection.doc(transaction.dedupeKey), transaction);
        inserted += 1;
      });

      await batch.commit();
    }

    return { inserted, updated };
  }

  async findAllByUserId(params: {
    userId: string;
    startDate?: string;
    endDate?: string;
    organization?: string;
  }): Promise<CardTransaction[]> {
    const snapshot = await this.collection.where('userId', '==', params.userId).get();

    return snapshot.docs
      .map((doc: QueryDocumentSnapshot<CardTransaction>) => doc.data())
      .filter((transaction) => {
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
    const snapshot = await this.collection.where('userId', '==', userId).get();
    const matches = snapshot.docs.filter(
      (doc) => doc.data().connectionId === connectionId,
    );

    if (matches.length === 0) {
      return;
    }

    const firestore = getFirestoreClient();
    for (let index = 0; index < matches.length; index += 250) {
      const chunk = matches.slice(index, index + 250);
      const batch = firestore.batch();
      for (const doc of chunk) {
        batch.delete(doc.ref);
      }
      await batch.commit();
    }
  }
}
