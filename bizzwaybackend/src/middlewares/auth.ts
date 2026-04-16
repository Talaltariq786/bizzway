import type { RequestHandler } from 'express';
import { z } from 'zod';

import type { Env } from '../config/env.js';
import type { JwtPayload } from '../types/auth.js';
import { verifyAccessToken } from '../utils/jwt.js';

const HeaderSchema = z.string().min(1);

declare module 'express-serve-static-core' {
  interface Request {
    auth?: JwtPayload;
  }
}

export function requireAuth(env: Env): RequestHandler {
  return (req, res, next) => {
    try {
      const authHeader = HeaderSchema.safeParse(req.headers.authorization);
      if (!authHeader.success) {
        return res.status(401).json({ error: 'unauthorized' });
      }
      const [scheme, token] = authHeader.data.split(' ');
      if (scheme !== 'Bearer' || !token) {
        return res.status(401).json({ error: 'unauthorized' });
      }
      req.auth = verifyAccessToken(token, env.JWT_ACCESS_SECRET);
      return next();
    } catch {
      return res.status(401).json({ error: 'unauthorized' });
    }
  };
}

