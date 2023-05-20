from gobotics import engine
from gobotics.robots import Alpha
import time

# engine.reload()
engine.stop()
alpha = Alpha(4243)
alpha.set_pose(0,0,0)
time.sleep(0.5)

engine.run()

alpha.move_to((1,0.05,1), 6, feedback=True)
while not alpha.task_finished():
    time.sleep(1)

alpha.move_to((0,0.05,1), 6, True)
while not alpha.task_finished():
    time.sleep(1)

alpha.move_to((0,0.05,0), 5, True)
while not alpha.task_finished():
    time.sleep(1)
