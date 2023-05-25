from gobotics import app
from gobotics.props import Props
from gobotics.robots import DifferentialRobot
import time

app.print("Hello Gobotics!")

ball = Props(4243)
print("Position de la balle: ", ball.get_position())

ball.set_position(0,0.5,0)
app.run()

time.sleep(2)
app.stop()

# my_robot = DifferentialRobot(4243)
# my_robot_2 = DifferentialRobot(4244)
# print("Pose of my_robot: ", my_robot.get_pose())
# print("Pose of my_robot_2: ", my_robot_2.get_pose())

# my_robot.set_pose(1, 0, math.radians(-90))
# my_robot_2.set_pose(0,-1,math.radians(180))
# engine.run()

# engine.stop()