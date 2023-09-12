from gobotics import GodotBridge, app
from gobotics.helper import Timer, StateMachine
import time

class Servo(GodotBridge):

    def set_revolute_angle(self, name: str, value: float):
        self.set("set_revolute", name, value)

# State functions
def start_scenario(once):
    if once:
        print("start scenario")
        app.run()
    else:
        sm.to("init")

def init_scenario(once):
    if once:
        print("init scenario")
        my_servo.set_revolute_angle("arm_servo", 0)
        my_servo.set_revolute_angle("arm2_servo", 0)
        timer.start(1)
    elif timer.is_elapsed():
            sm.to("rotate")

def rotate(once):
    if once:
        print("rotate")
        my_servo.set_revolute_angle("arm servo", 90)
        my_servo.set_revolute_angle("arm2_servo", -90)
        timer.start(1)
    elif timer.is_elapsed():
        sm.to("stop")

def stop(once):
    print("stop")
    sm.running = False
    app.stop()

timer = Timer()
sm = StateMachine({
    "start": start_scenario,
    "init": init_scenario,
    "rotate": rotate,
    "stop": stop,
})

my_servo = Servo(4243)

sm.start("start")

while sm.running:
    try:
        sm.update()
    except KeyboardInterrupt:
        sm.running = False
        app.stop()