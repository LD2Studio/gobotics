"""
PD Control Pose
"""

from gobotics import engine
from gobotics.robots import Alpha
import time

# engine.reload()
# engine.stop()
alpha = Alpha(4243)
# alpha.set_pose(0,0,0)
time.sleep(0.5)

# engine.run()

alpha.move_to_pose((1,0,0), 6)
# while not alpha.task_finished():
#     time.sleep(1)

