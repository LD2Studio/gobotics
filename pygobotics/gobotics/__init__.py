from gobotics.godotbridge import GodotBridge
import time
import numpy as np
import cv2

class Gobotics(GodotBridge):
    def run(self):
        self.call("run")
    def stop(self):
        self.call("stop")
    def is_running(self) -> bool:
        return self.call("is_running")
    def reload(self):
        self.call("reload")
        time.sleep(0.1)
    
    def print(self, msg: str):
        self.call("print_on_terminal", msg)

app = Gobotics(4242)

# Robot base
class Robot(GodotBridge):

    def get_pose(self) -> tuple:
        return self.call("get_pose")
    
    def set_pose(self, x: float, y: float, a: float):
        self.call("set_pose", x, y, a)

    def set_continuous_velocity(self, name: str, value: float):
        self.call("set_continuous_velocity", name, value)

    def set_revolute_config(self, name: str, custom: bool):
        self.call("set_revolute_config", name, custom)

    def set_revolute_angle(self, name: str, value: float):
        self.call("set_revolute", name, value)

    def set_revolute_vel(self, name: str, value: float):
        self.call("set_revolute", name, value, True)
    
    def get_revolute(self, name: str) -> tuple:
        return self.call("get_revolute", name)

    def set_prismatic_config(self, name: str, custom: bool):
        self.call("set_prismatic_config", name, custom)
    
    def set_prismatic_dist(self, name: str, value: float):
        self.call("set_prismatic", name, value)

    def set_prismatic_vel(self, name: str, value: float):
        self.call("set_prismatic", name, value, True)

    def get_prismatic(self, name: str) -> tuple:
        return self.call("get_prismatic", name)
    
    def set_grouped_joints(self, name: str, value: float):
        self.call("set_grouped_joints", name, value)

    def is_ray_colliding(self, name: str) -> bool:
        return self.call("is_ray_colliding", name)
    
    def get_ray_scanner(self, name: str) -> tuple:
        return self.call("get_ray_scanner", name)
    
    def get_image(self, name: str) -> bytearray:
        return self.call("get_image", name)
    
    def image_read(self, name: str):
        img = self.call("get_image", name)
        nparr = np.frombuffer(bytes(img), np.uint8)
        return cv2.imdecode(nparr, cv2.IMREAD_COLOR)


    # Diff Drive
class DiffRobot(Robot):
    
    def move(self, right_vel: float, left_vel: float):
        self.call("move_diff_drive", right_vel, left_vel)

    def move_to(self, position: tuple, speed: float,
                precision: float = 0.01,
                response: float = 20):
        self.call("move_to", position, speed, precision, response)

    def finished_task(self) -> bool:
        return self.call("finished_task")

    def stop_task(self):
        self.call("stop_task")

# 4 Mecanum Drive
class MecanumRobot(Robot):

    def move(self, front_right_vel: float, front_left_vel: float, back_right_vel: float, back_left_vel: float):
        self.call("move_mecanum_drive", front_right_vel, front_left_vel, back_right_vel, back_left_vel)

# Omni Drive
class OmniRobot(Robot):
    
    def move(self, wheel_1_vel: float, wheel_2_vel: float, wheel_3_vel: float):
        self.call("move_omni_drive", wheel_1_vel, wheel_2_vel, wheel_3_vel)
    
    def move_to(self, position: tuple, speed: float,
                precision: float = 0.01,
                response: float = 20):
        self.call("move_to", position, speed, precision, response)
    
    def rotate_to(self, angle: float, speed: float):
        self.call("rotate_to", angle, speed)
    
    def finished_task(self) -> bool:
        return self.call("finished_task")
    
    def stop_task(self):
        self.call("stop_task")