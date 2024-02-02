from gobotics import app, DiffRobot
from time import sleep

pioneer = DiffRobot(4243)

app.run()

# pioneer.move(2,-2)
pioneer.move_to((1,0), 2)

sleep(2)

app.stop()