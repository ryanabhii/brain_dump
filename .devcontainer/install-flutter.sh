#!/usr/bin/env bash
set -e

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_HOME="/home/vscode/flutter"
ANDROID_HOME="/home/vscode/android-sdk"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

# ---------------------------------------------------------------------------
# System packages: Flutter deps + JDK + Linux desktop build deps
# ---------------------------------------------------------------------------
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  git curl unzip xz-utils zip ca-certificates \
  libglu1-mesa \
  openjdk-17-jdk \
  cmake ninja-build clang pkg-config \
  libgtk-3-dev liblzma-dev

# ---------------------------------------------------------------------------
# Flutter SDK
# ---------------------------------------------------------------------------
if [ ! -d "$FLUTTER_HOME" ]; then
  git clone --depth 1 -b "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi
git config --global --add safe.directory "$FLUTTER_HOME"

# ---------------------------------------------------------------------------
# Android SDK (command-line tools + platform + build-tools)
# ---------------------------------------------------------------------------
if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  TMP_ZIP="$(mktemp --suffix=.zip)"
  curl -L -o "$TMP_ZIP" "$CMDLINE_TOOLS_URL"
  unzip -q "$TMP_ZIP" -d "$ANDROID_HOME/cmdline-tools"
  mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  rm -f "$TMP_ZIP"
fi

# ---------------------------------------------------------------------------
# PATH + env for all future shells (login shells)
# ---------------------------------------------------------------------------
sudo tee /etc/profile.d/flutter.sh >/dev/null <<EOF
export FLUTTER_ROOT="$FLUTTER_HOME"
export ANDROID_HOME="$ANDROID_HOME"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="\$PATH:$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"
EOF
sudo chmod +x /etc/profile.d/flutter.sh

# Make available in this script too
export FLUTTER_ROOT="$FLUTTER_HOME"
export ANDROID_HOME="$ANDROID_HOME"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"

# ---------------------------------------------------------------------------
# Android SDK packages + license acceptance
# ---------------------------------------------------------------------------
yes | sdkmanager --licenses >/dev/null || true
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" >/dev/null

# ---------------------------------------------------------------------------
# Flutter configuration + precache
# ---------------------------------------------------------------------------
flutter config --no-analytics
flutter config --android-sdk "$ANDROID_HOME"
flutter config --enable-web
flutter precache --universal --web --linux --android || true
yes | flutter doctor --android-licenses >/dev/null || true
flutter doctor || true