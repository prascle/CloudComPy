## Installing, testing and using a CloudComPy binary on Linux, with conda

The binary *CloudComPy_Conda312_Linux64_-date-.tgz* available [here](https://www.simulation.openfields.fr/index.php/cloudcompy-downloads) is built with a Conda environment
(see [here](BuildLinuxConda.md) for the corresponding building instructions).

As CloudComPy is under development, these instructions and the link are subject to change from time to time...

**This binary works only on Linux 64, on recent distributions, and with a (virtual) Python 3.12 environment as described below**.

**Only tested un Ubuntu 26.04 and Ubuntu 20.04, please report any problems on other distributions.**

GLIBC version should be 2.28 or more. To know your version of GLIBC:

```
ldd --version
```

**Note:** CloudComPy versions released in 2025 and earlier were built using a **Conda** **Python 3.10** or **Python 3.11** environment: **CloudComPy310** or  **CloudComPy311**.
Now, new versions require only a **Python 3.12** environment. **Conda is not needed anymore**, unless you want it to provide your Python packages.

The Python 3.12 environment must contain the following packages to run all the tests : 
```numpy requests psutil scipy numpy-quaternion cmake matplotlib```

Create a Python virtual environment with venv (*adapt the path for Your Python 3.12 install and for the virtual env*). In the terminal :

```
path/to/python3.12 -m venv ${HOME}/.venv312
source ${HOME}/.venv312/bin/activate
python3 -m pip install --upgrade pip
pip install numpy scipy requests psutil matplotlib numpy-quaternion cmake
```

Unzip the CloudcomPy binary in the directory of your choice.

### Using CloudCompare and CloudComPy:

Before using CloudCompare or CloudComPy, you need to load the environment, with 2 steps :

 - The Python virtual environment:

```
source ${HOME}/.venv312/bin/activate
```

 - The paths (PYTHONPATH, PATH) required for cloudComPy and CloudCompare:

```
cd path/to/CloudComPy312
source bin/envCloudComPy.sh activate
```

To run CloudCompare:

```
CloudCompare
```

To execute a Python script (for instance myscript.py) using CloudComPy:

```
python myscript.py
```

### Working with an Integrated Development Environment

On Linux, the integrated development environments [Spyder](https://www.spyder-ide.org/) and [Jupyter](https://jupyter.org/) have not yet been tested with this version of CloudComPy.

### Execute all the Python tests:

In the virtual environment above :
```
cd path/to/CloudComPy312/cloudComPy/doc/PythonAPI_test
```

To execute all the tests (takes about three to five minutes, creates about 2.2GB of data files):

```
ctest
```

The files created with the tests are in your user space: `${HOME}/CloudComPy/Data`

From the prompt, you can :

### In case of problem:

There may be a version conflict between some libraries included in the cloudComPy package and those provided by your Python environment, depending on the packages you have installed. Please post an issue on CloudComPy GitHub [bugtracker](https://github.com/CloudCompare/CloudComPy/issues).

