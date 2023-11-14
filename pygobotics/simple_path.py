from gobotics import app, DiffRobot
from gobotics.helper import Timer, StateMachine, clamp
from time import sleep
from math import atan2, degrees, radians, sin, cos

my_robot = DiffRobot(4243)

# print("Pose: ", my_robot.get_pose())

app.run()
my_robot.set_pose(0,0,radians(0))

target_pos = [0, 0]
Kp = 5.0
speed = 5.0
max_speed = 7.0

# State functions
def idle(once):
    if once:
        my_robot.move(0,0)
    else:
        sm1.to("line_control")

def line_control(once):
    global target_pos
    if once:
        print("Move to target")
    pose = my_robot.get_pose()
    d_square = pow((target_pos[0] - pose[0]), 2) + pow((target_pos[1] - pose[1]), 2)
    # print("d_square: ", d_square)
    if d_square > 0.001:
        # theta_m = atan2(target_pos[1] - pose[1], target_pos[0] - pose[0])
        # print("theta_m: ", degrees(theta_m))
        # err_theta = theta_m - pose[2]

        dir = [cos(pose[2]), sin(pose[2])]
        line = [target_pos[0] - pose[0], target_pos[1] - pose[1]]
        err_theta = atan2(dir[0]*line[1] - dir[1]*line[0], dir[0]*line[0] + dir[1]*line[1])

        # print("err_theta: ", degrees(err_theta))
        omega_c = Kp * err_theta
        vr = clamp(speed + omega_c, -max_speed, max_speed)
        vl = clamp(speed - omega_c, -max_speed, max_speed)
        my_robot.move(vr, vl)
        # print("vr: %f , vl: %f" % (vr, vl))
    else:
        my_robot.move(0,0)
        sm1.to("orientation_control")

def orientation_control(once):
    if once:
        print("Moves towards the desired direction")


sm1 = StateMachine({
    "idle": idle,
    "line_control": line_control,
    "orientation_control": orientation_control,
})

sm1.start("idle")

try:
    target_pos = [0,1]
    while sm1.running:
        sm1.update()
except KeyboardInterrupt:
    print("stop")
    my_robot.move(0, 0)
    app.stop()
