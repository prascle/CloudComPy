//##########################################################################
//#                                                                        #
//#                                PYCC                                    #
//#                                                                        #
//#  This program is free software; you can redistribute it and/or modify  #
//#  it under the terms of the GNU Library General Public License as       #
//#  published by the Free Software Foundation; version 2 or later of the  #
//#  License.                                                              #
//#                                                                        #
//#  This program is distributed in the hope that it will be useful,       #
//#  but WITHOUT ANY WARRANTY; without even the implied warranty of        #
//#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the          #
//#  GNU General Public License for more details.                          #
//#                                                                        #
//#          Copyright 2020 Paul RASCLE www.openfields.fr                  #
//#                                                                        #
//##########################################################################

// sip implementation of cloudCompare

%DefaultDocstringSignature(name="prepended")

%Import QtGui/QtGuimod.sip

%Module(name=cloudCompare)
{
%Docstring
cloudCompare is the Python module interfacing cloudCompare library
Python3 access to cloudCompare objects is done like this:
from PyQt5.QtWidgets import QApplication
app = QApplication(sys.argv)
import cloudCompare as cc
cloud = cc.loadPointCloud("/home/paul/projets/CloudCompare/data/altiXYZ/RGEALTI_FXX_0845_6446_MNT_LAMB93_IGN69.xyz")
%End
};

// Not tested with a Qt version below 5.9: %If (Qt_5_9_1 -) means version 5.9.1 and up.
%If (Qt_5_9_1 -)

%ModuleHeaderCode
#include <ccTrace.h>
#include <pyCC.h>
%End

class initNumpy
{
    %TypeHeaderCode
    #define NPY_NO_DEPRECATED_API NPY_1_7_API_VERSION
    // see Numpy documentation for PY_ARRAY_UNIQUE_SYMBOL and NO_IMPORT_ARRAY
    // more explanation in ccNumpyIncludes.h
    #define PY_ARRAY_UNIQUE_SYMBOL PYCC_ARRAY_API
    #include <numpy/arrayobject.h>
    #include <initNumpy.h>
    #include <PyScalarType.h>
    %End
    
public:
    static void init();
    %Docstring
    Should be done once before dealing with Numpy: transforming Cloud Cooordinates or ScalarField in numpyArray (and the other way).
    %End
    %MethodCode
    CCTRACE("initialization numpy C++ API");
    import_array();
    CCTRACE("initialization numpy C++ API done");
    %End
    
    static const char* getScalarType();
    %Docstring
    Get the scalar type used in cloudCompare under the form defined in Numpy: 'float32' or 'float64'
    %End
    %MethodCode
    int type_num = CC_NPY_FLOAT;
    if (type_num == NPY_FLOAT32)
        sipRes = "float32";
    else
        sipRes = "float64";
    %End
    
private:
    initNumpy();
    initNumpy(const initNumpy&);    
};

%Include pyCC.sip
%Include ccPointCloud.sip
%Include ScalarField.sip
namespace CCCoreLib;
%End
