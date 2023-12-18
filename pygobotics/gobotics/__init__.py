from gobotics.godotbridge import GodotBridge
import time

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

    def is_ray_colliding(self, name: str) -> bool:
        return self.call("is_ray_colliding", name)
    
    def get_ray_scanner(self, name: str) -> tuple:
        return self.call("get_ray_scanner", name)

    # Diff Drive
class DiffRobot(Robot):
    
    def move(self, right_vel: float, left_vel: float):
        self.call("move_diff_drive", right_vel, left_vel)

# 4 Mecanum Drive
class MecanumRobot(Robot):

    def move(self, front_right_vel: float, front_left_vel: float, back_right_vel: float, back_left_vel: float):
        self.call("move_mecanum_drive", front_right_vel, front_left_vel, back_right_vel, back_left_vel)