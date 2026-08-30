#!/usr/bin/env bash
set -Eeuo pipefail

set +u
source /opt/ros/humble/setup.bash
source /opt/roscar/install/setup.bash
set -u

mkdir -p /var/roscar/log /var/roscar/maps /var/roscar/bags /tmp/.X11-unix
export ROS_LOG_DIR=/var/roscar/log

if [[ -n "${ROSCAR_XAUTH_B64:-}" ]]; then
  export XAUTHORITY=/tmp/roscar.Xauthority
  : >"${XAUTHORITY}"
  printf '%s' "${ROSCAR_XAUTH_B64}" | base64 --decode | xauth -f "${XAUTHORITY}" nmerge -
  chmod 0600 "${XAUTHORITY}"
fi

if [[ "${1:-}" == "ros2" && "${2:-}" == "launch" ]]; then
  set -- "$@" "use_rviz:=${ROSCAR_USE_RVIZ:-true}"
fi

exec "$@"
