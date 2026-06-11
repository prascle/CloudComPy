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

#ifndef HoughNormals_DOCSTRINGS_HPP_
#define HoughNormals_DOCSTRINGS_HPP_


const char* HoughNormals_doc= R"(
HoughNormals is a standard plugin of cloudComPy.

The availability of the plugin can be tested with the isPluginHoughNormals function:

  isHoughNormals_available = cc.isPluginHoughNormals()

HoughNormals is a submodule of cloudCompy:
::

  import cloudComPy as cc
  # ...
  if cc.isPluginHoughNormals():
      import cloudComPy.HoughNormals
      cc.HoughNormals.computeHoughNormals(...)
 )";

const char* HoughNormals_computeHoughNormals_doc=R"(
Compute Hough normals for a point cloud.

:param ccPointCloud cloud: input point cloud.
:param int,optionalK: number of nearest neighbors to consider, default is 100.
:param int,optional T: number of planes, default is 1000.
:param int,optional n_phi: accumulator steps, default is 15.
:param int,optional n_rot: number of rotation, default is 5.
:param bool,optional use_density: whether to use density information, default is false.
:param float,optional tol_angle_rad: tolerance for angle comparison, default is 0.79.
:param int,optional k_density: number of neighbors for density estimation, default is 5.
)";

const char* HoughNormals_initTrace_HoughNormals_doc=R"(
Debug trace must be initialized for each Python module.

Done in module init, following the value of environment variable _CCTRACE_ ("ON" if debug traces wanted)
)";


#endif /* HoughNormals_DOCSTRINGS_HPP_ */
