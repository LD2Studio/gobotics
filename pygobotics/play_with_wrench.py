from gobotics import app, Robot
import time

app.run()
wrench = Robot(4243)

wrench.set_grouped_joints("two_sliders", 0)
time.sleep(2)
wrench.set_grouped_joints("two_sliders", 0.1)
time.sleep(2)

app.stop()
