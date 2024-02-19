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
    

py_version = "0.9.0"

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
    
    subprocess.run(["godot4_2" , "--export-debug", "Gobotics-"+ platform , "exports/gobotics-"+ version +"-"+ platform + "-x86_64/" + executable[platform], "--headless"])

    shutil.make_archive("exports/gobotics-"+ version +"-"+ platform +"-x86_64", 'zip', "exports/gobotics-"+ version +"-" + platform + "-x86_64")

