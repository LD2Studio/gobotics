from gobotics import Robot, app
from time import sleep

app.run()

my_device = Robot(4243)

my_device.set_revolute_angle("rot1", 0)

sleep(2)

my_device.set_revolute_angle("rot1", 45)

sleep(2)

my_device.set_continuous_velocity("rot2", 2)

sleep(2)

my_device.set_continuous_velocity("rot2", 0)
app.stop()