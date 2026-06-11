## Installing, testing and using a CloudComPy binary on Windows 10 or 11 in a Python 3.12 environment

The binary *CloudComPy\*_-date-.7z* available [here](https://www.simulation.openfields.fr/index.php/cloudcompy-downloads) is built in a Conda environment.
(see [here](BuildWindowsConda.md) for the corresponding building instructions).

As CloudComPy is still under development, these instructions and the link are subject to change from time to time...

**This binary works only on Windows 10 or 11, and with a (virtual) Python 3.12 environment as described below**.

**Note:** CloudComPy versions released in 2025 and earlier were built using a **Conda** **Python 3.10** or **Python 3.11** environment: **CloudComPy310** or  **CloudComPy311**.
From now on, new versions only require a **Python 3.12** environment. **Conda is now optional**. Depending on your requirements, you can use either a Conda environment or a Python venv environment.

The Python 3.12 environment (Conda or venv) must contain the following packages to run all the tests : 
```numpy requests psutil scipy (numpy-)quaternion cmake matplotlib``` 
(The Conda package for quaternions is `quaternion`, and the Python venv package for quaternions is `numpy-quaternion`)

### How do I choose between a Conda environment and a venv environment?

The new CloudComPy package (2026) includes all the libraries required by CloudComPy and CloudCompare. Previous versions (2025 and earlier) depended on a specific Conda configuration. The main goal of this packaging change is to avoid being forced to use a very specific Conda environment corresponding to the CloudComPy version. This is quite difficult to manage, as Conda packages evolve rapidly. What works one day may no longer work a few days later.
This new packaging has one drawback: on Windows, there may be a version conflict between certain DLLs included in the cloudComPy package and those provided by your Python environment. This can happen, for example, when you install a package that depends on a different build of Qt6, or if you use Spyder or Jupyter. Conda and PyPI packages are not built in the same way.
If you want to use Jupyter Notebook or Spyder, we recommend using a Conda environment. If you only need the essential packages, a Python venv environment is perfectly suitable.

### Creating a Python venv

Create a Python virtual environment with venv (*adapt the path for Your Python 3.12 install and for the virtual env*). In the Command Prompt (`cmd`) :

```
cd "%USERPROFILE%\AppData\Local\Programs\Python\Python312"
python -m venv "%USERPROFILE%\CloudComPy\venv312"
cd "%USERPROFILE%\CloudComPy"
venv312\Scripts\activate
pip install numpy requests psutil scipy numpy-quaternion cmake matplotlib
```

### Creating a Conda venv

The Conda procedure relies on a `.yml` file that describes the environment to be configured: `cpy312.yml`. 

```yaml
name: cpy312
channels:
 - conda-forge
 - nodefaults
dependencies:
 - python=3.12
 - cmake
 - matplotlib
 - numpy
 - psutil
 - quaternion
 - requests
 - scipy
 - ipykernel
 - jupyter
 - jupyterlab
 - spyder
 ```

To create the Conda environment, use the Conda Command prompt:

 ```bat
conda install -y -n base mamba -c conda-forge
conda update -y -n base -c defaults conda
conda activate 
mamba env create -y -n cpy312 -f cpy312.yml
 ```

Of course, you can replace the name of the Conda environment (cpy312) with the name of your choice.

### Unzip the cloudComPy binary in the directory of your choice. 

## Using CloudCompare and CloudComPy:

### Two steps to set the environment

#### With the Python venv
From the Command Prompt, activate the Python venv, cd to the cloudComPy install and launch envCloudComPy.bat, to set the CloudComPy PATH and PYTHONPATH.

```bat
cd %USERPROFILE%\CloudComPy
venv312\Scripts\activate
cd install\CloudComPy312 rem where the cloudComPy binary file was extracted
envCloudComPy.bat
```
#### With the Conda env
From the Conda Command prompt, activate the Conda env, cd to the cloudComPy install and launch envCloudComPy.bat, to set the CloudComPy PATH and PYTHONPATH.

```bat
conda activate cpy312
cd install\CloudComPy312 rem where the cloudComPy binary file was extracted
envCloudComPy.bat
```

### running CloudCompare and cloudComPy

To run CloudCompare:

```bat
CloudCompare
```

To execute a Python script (for instance myscript.py) using CloudComPy:

```bat
python myscript.py
```

### Working with an Integrated Development Environment

On Windows, the integrated development environments [Spyder](https://www.spyder-ide.org/) and [Jupyter](https://jupyter.org/) only work with the Conda environment.

If you're using a Python venv and looking for an integrated development environment to write, run, and debug your Python scripts, [VS Code](https://code.visualstudio.com/) is an excellent choice. You need to open the package folder in VS Code; it contains a preconfigured `.vscode` directory to set up the cloudComPy environment for the integrated terminal and the debugger. You need to modify the venv path in `.vscode/launch.json`, depending on your installation.


### Execute all the Python tests:

In the virtual environment above :
```bat
cd  <path install>\CloudComPy312\doc\PythonAPI_test
```

To execute all the tests (takes about three minutes, creates about 2.3GB of data files):

```bat
ctest
```

The files created with the tests are in your user space: %USERPROFILE%\CloudComPy\data

### In case of problem:

The `envCloudComPy.bat` file checks whether cloudComPy has been successfully imported into your Python environment. If everything is in order, it displays `Environment OK!`. If not, there may be a version conflict between certain DLLs included in the cloudComPy package and those provided by your Python environment.