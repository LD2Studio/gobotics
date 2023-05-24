from gobotics import engine
from gobotics.robots import DifferentialRobot
import time

# engine.reload()
engine.stop()
my_robot = DifferentialRobot(4243)

my_robot.set_pose(0,0,0)
time.sleep(1)

engine.run()

my_robot.move_to((1,-1,0), 8)

while not my_robot.task_finished():
    time.sleep(1)

time.sleep(1)

my_robot.move_to((0,0,0), 8)

while not my_robot.task_finished():
    time.sleep(1)

print(my_robot.get_pose())
engine.stop()