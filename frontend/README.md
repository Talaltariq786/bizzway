## BizzWay Frontend (Flutter)

### Run

```bash
flutter pub get
flutter run
```

### Backend URL (dev)

- **iOS Simulator**: `http://127.0.0.1:8080`
- **Android emulator**: `http://10.0.2.2:8080`
- **Physical phone**: use your Mac/PC LAN IP, e.g. `http://192.168.1.10:8080`

You can set it from the login screen via the **`API:`** row, or:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```
