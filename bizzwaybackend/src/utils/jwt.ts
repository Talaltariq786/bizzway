import jwt from 'jsonwebtoken';
import type { JwtPayload } from '../types/auth.js';

export function signAccessToken(
  payload: JwtPayload,
  opts: { secret: string; ttl: jwt.SignOptions['expiresIn'] },
) {
  return jwt.sign(payload, opts.secret, { expiresIn: opts.ttl });
}

export function signRefreshToken(
  payload: JwtPayload,
  opts: { secret: string; ttl: jwt.SignOptions['expiresIn'] },
) {
  return jwt.sign(payload, opts.secret, { expiresIn: opts.ttl });
}

export function verifyAccessToken(token: string, secret: string): JwtPayload {
  const decoded = jwt.verify(token, secret);
  if (typeof decoded !== 'object' || decoded === null) throw new Error('Invalid token');
  return decoded as JwtPayload;
}

