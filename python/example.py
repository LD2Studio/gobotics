from gobotics import engine
from gobotics.robots import Alpha
import time

engine.run()

alpha = Alpha(4243)
alpha.set_pose(0,0,0)

time.sleep(1)

alpha.move(4,4)
time.sleep(1)
alpha.move(4,-4)
time.sleep(1)
alpha.move(-4,-4)
time.sleep(1)
alpha.move(0,0)

engine.stop()
