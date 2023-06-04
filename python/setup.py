from setuptools import setup, find_packages

setup(
    name = "pygobotics",
    version = "0.0.4",
    author = "Laurent Dethoor",
    author_email = "ld2studiogame@gmail.com",
    packages = ["gobotics"],
    install_requires = [
        'numpy',
    ],
)