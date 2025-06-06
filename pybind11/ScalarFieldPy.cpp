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

#include <ccScalarField.h>
#include <ScalarField.h>

#include "PyScalarType.h"
#include "pyccTrace.h"
#include "ScalarFieldPy_DocStrings.hpp"

#include <vector>

py::array ToNpArray_copy(CCCoreLib::ScalarField &self)
{
    CCTRACE("ScalarField ToNpArray with copy, ownership transfered to Python");
    size_t nRows = self.size();
    double offset = self.getOffset();
    float* data = self.getInternalData();

    py::array_t<double> result(nRows);
    auto buf = result.request();
    double* ptr = static_cast<double*>(buf.ptr);
    for (size_t i = 0; i < nRows; ++i)
    {
        ptr[i] = static_cast<double>(data[i] + offset);
    }
    return result;
}

py::array ToNpArray_py(CCCoreLib::ScalarField &self)
{
    CCTRACE("ScalarField ToNpArray without copy, ownership stays in C++. Offset non included");
    auto capsule = py::capsule(self.getInternalData(), [](void *v) { CCTRACE("C++ ScalarField not deleted"); });
    return py::array(self.size(), self.getInternalData(), capsule);
}

void fromNPArray_copy(CCCoreLib::ScalarField &self, py::array_t<double, py::array::c_style | py::array::forcecast> array)
{
    size_t nRows = self.size();
    if (array.ndim() != 1 && array.shape(0) != nRows)
    {
        throw std::runtime_error("Incorrect array dimension");
    }
    self.clear(); // clear the vector and reset offset
    self.reserveSafe(nRows);
    self.resizeSafe(nRows);
    const double *s = reinterpret_cast<const double*>(array.data());
    for (size_t i = 0; i < nRows; ++i)
    {
        self.setValue(i, static_cast<double>(s[i]));
    }
    CCTRACE("copied " << nRows << " values");
    self.computeMinAndMax();
}

void fromNPArray_copyFloat(CCCoreLib::ScalarField &self, py::array_t<float, py::array::c_style | py::array::forcecast> array, double offset)
{
    size_t nRows = self.size();
    if (array.ndim() != 1 && array.shape(0) != nRows)
    {
        throw std::runtime_error("Incorrect array dimension");
    }
    self.clear(); // clear the vector and reset offset
    self.reserveSafe(nRows);
    self.resizeSafe(nRows);
    const PyScalarType *s = reinterpret_cast<const PyScalarType*>(array.data());
    float *d = self.getInternalData();
    memcpy(d, s, nRows*sizeof(float));
    CCTRACE("copied " << nRows*sizeof(float) << " bytes");
    self.setOffset(offset);
    self.computeMinAndMax();
}

py::tuple computeMeanAndVariance_py(CCCoreLib::ScalarField &self)
{
    ScalarType mean, variance;
    self.computeMeanAndVariance(mean, &variance);
    py::tuple res = py::make_tuple(mean, variance);
    return res;
}

//ScalarType& (CCCoreLib::ScalarField::* getValue1)(std::size_t) = &CCCoreLib::ScalarField::getValue; // getValue1: pointer to member function
ScalarType (CCCoreLib::ScalarField::* getValue2)(std::size_t) const = &CCCoreLib::ScalarField::getValue; //pointer to member function with const qualifier
//typedef const ScalarType& (CCCoreLib::ScalarField::*gvftype)(std::size_t) const; // the same using a typedef
//gvftype getValue2 = &CCCoreLib::ScalarField::getValue;

void setColorScalePy(ccScalarField& self, ccColorScale* scale)
{
    QSharedPointer<ccColorScale> shared = QSharedPointer<ccColorScale>(scale);
    self.setColorScale(shared);
}

void export_ScalarField(py::module &m0)
{
    py::class_<CCCoreLib::ScalarField, std::unique_ptr<CCCoreLib::ScalarField, py::nodelete>>(m0, "ScalarField",
            ScalarFieldPy_ScalarField_doc)
        .def(py::init<const char*>(), py::arg("name")=nullptr, ScalarFieldPy_ScalarField_ctor_doc)
        .def("addElement", &CCCoreLib::ScalarField::addElement, ScalarFieldPy_addElement_doc)
        .def("computeMeanAndVariance", &computeMeanAndVariance_py, ScalarFieldPy_computeMeanAndVariance_doc)
        .def("computeMinAndMax", &CCCoreLib::ScalarField::computeMinAndMax, ScalarFieldPy_computeMinAndMax_doc)
        .def("currentSize", &CCCoreLib::ScalarField::currentSize, ScalarFieldPy_currentSize_doc)
        .def("fill", &CCCoreLib::ScalarField::fill, ScalarFieldPy_fill_doc)
        .def("flagValueAsInvalid", &CCCoreLib::ScalarField::flagValueAsInvalid, ScalarFieldPy_flagValueAsInvalid_doc)
        .def("fromNpArrayCopy", &fromNPArray_copy, ScalarFieldPy_fromNpArrayCopy_doc)
        .def("fromNpArrayCopyFloat", &fromNPArray_copyFloat, ScalarFieldPy_fromNpArrayCopyFloat_doc)
        .def("getMax", &CCCoreLib::ScalarField::getMax, ScalarFieldPy_getMax_doc)
        .def("getMin", &CCCoreLib::ScalarField::getMin, ScalarFieldPy_getMin_doc)
        .def("getName", &CCCoreLib::ScalarField::getName, ScalarFieldPy_getName_doc)
        .def("getOffset", &CCCoreLib::ScalarField::getOffset, ScalarFieldPy_getOffset_doc)
        .def("getValue", getValue2, ScalarFieldPy_getValue_doc, py::return_value_policy::reference)
        .def("reserveSafe", &CCCoreLib::ScalarField::reserveSafe, ScalarFieldPy_reserveSafe_doc)
        .def("resizeSafe", &CCCoreLib::ScalarField::resizeSafe, ScalarFieldPy_resizeSafe_doc)
        .def("setName", &CCCoreLib::ScalarField::setName, ScalarFieldPy_setName_doc)
        .def("setValue", &CCCoreLib::ScalarField::setValue, ScalarFieldPy_setValue_doc)
        .def("swap", &CCCoreLib::ScalarField::swap, ScalarFieldPy_swap_doc)
        .def("toNpArrayCopy", &ToNpArray_copy, ScalarFieldPy_toNpArrayCopy_doc)
        .def("toNpArrayNoCopy", &ToNpArray_py, ScalarFieldPy_toNpArrayNoCopy_doc)
        ;
    //TODO optional parameters on resizeSafe

    py::class_<ccScalarField, CCCoreLib::ScalarField , std::unique_ptr<ccScalarField, py::nodelete>>(m0, "ccScalarField",
            ccScalarFieldPy_ccScalarField_doc)
        .def(py::init<const char*>(), py::arg("name")=nullptr, ccScalarFieldPy_ccScalarField_ctor_doc)
        .def("isSerializable", &ccScalarField::isSerializable)
//        .def("getGlobalShift", &ccScalarField::getGlobalShift, ccScalarFieldPy_getGlobalShift_doc)
        .def("setColorScale", &setColorScalePy, ccScalarFieldPy_setColorScale_doc)
        ;

    //TODO add serialization functions
}

