from setuptools import setup, find_packages
import codecs
import os.path

setup(
    name="data-platform-databricks",
    version="1.0",
    packages=find_packages(exclude=["unittests", "unittests.*"]),
    install_requires=["atc-dataplatform"],
    description="Common Python Library for Data Platform"
)