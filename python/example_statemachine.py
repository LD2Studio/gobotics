from gobotics import engine
from gobotics.robots import Alpha
from gobotics.helper import Timer, StateMachine

alpha = Alpha(4243)

# State functions
def pose(once):
    if once:
        # print("init")
        alpha.set_pose(0.1,0,0)
        engine.run()
    else:
        sm.to("forward")

def forward(once):
    if once:
        # print("forward")
        alpha.move(5, 5)
        timer.start(1)
    else:
        if timer.is_elapsed():
            sm.to("turn_left")

def turn_left(once):
    if once:
        # print("turn left")
        alpha.move(4,-4)
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

while sm.running:
    try:
        sm.update()
    except KeyboardInterrupt:
        alpha.move(0, 0)
        sm.running = False
        engine.stop()