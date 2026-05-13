import crypto from 'node:crypto';

import { decrypt, encrypt } from '../../utils/crypto.js';
import { AppError } from '../../utils/app-error.js';
import type { CardConnectionRepository } from '../../repositories/card-connection-repository.js';
import type { CardTransactionRepository } from '../../repositories/card-transaction-repository.js';
import { CodefClient } from '../codef/codef-client.js';
import { normalizeApprovalItems } from './transaction-normalizer.js';
import type {
  CardConnection,
  CreateConnectionInput,
  ListTransactionsInput,
  SyncTransactionsInput,
} from './cards-types.js';

export class CardsService {
  constructor(
    private readonly codefClient: CodefClient,
    private readonly cardConnectionRepository: CardConnectionRepository,
    private readonly cardTransactionRepository: CardTransactionRepository,
  ) {}

  async createConnection(userId: string, input: CreateConnectionInput) {
    const response = await this.codefClient.createConnection(input);
    const connectedId = response.data?.connectedId;

    if (!connectedId) {
      throw new AppError(502, 'CODEF_CONNECTED_ID_MISSING', 'CODEF did not return connectedId');
    }

    const now = new Date().toISOString();
    const connection: CardConnection = {
      id: crypto.randomUUID(),
      userId,
      organization: input.organization,
      organizationName: input.organizationName ?? input.organization,
      loginType: input.loginType,
      encryptedConnectedId: encrypt(connectedId),
      status: 'ACTIVE',
      createdAt: now,
      updatedAt: now,
    };

    await this.cardConnectionRepository.create(connection);

    return this.toPublicConnection(connection);
  }

  async listConnections(userId: string) {
    const connections = await this.cardConnectionRepository.findAllByUserId(userId);
    return connections.map((connection) => this.toPublicConnection(connection));
  }

  async deleteConnection(userId: string, connectionId: string) {
    const connection = await this.cardConnectionRepository.findById(userId, connectionId);
    if (!connection) {
      throw new AppError(404, 'CONNECTION_NOT_FOUND', 'Card connection not found');
    }

    await this.cardTransactionRepository.deleteByConnectionId(userId, connectionId);
    await this.cardConnectionRepository.delete(userId, connectionId);
  }

  async syncTransactions(
    userId: string,
    connectionId: string,
    input: SyncTransactionsInput,
  ) {
    const connection = await this.cardConnectionRepository.findById(userId, connectionId);
    if (!connection) {
      throw new AppError(404, 'CONNECTION_NOT_FOUND', 'Card connection not found');
    }

    const connectedId = decrypt(connection.encryptedConnectedId);
    const response = await this.codefClient.fetchApprovalList({
      connectedId,
      organization: connection.organization,
      startDate: input.startDate,
      endDate: input.endDate,
      cardNo: input.cardNo,
    });
    const items =
      response.data?.approvalList ??
      response.data?.resApprovalList ??
      [];
    const normalized = normalizeApprovalItems({ connection, items });
    const result = await this.cardTransactionRepository.upsertMany(normalized);

    const updatedConnection: CardConnection = {
      ...connection,
      lastSyncedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    await this.cardConnectionRepository.update(updatedConnection);

    return {
      connection: this.toPublicConnection(updatedConnection),
      syncResult: {
        inserted: result.inserted,
        updated: result.updated,
        fetched: normalized.length,
      },
      transactions: normalized,
    };
  }

  async listTransactions(userId: string, query: ListTransactionsInput) {
    return this.cardTransactionRepository.findAllByUserId({
      userId,
      startDate: query.startDate,
      endDate: query.endDate,
      organization: query.organization,
    });
  }

  private toPublicConnection(connection: CardConnection) {
    return {
      id: connection.id,
      organization: connection.organization,
      organizationName: connection.organizationName,
      loginType: connection.loginType,
      status: connection.status,
      createdAt: connection.createdAt,
      updatedAt: connection.updatedAt,
      lastSyncedAt: connection.lastSyncedAt,
    };
  }
}
