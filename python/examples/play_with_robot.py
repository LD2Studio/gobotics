from gobotics import app
from gobotics.robots import DifferentialRobot
import time
import math

my_robot = DifferentialRobot(4243)
my_robot.set_pose(1,0,0)
app.run()

my_robot.move(6,6)
time.sleep(2)

my_robot.move_to((2, -1, math.radians(90)), 7)
while not my_robot.task_finished():
    time.sleep(0.1)

# my_robot.move_to((0.5, 1, 0), 7)
# while not my_robot.task_finished():
#     time.sleep(0.1)

# my_robot.move_to((0, 0, 0), 7)
# while not my_robot.task_finished():
#     time.sleep(0.1)

# time.sleep(1)
# print("Target pose: ", my_robot.get_pose())
my_robot.move(0,0)
app.stop()