from gobotics import app, Robot
import time

app.run()
my_servo = Robot(4243)
my_servo.set_prismatic_config("arm_servo", False)
my_servo.set_prismatic_dist("arm_servo", 0)
time.sleep(2)

my_servo.set_prismatic_config("arm_servo", True)
# print("dist: ", my_servo.get_prismatic_dist("arm_servo"))
# my_servo.set_prismatic_dist("arm servo", 0.1)
# my_servo.set_prismatic_vel("arm servo", 0.2)
# time.sleep(1)

# print("dist: ", my_servo.get_prismatic_dist("arm_servo"))
# my_servo.set_prismatic_dist("arm_servo", 0)
# my_servo.set_prismatic_vel("arm servo", 0)
# time.sleep(2)

import numpy as np
import matplotlib.pyplot as plt

times = []
dist_array = []

target_dist = 0.1
K = 20
t = 0.0
dist, tick_start = my_servo.get_prismatic("arm servo")
print("tick start: ", tick_start)
try:
    while True:
        dist, tick = my_servo.get_prismatic("arm servo")
        dist_array.append(dist)
        times.append(t)
        err = target_dist - dist
        command = K * err
        my_servo.set_prismatic_vel("arm servo", command)
        t = (tick - tick_start)/120.0

except KeyboardInterrupt:
    my_servo.set_prismatic_config("arm_servo", False)
    app.stop()

print("continue...")

plt.figure()
plt.plot(times, dist_array)
plt.grid()
plt.show()