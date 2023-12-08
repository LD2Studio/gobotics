from gobotics import app, DiffRobot
from time import sleep

app.run()
my_robot = DiffRobot(4243)

try:
    while True:
        if my_robot.is_ray_colliding("front_ray"):
            print("ray lengths: ", my_robot.get_ray_scanner("front_ray"))
        sleep(0.1)
except:
    app.stop()
