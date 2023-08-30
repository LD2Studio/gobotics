from gobotics import app
from gobotics.robots import DifferentialRobot
import time
import math

# app.reload()
my_robot = DifferentialRobot(4243)
print(my_robot.get_pose())
my_robot.set_pose(0,0,math.radians(90))
app.run()

my_robot.move(4,4)
time.sleep(1)
my_robot.move(3,-3)
time.sleep(1)
my_robot.move(4,4)
time.sleep(2)
app.stop()

# my_robot.move_to((0, 1, math.radians(90)), 7)
# while not my_robot.task_finished():
#     time.sleep(1)

# my_robot.move_to((0.5, 1, math.radians(-180)), 7)
# while not my_robot.task_finished():
#     time.sleep(1)

# my_robot.move_to((1, 0, 0), 7)
# while not my_robot.task_finished():
#     time.sleep(1)

# app.stop()
