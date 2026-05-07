#!/usr/bin/env bash
# Is repo mein Android flavors hain (customer / business / riderServices).
# Seedha `flutter build apk --release` APK path dhundhne mein fail ho sakta hai — flavor zaroori hai.
#
# Live backend (optional): set API_BASE_URL for this shell, e.g.
#   export API_BASE_URL='https://api.merastore.pk'
#   ./build_apk.sh customer
#
# **Size:** default = `--split-per-abi` (har phone ko sirf apna CPU wala chhota APK).
# Ek hi fat APK chahiye ho to:  UNIVERSAL_APK=1  ./build_apk.sh customer
#
# Play Store ke liye zyada behtar:  flutter build appbundle --release --flavor ...
set -euo pipefail
cd "$(dirname "$0")"
FLAVOR="${1:-customer}"
[[ $# -gt 0 ]] && shift

DART_DEFINES=()
if [[ -n "${API_BASE_URL:-}" ]]; then
  DART_DEFINES+=(--dart-define=API_BASE_URL="${API_BASE_URL}")
  DART_DEFINES+=(--dart-define=OFFLINE_MODE=false)
fi

SPLIT_PER_ABI=(--split-per-abi)
if [[ "${UNIVERSAL_APK:-}" == "1" ]]; then
  SPLIT_PER_ABI=()
fi

flutter build apk --release --flavor "$FLAVOR" "${SPLIT_PER_ABI[@]}" "${DART_DEFINES[@]}" "$@"
echo ""
OUTDIR="$(pwd)/build/app/outputs/flutter-apk"
echo "Output folder: $OUTDIR"
if [[ "${UNIVERSAL_APK:-}" == "1" ]]; then
  echo "APK (universal): $OUTDIR/app-${FLAVOR}-release.apk"
else
  echo "APKs (per device CPU — arm64 most phones):"
  ls -1 "$OUTDIR"/*${FLAVOR}*release.apk 2>/dev/null || ls -1 "$OUTDIR"/*.apk
fi
