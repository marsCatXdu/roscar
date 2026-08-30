import json
import os
import time

from nav_msgs.msg import Odometry
from nvblox_msgs.msg import Mesh
import rclpy
from rclpy.node import Node
from rclpy.qos import qos_profile_sensor_data
from sensor_msgs.msg import Image


class StackMonitor(Node):
    def __init__(self):
        super().__init__('roscar_stack_monitor')
        self._last_seen = {
            'infra': None,
            'depth': None,
            'odometry': None,
            'mesh': None,
        }
        self.create_subscription(
            Image, '/camera/infra1/image_rect_raw',
            lambda _: self._mark('infra'), qos_profile_sensor_data)
        self.create_subscription(
            Image, '/camera/depth/image_rect_raw',
            lambda _: self._mark('depth'), qos_profile_sensor_data)
        self.create_subscription(
            Odometry, '/visual_slam/tracking/odometry',
            lambda _: self._mark('odometry'), qos_profile_sensor_data)
        self.create_subscription(
            Mesh, '/nvblox_node/mesh',
            lambda _: self._mark('mesh'), 10)
        self.create_timer(2.0, self._write_status)
        self._status_path = '/var/roscar/status.json'
        self.get_logger().info('Stack readiness monitor started')

    def _mark(self, stream):
        self._last_seen[stream] = time.time()

    def _fresh(self, stream, maximum_age):
        timestamp = self._last_seen[stream]
        return timestamp is not None and time.time() - timestamp <= maximum_age

    def _write_status(self):
        now = time.time()
        status = {
            'updated_at': now,
            'camera_ready': self._fresh('infra', 5.0) and self._fresh('depth', 5.0),
            'vslam_ready': self._fresh('odometry', 5.0),
            'nvblox_ready': self._fresh('mesh', 15.0),
            'last_seen': self._last_seen,
        }
        temporary_path = self._status_path + '.tmp'
        os.makedirs(os.path.dirname(self._status_path), exist_ok=True)
        with open(temporary_path, 'w', encoding='utf-8') as stream:
            json.dump(status, stream, indent=2, sort_keys=True)
            stream.write('\n')
        os.replace(temporary_path, self._status_path)


def main(args=None):
    rclpy.init(args=args)
    node = StackMonitor()
    try:
        rclpy.spin(node)
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
