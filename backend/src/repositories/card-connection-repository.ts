import type { CollectionReference } from '@google-cloud/firestore';

import type { CardConnection } from '../modules/cards/cards-types.js';
import { getFirestoreClient } from './firestore-client.js';

export interface CardConnectionRepository {
  create(connection: CardConnection): Promise<void>;
  findById(userId: string, connectionId: string): Promise<CardConnection | null>;
  findAllByUserId(userId: string): Promise<CardConnection[]>;
  update(connection: CardConnection): Promise<void>;
  delete(userId: string, connectionId: string): Promise<void>;
}

export class InMemoryCardConnectionRepository implements CardConnectionRepository {
  private readonly connections = new Map<string, CardConnection>();

  async create(connection: CardConnection): Promise<void> {
    this.connections.set(connection.id, connection);
  }

  async findById(userId: string, connectionId: string): Promise<CardConnection | null> {
    const connection = this.connections.get(connectionId);
    if (!connection || connection.userId !== userId) {
      return null;
    }
    return connection;
  }

  async findAllByUserId(userId: string): Promise<CardConnection[]> {
    return [...this.connections.values()]
      .filter((connection) => connection.userId === userId)
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  }

  async update(connection: CardConnection): Promise<void> {
    this.connections.set(connection.id, connection);
  }

  async delete(userId: string, connectionId: string): Promise<void> {
    const existing = await this.findById(userId, connectionId);
    if (existing) {
      this.connections.delete(connectionId);
    }
  }
}

export class FirestoreCardConnectionRepository
  implements CardConnectionRepository {
  private readonly collection: CollectionReference<CardConnection>;

  constructor() {
    this.collection = getFirestoreClient().collection(
      'cardConnections',
    ) as CollectionReference<CardConnection>;
  }

  async create(connection: CardConnection): Promise<void> {
    await this.collection.doc(connection.id).set(connection);
  }

  async findById(
    userId: string,
    connectionId: string,
  ): Promise<CardConnection | null> {
    const snapshot = await this.collection.doc(connectionId).get();
    const connection = snapshot.data();
    if (!connection || connection.userId !== userId) {
      return null;
    }
    return connection;
  }

  async findAllByUserId(userId: string): Promise<CardConnection[]> {
    const snapshot = await this.collection.where('userId', '==', userId).get();
    return snapshot.docs
      .map((doc) => doc.data())
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  }

  async update(connection: CardConnection): Promise<void> {
    await this.collection.doc(connection.id).set(connection);
  }

  async delete(userId: string, connectionId: string): Promise<void> {
    const existing = await this.findById(userId, connectionId);
    if (existing) {
      await this.collection.doc(connectionId).delete();
    }
  }
}
