## Run 3 separate apps (same codebase)

Your original app stays the same (`lib/main.dart`).

These are **separate Android apps** via flavors (different package IDs + app names).

### Customer app

```bash
flutter run --flavor customer -t lib/main_customer.dart
```

### Business app

```bash
flutter run --flavor business -t lib/main_business.dart
```

### Rider + Home Services app

```bash
flutter run --flavor riderServices -t lib/main_rider_services.dart
```

### Note about login sessions

All apps use the same `SharedPreferences` keys. To avoid “role mixup”, each app’s splash enforces its role; if it detects a different role saved, it logs out and shows that app’s login.

