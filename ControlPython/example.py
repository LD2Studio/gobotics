from gobotics.robots import Alpha
import time

alpha = Alpha(4242)

alpha.set_pose(0,0,0)

if alpha.is_running():
    alpha.move(4,4)
    time.sleep(1)
    alpha.move(4,-4)
    time.sleep(1)
    alpha.move(-4,-4)
    time.sleep(1)
    alpha.stop()
else:
    print("Scene is not running!")