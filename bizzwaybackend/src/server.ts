import 'dotenv/config';

import { createApp } from './app.js';
import { loadEnv } from './config/env.js';
import { connectMongo } from './db/mongoose.js';

async function main() {
  const env = loadEnv(process.env);

  try {
    await connectMongo(env.MONGODB_URI);
  } catch (err) {
    console.error('MongoDB connection failed. Start MongoDB then re-run.', err);
    process.exit(1);
  }

  const app = createApp({ corsOrigin: env.CORS_ORIGIN, env });
  const host = process.env.HOST ?? '0.0.0.0';
  app.listen(env.PORT, host, () => {
    console.log(`API listening on http://${host}:${env.PORT}`);
  });
}

main().catch((err) => {
  console.error('Fatal startup error', err);
  process.exit(1);
});

