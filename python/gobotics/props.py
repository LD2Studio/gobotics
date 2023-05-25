from gobotics.godotbridge import GodotBridge

class Props(GodotBridge):
    def get_position(self):
        return self.get("get_pos")
    def set_position(self, x: float, y: float, z: float):
        self.set("set_pos", (x,y,z))