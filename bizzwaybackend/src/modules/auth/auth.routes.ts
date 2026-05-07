import { Router } from 'express';
import * as jwt from 'jsonwebtoken';

import type { Env } from '../../config/env.js';
import { UserModel } from '../../models/User.js';
import type { JwtPayload, Role } from '../../types/auth.js';
import { hashPassword, verifyPassword } from '../../utils/password.js';
import { signAccessToken, signRefreshToken } from '../../utils/jwt.js';
import { LoginSchema, RefreshSchema, RegisterSchema } from './auth.schemas.js';

export function authRouter(env: Env) {
  const r = Router();

  r.post('/register', async (req, res, next) => {
    try {
      const body = RegisterSchema.parse(req.body);

      const passwordHash = await hashPassword(body.password);
      const roles: Role[] = [body.role];
      const fullName = body.name.trim();

      const user = await UserModel.create({
        phone: body.phone?.trim(),
        email: body.email?.trim()?.toLowerCase(),
        passwordHash,
        roles,
        name: fullName,
      });

      const payload: JwtPayload = { sub: user._id.toString(), roles };
      const accessToken = signAccessToken(payload, {
        secret: env.JWT_ACCESS_SECRET,
        ttl: env.JWT_ACCESS_TTL as any,
      });
      const refreshToken = signRefreshToken(payload, {
        secret: env.JWT_REFRESH_SECRET,
        ttl: env.JWT_REFRESH_TTL as any,
      });

      return res.status(201).json({
        user: { id: user._id.toString(), roles: user.roles, phone: user.phone, email: user.email, name: user.name },
        accessToken,
        refreshToken,
      });
    } catch (e) {
      return next(e);
    }
  });

  r.post('/login', async (req, res, next) => {
    try {
      const body = LoginSchema.parse(req.body);
      const ident = body.identifier.trim();

      const user = await UserModel.findOne({
        $or: [{ phone: ident }, { email: ident.toLowerCase() }],
      }).select('+passwordHash');

      if (!user) return res.status(401).json({ error: 'invalid_credentials' });

      const ok = await verifyPassword(body.password, (user as any).passwordHash);
      if (!ok) return res.status(401).json({ error: 'invalid_credentials' });

      const payload: JwtPayload = { sub: user._id.toString(), roles: user.roles };
      const accessToken = signAccessToken(payload, {
        secret: env.JWT_ACCESS_SECRET,
        ttl: env.JWT_ACCESS_TTL as any,
      });
      const refreshToken = signRefreshToken(payload, {
        secret: env.JWT_REFRESH_SECRET,
        ttl: env.JWT_REFRESH_TTL as any,
      });

      return res.json({
        user: { id: user._id.toString(), roles: user.roles, phone: user.phone, email: user.email, name: user.name },
        accessToken,
        refreshToken,
      });
    } catch (e) {
      return next(e);
    }
  });

  r.post('/refresh', async (req, res) => {
    try {
      const body = RefreshSchema.parse(req.body);
      const decoded = jwt.verify(body.refreshToken, env.JWT_REFRESH_SECRET);
      if (typeof decoded !== 'object' || decoded === null) {
        return res.status(401).json({ error: 'invalid_refresh' });
      }
      const payload = decoded as JwtPayload;

      // Optional: verify user still exists
      const user = await UserModel.findById(payload.sub);
      if (!user) return res.status(401).json({ error: 'invalid_refresh' });

      const nextPayload: JwtPayload = { sub: user._id.toString(), roles: user.roles };
      const accessToken = signAccessToken(nextPayload, {
        secret: env.JWT_ACCESS_SECRET,
        ttl: env.JWT_ACCESS_TTL as any,
      });
      const refreshToken = signRefreshToken(nextPayload, {
        secret: env.JWT_REFRESH_SECRET,
        ttl: env.JWT_REFRESH_TTL as any,
      });

      return res.json({ accessToken, refreshToken });
    } catch {
      return res.status(401).json({ error: 'invalid_refresh' });
    }
  });

  r.post('/logout', (_req, res) => {
    // Stateless JWT: client just deletes tokens.
    res.json({ ok: true });
  });

  return r;
}

