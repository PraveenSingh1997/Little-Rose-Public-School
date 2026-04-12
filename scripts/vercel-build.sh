#!/usr/bin/env bash
set -e

echo "==> Setting up Flutter SDK..."
FLUTTER_HOME="$HOME/flutter"

if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git \
    -b stable --depth 1 "$FLUTTER_HOME"
fi

export PATH="$PATH:$FLUTTER_HOME/bin"
flutter --version

echo "==> Creating Supabase config from environment variables..."
mkdir -p lib/config
cat > lib/config/supabase_config.dart << EOF
class SupabaseConfig {
  static const String url = '$SUPABASE_URL';
  static const String anonKey = '$SUPABASE_ANON_KEY';
}
EOF

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "ERROR: SUPABASE_URL and SUPABASE_ANON_KEY environment variables must be set."
  echo "Add them in Vercel: Settings -> Environment Variables"
  exit 1
fi

echo "==> Installing dependencies..."
flutter pub get

echo "==> Building Flutter web (release)..."
flutter build web --release --base-href /

echo "==> Build complete. Output: build/web/"
ls -lh build/web/
