from gobotics import app, OmniRobot
from time import sleep

my_robot = OmniRobot(4243)
app.reload()
app.run()


my_robot.set_pose(0, 0, 0)

my_robot.move_to(position = (1,0), speed = 8,
                precision = 0.01, response = 30)

while True:
    if my_robot.finished_task():
        break

print("position: ", my_robot.get_pose()[0:2])
app.stop()

