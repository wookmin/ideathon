import { Router } from 'express';

import { requireUser } from '../middleware/require-user.js';
import type { CardsService } from '../modules/cards/cards-service.js';
import {
  createConnectionSchema,
  listCardsSchema,
  listTransactionsSchema,
  syncTransactionsSchema,
} from '../modules/cards/cards-types.js';
import { asyncHandler } from '../utils/async-handler.js';

export function createCardsRouter(cardsService: CardsService) {
  const router = Router();

  const getSingleParam = (value: string | string[]) =>
    Array.isArray(value) ? value[0] ?? '' : value;

  router.use(requireUser);

  router.get(
    '/card/connections',
    asyncHandler(async (req, res) => {
      const connections = await cardsService.listConnections(req.userId!);
      res.json({ connections });
    }),
  );

  router.post(
    '/card/connections',
    asyncHandler(async (req, res) => {
      const input = createConnectionSchema.parse(req.body);
      const connection = await cardsService.createConnection(req.userId!, input);
      res.status(201).json({ connection });
    }),
  );

  router.delete(
    '/card/connections/:connectionId',
    asyncHandler(async (req, res) => {
      await cardsService.deleteConnection(req.userId!, getSingleParam(req.params.connectionId));
      res.status(204).send();
    }),
  );

  router.get(
    '/card/connections/:connectionId/cards',
    asyncHandler(async (req, res) => {
      const query = listCardsSchema.parse(req.query);
      const cards = await cardsService.listCards(
        req.userId!,
        getSingleParam(req.params.connectionId),
        query,
      );
      res.json({ cards });
    }),
  );

  router.post(
    '/card/connections/:connectionId/sync',
    asyncHandler(async (req, res) => {
      const input = syncTransactionsSchema.parse(req.body);
      const result = await cardsService.syncTransactions(
        req.userId!,
        getSingleParam(req.params.connectionId),
        input,
      );
      res.json(result);
    }),
  );

  router.get(
    '/transactions',
    asyncHandler(async (req, res) => {
      const query = listTransactionsSchema.parse(req.query);
      const transactions = await cardsService.listTransactions(req.userId!, query);
      res.json({ transactions });
    }),
  );

  return router;
}
