#!/usr/bin/env bash
set -e

PACKAGE="um.musify.mu.musify_mu"
ACTIVITY=".MainActivity"

# Discover device transport or use first available android device
DEVICE_SERIAL=$(adb devices -l | grep "model:V2126" | awk '{print $1}' | head -n 1)
if [ -z "$DEVICE_SERIAL" ]; then
  DEVICE_SERIAL=$(adb devices | grep -w "device" | awk '{print $1}' | head -n 1)
fi

if [ -z "$DEVICE_SERIAL" ]; then
  echo "Error: No connected Android device found via ADB."
  exit 1
fi

ADB="adb -s $DEVICE_SERIAL"

if [ "$1" == "--build" ] || [ "$1" == "-b" ]; then
  echo "Building debug APK..."
  flutter build apk --debug
  echo "Installing APK to device..."
  $ADB install -r build/app/outputs/flutter-apk/app-debug.apk
fi

echo "Starting Musify on device ($DEVICE_SERIAL)..."
$ADB logcat -c
$ADB shell am force-stop $PACKAGE > /dev/null 2>&1 || true
$ADB shell am start -n "$PACKAGE/$ACTIVITY" \
  --ez enable-checked-mode true \
  --ez verify-entry-points true > /dev/null

echo "Waiting for Dart VM Service handshake..."
PORT=""
PATH_URL=""

for i in {1..40}; do
  LOGS=$($ADB logcat -d -s flutter:V 2>/dev/null)
  PORT=$(echo "$LOGS" | grep -o 'VIVO_PORT: [0-9]*' | tail -n 1 | awk '{print $2}')
  PATH_URL=$(echo "$LOGS" | grep -o 'VIVO_PATH: \S*' | tail -n 1 | awk '{print $2}')
  if [ -n "$PORT" ] && [ -n "$PATH_URL" ]; then
    break
  fi
  sleep 0.5
done

if [ -z "$PORT" ] || [ -z "$PATH_URL" ]; then
  echo "Error: Could not retrieve Dart VM Service URI."
  echo "Ensure the debug build is installed on the phone."
  exit 1
fi

echo "Connected! VM Port: $PORT | Token: $PATH_URL"
$ADB forward tcp:$PORT tcp:$PORT

echo "Attaching Flutter CLI (Hot Reload [r], Hot Restart [R] enabled)..."
exec flutter attach -d "$DEVICE_SERIAL" --debug-url "http://127.0.0.1:$PORT$PATH_URL"
