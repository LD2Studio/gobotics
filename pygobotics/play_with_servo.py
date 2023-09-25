from gobotics import GodotBridge, app
import time

class Servo(GodotBridge):

    def set_revolute_angle(self, name: str, value: float):
        self.set("set_revolute", name, value)

app.run()
my_servo = Servo(4243)
my_servo.set_revolute_angle("arm_servo", 0)

time.sleep(1)

my_servo.set_revolute_angle("arm servo", 90)

time.sleep(1)

app.stop()