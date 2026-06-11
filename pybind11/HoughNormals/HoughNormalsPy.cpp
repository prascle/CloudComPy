//##########################################################################
//#                                                                        #
//#                              CloudComPy                                #
//#                                                                        #
//#  This program is free software; you can redistribute it and/or modify  #
//#  it under the terms of the GNU General Public License as published by  #
//#  the Free Software Foundation; either version 3 of the License, or     #
//#  any later version.                                                    #
//#                                                                        #
//#  This program is distributed in the hope that it will be useful,       #
//#  but WITHOUT ANY WARRANTY; without even the implied warranty of        #
//#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the          #
//#  GNU General Public License for more details.                          #
//#                                                                        #
//#  You should have received a copy of the GNU General Public License     #
//#  along with this program. If not, see <https://www.gnu.org/licenses/>. #
//#                                                                        #
//#          Copyright 2020-2025 Paul RASCLE www.openfields.fr             #
//#                                                                        #
//##########################################################################

#include "cloudComPy.hpp"

#include <QString>
#include <vector>

#include <ccMesh.h>

#include <qHoughNormals.h>

#include "pyccTrace.h"
#include "HoughNormals_DocStrings.hpp"

void initTrace_HoughNormals()
{
#ifdef _PYTHONAPI_DEBUG_
    ccLogTrace::settrace();
#endif
}


PYBIND11_MODULE(_HoughNormals, m12)
{
    m12.doc() = HoughNormals_doc;

        m12.def("computeHoughNormals", &computeHoughNormalsPy,
            ::py::arg("cloud"),
            ::py::arg("K") = 100,
            ::py::arg("T") = 1000,
            ::py::arg("n_phi") = 15,
            ::py::arg("n_rot") = 5,
            ::py::arg("use_density") = false,
            ::py::arg("tol_angle_rad") = 0.79f,
            ::py::arg("k_density") = 5,
            HoughNormals_computeHoughNormals_doc);

        m12.def("initTrace_HoughNormals", initTrace_HoughNormals, HoughNormals_initTrace_HoughNormals_doc);
}
