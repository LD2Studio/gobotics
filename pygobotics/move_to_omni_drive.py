from gobotics import app, OmniRobot
from time import sleep

my_robot = OmniRobot(4243)
app.reload()
app.run()


my_robot.set_pose(0, 0, 0)

my_robot.move_to(position = (0.5,0.5), speed = 15,
                precision = 0.01, response = 30)

while True:
    if my_robot.finished_task():
        break

my_robot.rotate_to(-2, speed = 15)
while True:
    if my_robot.finished_task():
        break

my_robot.rotate_to(2, speed = 15)
while True:
    if my_robot.finished_task():
        break

my_robot.rotate_to(-2, speed = 15)
while True:
    if my_robot.finished_task():
        break

# my_robot.rotate_to(-3.141, speed = 15)
# while True:
#     if my_robot.finished_task():
#         break

my_robot.move_to(position = (0,0), speed = 15,
                precision = 0.01, response = 30)

while True:
    if my_robot.finished_task():
        break

my_robot.rotate_to(0.0, speed = 15)
while True:
    if my_robot.finished_task():
        break

print("position: ", my_robot.get_pose()[0:2])
app.stop()

