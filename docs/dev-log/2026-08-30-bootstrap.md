# 2026-08-30 clean-stack bootstrap

## Decision

Start from the immutable pre-iteration image, not either legacy container.
Build matching RealSense 2.57.7/4.57.7 from official source, install exact
NVIDIA Isaac ROS 3.2 binary packages, bake all project files into a new image,
and persist only runtime outputs in a new Docker named volume.

## Host facts

- Jetson Orin Nano Engineering Reference Developer Kit Super.
- Ubuntu 22.04, L4T R36.5, aarch64.
- Docker overlay filesystem on a 233 GB NVMe with 144 GB free at initial
  inspection.
- NVIDIA container runtime available.
- D435i visible on USB 3 and as `/dev/video0` through `/dev/video5`.
- The initial desktop used Xorg `:1`; after the unexpected build-time restart,
  GDM owned display `:0` and its private Xauthority file.

## Build incident and design correction

An initial attempt to compile the full Isaac ROS VSLAM/nvblox source graph made
SSH unresponsive and the Jetson restarted without a reboot command being sent.
The short uptime observed after reconnecting confirmed the restart. Resource
pressure is the likely cause, but the exact reset source was not captured.

That attempt was abandoned. The final Dockerfile compiles only librealsense and
the RealSense ROS overlay with one build worker, and installs NVIDIA's signed,
version-pinned VSLAM and nvblox binaries. This completed reliably. A stale
colcon cache found during the first runtime test was isolated by a
version-specific cache ID; the resulting node now reports wrapper `4.57.7` and
SDK `2.57.7`.

## Validation record

Observed on the final image on 2026-08-30:

- Image: `roscar:0.1.0`, ID
  `sha256:881b0e2e65ff3f327ce5fb9472c2f708d84a75812c6fbdb1e78eed48fe9f226e`,
  approximately 13.79 GB.
- `cd /home/jetson/roscar && ./roscar up` rebuilt/recreated the container and
  returned healthy.
- Status reported fresh camera, VSLAM odometry, and nvblox mesh timestamps.
- Measured stereo IR rate was approximately 29.4 Hz, VSLAM odometry 23 Hz, and
  mesh publication 2 Hz while the camera was stationary and facing the ceiling.
- `odom -> camera_link` was available through TF.
- Active camera parameters were stereo `848x480x30`, color `640x480x30`, and
  emitter disabled.
- A direct capture of the mapped RViz window showed both live camera images,
  `Global Status: Ok`, TF/path displays, and reconstructed mesh fragments.
- RViz initialized NVIDIA OpenGL 4.6. A full root-window capture was black due
  to GDM/Mutter composition; capturing the mapped RViz X window worked.
- The container mount audit showed only `roscar-data` at `/var/roscar` and the
  single `/tmp/.X11-unix/X0` socket file read-only. No host directory or legacy
  workspace was mounted.
- Both legacy containers remained stopped with their original exit states.
- Final disk free space was 139 GB; Docker build cache occupied 20.84 GB, of
  which 4.886 GB was reported reclaimable. No cache or legacy data was deleted.

Startup produced short-lived RealSense USB `EAGAIN` warnings and nvblox TF
lookup waits. They did not persist as readiness failures: all three monitored
data paths remained healthy after initialization.
