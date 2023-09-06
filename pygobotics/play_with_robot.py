from gobotics import app, DifferentialRobot
from time import sleep

my_robot = DifferentialRobot(4243)

app.run()
my_robot.set_pose(0,0,0)
my_robot.move(5,5)

while True:
    pose = my_robot.get_pose()
    if pose[0] > 1.0:
        my_robot.move(0,0)
        break
    sleep(0.1)

sleep(1)
app.stop()