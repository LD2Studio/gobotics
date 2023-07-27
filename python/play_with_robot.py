from gobotics import app, Robot
from time import sleep

my_robot = Robot(4243)

while True:
    print(my_robot.get_pose())
    sleep(1)
