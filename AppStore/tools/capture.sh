#!/bin/zsh
# Captures raw App Store screenshots from a simulator in demo mode.
# usage: capture.sh <simulator-udid> <lang: en|hi> <out-dir> <app-path>
set -e
DEV=$1; LANG_CODE=$2; OUT=$3; APP=$4
BUNDLE=ca.thebighead.cleanconnect
mkdir -p "$OUT"
xcrun simctl install "$DEV" "$APP"
xcrun simctl status_bar "$DEV" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
xcrun simctl privacy "$DEV" grant location "$BUNDLE" >/dev/null 2>&1 || true

LOCALE=$([[ "$LANG_CODE" == "hi" ]] && echo hi_IN || echo en_IN)

shot() {
  local name=$1; shift
  xcrun simctl terminate "$DEV" "$BUNDLE" >/dev/null 2>&1 || true
  xcrun simctl launch "$DEV" "$BUNDLE" -demo -AppleLanguages "($LANG_CODE)" -AppleLocale "$LOCALE" "$@" >/dev/null
  perl -e 'select(undef,undef,undef,5.5)'
  xcrun simctl io "$DEV" screenshot "$OUT/$name.png" >/dev/null 2>&1
  echo "$OUT/$name.png"
}

shot 01_before_after -push spot:s1
shot 02_report -sheet report
shot 03_map -tab map
shot 04_home
shot 05_drive -tab drives -push drive:d1
shot 06_profile -tab profile
shot 07_leaders -tab leaders
shot 08_complaint -push complaint:s2
shot 09_support -sheet support
xcrun simctl terminate "$DEV" "$BUNDLE" >/dev/null 2>&1 || true
