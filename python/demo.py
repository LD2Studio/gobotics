from gobotics.robots import DifferentialRobot
import time
my_robot = DifferentialRobot(4243)

def setup():
    pass

def loop():
    my_robot.move(-5,5)
    time.sleep(1)

def main():
    while my_robot.is_running():
        loop()

    my_robot.move(0,0)
    print('Exited demo.py')

if __name__ == '__main__':
    setup()
    main()
