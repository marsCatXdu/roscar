# roscar

Reproducible, isolated bring-up for an NVIDIA Jetson Orin Nano Super with an
Intel RealSense D435i. One command starts the camera driver, Isaac ROS cuVSLAM,
nvblox 3D reconstruction, readiness monitoring, and RViz on the Jetson desktop.

```bash
cd /home/jetson/roscar && ./roscar up
```

The first run builds the pinned RealSense SDK and ROS wrapper and installs
version-pinned NVIDIA packages; on the current Jetson it took about 30 minutes.
Later starts use Docker's build cache. Runtime code is baked into the image; no
source or project directory is mounted into the container. Persistent maps,
bags, and ROS logs live in the Docker-managed `roscar-data` volume.

If the machine is showing the GDM login screen, `up` asks for sudo once so it
can read that session's X11 cookie. It does not alter the host X11
configuration.

## Operator commands

```bash
./roscar status
./roscar logs
./roscar doctor
./roscar shell
./roscar down
```

`down` retains `roscar-data`. The legacy Isaac containers and
`/home/jetson/workspaces/isaac_ros-dev` are neither referenced nor modified.
`status` reports camera, VSLAM, and nvblox readiness independently.

## Runtime boundary

The container receives GPU and camera access through the NVIDIA runtime and
Docker's device boundary. RViz receives one read-only X11 socket file and an
ephemeral authentication cookie. No host directory is mounted.

See [docs/architecture.md](docs/architecture.md) for design details and
[docs/portability.md](docs/portability.md) before setting up another Jetson.
[docs/legacy-baseline.md](docs/legacy-baseline.md) records the evidence that led
to this clean-room implementation.
