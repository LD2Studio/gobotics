from gobotics import Robot

class DifferentialRobot(Robot):
    def is_running(self) -> bool:
        return self.get("is_running")
    
    def set_pose(self, x, y, a):
        self.set("set_pose", x, y, a)

    def get_pose(self):
        return self.get("get_pose")
    
    def move(self, right_vel, left_vel):
        self.set("move", right_vel, left_vel)

    def move_to(self, new_pose: tuple, speed: float):
        self.set("move_to", new_pose, speed)
    
    def task_finished(self) -> bool:
        return self.get("task_finished")
