from robot_beta import RobotBeta
import time

robot = RobotBeta(4242)

robot.run()

robot.move(5,5)
time.sleep(2)
robot.move(0,0)

robot.stop()