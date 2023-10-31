import os
import shutil
import subprocess

version = "0.8.1"
py_version = "0.3.0"

executable = {
    "linux": "gobotics.x86_64",
    "windows": "gobotics.exe",
}

if os.path.exists("exports"):
    shutil.rmtree('exports')
os.mkdir("exports")
subprocess.call(["touch", "exports/.gdignore"])

for platform in ["linux", "windows"]:

    os.mkdir("exports/gobotics-"+ version +"-"+ platform+"-x86_64")
    os.mkdir("exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets")
    os.mkdir("exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/demo")
    os.mkdir("exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/demo/meshes")
    os.mkdir("exports/gobotics-"+ version +"-"+ platform+"-x86_64/pygobotics")

    shutil.copy("assets/demo/ball.urdf", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/cube.urdf", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/prism.urdf", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/meshes/prism.glb", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/demo/meshes")
    shutil.copy("assets/demo/robot.urdf", "exports/gobotics-"+ version +"-"+platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/robot_wrench.urdf", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/robot_mecanum.urdf", "exports/gobotics-"+ version +"-"+platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/robot_mecanum_wrench.urdf", "exports/gobotics-"+ version +"-"+platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/servos.urdf", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/slider.urdf", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/demo")

    shutil.copy("pygobotics/dist/pygobotics-"+ py_version +"-py3-none-any.whl", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/pygobotics/")
    shutil.copy("pygobotics/hello_gobotics.py", "exports/gobotics-"+ version +"-"+ platform +"-x86_64/pygobotics/")
    shutil.copy("pygobotics/play_with_servo.py", "exports/gobotics-"+ version +"-"+ platform +"-x86_64/pygobotics/")
    shutil.copy("pygobotics/play_with_robot.py", "exports/gobotics-"+ version +"-"+ platform +"-x86_64/pygobotics/")
    shutil.copy("pygobotics/play_with_mecanum_robot.py", "exports/gobotics-"+ version +"-"+ platform +"-x86_64/pygobotics/")

    subprocess.run(["godot4" , "--export-debug", "Gobotics-"+ platform , "exports/gobotics-"+ version +"-"+ platform + "-x86_64/" + executable[platform], "--headless"])

    shutil.make_archive("exports/gobotics-"+ version +"-"+ platform +"-x86_64", 'zip', "exports/gobotics-"+ version +"-" + platform + "-x86_64")
