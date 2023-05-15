from gobotics.godotbridge import GodotBridge

class Alpha(GodotBridge):
    
    def set_pose(self, x, z, a):
        self.set("set_pose", x, z, a)

    def get_pose(self):
        return self.get("get_pose")
    
    def move(self, right_vel, left_vel):
        self.set("move", right_vel, left_vel)

    def move_to(self, target_pos: tuple, speed: float):
        self.set("move_to", target_pos, speed)
    
