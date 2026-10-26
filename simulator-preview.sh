#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
xcrun simctl list devices available --json > /tmp/telemetria-devices.json
WATCH_ID=$(python3 - <<'PY'
import json
data=json.load(open('/tmp/telemetria-devices.json'))
devices=[d for runtime,ds in data['devices'].items() if 'watchOS' in runtime for d in ds if d.get('isAvailable')]
devices.sort(key=lambda d: ('Ultra' not in d['name'], d['name']))
if not devices:
    raise SystemExit('No hay un runtime watchOS disponible; no se ha probado el arranque.')
print(devices[0]['udid'])
PY
)
echo "Simulador seleccionado: $WATCH_ID"
xcrun simctl boot "$WATCH_ID"
xcrun simctl bootstatus "$WATCH_ID" -b
xcrun simctl install "$WATCH_ID" build/Build/Products/Debug-watchsimulator/Telemetria02.app
xcrun simctl launch "$WATCH_ID" com.telemetria02.watch --demo
sleep 8
xcrun simctl io "$WATCH_ID" screenshot /tmp/telemetria-demo.png
# Small synthetic screenshot in build logs, without paid artifact storage.
python3 - <<'PY'
import base64
data=open('/tmp/telemetria-demo.png','rb').read()
if len(data)>1500000:
    raise SystemExit('La captura supera el límite previsto para el registro.')
print('TELEMETRIA_SCREENSHOT_BEGIN')
encoded=base64.b64encode(data).decode('ascii')
for i in range(0,len(encoded),120): print(encoded[i:i+120])
print('TELEMETRIA_SCREENSHOT_END')
PY
xcrun simctl terminate "$WATCH_ID" com.telemetria02.watch
xcrun simctl shutdown "$WATCH_ID"
