from gobotics.godotbridge import GodotBridge

class Ball(GodotBridge):
    def get_position(self):
        return self.get("get_position")