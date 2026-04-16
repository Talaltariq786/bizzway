# Bizzway Backend (Node.js + MongoDB)

## Setup

1) Copy env file:

```bash
cp .env.example .env
```

2) Edit `.env` and set:
- `MONGODB_URI`
- `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`

3) Install + run:

```bash
npm install
npm run dev
```

Health check:
- `GET http://localhost:8080/health`

## Core endpoints (MVP)

### Auth
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`

### Me
- `GET /api/me` (Bearer access token)
- `PATCH /api/me`
- `GET /api/me/addresses`
- `POST /api/me/addresses`
- `PATCH /api/me/addresses/:id/select`
- `DELETE /api/me/addresses/:id`

### Businesses + Products
- `POST /api/businesses` (owner)
- `GET /api/businesses?near=lat,lng&radiusKm=5&type=grocery`
- `GET /api/businesses/:id`
- `POST /api/businesses/:id/products` (owner)
- `GET /api/businesses/:id/products`
- `PATCH /api/businesses/products/:id` (owner)
- `DELETE /api/businesses/products/:id` (owner)

### Orders
- `POST /api/orders` (customer)
- `GET /api/orders` (role-filtered)
- `PATCH /api/orders/:id/status` (owner)
- `POST /api/orders/:id/assign-rider` (owner)

### Location (nearby)
- `POST /api/service-providers/me/location` (service worker)
- `POST /api/riders/me/location` (rider)
- `GET /api/service-providers?near=lat,lng&radiusKm=5&profession=Electrician`

### Chat
- `POST /api/chats`
- `GET /api/chats`
- `GET /api/chats/:id/messages`
- `POST /api/chats/:id/messages`

### Bookings
- `POST /api/bookings` (customer)
- `GET /api/bookings` (role-filtered, MVP)
- `PATCH /api/bookings/:id/status` (owner/admin)

### Notifications
- `GET /api/notifications` (me)
- `POST /api/notifications` (me; useful for testing)
- `PATCH /api/notifications/:id` (mark read/unread)

### Payments (stub)
- `POST /api/payments/intents`
- `GET /api/payments/intents`
- `PATCH /api/payments/intents/:id`

### Rider
- `GET /api/riders/me`
- `PUT /api/riders/me`
- `GET /api/riders/me/orders`

### Service Provider
- `GET /api/service-providers/me`
- `PUT /api/service-providers/me`

### Uploads (stub)
- `POST /api/uploads`

### Push / FCM
- `POST /api/push-tokens` (save device token)
- `DELETE /api/push-tokens`
- `POST /api/push/test` (send test notification to a token)

## Quick curl examples

### Register (customer)
```bash
curl -X POST http://localhost:8080/api/auth/register \\
  -H 'Content-Type: application/json' \\
  -d '{"phone":"03123456789","password":"123456","role":"customer","name":"Ali"}'
```

### Login
```bash
curl -X POST http://localhost:8080/api/auth/login \\
  -H 'Content-Type: application/json' \\
  -d '{"identifier":"03123456789","password":"123456"}'
```

### Create business (owner)
```bash
ACCESS=REPLACE_ME
curl -X POST http://localhost:8080/api/businesses \\
  -H "Authorization: Bearer $ACCESS" \\
  -H 'Content-Type: application/json' \\
  -d '{"name":"My Grocery","type":"grocery","lat":24.8607,"lng":67.0011,"address":"Karachi"}'
```

