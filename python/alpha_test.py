from gobotics import engine
from gobotics.robots import Alpha
import time

# engine.reload()
engine.stop()
alpha = Alpha(4243)
alpha.toto()

alpha.set_pose(0,0,0)
time.sleep(1)

engine.run()
# alpha.move(5, 2)

alpha.move_to_pose((1,-1,0), 8)

while not alpha.task_finished():
    time.sleep(1)

time.sleep(1)

alpha.move_to_pose((0,0,0), 8)

while not alpha.task_finished():
    time.sleep(1)

print(alpha.get_pose())
# alpha.move(0,0)
engine.stop()