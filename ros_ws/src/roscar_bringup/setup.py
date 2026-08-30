from glob import glob
from setuptools import find_packages, setup


package_name = 'roscar_bringup'

setup(
    name=package_name,
    version='0.1.0',
    packages=find_packages(),
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
        ('share/' + package_name + '/launch', glob('launch/*.launch.py')),
        ('share/' + package_name + '/config', glob('config/*.yaml')),
        ('share/' + package_name + '/rviz', glob('rviz/*.rviz')),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='roscar maintainers',
    maintainer_email='maintainers@example.invalid',
    description='Reproducible ROS car perception bring-up.',
    license='Apache-2.0',
    entry_points={
        'console_scripts': [
            'stack_monitor = roscar_bringup.stack_monitor:main',
        ],
    },
)
