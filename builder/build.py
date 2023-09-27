import os
import shutil
import subprocess

version = "0.5.0"
py_version = "0.2.0"

if os.path.exists("exports"):
    shutil.rmtree('exports')

os.mkdir("exports")
os.mkdir("exports/gobotics-"+ version +"-linux-x86_64")
os.mkdir("exports/gobotics-"+ version +"-linux-x86_64/assets")
os.mkdir("exports/gobotics-"+ version +"-linux-x86_64/pygobotics")
shutil.copy("assets/demo/red_ball.asset", "exports/gobotics-"+ version +"-linux-x86_64/assets/")
shutil.copy("assets/demo/green_cube.asset", "exports/gobotics-"+ version +"-linux-x86_64/assets/")
shutil.copy("assets/demo/robot_2_wheels.asset", "exports/gobotics-"+ version +"-linux-x86_64/assets/")
shutil.copy("assets/demo/servo.asset", "exports/gobotics-"+ version +"-linux-x86_64/assets/")
shutil.copy("assets/demo/servo2.asset", "exports/gobotics-"+ version +"-linux-x86_64/assets/")
shutil.copy("pygobotics/dist/pygobotics-"+ py_version +"-py3-none-any.whl", "exports/gobotics-"+ version +"-linux-x86_64/pygobotics/")
shutil.copy("pygobotics/play_with_robot.py", "exports/gobotics-"+ version +"-linux-x86_64/pygobotics/")

os.mkdir("exports/gobotics-"+ version +"-windows-x86_64")
os.mkdir("exports/gobotics-"+ version +"-windows-x86_64/assets")
os.mkdir("exports/gobotics-"+ version +"-windows-x86_64/pygobotics")
shutil.copy("assets/demo/red_ball.asset", "exports/gobotics-"+ version +"-windows-x86_64/assets/")
shutil.copy("assets/demo/green_cube.asset", "exports/gobotics-"+ version +"-windows-x86_64/assets/")
shutil.copy("assets/demo/robot_2_wheels.asset", "exports/gobotics-"+ version +"-windows-x86_64/assets/")
shutil.copy("assets/demo/servo.asset", "exports/gobotics-"+ version +"-windows-x86_64/assets/")
shutil.copy("assets/demo/servo2.asset", "exports/gobotics-"+ version +"-windows-x86_64/assets/")
shutil.copy("pygobotics/dist/pygobotics-"+ py_version +"-py3-none-any.whl", "exports/gobotics-"+ version +"-windows-x86_64/pygobotics/")
shutil.copy("pygobotics/play_with_robot.py", "exports/gobotics-"+ version +"-windows-x86_64/pygobotics/")

subprocess.run(["godot4" , "--export-debug", "Gobotics-v"+ version +"-linux", "exports/gobotics-"+ version +"-linux-x86_64/gobotics.x86_64", "--headless"])
subprocess.run(["godot4" , "--export-debug", "Gobotics-v"+ version +"-windows", "exports/gobotics-"+ version +"-windows-x86_64/gobotics.exe", "--headless"])

shutil.make_archive("exports/gobotics-"+ version +"-linux-x86_64", 'zip', "exports/gobotics-"+ version +"-linux-x86_64")
shutil.make_archive("exports/gobotics-"+ version +"-windows-x86_64", 'zip', "exports/gobotics-"+ version +"-windows-x86_64")