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

#ifndef CLOUDCOMPY_PYAPI_PYCC_H_
#define CLOUDCOMPY_PYAPI_PYCC_H_

#include <QList>
#include <QString>

#if not defined CC_CORE_LIB_USES_DOUBLE and not defined CC_CORE_LIB_USES_FLOAT
#define CC_CORE_LIB_USES_FLOAT
#endif

#include <ccCommandLineInterface.h>
#include <GeometricalAnalysisTools.h>

// --- for Python3 interface

namespace PYCC
{

enum CC_SHIFT_MODE
{
    AUTO = 0, XYZ = 1
};

//! load a point cloud from file
/*! TODO process optional parameters following ccCommandLineInterface::processGlobalShiftCommand
 * \param filename
 * \param mode optional default AUTO
 * \param skip optional default 0
 * \param x optional default 0
 * \param y optional default 0
 * \param z optional default 0
 * \return cloud if success, or nullptr
 */
ccPointCloud* loadPointCloud(
    const char* filename,
    CC_SHIFT_MODE mode = AUTO,
    int skip = 0,
    double x = 0,
    double y = 0,
    double z = 0);

//! save a point cloud to a file
/*! the file type is given by the extension
 * \param cloud
 * \param filename
 * \return IO status
 */
CC_FILE_ERROR SavePointCloud(ccPointCloud* cloud, const QString& filename);

enum CurvatureType
{
    GAUSSIAN_CURV = 1, MEAN_CURV, NORMAL_CHANGE_RATE
};

//! Computes a geometric characteristic (see GeometricalAnalysisTools::GeomCharacteristic) on a list of clouds
/*! Computes a geometric characteristic (see GeometricalAnalysisTools::GeomCharacteristic) on a set of entities
 * \param option from (GAUSSIAN_CURV, MEAN_CURV, NORMAL_CHANGE_RATE)
 * \param list of clouds
 * \return status
 */
bool computeCurvature(CurvatureType option, double radius, QList<ccPointCloud*> clouds);

//! Filters out points whose scalar values falls into an interval(see ccPointCloud::filterBySFValue)
/** Threshold values should be expressed relatively to the current displayed scalar field.
 \param minVal minimum value
 \param maxVal maximum value
 \return resulting cloud (remaining points)
 **/
ccPointCloud* filterBySFValue(double minVal, double maxVal, ccPointCloud* cloud);

//! Returns a default first guess for algorithms kernel size (several clouds)
/*! copied from ccLibAlgorithms::GetDefaultCloudKernelSize
 * \param list of clouds
 * \param number of nodes wanted within the radius
 * \return radius
 */
double GetPointCloudRadius(QList<ccPointCloud*> clouds, unsigned knn = 12);

// --- internal functions (not wrapped in the Python API) ---------------------

//! initialize internal structures: should be done once, multiples calls allowed (does nothing)
struct pyCC;
pyCC* initCloudCompare();

//! copied from ccLibAlgorithms::ComputeGeomCharacteristic
bool pyCC_ComputeGeomCharacteristic(
    CCCoreLib::GeometricalAnalysisTools::GeomCharacteristic c,
    int subOption,
    PointCoordinateType radius,
    ccHObject::Container& entities);

//! copied from ccLibAlgorithms::GetDensitySFName
QString pyCC_GetDensitySFName(
    CCCoreLib::GeometricalAnalysisTools::Density densityType,
    bool approx,
    double densityKernelSize = 0.0);

//! copied from ccLibAlgorithms::GetDefaultCloudKernelSize
PointCoordinateType pyCC_GetDefaultCloudKernelSize(ccGenericPointCloud* cloud, unsigned knn = 12);
}

#endif /* CLOUDCOMPY_PYAPI_PYCC_H_ */
