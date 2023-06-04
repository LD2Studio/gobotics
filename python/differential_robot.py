from gobotics import app
from gobotics.robots import DifferentialRobot
import time

# engine.reload()
app.stop()
my_robot = DifferentialRobot(4243)

my_robot.set_position(0,0.5,0)
app.run()
time.sleep(2)

my_robot.set_pose(0,0,0)
time.sleep(1)

app.run()

my_robot.move_to((1,-1,0), 8)

while not my_robot.task_finished():
    time.sleep(1)

# time.sleep(1)

my_robot.move_to((0,0,0), 8)

while not my_robot.task_finished():
    time.sleep(1)

print(my_robot.get_pose())
app.stop()