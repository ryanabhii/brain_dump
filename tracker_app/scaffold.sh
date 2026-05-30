#!/usr/bin/env bash
#
# scaffold.sh — create the Universal Tracker file/folder skeleton.
#
# Creates:
#   1. pubspec.yaml (the real dependencies) — only if one doesn't already exist.
#   2. Every lib/ folder + Dart file as EMPTY files for you to fill.
#
# It does NOT run `flutter create` — bring your own Flutter project / platform
# folders. After filling the lib/ files:
#   flutter pub get && flutter run
#
# Re-running is safe: existing pubspec.yaml and any non-empty lib files are left
# untouched (empty files are only created where missing).
#
# Usage:
#   chmod +x scaffold.sh
#   ./scaffold.sh             # scaffold in this script's directory
#   ./scaffold.sh path/to/app # scaffold elsewhere
#
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "$0")" && pwd)}"
mkdir -p "$ROOT"
cd "$ROOT"

# ── 1. Real pubspec.yaml (only if missing, so re-runs don't clobber edits) ──
if [ ! -f pubspec.yaml ]; then
  cat > pubspec.yaml <<'YAML'
name: tracker_app
description: "Universal tracker — killzones, spend, capture, household, body."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.12.0

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  # State management + local persistence
  provider: ^6.1.2
  shared_preferences: ^2.3.2
  # Formatting
  intl: ^0.20.2
  # Timezone detection + timezone-aware notifications
  flutter_timezone: ^5.1.0
  timezone: ^0.11.0
  flutter_local_notifications: any
  # Google Drive sync (backup + multi-user, backend-free)
  google_sign_in: ^7.2.0
  google_sign_in_web: ^1.1.3
  googleapis: ^16.0.0
  extension_google_sign_in_as_googleapis_auth: ^3.0.0
  http: ^1.6.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
YAML
  echo "Wrote pubspec.yaml"
else
  echo "pubspec.yaml already exists — left as-is"
fi

# ── 2. Empty lib/ structure ────────────────────────────────────────────
FILES=(
  "lib/main.dart"

  "lib/data/default_data.dart"
  "lib/data/meal_nutrition.dart"
  "lib/data/suggestions.dart"

  "lib/models/app_data.dart"
  "lib/models/body.dart"
  "lib/models/brain_dump.dart"
  "lib/models/grocery.dart"
  "lib/models/killzone.dart"
  "lib/models/meal_nutrition.dart"
  "lib/models/profile.dart"
  "lib/models/subscription.dart"
  "lib/models/trading.dart"
  "lib/models/workout.dart"

  "lib/screens/body_screen.dart"
  "lib/screens/capture_screen.dart"
  "lib/screens/dashboard_screen.dart"
  "lib/screens/grocery_screen.dart"
  "lib/screens/killzone_screen.dart"
  "lib/screens/profile_screen.dart"
  "lib/screens/spend_screen.dart"

  "lib/services/drive_config.dart"
  "lib/services/drive_sync.dart"
  "lib/services/drive_web_button.dart"
  "lib/services/drive_web_button_stub.dart"
  "lib/services/drive_web_button_web.dart"
  "lib/services/notifications.dart"
  "lib/services/notifications_impl.dart"
  "lib/services/notifications_stub.dart"
  "lib/services/storage_service.dart"
  "lib/services/time_zone.dart"

  "lib/state/app_state.dart"

  "lib/sync/merge.dart"
  "lib/sync/remote_store.dart"
  "lib/sync/drive_remote_store.dart"
  "lib/sync/sync_engine.dart"
  "lib/sync/sync_tabs.dart"

  "lib/theme/app_theme.dart"
  "lib/theme/colors.dart"

  "lib/utils/auto_route.dart"
  "lib/utils/day.dart"
  "lib/utils/format.dart"
  "lib/utils/grouping.dart"
  "lib/utils/meal_time.dart"
  "lib/utils/recurring.dart"
  "lib/utils/suggestions.dart"
  "lib/utils/time_util.dart"

  "lib/widgets/bottom_nav.dart"
  "lib/widgets/trading_pnl.dart"
  "lib/widgets/ui.dart"
)

created=0
skipped=0
for f in "${FILES[@]}"; do
  mkdir -p "$(dirname "$f")"
  if [ -e "$f" ]; then
    skipped=$((skipped + 1))
  else
    touch "$f"
    created=$((created + 1))
  fi
done

echo
echo "Scaffold complete in: $ROOT"
echo "  lib files — created: $created   existed: $skipped   total: ${#FILES[@]}"
echo
echo "Next: fill the lib/*.dart files, then  flutter pub get && flutter run"
