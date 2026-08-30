#!/usr/bin/env bash
set -Eeuo pipefail

pgrep -f "ros2 launch roscar_bringup roscar.launch.py" >/dev/null
pgrep -f "realsense2_camera_node" >/dev/null
pgrep -f "component_container.*roscar_vslam_container" >/dev/null
pgrep -f "component_container.*roscar_nvblox_container" >/dev/null

if [[ "${ROSCAR_USE_RVIZ:-true}" == "true" ]]; then
  pgrep -x rviz2 >/dev/null
fi

python3 - <<'PY'
import json
import time

with open('/var/roscar/status.json', encoding='utf-8') as stream:
    status = json.load(stream)

if not status.get('camera_ready'):
    raise SystemExit('camera stream is not ready')
if not status.get('vslam_ready'):
    raise SystemExit('VSLAM odometry is not ready')
if time.time() - status.get('updated_at', 0) > 20:
    raise SystemExit('monitor status is stale')
PY
