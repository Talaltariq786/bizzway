## BizzWay (Monorepo)

This repo is split into two separate apps:

- `bizzwaybackend/` — Node.js + MongoDB REST API (source of truth)
- `frontend/` — Flutter mobile app (customer/owner/rider)

### Backend (Node + Mongo)

```bash
cd bizzwaybackend
npm install
npm run dev
```

Health check:

```bash
curl -s http://127.0.0.1:8080/health
```

### Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

#### Running on a physical phone (iPhone/Android)

If you run the API on your Mac/PC, **do not use `127.0.0.1` on a physical phone**.
Set the backend base URL to your machine’s LAN IP:

- In the app: Login screen → bottom **`API:`** row → set `http://<your-ip>:8080`
- Or via build flag:

```bash
cd frontend
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

### Legacy

`server/` is an older demo backend (port 3000). It is not used by the current app.

