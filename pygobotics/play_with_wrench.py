from gobotics import app, GodotBridge
import time

class Wrench(GodotBridge):
    def set_value(self, value: float):
        self.set("set_grouped_joints", "control_wrench", value)

app.run()
wrench = Wrench(4243)

wrench.set_value(0.5)
time.sleep(1)
wrench.set_value(0)
time.sleep(1)

app.stop()
