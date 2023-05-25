from gobotics.props import Props

ball = Props(4243)

print("Position de la balle: ", ball.get_position())

ball.set_position(0,0.5,0)
print("Nouvelle position de la balle: ", ball.get_position())