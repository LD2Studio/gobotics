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

app = Gobotics(4242)