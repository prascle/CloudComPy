
## Build on Linux64, with Anaconda3 or miniconda3

The script [genCloudComPy_Conda311_Ubuntu2004.sh](../building/genCloudComPy_Conda311_Ubuntu2004.sh) executes the following:

 - create or update the conda environment
 - activate the environment
 - build and install CloudComPy (Sources must be cloned from the [GitHub repository](https://github.com/CloudCompare/CloudComPy)
   or the [GitLab repository](https://gitlab.com/openfields1/CloudComPy) and up to date)
 - create the tarfile
 - execute ctest

**Note:** CloudComPy versions released in 2024 and earlier were built using a Conda **Python 3.10** environment: **CloudComPy310**.
Now, new versions are built with a **Python 3.11** Conda environment: **CloudComPy311**
