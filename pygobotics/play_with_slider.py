from gobotics import GodotBridge, app
import time

class Slider(GodotBridge):

    def set_slider_translation(self, name: str, value: float):
        self.set("set_prismatic", name, value)

app.run()
my_servo = Slider(4243)

my_servo.set_slider_translation("arm servo", 0.1)
time.sleep(2)

my_servo.set_slider_translation("arm_servo", 0)
time.sleep(2)

app.stop()