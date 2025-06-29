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

#ifndef CLOUDCOMPY_PYAPI_PYSCALARTYPE_H_
#define CLOUDCOMPY_PYAPI_PYSCALARTYPE_H_

#if defined SCALAR_TYPE_FLOAT
    #define PyScalarType float
    #define CC_NPY_FLOAT NPY_FLOAT32
    #define CC_NPY_FLOAT_STRING "float32"
#else
    #define PyScalarType double
    #define CC_NPY_FLOAT NPY_FLOAT64
    #define CC_NPY_FLOAT_STRING "float64"
#endif

#endif /* CLOUDCOMPY_PYAPI_PYSCALARTYPE_H_ */
