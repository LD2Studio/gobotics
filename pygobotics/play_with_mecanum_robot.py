from gobotics import app, GodotBridge
from time import sleep

class MecanumRobot(GodotBridge):
    def get_pose(self) -> list:
        return self.get("get_pose")
    def set_pose(self, x: float, y: float, a: float):
        self.set("set_pose", x,y,a)
    def move(self, fr_vel: float, fl_vel: float, br_vel: float, bl_vel: float):
        self.set("move", fr_vel, fl_vel, br_vel, bl_vel)


my_robot = MecanumRobot(4243)

app.run()

print(my_robot.get_pose())
my_robot.set_pose(0,0,0)

my_robot.move(5,5,5,5)

while True:
    pose = my_robot.get_pose()
    if pose[0] > 1.0:
        my_robot.move(0,0,0,0)
        break
    sleep(0.01)

sleep(1)
app.stop()