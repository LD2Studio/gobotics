from gobotics import app, DiffRobot
from gobotics.helper import Timer, StateMachine

my_robot = DiffRobot(4243)

# State functions
def pose(once):
    if once:
        print("init")
        my_robot.set_pose(0,0,0)
        app.run()
    else:
        sm.to("forward")

def forward(once):
    if once:
        print("forward")
        my_robot.move(5, 5)
        timer.start(1)
    else:
        if timer.is_elapsed():
            sm.to("turn_left")

def turn_left(once):
    if once:
        print("turn left")
        my_robot.move(4,-4)
        timer.start(1)
    if timer.is_elapsed():
        sm.to("forward")

timer = Timer()

sm = StateMachine({
    "init": pose,
    "forward": forward,
    "turn_left": turn_left,
})

sm.start("init")

try:
    while sm.running:
        sm.update()
except KeyboardInterrupt:
    print("stop")
    my_robot.move(0, 0)
    app.stop()