# BizLabel API

Minimal REST backend for the Flutter app (`BookingRepositoryApi`).

## Run

```bash
cd server
npm install
npm start
```

- Default URL: `http://localhost:3000`
- Bookings are stored in `data/bookings.json` (created on first write).

## Flutter

- Default `API_BASE_URL` in the app is already `http://localhost:3000`.
- **Android emulator:** use `http://10.0.2.2:3000` — run Flutter with:
  `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000`
- **Physical device:** use your PC’s LAN IP, e.g. `http://192.168.1.10:3000` (same Wi‑Fi).

## Endpoints

| Method | Path | Notes |
|--------|------|--------|
| GET | `/health` | `{ ok: true }` |
| GET | `/bookings` | Optional query `userId` filters by `userId` on stored rows |
| POST | `/bookings` | Body matches `CustomerBooking.toJson()`; server assigns `id` if missing |

Success shape: `{ "data": ... }` (matches the Flutter client).
