from gobotics.godotbridge import GodotBridge

class Gobotics(GodotBridge):
    def run(self):
        self.set("run")
    def stop(self):
        self.set("stop")
    def is_running(self) -> bool:
        return self.get("is_running")

engine = Gobotics(4242)