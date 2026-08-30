# Legacy baseline (read-only inspection)

Captured 2026-08-29/30 before creating the new stack. This document is memory
for the takeover; it is not generated runtime truth.

## Preserved state

- Legacy workspace: `/home/jetson/workspaces/isaac_ros-dev` (not mounted here).
- Legacy containers: `isaac_ros_dev-aarch64-test` and
  `isaac_ros_dev-aarch64-container` (both stopped when inspected).
- Clean immutable base image ID: `9d5af4d72ed5...`.
- Connected camera: Intel RealSense D435i, firmware recorded as `5.17.3.10`.

## Evidence that motivated the clean-room design

- The old workspace successfully built Isaac ROS packages, but the latest
  launch revisions had no preserved successful end-to-end validation.
- An official nvblox example failed to load `realsense_splitter_node` and then
  produced repeated `camera0_link` TF failures.
- A later custom nvblox launch existed outside Git and had been edited after the
  available runtime logs.
- `isaac_ros_visual_slam` had an uncommitted launch modification.
- `isaac_ros_nitros` had 788 staged deletions and 786 corresponding untracked
  paths. It must not be reset, cleaned, or used as a source of truth.
- No implemented chassis driver, Nav2 configuration, custom robot model, or
  saved user map was found.

## Non-negotiable boundary

No roscar command should alter, mount writable, clean, rebuild, or restart the
legacy workspace or containers.
