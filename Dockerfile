ARG BASE_IMAGE=isaac_ros_dev-aarch64:latest
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-c"]

ARG LIBREALSENSE_REPOSITORY=https://github.com/realsenseai/librealsense.git
ARG LIBREALSENSE_COMMIT=fec2d156e531f417c927262818f3440cfbcde4e9
ARG REALSENSE_ROS_REPOSITORY=https://github.com/realsenseai/realsense-ros.git
ARG REALSENSE_ROS_COMMIT=5c2244ca5cd9867c9ee63769668891430f460dfd
ARG BUILD_JOBS=1
ARG ROSCAR_REVISION=development

LABEL org.opencontainers.image.title="roscar"
LABEL org.opencontainers.image.description="Pinned RealSense + Isaac ROS VSLAM + nvblox bring-up"
LABEL org.opencontainers.image.revision="${ROSCAR_REVISION}"

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=humble
ENV ROSCAR_ROOT=/opt/roscar
ENV ROSCAR_INSTALL=/opt/roscar/install
ENV REALSENSE_ROOT=/opt/roscar/librealsense
ENV ROS_LOG_DIR=/var/roscar/log

RUN apt-get update && apt-get install -y --no-install-recommends \
        git-lfs \
        libglfw3-dev \
        libgtk-3-dev \
        libusb-1.0-0-dev \
        pkg-config \
        xauth \
    && rm -rf /var/lib/apt/lists/*

# Build a private librealsense prefix so the base image remains conceptually
# untouched and the ROS wrapper cannot accidentally resolve its older SDK.
RUN git clone --filter=blob:none "${LIBREALSENSE_REPOSITORY}" /tmp/librealsense \
    && git -C /tmp/librealsense checkout "${LIBREALSENSE_COMMIT}" \
    && cmake -S /tmp/librealsense -B /tmp/librealsense-build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${REALSENSE_ROOT}" \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_GRAPHICAL_EXAMPLES=OFF \
        -DBUILD_PYTHON_BINDINGS=OFF \
        -DBUILD_WITH_CUDA=ON \
        -DFORCE_RSUSB_BACKEND=ON \
    && cmake --build /tmp/librealsense-build --parallel "${BUILD_JOBS}" \
    && cmake --install /tmp/librealsense-build \
    && rm -rf /tmp/librealsense /tmp/librealsense-build

ENV CMAKE_PREFIX_PATH=/opt/roscar/librealsense:/opt/ros/humble
ENV LD_LIBRARY_PATH=/opt/roscar/librealsense/lib:/opt/roscar/install/lib:${LD_LIBRARY_PATH}
ENV PATH=/opt/roscar/librealsense/bin:${PATH}

# NVIDIA documents these as supported release-3.2 binary packages. Install the
# minimal pinned runtime set rather than the nvblox meta-package, which also
# pulls examples and Nav2 integration that this stack does not run.
RUN rm -f /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
         ros-humble-isaac-ros-visual-slam=3.2.6-0jammy \
         ros-humble-nvblox-msgs=3.2.5-0jammy \
         ros-humble-nvblox-ros=3.2.5-0jammy \
         ros-humble-nvblox-rviz-plugin=3.2.5-0jammy \
    && dpkg-query -W \
         ros-humble-isaac-ros-visual-slam \
         ros-humble-nvblox-msgs \
         ros-humble-nvblox-ros \
         ros-humble-nvblox-rviz-plugin \
         > /opt/roscar/isaac-ros-package-versions.txt \
    && rm -rf /var/lib/apt/lists/*

COPY ros_ws/src/roscar_bringup /opt/roscar/ws/src/roscar_bringup

# Build only the pinned RealSense wrapper and this project's small Python
# bring-up package. Isaac ROS itself comes from NVIDIA's signed binary repo.
RUN --mount=type=cache,id=roscar-realsense-ros-4_57_7,target=/opt/roscar/ws/src/vendor/realsense-ros,sharing=locked \
    --mount=type=cache,id=roscar-colcon-build-4_57_7,target=/opt/roscar/ws/build,sharing=locked \
    if [[ ! -d /opt/roscar/ws/src/vendor/realsense-ros/.git ]]; then \
         find /opt/roscar/ws/src/vendor/realsense-ros -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +; \
         git clone --filter=blob:none "${REALSENSE_ROS_REPOSITORY}" \
           /opt/roscar/ws/src/vendor/realsense-ros; \
       fi \
    && git -C /opt/roscar/ws/src/vendor/realsense-ros fetch --depth 1 origin "${REALSENSE_ROS_COMMIT}" \
    && git -C /opt/roscar/ws/src/vendor/realsense-ros checkout --detach --force "${REALSENSE_ROS_COMMIT}" \
    && source /opt/ros/humble/setup.bash \
    && cd /opt/roscar/ws \
    && mapfile -t package_paths < <(colcon list --paths-only --packages-up-to \
         realsense2_camera \
         roscar_bringup) \
    && apt-get update \
    && rosdep install --from-paths "${package_paths[@]}" --ignore-src --rosdistro humble -y \
         --skip-keys librealsense2 \
    && colcon build \
         --merge-install \
         --install-base "${ROSCAR_INSTALL}" \
         --parallel-workers "${BUILD_JOBS}" \
         --packages-up-to \
           realsense2_camera \
           roscar_bringup \
         --cmake-args -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release \
    && rm -rf /opt/roscar/ws/log \
    && rm -rf /var/lib/apt/lists/* \
    && ldconfig

COPY docker/entrypoint.sh /usr/local/bin/roscar-entrypoint
COPY docker/healthcheck.sh /usr/local/bin/roscar-healthcheck
RUN chmod 0755 /usr/local/bin/roscar-entrypoint /usr/local/bin/roscar-healthcheck \
    && mkdir -p /var/roscar/log /tmp/.X11-unix

HEALTHCHECK --interval=10s --timeout=5s --start-period=90s --retries=6 \
  CMD ["/usr/local/bin/roscar-healthcheck"]

ENTRYPOINT ["/usr/local/bin/roscar-entrypoint"]
CMD ["ros2", "launch", "roscar_bringup", "roscar.launch.py"]
