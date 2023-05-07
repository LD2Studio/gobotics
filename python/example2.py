from gobotics import engine
from gobotics.robots import Alpha
import time

engine.run()

alpha = Alpha(4243)
alpha2 = Alpha(4244)

alpha.set_pose(0,0,0)
alpha2.set_pose(1, 0, 0)

time.sleep(1)

alpha.move(4,4)
alpha2.move(4,-4)
time.sleep(1)
alpha.move(4,-4)
alpha2.move(4,4)
time.sleep(1)
alpha.move(-4,-4)
alpha2.move(6,6)
time.sleep(1)
alpha.move(0,0)
alpha2.move(0,0)

engine.stop()
