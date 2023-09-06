from gobotics.godotbridge import GodotBridge
import time

class Gobotics(GodotBridge):
    def run(self):
        self.set("run")
    def stop(self):
        self.set("stop")
    def is_running(self) -> bool:
        return self.get("is_running")
    def reload(self):
        self.set("reload")
        time.sleep(0.1)
    
    def print(self, msg: str):
        self.set("print_on_terminal", msg)

class DifferentialRobot(GodotBridge):
    
    def set_pose(self, x, y, a):
        self.set("set_pose", x, y, a)

    def get_pose(self):
        return self.get("get_pose")
    
    def move(self, right_vel, left_vel):
        self.set("move", right_vel, left_vel)

app = Gobotics(4242)