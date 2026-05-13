import { Router } from 'express';

export const healthRouter = Router();

healthRouter.get('/', (_req, res) => {
  res.json({
    ok: true,
    service: 'tripreceipt-codef-backend',
    now: new Date().toISOString(),
  });
});
