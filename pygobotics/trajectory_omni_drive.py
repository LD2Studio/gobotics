from gobotics import app, OmniRobot
from time import sleep

my_robot = OmniRobot(4243)
app.reload()
app.run()

trajectory = [
    [(0,0), 0],
    [(1,0), 1.57],
    [(1,1), 1.57],
    [(0,0), 0],
]


my_robot.set_pose(0, 0, 0)

for path in trajectory:
    my_robot.move_to(position = path[0], speed = 12)

    while True:
        if my_robot.finished_task():
            break
    
    my_robot.rotate_to(path[1], speed = 8)

    while True:
        if my_robot.finished_task():
            break

app.stop()

