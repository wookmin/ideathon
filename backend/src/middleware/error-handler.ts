import type { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';

import { AppError } from '../utils/app-error.js';

export function errorHandler(
  error: unknown,
  req: Request,
  res: Response,
  _next: NextFunction,
) {
  if (error instanceof ZodError) {
    console.error('[request-validation-error]', {
      method: req.method,
      path: req.originalUrl,
      details: error.flatten(),
    });
    res.status(400).json({
      error: {
        code: 'INVALID_REQUEST',
        message: 'Request validation failed',
        details: error.flatten(),
      },
    });
    return;
  }

  if (error instanceof AppError) {
    console.error('[app-error]', {
      method: req.method,
      path: req.originalUrl,
      code: error.code,
      message: error.message,
      details: error.details,
    });
    res.status(error.statusCode).json({
      error: {
        code: error.code,
        message: error.message,
        details: error.details ?? null,
      },
    });
    return;
  }

  console.error(error);

  res.status(500).json({
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: 'An unexpected error occurred',
    },
  });
}
