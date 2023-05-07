from gobotics.godotbridge import GodotBridge

class Alpha(GodotBridge):
    
    def move(self, right_vel, left_vel):
        self.set("set_vr", right_vel)
        self.set("set_vl", left_vel)
    def set_pose(self, x, z, a):
        self.set("set_pose", x, z, a)
    def get_pose(self):
        return self.get("get_pose")
