import type { CardConnection } from '../modules/cards/cards-types.js';

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
