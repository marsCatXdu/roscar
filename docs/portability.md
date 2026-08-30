# Portability

## Short answer

This repository can reproduce the VSLAM stack easily on another **matching
Jetson**, after the host prerequisites and exact Docker base image have been
prepared. It is not yet a complete installer for a freshly flashed device.

## Tested setup

- NVIDIA Jetson Orin Nano Super, aarch64
- Ubuntu 22.04 with L4T R36.5
- Intel RealSense D435i on USB 3
- Xorg desktop for RViz
- Docker, Docker Compose, and the NVIDIA container runtime
- Local base image `isaac_ros_dev-aarch64:latest` with ID:
  `sha256:9d5af4d72ed54331d31a1c173d4e71e2679a56765ab447c76a9aeb297965d4e3`

The image ID check is intentional: it prevents a new machine from silently
building against an unknown base.

## Where the base image came from

`isaac_ros_dev-aarch64:latest` is a local tag, not an image published under
that name. Docker metadata and layer history show this lineage:

1. NVIDIA's NGC image
   `nvcr.io/nvidia/isaac/ros:aarch64-ros2_humble_4c0c55dddd2bbcc3e8d5f9753bee634c`
   (ID `sha256:dd032d9aa0a...`) supplies the first 94 filesystem layers.
2. NVIDIA's unchanged
   [`Dockerfile.realsense`](https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_common/blob/fcf4d9e17f8f0a7f47f1d22d6a18421ce3768c01/docker/Dockerfile.realsense)
   from `isaac_ros_common` release 3.2 adds seven local layers.
3. Those layers install librealsense 2.55.1 and NVIDIA's RealSense ROS wrapper
   4.51.1, producing the current local image on 2026-06-28.

The `roscar` image then installs its own pinned RealSense 2.57.7/4.57.7 overlay,
so the older copy in the base is not the runtime camera boundary.

The historical base can be rebuilt from NVIDIA's source with:

```bash
git clone --branch release-3.2 \
  https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_common.git
cd isaac_ros_common
git checkout fcf4d9e17f8f0a7f47f1d22d6a18421ce3768c01
./scripts/build_image_layers.sh \
  --image_key aarch64.ros2_humble.realsense \
  --image_name isaac_ros_dev-aarch64
```

This records the origin but may not recreate the exact image ID because
external packages can change. The current launcher will correctly refuse such
an unreviewed replacement.

### Copy the exact base to another Jetson

For the current project, the simplest reliable method is to transfer the
accepted image. On this Jetson:

```bash
docker save isaac_ros_dev-aarch64:latest | gzip \
  > isaac_ros_dev-aarch64-9d5af4d7.tar.gz
scp isaac_ros_dev-aarch64-9d5af4d7.tar.gz jetson@NEW_JETSON_IP:
```

On the new Jetson:

```bash
gzip -dc isaac_ros_dev-aarch64-9d5af4d7.tar.gz | docker load
docker image inspect isaac_ros_dev-aarch64:latest --format '{{.Id}}'
```

The last command must print the full expected ID shown in **Tested setup**.
The image is about 43.2 GB before transfer compression, so keep the archive out
of Git and allow ample temporary disk space.

## What the repository provides

- Pinned RealSense and Isaac ROS versions
- Camera, VSLAM, nvblox, health-monitor, and RViz configuration
- An isolated Docker image with no project-directory mount
- One command to build and start the complete stack
- A Docker named volume for runtime logs, maps, and bags

The named volume belongs to one Docker host. Cloning the Git repository does
not copy maps, bags, or logs from another Jetson.

## What must already exist on a new Jetson

1. A compatible Ubuntu/L4T installation and NVIDIA drivers.
2. Docker, Docker Compose, and a working NVIDIA container runtime.
3. The exact `isaac_ros_dev-aarch64:latest` base image listed above.
4. A connected RealSense D435i accessible over USB 3.
5. An active Xorg display if RViz should run on the Jetson.
6. Internet access during the first build.
7. Enough disk space for the base image, the approximately 13.8 GB final
   image, and Docker build cache.

The repository currently does not install or download items 1–3.

## Compatibility at a glance

| Target | Expected result |
| --- | --- |
| Matching Orin Nano, L4T R36.5, D435i, exact base image | Supported path |
| Matching Jetson without the base image | Build is refused |
| Different Jetson or L4T release | Not validated |
| Different camera | Configuration changes required |
| x86 computer | Not supported by this image |
| Wayland-only or headless system | Current RViz launcher is not supported |

## Setup after prerequisites are ready

```bash
git clone git@github.com:marsCatXdu/roscar.git
cd roscar
./roscar up
```

The first build took about 30 minutes on the tested Jetson. Later runs normally
reuse Docker's cache. If the login screen owns Xorg, `up` may request sudo once
to read its temporary display cookie.

Check the result with:

```bash
./roscar status
```

A working perception stack reports `camera_ready`, `vslam_ready`, and
`nvblox_ready` as `true`. This confirms the data flow, not merely that the
container process exists.

## Portability boundary

Treat the current project as a reproducible **application stack for the tested
hardware**, not as a general Jetson provisioning system. Trying it on a
different board, L4T release, camera, or display system should be considered a
new validation effort.
