import type { ErrorRequestHandler } from 'express';
import mongoose from 'mongoose';
import { MongoServerError } from 'mongodb';
import { ZodError } from 'zod';

const exposeDetails = process.env.NODE_ENV !== 'production';

/** Mongo duplicate key (E11000) — same phone/email as existing user. */
function duplicateIndexField(err: unknown): 'phone' | 'email' | null {
  const e = err as {
    code?: number;
    keyPattern?: Record<string, unknown>;
    message?: string;
  };
  if (e.code !== 11000) return null;
  if (e.keyPattern && 'phone' in e.keyPattern) return 'phone';
  if (e.keyPattern && 'email' in e.keyPattern) return 'email';
  const msg = e.message ?? '';
  if (msg.includes('phone_') || msg.includes('"phone"')) return 'phone';
  if (msg.includes('email_') || msg.includes('"email"')) return 'email';
  return null;
}

export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  if (err instanceof ZodError) {
    return res.status(400).json({
      error: 'validation_error',
      issues: err.issues.map((i) => ({
        path: i.path.join('.'),
        message: i.message,
      })),
    });
  }

  const dup = duplicateIndexField(err);
  if (dup === 'phone') {
    return res.status(409).json({
      error: 'duplicate_phone',
      message:
        'Yeh phone number pehle se register hai. Login karein ya naya number use karein.',
    });
  }
  if (dup === 'email') {
    return res.status(409).json({
      error: 'duplicate_email',
      message:
        'Yeh email pehle se register hai. Login karein ya nayi email use karein.',
    });
  }

  if (err instanceof mongoose.Error.ValidationError) {
    const first = Object.values(err.errors)[0];
    return res.status(400).json({
      error: 'validation_error',
      message: first?.message ?? 'Invalid data',
    });
  }

  if (err instanceof mongoose.Error.CastError) {
    return res.status(400).json({
      error: 'invalid_id',
      message: 'ID format sahi nahi hai.',
    });
  }

  if (err instanceof MongoServerError && err.code !== 11000) {
    console.error('[mongo]', err.code, err.message);
    return res.status(503).json({
      error: 'database_error',
      message: exposeDetails
        ? err.message
        : 'Database abhi available nahi. MongoDB chal raha hai? Dobara try karein.',
    });
  }

  const rawMessage =
    err instanceof Error ? err.message : 'Unexpected server error';
  console.error('[bizzway-api] internal_error', err);
  if (err instanceof Error && err.stack) {
    console.error(err.stack);
  }

  return res.status(500).json({
    error: 'internal_error',
    message: exposeDetails
      ? rawMessage
      : 'Server masla aa gaya. Terminal / logs check karein. Thori dair baad try karein.',
  });
};

