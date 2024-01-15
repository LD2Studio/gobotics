from gobotics import app, DiffRobot
from time import sleep
import numpy as np
import cv2

app.run()
my_robot = DiffRobot(4243)

while True:
    img = my_robot.get_image("front_cam")
    nparr = np.frombuffer(bytes(img), np.uint8)
    image = cv2.imdecode(nparr, cv2.IMREAD_COLOR) # cv2.IMREAD_COLOR in OpenCV 3.1

    # Convertir l'image en niveaux de gris
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    # Appliquer un lissage pour réduire le bruit
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)

    # Détecter les cercles avec la transformation de Hough circulaire
    circles = cv2.HoughCircles(
        blurred,
        cv2.HOUGH_GRADIENT,
        dp=1,  # Rapport de résolution inverse du détecteur de gradient
        minDist=50,  # Distance minimale entre les centres des cercles détectés
        param1=100,  # Seuil du détecteur de gradient
        param2=30,  # Seuil du vote du détecteur de Hough
        minRadius=50,  # Rayon minimum du cercle
        maxRadius=200  # Rayon maximum du cercle
    )
    print(circles)
    
    # Si des cercles sont détectés, les dessiner sur l'image d'origine
    if circles is not None:
        circles = np.uint16(np.around(circles))
        for i in circles[0, :]:
            # Dessiner le cercle détecté
            cv2.circle(image, (i[0], i[1]), i[2], (0, 255, 255), 2)

    cv2.imshow("Front Cam", image)

    if cv2.waitKey(100) & 0xFF == ord('q'):
        break

cv2.destroyAllWindows()
app.stop()

