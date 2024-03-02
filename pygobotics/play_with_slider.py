from gobotics import app, Robot
import time

app.run()
my_servo = Robot(4243)

my_servo.set_prismatic_dist("slider_joint", 0.1)
time.sleep(2)

my_servo.set_prismatic_dist("slider_joint", -0.1)
time.sleep(2)
