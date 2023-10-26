from gobotics import Robot
import time

my_servo = Robot(4243)

my_servo.set_prismatic_dist("arm servo", 0.1)
time.sleep(2)

my_servo.set_prismatic_dist("arm_servo", 0)
time.sleep(2)
