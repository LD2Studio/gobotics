from godotbridge import GodotBridge

class RobotBeta(GodotBridge):

    def run(self):
        self.call("run")

    def stop(self):
        self.call("set_right_wheel_vel", 0)
        self.call("set_left_wheel_vel", 0)
        self.call("stop")

    def move(self, right_vel, left_vel):
        self.call("set_right_wheel_vel", right_vel)
        self.call("set_left_wheel_vel", left_vel)

    def localisation(self):
        return self.call("get_localisation")