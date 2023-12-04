from gobotics import app, DiffRobot
from time import sleep

app.run()
my_robot = DiffRobot(4243)
my_robot.set_pose(0,0,0)
my_robot.move(5,5)

while True:
    pose = my_robot.get_pose()
    if pose[0] > 1.0:
        my_robot.move(0,0)
        break
    if my_robot.is_ray_colliding("front_ray"):
        my_robot.move(0,0)
        print("ray length: ", my_robot.get_ray_length("front_ray"))
        break
    sleep(0.1)

app.stop()