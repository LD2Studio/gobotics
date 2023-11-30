from gobotics import app, DiffRobot, MecanumRobot
from time import sleep

my_robot = DiffRobot(4243)
robot2 = MecanumRobot(4251)


my_robot.set_pose(0,0,0)
my_robot.move(5,5)
robot2.set_pose(0,1,-0.5)
robot2.move(0,0,0,0)

while True:
    pose = my_robot.get_pose()
    if pose[0] > 1.0:
        my_robot.move(0,0)
        break
    sleep(0.1)

robot2.move(5,5,5,5)
while True:
    pose = robot2.get_pose()
    if pose[0] > 0.5:
        robot2.move(4,-4,4,-4)
        break
    sleep(0.1)