import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';

import { appEnv } from './config/env.js';
import { errorHandler } from './middleware/error-handler.js';
import { CardsService } from './modules/cards/cards-service.js';
import { CodefClient } from './modules/codef/codef-client.js';

import { PlacesService } from './modules/places/places-service.js';

import {
  InMemoryCardConnectionRepository,
} from './repositories/card-connection-repository.js';

import {
  InMemoryCardTransactionRepository,
} from './repositories/card-transaction-repository.js';

import { createCardsRouter } from './routes/cards.js';
import { createPlacesRouter } from './routes/places.js';
import { healthRouter } from './routes/health.js';

const codefClient = new CodefClient();

const cardConnectionRepository =
  new InMemoryCardConnectionRepository();

const cardTransactionRepository =
  new InMemoryCardTransactionRepository();

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
        // 브라우저 직접 접근 허용
        if (!origin) {
          callback(null, true);
          return;
        }

        // Flutter Web localhost 허용
        const isLocalhost =
          origin.startsWith('http://localhost:') ||
          origin.startsWith('http://127.0.0.1:');

        // 배포 주소 허용
        const isAllowedOrigin =
          appEnv.allowedOrigins.length === 0 ||
          appEnv.allowedOrigins.includes(origin);

        if (isLocalhost || isAllowedOrigin) {
          callback(null, true);
          return;
        }

        callback(
          new Error(
            `Origin ${origin} is not allowed by CORS`,
          ),
        );
      },

      credentials: true,
    }),
  );

  app.use(express.json());

  app.use(
    morgan(
      appEnv.NODE_ENV === 'production'
        ? 'combined'
        : 'dev',
    ),
  );

  app.use('/health', healthRouter);

  app.use(
    '/api/v1/places',
    createPlacesRouter(placesService),
  );

  app.use(
    '/api/v1',
    createCardsRouter(cardsService),
  );

  app.use(errorHandler);

  return app;
}