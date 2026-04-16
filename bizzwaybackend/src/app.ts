import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';

import { errorHandler } from './middlewares/error.js';
import type { Env } from './config/env.js';
import { authRouter } from './modules/auth/auth.routes.js';
import { meRouter } from './modules/me/me.routes.js';
import { businessRouter } from './modules/business/business.routes.js';
import { ordersRouter } from './modules/orders/orders.routes.js';
import { locationRouter } from './modules/location/location.routes.js';
import { chatRouter } from './modules/chat/chat.routes.js';
import { bookingsRouter } from './modules/bookings/bookings.routes.js';
import { notificationsRouter } from './modules/notifications/notifications.routes.js';
import { paymentsRouter } from './modules/payments/payments.routes.js';
import { ridersRouter } from './modules/riders/riders.routes.js';
import { serviceProvidersRouter } from './modules/service-providers/service_providers.routes.js';
import { uploadsRouter } from './modules/uploads/uploads.routes.js';
import { pushRouter } from './modules/push/push.routes.js';

export function createApp(opts: { corsOrigin?: string; env: Env }) {
  const app = express();

  app.use(helmet());
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true }));
  app.use(
    cors({
      origin: opts.corsOrigin ?? true,
      credentials: true,
    }),
  );
  app.use(morgan('dev'));

  /** Open in browser: lists clickable local links (same host/port as this request). */
  app.get('/', (_req, res) => {
    res.type('html').send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>Bizzway API</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 42rem; margin: 2rem auto; padding: 0 1rem; }
    h1 { font-size: 1.25rem; }
    a { color: #1565c0; }
    ul { line-height: 1.8; }
    code { background: #f5f5f5; padding: 0.1em 0.35em; border-radius: 4px; }
    p.muted { color: #555; font-size: 0.9rem; }
  </style>
</head>
<body>
  <h1>Bizzway backend (Node)</h1>
  <p class="muted">Ye page request wale hi host/port se links banati hai — phone pe Mac ka LAN IP + <code>:8080</code> use karo.</p>
  <ul>
    <li><a href="/health">GET /health</a> — JSON health check</li>
    <li><a href="/api/businesses">GET /api/businesses</a> — public business list (sample data ho to dikhega)</li>
  </ul>
  <p class="muted">Auth / orders wagaira <code>POST</code> + headers; Postman / app se test karein. Routes: <code>/api/auth/*</code>, <code>/api/me</code>, <code>/api/orders</code>, …</p>
</body>
</html>`);
  });

  app.get('/health', (_req, res) => {
    res.json({ ok: true, service: 'bizzway-backend' });
  });

  // API routes will be mounted here: /api/...
  app.use('/api/auth', authRouter(opts.env));
  app.use('/api/me', meRouter(opts.env));
  app.use('/api/businesses', businessRouter(opts.env));
  app.use('/api/orders', ordersRouter(opts.env));
  app.use('/api', locationRouter(opts.env));
  app.use('/api', chatRouter(opts.env));
  app.use('/api/bookings', bookingsRouter(opts.env));
  app.use('/api', notificationsRouter(opts.env));
  app.use('/api', paymentsRouter(opts.env));
  app.use('/api', ridersRouter(opts.env));
  app.use('/api', serviceProvidersRouter(opts.env));
  app.use('/api', uploadsRouter(opts.env));
  app.use('/api', pushRouter(opts.env));

  app.use(errorHandler);
  return app;
}

