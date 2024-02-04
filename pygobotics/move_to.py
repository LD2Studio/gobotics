from gobotics import app, DiffRobot
from time import sleep

pioneer = DiffRobot(4243)

app.run()


pioneer.set_pose(0, 0, 0)

pioneer.move_to(position = (0,1), speed = 8,
                precision = 0.01, response = 30)

while True:
    if pioneer.finished_task():
        break

print("position: ", pioneer.get_pose()[0:2])
app.stop()

