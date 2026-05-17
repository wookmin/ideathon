import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';

import { appEnv } from './config/env.js';
import { errorHandler } from './middleware/error-handler.js';
import { requireUser } from './middleware/require-user.js';
import { CardsService } from './modules/cards/cards-service.js';
import { CodefClient } from './modules/codef/codef-client.js';
import { PlacesService } from './modules/places/places-service.js';
import { FirestoreCardConnectionRepository } from './repositories/card-connection-repository.js';
import { FirestoreCardTransactionRepository } from './repositories/card-transaction-repository.js';
import { createCardsRouter } from './routes/cards.js';
import { createPlacesRouter } from './routes/places.js';
import { healthRouter } from './routes/health.js';

const codefClient = new CodefClient();
const cardConnectionRepository = new FirestoreCardConnectionRepository();
const cardTransactionRepository = new FirestoreCardTransactionRepository();

const cardsService = new CardsService(
  codefClient,
  cardConnectionRepository,
  cardTransactionRepository,
);
const placesService = new PlacesService();

export function createApp() {
  const app = express();

  app.use(helmet());

  app.use(
    cors({
      origin(origin, callback) {
        if (
          !origin ||
          appEnv.allowedOrigins.length === 0 ||
          appEnv.allowedOrigins.includes(origin)
        ) {
          callback(null, true);
          return;
        }

        callback(new Error(`Origin ${origin} is not allowed by CORS`));
      },
    }),
  );

  app.use(express.json());

  app.use(
    morgan(appEnv.NODE_ENV === 'production' ? 'combined' : 'dev'),
  );

  app.use('/health', healthRouter);
  app.use('/api/v1/places', requireUser, createPlacesRouter(placesService));

  app.use('/api/v1', createCardsRouter(cardsService));

  app.use(errorHandler);

  return app;
}
