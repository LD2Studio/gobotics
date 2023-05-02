from robot_beta import RobotBeta
import time
import math
import numpy as np
import matplotlib.pyplot as plt

def euler_integration(t, z0, u, params):
    v = 0.5 * params[0] * (u[0] + u[1])
    omega = params[0]/(2*params[1]) * (u[0] - u[1])
    delta = t[1] - t[0]

    x0 = z0[0]
    y0 = z0[1]
    theta0 = z0[2]

    x1 = x0 + v*math.cos(theta0 + math.pi/2) * delta
    y1 = y0 + v*math.sin(theta0 + math.pi/2) * delta
    theta1 = theta0 + omega * delta

    z1 = [x1, y1, theta1]
    return z1

def forward_kinematics(z0, t, u, params):
    
    z = np.array([z0])

    for i in range(0, len(t)-1):
        z0 = euler_integration([t[i], t[i+1]], z0, [u[i, 0], u[i, 1]], params)
        z = np.vstack([z, z0])  # concatenates vertically [[x, y, theta],
                            # [x0, y0, theta0], etc ...]

    return z

robot = RobotBeta(4242)
start_time = time.time()
elapsed_time = 5
right_vel = 5
left_vel= -5

robot.run()
# initial condition [x0, y0, theta0]
z0 = robot.localisation()
print("z0: ", z0)

# Kinematics model
# Robot characteristics
r = 0.05    # radius of wheel
b = 0.12    # center-wheel distance

t = np.arange(0, elapsed_time, 0.1)
vel = np.zeros((len(t), 2))

for i in range(0, len(t)):
    vel[i, 0] = right_vel # right wheel velocity
    vel[i, 1] = left_vel # left wheel velocity

params = [r, b]
z_model = forward_kinematics(z0, t, vel, params)

z = np.array([z0])

while (time.time() - start_time) < elapsed_time:
    robot.move(right_vel, left_vel)
    z = np.vstack([z, robot.localisation()])


robot.stop()

plt.plot(z[:, 0], z[:, 1], label="Robot Beta")
plt.plot(z_model[:, 0], z_model[:, 1], label="Model")
plt.xlim(0,3)
plt.ylim(0,2)
plt.grid()
plt.legend()
plt.gca().set_aspect("equal")
plt.show()