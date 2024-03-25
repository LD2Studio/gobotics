import cv2
import numpy as np

from gobotics import app, Robot

app.run()
my_cam = Robot(4243)

while True:
    image = my_cam.image_read("cam1")
    cv2.imshow("Cam1", image)
    if cv2.waitKey(100) & 0xFF == ord('q'):
        break
app.stop()