from gobotics import app, OmniRobot
from time import sleep
from math import radians

my_omni = OmniRobot(4243)
app.reload()
app.run()

my_omni.set_pose(0,0,radians(45))
my_omni.move(5,-5,0)

while True:
    pose = my_omni.get_pose()
    if pose[0] > 1.0: # Xr > 1m
        my_omni.move(0,0,0)
        break
    sleep(0.1)

app.stop()
