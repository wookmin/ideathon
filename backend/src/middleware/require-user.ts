import type { NextFunction, Request, Response } from 'express';

import { AppError } from '../utils/app-error.js';

export function requireUser(req: Request, _res: Response, next: NextFunction) {
  const userId = req.header('x-user-id')?.trim();

  if (!userId) {
    next(
      new AppError(
        401,
        'UNAUTHENTICATED',
        'Missing x-user-id header. Replace this with real auth before production.',
      ),
    );
    return;
  }

  req.userId = userId;
  next();
}
