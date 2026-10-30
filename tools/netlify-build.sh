#!/usr/bin/env bash
# Builds the admin dashboard on Netlify. Netlify has no Flutter, so this
# downloads the same version used locally, then builds against the live
# Supabase project set in the site's environment variables.
set -euo pipefail

FLUTTER_VERSION="3.47.7"
: "${SUPABASE_URL:?Set SUPABASE_URL in Netlify environment variables}"
: "${SUPABASE_PUBLISHABLE_KEY:?Set SUPABASE_PUBLISHABLE_KEY in Netlify environment variables}"

FLUTTER_DIR="$HOME/flutter-$FLUTTER_VERSION"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
flutter config --no-analytics >/dev/null
flutter --version

cd apps/admin
flutter pub get
flutter build web --release \
  --dart-define=APP_ENV=production \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=SHOW_SAMPLE_LABELS="${SHOW_SAMPLE_LABELS:-true}"
