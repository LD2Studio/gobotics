import os
import shutil
import subprocess


version = ""

try:
    with open("project.godot", "r", encoding='utf-8') as project:
        for line in project:
            if line.startswith("config/version"):
                version = line.split("=")[1]
                version = version[1:-2]
                print(version)
except FileNotFoundError:
    print("project.godot doesn't found")

py_version = "0.7.0"

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
    os.mkdir("exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/robots")
    os.mkdir("exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/robots/meshes")
    os.mkdir("exports/gobotics-"+ version +"-"+ platform+"-x86_64/pygobotics")

    shutil.copy("assets/demo/ball.urdf", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/cube.urdf", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/robot.urdf", "exports/gobotics-"+ version +"-"+platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/robot_wrench.urdf", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/robot_mecanum.urdf", "exports/gobotics-"+ version +"-"+platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/robot_mecanum_wrench.urdf", "exports/gobotics-"+ version +"-"+platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/servos.urdf", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/slider.urdf", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/demo")
    shutil.copy("assets/demo/rotations.urdf", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/demo")
    shutil.copy("assets/robots/robot_diff.urdf", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/robots")
    shutil.copy("assets/robots/robot_diff_raycast.urdf", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/robots")
    shutil.copy("assets/robots/meshes/PioneerCaster.glb", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/robots/meshes")
    shutil.copy("assets/robots/meshes/PioneerChassis.glb", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/robots/meshes")
    shutil.copy("assets/robots/meshes/PioneerWheel.glb", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/assets/robots/meshes")


    shutil.copy("pygobotics/dist/pygobotics-"+ py_version +"-py3-none-any.whl", "exports/gobotics-"+ version +"-"+ platform+"-x86_64/pygobotics/")
    shutil.copy("pygobotics/hello_gobotics.py", "exports/gobotics-"+ version +"-"+ platform +"-x86_64/pygobotics/")
    shutil.copy("pygobotics/play_with_servo.py", "exports/gobotics-"+ version +"-"+ platform +"-x86_64/pygobotics/")
    shutil.copy("pygobotics/play_with_robot.py", "exports/gobotics-"+ version +"-"+ platform +"-x86_64/pygobotics/")
    shutil.copy("pygobotics/play_with_mecanum_robot.py", "exports/gobotics-"+ version +"-"+ platform +"-x86_64/pygobotics/")
    shutil.copy("pygobotics/play_with_state_machine.py", "exports/gobotics-"+ version +"-"+ platform +"-x86_64/pygobotics/")
    shutil.copy("pygobotics/play_with_rotations.py", "exports/gobotics-"+ version +"-"+ platform +"-x86_64/pygobotics/")

    subprocess.run(["godot4_2" , "--export-debug", "Gobotics-"+ platform , "exports/gobotics-"+ version +"-"+ platform + "-x86_64/" + executable[platform], "--headless"])

    shutil.make_archive("exports/gobotics-"+ version +"-"+ platform +"-x86_64", 'zip', "exports/gobotics-"+ version +"-" + platform + "-x86_64")

