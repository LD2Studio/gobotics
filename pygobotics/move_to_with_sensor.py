from gobotics import app, DiffRobot
from time import sleep

my_robot = DiffRobot(4243)
app.reload()
app.run()


my_robot.set_pose(0, 0, 0)

my_robot.move_to(position = (1,1), speed = 8,
                precision = 0.01, response = 30)

while True:
    if my_robot.finished_task():
        break
    if my_robot.is_ray_colliding("lidar1"):
        my_robot.stop_task()
        break
    
print("position: ", my_robot.get_pose()[0:2])

app.stop()

