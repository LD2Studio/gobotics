from gobotics import app, GodotBridge
from time import sleep

object = GodotBridge(4244)

app.run()


object.set("set_prismatic", "arm_servo", 0)
sleep(2)

object.set("set_prismatic", "arm_servo", 0.2)

sleep(2)
app.stop()
