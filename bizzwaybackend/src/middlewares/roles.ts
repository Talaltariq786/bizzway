import type { RequestHandler } from 'express';
import type { Role } from '../types/auth.js';

export function requireRoles(...allowed: Role[]): RequestHandler {
  return (req, res, next) => {
    const roles = req.auth?.roles ?? [];
    const ok = allowed.some((r) => roles.includes(r));
    if (!ok) return res.status(403).json({ error: 'forbidden' });
    return next();
  };
}

