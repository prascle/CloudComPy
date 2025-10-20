#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
import shutil

def getDepLibs(packagePath):
    """
    Linux only!
    Find all the libraries (*.so*) used by cloudComPy, CloudCompare, ccViewer, to be added to the bundle.
    The system libraries (in /usr and /lib) are not taken into account.
    """

    # --- CloudCompare and ccViewer executables are always analysed
    pathlibs = [os.path.join(packagePath, "CloudCompare"), os.path.join(packagePath, "ccViewer")]

    # --- get all the *.so from the package, to look for dependencies
    for root, dirs, files in os.walk(packagePath):
        for f in files:
            pf = os.path.join(root,f)
            ext = os.path.splitext(pf)[1]
            if ext == ('.so'):
                pathlibs.append(pf)

    # --- the dependency libraries will be added to a set
    libs = set()

    # --- for each library or executable in the package, find all dependencies
    for pathLibmain in pathlibs:
        with subprocess.Popen(["ldd", str(pathLibmain)], stdout=subprocess.PIPE) as proc:
            lines = proc.stdout.readlines()
            for line in lines:
                res = line.decode()
                vals = res.split()
                if len(vals) > 3:
                    f = vals[2]
                    if f[0:4] != '/lib' and f[0:4] != '/usr':
                        libs.add(f)

    # --- copy the dependencies and fix RPATH (look in the same directory)
    for orig in libs:
        dest = os.path.join(packagePath, os.path.basename(orig))
        print(dest)
        if orig != dest:
            shutil.copy(orig, dest)
        subprocess.Popen(["patchelf", "--set-rpath", "$ORIGIN", str(dest)])


if __name__ == "__main__":
    # CLI parser
    parser = argparse.ArgumentParser("cloudComPyBundle")
    parser.add_argument(
        "install_path",
        help="Path where cloudComPy is installed (CMake install dir)"
    )
    arguments = parser.parse_args()
    getDepLibs(arguments.install_path)
