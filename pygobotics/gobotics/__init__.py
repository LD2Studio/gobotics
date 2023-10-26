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

class Robot(GodotBridge):
    def set_revolute_angle(self, name: str, value: float):
        self.call("set_revolute", name, value)
    
    def set_prismatic_dist(self, name: str, value: float):
        self.call("set_prismatic", name, value)

# class DifferentialRobot(GodotBridge):
    
#     def set_pose(self, x, y, a):
#         self.set("set_pose", x, y, a)

#     def get_pose(self):
#         return self.get("get_pose")
    
#     def move(self, right_vel, left_vel):
#         self.set("move", right_vel, left_vel)
