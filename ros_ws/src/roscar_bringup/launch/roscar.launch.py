from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, TimerAction
from launch.conditions import IfCondition
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import ComposableNodeContainer, Node
from launch_ros.descriptions import ComposableNode
import os


def generate_launch_description():
    share = get_package_share_directory('roscar_bringup')
    camera_config = os.path.join(share, 'config', 'realsense.yaml')
    nvblox_config = os.path.join(share, 'config', 'nvblox.yaml')
    rviz_config = os.path.join(share, 'rviz', 'roscar.rviz')
    use_rviz = LaunchConfiguration('use_rviz')

    camera = Node(
        package='realsense2_camera',
        executable='realsense2_camera_node',
        name='camera',
        namespace='camera',
        parameters=[camera_config],
        output='screen',
        respawn=True,
        respawn_delay=2.0,
    )

    vslam = ComposableNode(
        package='isaac_ros_visual_slam',
        plugin='nvidia::isaac_ros::visual_slam::VisualSlamNode',
        name='visual_slam_node',
        parameters=[{
            'num_cameras': 2,
            'min_num_images': 2,
            'enable_localization_n_mapping': False,
            'enable_image_denoising': False,
            'rectified_images': True,
            'enable_rectified_pose': True,
            'enable_imu_fusion': False,
            'calibration_frequency': 200.0,
            'image_jitter_threshold_ms': 100.0,
            'map_frame': 'map',
            'odom_frame': 'odom',
            'base_frame': 'camera_link',
            'camera_optical_frames': [
                'camera_infra1_optical_frame',
                'camera_infra2_optical_frame',
            ],
            'enable_slam_visualization': True,
            'enable_landmarks_view': True,
            'enable_observations_view': True,
            'path_max_size': 2000,
        }],
        remappings=[
            ('visual_slam/camera_info_0', '/camera/infra1/camera_info'),
            ('visual_slam/camera_info_1', '/camera/infra2/camera_info'),
            ('visual_slam/image_0', '/camera/infra1/image_rect_raw'),
            ('visual_slam/image_1', '/camera/infra2/image_rect_raw'),
        ],
    )

    vslam_container = ComposableNodeContainer(
        name='roscar_vslam_container',
        namespace='',
        package='rclcpp_components',
        executable='component_container_mt',
        composable_node_descriptions=[vslam],
        output='screen',
        arguments=['--ros-args', '--log-level', 'info'],
        respawn=True,
        respawn_delay=2.0,
    )

    nvblox = ComposableNode(
        package='nvblox_ros',
        plugin='nvblox::NvbloxNode',
        name='nvblox_node',
        parameters=[nvblox_config],
        remappings=[
            ('camera_0/depth/image', '/camera/depth/image_rect_raw'),
            ('camera_0/depth/camera_info', '/camera/depth/camera_info'),
            ('camera_0/color/image', '/camera/color/image_raw'),
            ('camera_0/color/camera_info', '/camera/color/camera_info'),
        ],
    )

    nvblox_container = ComposableNodeContainer(
        name='roscar_nvblox_container',
        namespace='',
        package='rclcpp_components',
        executable='component_container_mt',
        composable_node_descriptions=[nvblox],
        output='screen',
        arguments=['--ros-args', '--log-level', 'info'],
        respawn=True,
        respawn_delay=2.0,
    )

    monitor = Node(
        package='roscar_bringup',
        executable='stack_monitor',
        name='roscar_stack_monitor',
        output='screen',
        respawn=True,
        respawn_delay=2.0,
    )

    rviz = Node(
        package='rviz2',
        executable='rviz2',
        name='rviz2',
        arguments=['-d', rviz_config],
        output='screen',
        condition=IfCondition(use_rviz),
        respawn=True,
        respawn_delay=3.0,
    )

    return LaunchDescription([
        DeclareLaunchArgument('use_rviz', default_value='true'),
        camera,
        TimerAction(period=2.0, actions=[vslam_container]),
        TimerAction(period=4.0, actions=[nvblox_container]),
        monitor,
        TimerAction(period=8.0, actions=[rviz]),
    ])
