from gobotics import Robot, app
import time

app.run()
my_servo = Robot(4243)
my_servo.set_revolute_angle("arm_servo", 0)
my_servo.set_revolute_angle("arm2_servo", 0)
# my_servo.set_revolute_angle("arm3_servo", 0)

time.sleep(1)

my_servo.set_revolute_angle("arm servo", 45)
my_servo.set_revolute_angle("arm2_servo", -45)
time.sleep(1)

app.stop()