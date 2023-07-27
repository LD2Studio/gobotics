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

class Robot(GodotBridge):
    def get_pose(self):
        return self.get("get_pose")
    def set_position(self, x: float, y: float, z: float):
        self.set("set_pos", (x,y,z))

app = Gobotics(4242)