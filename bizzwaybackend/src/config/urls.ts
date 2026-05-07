import type { Env } from './env.js';

/** Base URL for callbacks; set PUBLIC_APP_BASE_URL in production. */
export function publicAppBaseUrl(env: Env) {
  return (env.PUBLIC_APP_BASE_URL ?? 'http://127.0.0.1:8080').replace(/\/$/, '');
}
