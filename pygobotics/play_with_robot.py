from gobotics import app, Robot
from math import radians
from time import sleep

my_robot = Robot(4243)
app.run()

print("Pose: ", my_robot.get_pose())

my_robot.set_pose(0,0.5,radians(45))

my_robot.set_continuous_velocity("right_joint", 2)
sleep(2)
my_robot.set_continuous_velocity("right_joint", 0)

sleep(1)
app.stop()
