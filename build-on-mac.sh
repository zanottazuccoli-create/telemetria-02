#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Falta XcodeGen. Instálalo desde https://github.com/yonaskolb/XcodeGen y vuelve a ejecutar."
  exit 1
fi
xcodegen generate
xcodebuild -project Telemetria02.xcodeproj -scheme Telemetria02 \
  -sdk watchsimulator -destination 'generic/platform=watchOS Simulator' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
