from robot_beta import RobotBeta
import time
import numpy as np
import matplotlib.pyplot as plt

robot = RobotBeta(4242)
start_time = time.time()
elapsed_time = 3

robot.run()
z0 = robot.localisation()
print("z0: ", z0)
z = np.array([z0])

while (time.time() - start_time) < elapsed_time:
    robot.move(4,1)
    z = np.vstack([z, robot.localisation()])


robot.stop()

plt.plot(z[:, 0], z[:, 1])
plt.xlim(0,3)
plt.ylim(0,2)
plt.grid()
plt.gca().set_aspect("equal")
plt.show()