from gobotics import app, DiffRobot
from time import sleep
from math import radians

my_robot = DiffRobot(4243)

app.run()

my_robot.set_pose(0,0,radians(45))
my_robot.move(5,5)

while True:
    pose = my_robot.get_pose()
    if pose[0] > 1.0: # Xr > 1m
        my_robot.move(0,0)
        break
    sleep(0.1)

app.stop()
