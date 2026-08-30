# Architecture

## Goals

- Build the RealSense boundary from pinned upstream commits and install exact
  NVIDIA binary package versions.
- Keep the legacy containers and workspace untouched.
- Start the complete perception stack with `./roscar up`.
- Keep runtime data outside the container lifecycle without bind-mounting a
  host project directory.
- Make readiness observable rather than equating “process exists” with
  “pipeline works.”

## Runtime topology

One Docker container runs one ROS 2 launch description:

1. `realsense2_camera_node` publishes stereo infrared, depth, and color.
2. `isaac_ros_visual_slam` estimates `odom -> camera_link` from stereo IR.
3. `nvblox_ros` consumes depth, color, camera calibration, and TF to build a
   bounded 3D reconstruction.
4. `rviz2` displays images, TF, trajectory, and the nvblox mesh.
5. `roscar_stack_monitor` records independent camera, VSLAM, and mesh readiness
   in `/var/roscar/status.json`.

Camera, VSLAM, and nvblox run as separate ROS processes inside one container
under one launch file. This preserves ROS process-failure isolation without
turning tightly coupled, same-machine nodes into separately operated
containers.
An unexpected process exit is respawned without requiring manually maintained
terminal sessions.

## Persistence and isolation

- Application code and configuration are copied into the image at build time.
- `/var/roscar` is a Docker named volume for logs, bags, maps, and readiness.
- The legacy workspace is never mounted.
- The only bind mount is a single read-only X11 socket file required to render
  RViz on the Jetson's existing desktop.
- The X11 cookie is copied into an ephemeral file inside the container.

## Version pins

The immutable starting image must have ID:

`sha256:9d5af4d72ed54331d31a1c173d4e71e2679a56765ab447c76a9aeb297965d4e3`

The matching RealSense pair is librealsense `v2.57.7` and ROS wrapper `4.57.7`,
both built from commits pinned in the Dockerfile and `vendor.repos`. The runtime
Isaac packages are pinned to the following NVIDIA release-3 apt versions:

- `ros-humble-isaac-ros-visual-slam=3.2.6-0jammy`
- `ros-humble-nvblox-msgs=3.2.5-0jammy`
- `ros-humble-nvblox-ros=3.2.5-0jammy`
- `ros-humble-nvblox-rviz-plugin=3.2.5-0jammy`

The Isaac Git commits in `vendor.repos` preserve the source snapshot evaluated
during takeover; they are provenance references, not build inputs for the
current image. Building the complete Isaac dependency graph from source was
rejected after an observed resource-pressure restart on this 8 GB Jetson.

## Current deliberate limitations

- IMU fusion is disabled until D435i HID transport is validated independently.
- The RealSense emitter is disabled because this direct stereo pipeline does
  not use NVIDIA's emitter-flashing splitter.
- The bounded nvblox map is intended for room-scale validation, not long-range
  autonomous navigation.
- Chassis control, URDF, Nav2, and safety control are future layers and are not
  implied by a healthy perception stack.
