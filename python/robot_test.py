from gobotics import app
from gobotics.robots import DifferentialRobot
import time
import math

# app.reload()
my_robot = DifferentialRobot(4243)
my_robot.set_pose(0,0,math.radians(0))
app.run()

my_robot.move_to((0, 1, math.radians(90)), 7)
while not my_robot.task_finished():
    time.sleep(1)

my_robot.move_to((0.5, 1, math.radians(-180)), 7)
while not my_robot.task_finished():
    time.sleep(1)

my_robot.move_to((1, 0, 0), 7)
while not my_robot.task_finished():
    time.sleep(1)

app.stop()
