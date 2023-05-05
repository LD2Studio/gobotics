from gobotics.godotbridge import GodotBridge

class Alpha(GodotBridge):

    def stop(self):
        self.set("set_vr", 0)
        self.set("set_vl", 0)

    def move(self, right_vel, left_vel):
        self.set("set_vr", right_vel)
        self.set("set_vl", left_vel)
    def set_pose(self, x, z, a):
        self.set("set_pose", x, z, a)
    def get_pose(self):
        return self.get("get_pose")
    def is_running(self) -> bool:
        return self.get("is_running")