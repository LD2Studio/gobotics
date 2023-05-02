import matplotlib.pyplot as plt
import numpy as np
import time
from godotbridge import GodotBridge

robot = GodotBridge(4242)

# Robot characteristics
r = 0.05    # radius of wheel
right_rot_vel = 0
left_rot_vel = 0

loop = True
state = 1

start_time = time.time()
robot.call("run")
is_actived = False

# initial condition [x0, y0, theta0]
z0 = robot.call("get_localisation")
# print(robot.call("get_localisation"))
z = np.array([z0])

while loop:
    # print(is_actived)
    if state == 0:
        if not is_actived:
            # print(robot.call("get_localisation"))
            robot.call("set_right_wheel_vel", 0)
            robot.call("set_left_wheel_vel", 0)
            is_actived = True
            print("State 0")
            break

    elif state == 1:
        if not is_actived:
            # print(robot.call("get_localisation"))
            robot.call("set_right_wheel_vel", 5)
            robot.call("set_left_wheel_vel", 5)
            is_actived = True
            start_time = time.time()
            print("State 1")
        elif elapsed_time > 1:
            state = 2
            is_actived = False
        z = np.vstack([z, robot.call("get_localisation")])

    elif state == 2:
        if not is_actived:
            # print(robot.call("get_localisation"))
            robot.call("set_right_wheel_vel", 4)
            robot.call("set_left_wheel_vel", -4)
            is_actived = True
            start_time = time.time()
            print("State 2")
        elif elapsed_time > 1:
            state = 3
            is_actived = False
        z = np.vstack([z, robot.call("get_localisation")])

    elif state == 3:
        if not is_actived:
            # print(robot.call("get_localisation"))
            robot.call("set_right_wheel_vel", 5)
            robot.call("set_left_wheel_vel", 5)
            is_actived = True
            start_time = time.time()
            print("State 3")
        elif elapsed_time > 1:
            state = 0
            is_actived = False
        z = np.vstack([z, robot.call("get_localisation")])

    elapsed_time = time.time() - start_time
    

print("End loop")

robot.call("set_right_wheel_vel", 0)
robot.call("set_left_wheel_vel", 0)
robot.call("stop")

# print(z)
# for i in range(0, len(z)):
#     # print(z[i])

#     shape, = plt.plot(z[0:i, 0], z[0:i, 1], color="red")

#     plt.xlim(0,3)
#     plt.ylim(0,2)
#     plt.gca().set_aspect("equal")
#     plt.pause(0.1)

#     shape.remove()

plt.plot(z[:, 0], z[:, 1])
plt.xlim(0,3)
plt.ylim(0,2)
plt.grid()
plt.gca().set_aspect("equal")
plt.show()