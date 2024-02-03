from gobotics import app, DiffRobot
from time import sleep

pioneer = DiffRobot(4243)

app.run()
# pioneer.set_pose(-1, 1, 0)
print("pose: ", pioneer.get_pose())

# pioneer.move(2,-2)
pioneer.move_to((1,0), 4)

while True:
    if pioneer.finished_task():
        break

app.stop()