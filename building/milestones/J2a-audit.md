# J2a - Audit of the CloudComPy fork of CloudCompare (work in progress)

Milestone J2a deliverable. Base for comparison: upstream commit `55bc79b2cbf1`
(taken from CloudCompare master). Fork pin (submodule CloudComPy CloudCompare):
`d070dc6`. Diff: 127 files, +3020 / -599 lines. Raw diff kept out of the repo
(`J2a-fork-vs-base.diff`, local working file).

Status 27/11/2026: VALIDATED by Paul. Sections 1-8 complete (fork diff
classification, anomalies, upstream strategy, J2a.1 value matrix, J2a.2
dead flags, review notes, J2a.4 impact audit + guards G1/G2/G4/G5/G6).
Commit pending on ci/j2a-audit. Resume notes: see
`building/milestones/README.md`.

## 0. Working method of Paul (key context, 25/11)

The pin diff below (`55bc79b2cbf1`..`d070dc6`) is only a SNAPSHOT: CloudCompare
master evolves daily, and Paul does not maintain a long-lived patch branch.
When producing binaries he starts from the HEAD master of the reference
repository and applies minimal fixes:

- CloudCompare (macOS): HEAD `001bfd04a1` -> branch `paul_20261028`,
  tag `b3b6a03d9d` on fork prascle/CloudCompare (local clone
  `~/projets/CloudCompare/CloudCompare`). Quick-test variant: HEAD
  `4ce020b9e5` -> branch `3DmouseMacOSdriver`, tag `1e4793b2f79a`.
- CloudComPy (all platforms): same approach - start from HEAD master, apply
  the CloudComPy delta by cherry-pick + conflict resolution, occasionally
  regrouping commits. Separate branches for CloudCompare vs CloudComPy
  productions (different rhythms). Everything is pushed to the fork and
  never destroyed.

Consequences for J2:
- The goal is not (only) to minimize a static diff, but to structure the
  CloudComPy delta as a clean, minimal, RE-APPLIABLE patch series (cherry-pick
  friendly, low-conflict, well separated by topic), plus the CMake presets.
- E-family decisions must be taken against a chosen reference HEAD at a
  given time, keeping the CloudCompare side and the CloudComPy side coherent.
- F-family items must be re-checked against the latest upstream evolutions
  before any proposal (fast-moving target).


## 1. Classification of the fork changes

### A. PythonAPI core (essential for the wrapping, hard to circumvent) - ~55 files

- `pyccTrace.h` (new, 47 l.) + `ccLog.h/cpp` + `qCC_db` CMakeLists: the
  `CCTRACE` mechanism, gated by `_PYTHONAPI_DEBUG_`, activated by the
  `_CCTRACE_` environment variable at runtime. `ccLog.cpp` is a PUBLIC source
  on Linux only (symbol export needed by the pyd), PRIVATE elsewhere.
  Proposal: KEEP. Known J3 item: the `#ifdef _PYTHONAPI_DEBUG_` gating makes
  traces compile-time optional in the pyd.
- 11 new export headers (`qCSFExport.h`, `qCanupoExport.h`, `qCorkExport.h`,
  `qHPRExport.h`, `qHoughNormalsExport.h`, `qM3C2Export.h`,
  `qMeshBooleanExport.h`, `qPCVExport.h`, `qPoissonReconExport.h`,
  `qRANSAC_SDExport.h`, `qSRAExport.h`) + the `_LIBRARY_BUILD` definition
  added in `plugins/cmake/Plugins.cmake` + class/struct `*_LIB_API` markings:
  the dllexport/dllimport mechanism used by pybind11 to wrap plugin classes.
  Proposal: KEEP, mechanism is uniform and clean. (Note: several export header
  banners carry copy-pasted wrong plugin names, e.g. qCanupoExport.h says
  "qM3C2"; cosmetic.)
- Scriptable API extractions in plugins (compute without GUI dialog):
  `qCSF::computeCSF`, `qCork::compute` + CSG_OPERATION, `computeMeshBoolean`,
  `computeHoughNormalsPy`, `qHPR::removeHiddenPoints` (static, public),
  `qSRA` methods moved to public, `qM3C2Process::getM3C2Params` extracted
  from `Compute` (params from a file, dialogs skipped), `saveParamsToGivenFile`,
  PCL filters `setParameters` / `getOutputCloud` / `getTransformation`
  (FGR, MLS, NormalEstimation). Proposal: KEEP, all essential for the Python
  API. `qM3C2Process.cpp` is the largest rewrite (+83/-266): structs moved to
  the header, `ComputeM3C2DistForPoint` becomes a static member. KEEP.
- `ccPointCloud::setVisibility` + `ccMesh::crop2D` (new in qCC_db):
  Python-exposed methods. KEEP.
- `FileIOFilter.h`: `LoadParameters::extraData` (QRegularExpression) and
  `SaveParameters{minorVersion, pointFormat, isAscii}`; consumed by
  `PlyFilter` (extra fields regex + ascii switch), `E57Filter` (scan filter),
  `LasIOFilter` (version/format forcing). KEEP (essential API surface).
- `ccApplicationBase`: `appPath` parameter + the `cloudComPy` (PyPI layout)
  branch in `setupPaths`: plugin/shader/translation resolution from the wheel
  layout, and the `actionResume_Python` menu in ccViewer.ui ("close window,
  resume Python script" = the GUI pause/resume of CloudComPy). KEEP.
- `ccObject.h`: `enum : CC_CLASS_ENUM` -> `enum CCTYPES : CC_CLASS_ENUM`.
  KEEP (needed for the wrapping; small, upstreamable).
- `qCC/main.cpp` + plugin ctors: `ccLogTrace::settrace()` calls. KEEP.

### B. Install layout "cloudComPy" + INSTALL_PREREQUISITE_LIBRARIES - ~20 files

- Root `CMakeLists.txt`: dest folders per platform (`cloudComPy/...`,
  BUILD_PYPI variant on WIN32), Linux shared destination == rpath ==
  prefix/cloudComPy, and the `INSTALL_PREREQUISITE_LIBRARIES` option (OFF on
  Apple, ON elsewhere). KEEP: this is the core of the current packaging and
  the D13 lesson validated in J1b. Document that this is the main thing that
  makes the fork non-mergeable upstream as-is.
- `cmake/CMakeInclude.cmake` (copy_files guard), `cmake/Install.cmake`
  (guards + verbose messages), `cmake/DeployQt.cmake` (windeployqt replaced,
  when INSTALL_PREREQUISITE_LIBRARIES is OFF, by a manual copy of
  qwindows.dll from `${CONDA_ROOT_DIRECTORY}`), `qCC/CMakeLists.txt` (shaders /
  plugins / translations destinations, `-static-libstdc++` on non-Apple,
  DEPLOY_PATH), `ccViewer/CMakeLists.txt` (plugin destinations + static
  libstdc++), `qCC/Mac/CMakeLists.txt`, translations CMakeLists (destination
  cloudComPy/share), `qRDBIO/CMakeLists.txt` (libdir -> prefix/cloudComPy).
  Proposal: KEEP (layout is acting), but see anomalies (D copy of qwindows.dll
  hardcodes a Conda layout; document, possibly guard on CONDA_ROOT_DIRECTORY
  being defined).
- qHPR external qhull: `USE_EXTERNAL_QHULL_FOR_QHPR` option +
  `cmake/FindQhull.cmake` (new, 79 l., from PCL) + `optdefineshpr.h.in`.
  KEEP (needed to build against the Conda qhull instead of the vendored one).
- `qDracoIO/CMakeLists.txt`: MSVC/USE_CONDA_PACKAGES branch. Anomaly: both
  branches do the same thing (dead conditional). Proposal: simplify.
- `qCanupo/CMakeLists.txt`: `DLIB_USE_BLAS OFF` (Windows Conda cblas issue).
  KEEP (documented workaround). `libs/qCC_io/test/CMakeLists.txt`:
  `-static-libstdc++` on non-Apple. Keep or drop, low impact.

### C. Native file dialogs bypassed on macOS - ~16 files

`QFileDialog::DontUseNativeDialog` forced under `Q_OS_MAC` in:
CSVMatrixOpenDialog, LasOpenDialog, qCanupo x2, qCompass x2,
qFacets, qM3C2Dialog x2, qSRA x3, ccApplyTransformationDlg,
ccPointListPickingDlg, ccRasterizeTool, matrixDisplayDlg, mainwindow.cpp
(global CCFileDialogOptions), qAnimationDlg, profileImportDlg (extended to
Q_OS_MAC). Status per Paul (25/11): the underlying issue is solved by adding
ONE LINE in the macOS packaging files (of the kind Info.plist / resources) -
with that line present in the bundle, the native dialogs work. The whole
C family is therefore REMOVABLE as soon as the CloudComPy mac packaging
carries that line. ACTION for J2b: identify that packaging line, pin it into
the CloudComPy build scripts/presets, verify the dialogs, then drop the C
family (~16 files). Until then: KEEP.

### D. Submodule pins and personal forks - 6 entries

`.gitmodules`: dlib, q3DMASC, qVoxFall point to `prascle/*` forks; submodule
pins changed (dlib, qVoxFall, q3DMASC, quazip). Per Paul (25/11): to verify
and document (which pins diverge from upstream, and what each fork contains).
J3 candidate: track them in the 3-way diff report.

### E. macOS bundle, signature, pixi - 8 files

- `libBundleCloudCompare.py` (+180): rpath rework (purge old rpaths, add
  @loader_path everywhere, rewrite install names), FBX SDK and Homebrew
  libpng paths hard-coded, links libpng16.16.dylib of libQCANUPO_PLUGIN from
  /opt/homebrew. Proposal: KEEP for the signed .app bundle, but see anomaly:
  the CI wheel (delocate pipeline) does NOT get this patch, which is exactly
  the class of the test046 CANUPO giflib failure. J3 candidate.
- `signatureCloudCompare.py`: hardened runtime option + sign-all branch.
  KEEP.
- `Mouse3DInput_mac.cpp/h` (new, 615 l.): 3DConnexion HID support on macOS
  (option OPTION_SUPPORT_3DMOUSE_WITH_HIDAPI). Proposal: KEEP, isolated feature;
  upstream PR candidate if CloudCompare wants it.
- `.ci/conda-macos.yml` (pdal), `pixi.toml`, `pixi.lock`: see anomalies.

### F. Cosmetics, small fixes, upstreamable bug fixes - ~12 files

- `GDALSupport.cmake`: Windows DLL list updated (proj_9, xerces-c_3_3,
  removal of ssleay/libeay) - upstreamable.
- `DRCFilter.cpp`: guard `hasDisplayedScalarField()` - real bug fix,
  upstreamable.
- `QVideoEncoder.cpp`: ffmpeg const-cast compat - upstreamable.
- `LASFWFFilter.cpp`: memcpy_s/memcpy portability + `global_encoding = 17`
  hard fix + ScalarType casts (CloudComPy issue #54) - upstreamable with a
  guard.
- `qPDALIO/LASFields.h`: extra-dim name sanitization ('(' ')' '.') - keep,
  minor.
- README.md (CloudComPy mention), qt5.natvis (QRegExp display),
  ccViewer/main.cpp typo, ObjFilter/BundlerImportDlg blank-line removals,
  qRANSAC_SD CMakeLists (commented message), start.bat PATH save/restore x2.
  Low stakes.

## 2. Anomalies found (proposals)

1. **pixi.toml / pixi.lock**: committed conflict markers, contradictory
   duplicated flags, machine-specific paths; NOT used by CloudComPy builds.
   Decision Paul (25/11): keep the ORIGINAL CloudCompare upstream versions of
   both files (the fork versions are unused and obsolete).
2. **qLASFWFIO/CMakeLists: `if(WIN32)` commented out**, so the deprecated LASFWF
   plugin can now build on mac/linux. OK per Paul: restore the guard.
3. **FBXFilter: `s_defaultOutputFormat = "FBX_ascii"`** changes the default
   for everyone (GUI included). Per Paul: to clarify and document (origin and
   need of the change) before deciding.
4. **LasIOFilter: the "custom offset" dialog block was removed**. Per Paul:
   to be discussed (origin to clarify; interplay with the GUI).
5. **DeployQt + qwindows.dll copy hardcodes the Conda layout**: OK per Paul
   (accepted); keep, with the existence guard.
6. **translations CMakeLists (`if(NOT WIN32)` skip, "temporary fix" Qt 5.15.4)**:
   Paul asks to RETEST that translations cause no problem, then drop if green.
7. **`CloudCompare_ru.ts` renamed `.noToTranslate`**: the Russian translation
   file was breaking the build (Paul, 25/11). KEEP the rename, reason now
   documented; possibly a candidate to re-test with recent Qt too.
8. **libBundleCloudCompare.py machine-specific paths** (FBX SDK path,
   Homebrew libpng: to discuss (same class as the wheel giflib gap, J3).
9. **Dead conditional in qDracoIO/CMakeLists**: OK per Paul: simplify.
10. **INSTALL_PREREQUISITE_LIBRARIES platform-asymmetric default**: Paul notes
    a simple CMake warning would be drowned among prerequisite warnings.
    Proposal: make the guard a FATAL_ERROR on the invalid combination
    (BUILD_PYPI + Apple + explicit ON), or validate via the presets only
    and drop the guard idea.

## 3. Minimizing the diff / upstream contributions (DJ2, updated after Paul's review)

- The static diff is a snapshot of a moving-target workflow (see section 0):
  the real goal is a clean, minimal, RE-APPLIABLE patch series on top of a
  chosen upstream HEAD, coherent between the CloudCompare side and the
  CloudComPy side.
- F-family upstreamable fixes (GDAL DLL names, DRCFilter guard, QVideoEncoder,
  LASFWF issue #54, PDAL sanitize, ccObject enum) must first be re-checked
  against the LATEST upstream evolutions (master moves daily).
- Paul's decision (25/11): upstream contributions are KEPT FOR THE END of the
  work, prepared as targeted and well-documented PRs (the CloudCompare team
  sees many PRs these days - make each one easy to review).
- B-family layout changes remain the main upstream-merge blocker; an
  option-gated (`BUILD_PYPI`-style) variant would reduce the effective diff
  to zero for non-CloudComPy builds.

## 4. J2a.1 - Cross-table of build flags: option x family x value (25/11)

Scripts compared (full definitions with values extracted automatically):

| Col | Family | Script |
|-----|--------|--------|
| L | CI Linux | building/ci_linux_lean.sh |
| W | CI Windows | building/ci_windows_lean.ps1 |
| M | CI macOS | building/ci_macos_lean.zsh |
| G | Production wheels macOS | building/genCloudComPy_Conda3xx_macos.zsh |
| B | Production wheels Windows | build.ps1 (local, not versioned) |

Union: 146 distinct flags (the 2 previously suspected false positives
"-DESSOUS" and "-DDate" are excluded).

### 4.1 Flags set by ALL 5 scripts with the SAME normalized value (preset core)

BUILD_PY_TESTING=1, BUILD_TESTING=1, CCCORELIB_SHARED=1,
CCCORELIB_USE_CGAL=1, CCCORELIB_USE_QT_CONCURRENT=1, CCCORELIB_USE_TBB=0,
OPENCASCADE_78_OR_NEWER=1, OPTION_USE_GDAL=1, PLUGIN_GL_QEDL=1,
PLUGIN_GL_QSSAO=1, PLUGIN_IO_QADDITIONAL=1, PLUGIN_IO_QCORE=1,
PLUGIN_IO_QCSV_MATRIX=1, PLUGIN_IO_QDRACO=1, PLUGIN_IO_QE57=1,
PLUGIN_IO_QLAS=1, PLUGIN_IO_QSTEP=1, PLUGIN_PYTHON=0,
PLUGIN_STANDARD_QBROOM=1, QCANUPO=1, QCLOUDLAYERS=1, QCOMPASS=1, QCSF=1,
QFACETS=1, QHOUGH_NORMALS=1, QHPR=1, QM3C2=1, QMPLANE=1,
QPOISSON_RECON=1, QRANSAC_SD=1, QSRA=1, QTREEISO=1, PYTHONAPI_TRACES=1,
USE_CONDA_PACKAGES=1, USE_EXTERNAL_QHULL_FOR_QHPR=0.   (35 flags)

### 4.2 Set by all 5 but with SEMANTIC divergence

| Flag | Observation |
|------|--------------|
| BUILD_REFERENCE_DOC | CI = 0 (all 3), production = 1 (G, B) |
| CMAKE_BUILD_TYPE | Release everywhere, EXCEPT B: $Configuration (locally parameterizable) |
| BUILD_PYPI | M, G, B = 1 but ABSENT from L (Linux CI does not build PyPI) and W |
| OPENCASCADE_{INC,LIB,DLL,TBB_DLL}_DIR | L/M: conda; W/B: conda ($Library); G: ${OPENCASCADE_REP} = local Homebrew build, out of conda |
| PYMINOR / PYTHON_PREFERED_VERSION | 3.12 fixed on L; parameterized elsewhere |
| CMAKE_INSTALL_PREFIX, CLOUDCOMPARE_VERSION | same semantics, variable naming only |

### 4.3 Set by 4 of 5: the CI lean vs production wheel divergence

Plugins ON in production (G, B) but OFF in CI (W, M; absent on L):
PLUGIN_IO_QFBX, PLUGIN_STANDARD_QCORK, PLUGIN_STANDARD_QMESH_BOOLEAN;
PLUGIN_IO_QRDB off everywhere EXCEPT B (=1, with QRDB_FETCH/INSTALL_DEPENDENCY);
PLUGIN_IO_QPHOTOSCAN, QANIMATION_WITH_FFMPEG_SUPPORT, PLUGIN_EXAMPLE_*,
QPCL, QPCV, Q3DMASC, MASONRY_*, QCOLORIMETRIC_SEGMENTER, QJSONRPC: set by
W/M/G/B, absent on L (Linux CI relies on defaults? to check against J2a.2).
OPTION_BUILD_CCVIEWER=0, OPTION_HID_DEBUG=0,
OPTION_SUPPORT_3DMOUSE_WITH_3DxWARE=0/OPTION_SUPPORT_3DMOUSE_WITH_HIDAPI=1
(set W/M/G/B, absent on L).
INSTALL_PREREQUISITE_LIBRARIES=0: W, M, B only (ABSENT from G and L).
PYTHONAPI_{TEST,EXTDATA}_DIRECTORY=CloudComPy/{Data,ExternalData}: W/M/G/B.
macOS specifics (M, G): CMAKE_OSX_DEPLOYMENT_TARGET=13.0, CMAKE_MACOSX_RPATH=ON,
CGAL_DIR, Qhull_DIR, QHULL_LIBRARY_*, PNG_*, OpenCV_DIR, PCL_DIR,
pybind11_DIR, CONDA_LIBS, FFMPEG_*, XercesC both DEBUG/RELEASE dylib.
Windows specifics (W, B): Qt6_DIR, CMAKE_PREFIX_PATH, CMAKE_SHARED_LINKER_FLAGS
(W: /machine:x64; B adds /FORCE:MULTIPLE), CONDA_BASE_DIRECTORY,
CONDA_ENV_NAME, CONDA_ROOT_DIRECTORY.
CORK_*, LIBIGL_*, FBX_SDK_*: production only (G, B, and the Linux
production families P and K - see 4.5: the FBX SDK exists on Linux as a
static library, the Linux wheel builds the QFBX plugin; CORRECTED after
Paul's review).
CMAKE_INSTALL_RPATH: M = relative @loader_path scheme; G = absolute install
scheme. PYTHONVENV_DIR: L/M=${CONDA_PATH}, W=$CondaRoot, G=${PYTHONVENV};
B passes PYTHONVENV (without _DIR suffix!) - naming to harmonize.

### 4.4 Unique to one script

Linux CI: CMAKE_C_COMPILER(cc), CMAKE_CXX_COMPILER(c++), CONDA_ENV,
GMP_LIBRARIES(_DIR), MPFR_LIBRARIES_DIR, OpenMP_omp_LIBRARY.
Gen3xx macOS: FBX_SDK_LIBRARY_DIR. build.ps1: FBX_ZLIB_LIBRARY_FILE,
FBX_XML2_LIBRARY_FILE, PYTHONVENV, WORKROOT. Windows CI: win_deploy_qt.

### 4.5 The missing production Linux family (added after Paul's review, 25/11)

The 6f families above covered the 3 CI scripts and the macOS/Windows
production scripts. Production on Linux exists in two other shapes:

**P = production Linux "legacy Conda binaries"**: near-twin scripts
genCloudComPy_Conda31x_Ubuntu*.sh (310/311 on 2004, 312 on 2004 and 2604,
313 on 2604) + older genCloudComPy_Conda310/311_docker.sh. Representative
= genCloudComPy_Conda312_Ubuntu2004.sh (~102 flags).
- Same production plugin set as G/B (QFBX/QCORK/QMESH_BOOLEAN/QRDB on,
  QLAS_FWF/QPDAL off, EXAMPLE_*/Q3DMASC/QPCL/QPCV/QANIMATION on).
- Same local-repository choices as G for CORK/LIBIGL/FBX SDK; OPENCASCADE
  varies by script vintage: conda path in 312/313, self-built OCCT 7.4 in
  the 310 script, /root/occt in the docker scripts.
- PYMINOR hardcoded per script (one script per Python version), unlike
  genCloudComPy_Conda3xx_macos.zsh which parameterizes 310/311/312.
- No BUILD_PYPI (313 passes it explicitly =0): legacy layout.
- Twins drift: 310 adds LASLIB_*/LASZIP_LASTOOLS_*; 312-2604 passes
  LASZIP explicitly; 313 adds OPENCASCADE_78_OR_NEWER; the docker scripts
  lack QANIMATION_WITH_FFMPEG_SUPPORT and DRACO_LIBRARIES.
- They still pass the Linux dead flags of 5.3/5.4 (DRACO_INCLUDE_DIR,
  DRACO_LIB_DIR, EIGEN_INCLUDE_DIR, GMP_LIBRARIES_DIR, MPFR_LIBRARIES_DIR,
  OpenMP_omp_LIBRARY, TBB_DIR, PLUGIN_PYTHON, MASONRY_*,
  OPENCASCADE_DLL_DIR/TBB_DLL_DIR false friends): the 5.8 cleanups apply
  to them as well.

**K = production Linux wheels**: genCloudComPyWheels_U2004.sh is only a
DRIVER (loops over Python 3.9 to 3.14, sets env vars); the CMake defines
live in Linux/pyproject.toml ([tool.scikit-build.cmake.define] +
{env=...} indirections), built through scikit-build-core, repaired then
repacked with auditwheel (Linux counterpart of delocate).
- IN-TREE PRECEDENT for the dead-flag audit: the pyproject already has
  the dead flags COMMENTED OUT: DRACO_INCLUDE_DIR, DRACO_LIB_DIR,
  EIGEN_INCLUDE_DIR, GMP_LIBRARIES_DIR, MPFR_LIBRARIES_DIR,
  OPENCASCADE_DLL_DIR, OpenMP_omp_LIBRARY, PLUGIN_PYTHON, MASONRY_*.
  Independent confirmation of sections 5.3/5.4.
- KEY for DJ4/J2b: scikit-build-core can consume CMake presets
  (cmake.args = ["--preset", ...] equivalent), so the Linux wheel family
  is a natural future consumer of the presets, not just the CI scripts.

### 4.6 Naming inconsistencies (candidates for harmonization in J2b)

DRACO_INCLUDE_DIR (L/M/G) vs DRACO_INCLUDE_DIRS (W/B) - two different
CMake variables reach the same goal; CONDA_ENV (L) vs CONDA_ENV_NAME (W/B);
PYTHONVENV_DIR vs PYTHONVENV. No rename inside CloudCompare, but the PRESETS
and scripts should normalize the calling side where possible.

### 4.7 Measured proximity: CI vs production (for DJ4/DJ5, 25/11)

Pairwise -D flag-name overlap (values aside, false positives removed):

| CI family | Production family | Common | Production-only additions |
|-----------|-------------------|--------|---------------------------|
| L (ci_linux_lean) | P (Ubuntu 312 legacy) | 71/74 | 31: plugin panel ON (QFBX, QCORK, QMESH_BOOLEAN, QRDB+deps, QANIMATION, QPCL, QPCV, Q3DMASC, EXAMPLE_*, PHOTOSCAN, COLORIMETRIC, JSONRPC), CORK/FBX/LIBIGL paths, CMAKE_Fortran_COMPILER, TEST/EXTDATA_DIRECTORY |
| M (ci_macos_lean) | G (gen3xx wheel prod) | 118/119 | 9: CORK/FBX/LIBIGL paths, QRDB fetch/install deps |
| W (ci_windows_lean) | B (build.ps1 wheel prod) | 83/86 | 14: PLUGIN_ON panel + CORK/FBX/LIBIGL paths, BUILD_PYPI, PYTHONVENV/WORKROOT naming |

The CI lean is therefore a STRICT SUBSET of production at the configure step
(nearly: W adds win_deploy_qt stub, PYTHONVENV_DIR naming; M values differ
on OPENCASCADE source conda vs Homebrew, G). The CI validates: the
35-flag core preset, the conda pre-allocation scheme, the PythonAPI paths,
the base inheritance mechanism. Production families are then almost pure
additive overlays: enable plugins, BUILD_REFERENCE_DOC/BUILD_PYPI,
machine-specific paths.

What presets will NOT carry over, by nature (stays script-side):
machine-specific absolute paths (FBX SDK, CORK, LIBIGL, OPENCASCADE_REP,
venvs), wheel post-build steps (delocate/auditwheel/rpaths, signature),
legacy-vs-wheel layout choices, gfortran/packaging.

CONSEQUENCE (DJ5 acted by Paul, 25/11): tuning on the 3 CI is effective and
extensible. 9 named families from J2b: ci-{linux,windows,macos},
legacy-{linux,windows,macos}, wheel-{linux,windows,macos}. J2b implements
only the 3 ci-* (DJ3 unchanged); the legacy-*/wheel-* placeholders are
declared now so J2c stays additive, no base churn. Machine paths and
wheel post-build steps stay script-side.

## 5. J2a.2 - Dead flags: "Manually-specified variables were not used" (macOS, Linux, Windows configs, 25/11)

List provided by Paul from the macOS lean configure. Classification by
cause, verified against the CMake sources of the submodule pin:

### 5.1 Dead by platform gating (expected on macOS, ALIVE on Windows)

| Flag | Consumer | Cause on macOS |
|------|----------|----------------|
| OPENCASCADE_DLL_DIR | qStepCADInstall WIN32 install rules (+ pybind11 WIN32 OCCT_DLL_FILES) | WIN32-only reads |
| OPENCASCADE_TBB_DLL_DIR | qStepCADImport WIN32 rules (tbb.dll copy) | WIN32-only reads |
| MPIR_INCLUDE_DIR, MPIR_RELEASE_LIBRARY_FILE | qCork cmake/CorkSupport.cmake | only read when PLUGIN_STANDARD_QCORK=1 (OFF in the lean; gen3xx keeps them used) |

### 5.2 Dead everywhere (feature always OFF in all 5 scripts)

| Flag | Consumer | Cause |
|------|----------|-------|
| QHULL_LIBRARY_DEBUG / _DEBUG_STATIC / _SHARED / _STATIC | qHPR cmake/FindQhull.cmake | only read when USE_EXTERNAL_QHULL_FOR_QHPR=1, set to 0 in all 5 scripts. Consistent with the earlier plan (family B: qHPR uses bundled qhull) but the flags should then simply be removed from the scripts |

### 5.3 Dead by naming error (false friends, never consumed)

| Flag passed | Real consumer expects |
|-------------|----------------------|
| DRACO_INCLUDE_DIR | DRACO_INCLUDE_DIRS (qDracoIO reads the plural form) |
| DRACO_LIB_DIR | no consumer found (DRACO_LIBRARIES is the real one) |
| EIGEN_INCLUDE_DIR | EIGEN_ROOT_DIR is the real one (EIGEN_INCLUDE_DIR only appears inside the vendored Eigen of cc3DFin) |
| CONDA_LIBS | no consumer anywhere (vestige; grep shows only the passing scripts) |

### 5.4 Dead because the option does not exist (in this fork state)

| Flag | Evidence |
|------|----------|
| PLUGIN_PYTHON | option declared nowhere in the submodule. Paul: PLUGIN_PYTHON belongs to a CLOUDCOMPARE plugin (embedded Python interpreter of the CloudCompare GUI), never used by CloudComPy: harmless legacy in the scripts, removable |
| PLUGIN_STANDARD_MASONRY_QAUTO_SEG / QMANUAL_SEG | option files live in plugins/core/Standard/qMasonry/ but the qMasonry directory is COMMENTED OUT in plugins/core/Standard/CMakeLists.txt (line 26) so the option is never declared. Passed by 4 of the 5 scripts + the Ubuntu production scripts, dead on all 3 CI platforms. Paul: the plugin is no longer maintained upstream: removal from the scripts is safe (re-check against latest upstream master first) |

### 5.5 Dead by plugin-off gating (this config only)

| Flag | Cause |
|------|-------|
| FBX_XML2_LIBRARY_FILE | declared/consumed by qFBXIO only (FBX 2019 SDK path); passed EMPTY by the maclean script while PLUGIN_IO_QFBX=0 |

### 5.6 Linux run (provided by Paul, same day)

Dead on Linux, already dead on macOS (cross-platform confirmation):
DRACO_INCLUDE_DIR, DRACO_LIB_DIR, EIGEN_INCLUDE_DIR, MPIR_INCLUDE_DIR,
MPIR_RELEASE_LIBRARY_FILE, OPENCASCADE_DLL_DIR, OPENCASCADE_TBB_DLL_DIR,
PLUGIN_PYTHON.

Dead on Linux only:

| Flag | Verified cause |
|------|----------------|
| GMP_LIBRARIES_DIR | no consumer anywhere; only GMP_LIBRARIES is read (CCCoreLib CGAL path, InstallCGALDependencies.cmake) |
| MPFR_LIBRARIES_DIR | no consumer anywhere; only MPFR_LIBRARIES is read |
| OpenMP_omp_LIBRARY | no consumer anywhere (vestige of an OpenMP override attempt) |
| TBB_DIR | no consumer found with CCCORELIB_USE_TBB=0. NOT dead on macOS (not in the mac list): TBB_DIR is consumed over there, presumably via a find_package chain pulled by OPENCASCADE/PCL. Keep it in the macOS families of the presets |

Notes:
- CONDA_ENV, CMAKE_C/CXX_COMPILER, GMP_LIBRARIES, MPFR_LIBRARIES, GDAL_*,
  LASZIP_*, XercesC_* are NOT in the dead list: the Linux-unique conda
  pre-allocation flags (except the 4 above) do their job.
- The Linux CI script does not pass QHULL_LIBRARY_* nor MASONRY_* (no
  surprise there).
- CORRECTED (Paul's review): there IS an FBX SDK on Linux, as a static
  library: the wheel driver exports fbxsdk_rep and Linux/pyproject.toml
  passes FBX_SDK_INCLUDE_DIR / FBX_SDK_LIBRARY_FILE / FBX_XML2_LIBRARY_FILE.
  Only the linux CI lean script omits the FBX flags (lean choice).

### 5.7 Windows run (provided by Paul, same day)

Dead on Windows: MPIR_INCLUDE_DIR, MPIR_RELEASE_LIBRARY_FILE (expected:
PLUGIN_STANDARD_QCORK=0 in the lean; alive in build.ps1 where QCORK=1),
PLUGIN_PYTHON and PLUGIN_STANDARD_MASONRY_* (3rd platform confirming 5.4),
and two flags dead by doc-build gating:

| Flag | Verified consumer | Cause on the Windows lean |
|------|-------------------|---------------------------|
| PYTHONVENV_DIR | sphinxDoc/genSphinxDocConda.sh.in and genSphinxDocMacOSConda.zsh.in (`@PYTHONVENV_DIR@` substitution) | no Windows doc template; alive on Linux/macOS |
| REPO_DIR | sphinxDoc/CMakeLists.txt, only under BUILD_PYPI=1 (`REPO_GIT_DIR`) | the lean does not set BUILD_PYPI; alive in the wheel families (mac CI passes BUILD_PYPI=1) |

Positive confirmation of 5.1: OPENCASCADE_DLL_DIR and OPENCASCADE_TBB_DLL_DIR
are NOT dead on Windows (the WIN32 rules read them, exactly as predicted).
The Windows script also does not pass the DRACO/EIGEN false friends (it
uses the correct DRACO_INCLUDE_DIRS / EIGEN_ROOT_DIR spellings) and passes
no TBB_DIR.

### 5.8 Consequences for J2b

- J2a.2 is now COMPLETE for the 3 CI platforms.
- Naming errors (5.3) and nonexistent options (5.4, incl. MASONRY confirmed
  on all 3 platforms) are removable from the scripts in all cases: zero
  risk (re-check qMasonry against latest upstream master first).
- 5.2 flags (QHULL_LIBRARY_*): removable since the feature stays OFF everywhere.
- Linux-only dead flags (5.6: GMP_LIBRARIES_DIR, MPFR_LIBRARIES_DIR,
  OpenMP_omp_LIBRARY, TBB_DIR): removable from the Linux script; TBB_DIR
  stays in the macOS families.
- PYTHONVENV_DIR: keep for the Linux/mac families (doc generation), remove
  from the Windows script.
- REPO_DIR: keep only in the BUILD_PYPI (wheel) families.
- Platform-gated flags (5.1) stay in the WINDOWS family only, disappear
  from the macOS family.
- Scope: the same removals apply to the Ubuntu legacy production scripts
  (family P, still passing the Linux dead flags) and, as an IN-TREE
  PRECEDENT, Linux/pyproject.toml (family K) already has them commented
  out: the cleanups to come converge toward the state the Linux wheel
  family had already reached (4.6).
- CAUTION: removal changes nothing functionally (dead -D only pollutes the
  cache) but reduces the audit noise; do it in the same J2b commit series,
  one family per commit, CI runs to confirm green.

## 6. Pending (other J2a sections)

- J2a.1 / J2a.2 / J2a.3 / J2a.4: complete, reviewed by Paul for 1-3 and 7.
- J2a.5: final pass on the completed document, then commit by Paul on
  ci/j2a-audit (do not commit J2a-fork-vs-base.diff).

## 7. Review notes (J2a.5, Paul, 26/11/2026)

### 7.1 Decisions acted (they supersede or extend the section 2 proposals)

| Topic | Decision |
|-------|----------|
| LASFWF (anomaly 2/4 related) | the plugin is deprecated and no longer used: KEEP THE UPSTREAM ORIGINAL, drop the fork modifications entirely (supersedes the earlier "restore the WIN32 guard" proposal: even better, nothing to keep) |
| pixi.toml / pixi.lock | keep the ORIGINAL upstream versions (CloudCompare standalone builds only, not CloudComPy) - confirms anomaly 1 |
| .ci/conda-macos.yml (pdal) | to verify, but was meant for STANDALONE CloudCompare builds (possibly a plugin): must not serve CloudComPy: keep the original, do not document it as a CloudComPy path |
| Docker builds (family P, Conda310/311_docker.sh) | users still ask for them: keep if not too complicated - maintenance confirmed as wanted, low priority |
| FBX on Linux | factual correction integrated in 4.3/4.5/5.6: FBX SDK exists on Linux (static library), the Linux wheel builds the QFBX plugin |

### 7.2 Verification items (J2b prerequisites or during J2b)

1. Mouse3DInput_mac.cpp/.h (family E): probably unnecessary with the latest
   CloudCompare versions: verify against the current HEAD.
2. OPTION_SUPPORT_3DMOUSE_WITH_3DxWARE / WITH_HIDAPI: evolved a lot in
   CloudCompare: re-read the HEAD option semantics before freezing CI
   values in the ci-* presets.
3. OPENCASCADE conda vs Homebrew in gen3xx (M vs G, section 4.2): IF the
   conda OCCT works, take it in production (simpler, no $HOME path).
   Paul does not remember testing it: add a one-shot test build with
   conda OCCT to J2b.
4. TBB_DIR / CCCORELIB_USE_TBB: when does TBB actually serve? Possible
   redundancy with QtConcurrent; Paul removed it once because of compile
   problems on one platform. Check the HEAD usage of CCCORELIB_USE_TBB
   before deciding whether the ci-* presets even mention TBB.
5. REPO_DIR (5.7): consumer identified: sphinxDoc/CMakeLists.txt uses it
   only under BUILD_PYPI=1 as REPO_GIT_DIR (git version string into the
   reference doc when the build tree differs from the source tree).
   Documentation TODO: one inline comment in the sphinxDoc CMakeLists
   explaining the indirection, so the reason stays visible.

### 7.3 Dead naming errors: correct or remove? (answer to Paul's question)

REMOVE, do not "correct". Rationale: a correction would mean adding the
correctly-named variables (DRACO_INCLUDE_DIRS, etc.), but the CI builds
are green without them: CMake autodetection (via CMAKE_PREFIX_PATH /
conda install tree) does the job, and where pre-allocation is genuinely
needed the correctly-named variables are already passed (W/B already use
DRACO_INCLUDE_DIRS, all families use EIGEN_ROOT_DIR / DRACO_LIBRARIES).
If some future run shows autodetection flakiness, the fix is to add the
correctly-named cache variable AT THE PLACE where it is consumed, i.e. one
visible change, never again anonymously in a 100-line -D list.

### 7.4 Deferred (J3 or later)

- Duplicated CloudCompare code inside CloudComPy (PyCC.cpp and the
  pybind11 translation units): (a) tag each duplicated zone with precise
  provenance comments (exact upstream file, commit/tag); (b) set up a
  systematic check of what changed upstream in those zones (the J1b
  extern-template LNK2005 lesson: PointCloudTpl::addPoint) and report the
  changes; (c) the split between pyCC.cpp and the pybind11 files is
  historical and arbitrary: rationalize.
- FBX licensing: is it correct to ship the proprietary FBX plugin in the
  wheels/legacy artifacts? Minimal step: document the list of embedded
  components with their respective licenses (THIRD_PARTY-style doc),
  and revisit the question from there.

## 8. J2a.4 - Impact audit option by option + proposed CMake guards (26/11)

Scope: the options with KNOWN side effects (from the J1b lessons, the
anomalies of section 2 and the review notes of section 7). The 35 flags of
the preset core (4.1) with uninteresting semantics are not repeated here.
Guard severities: **FATAL** = the configuration is nonsense, stop the
configure; **WARN** = suspicious but plausible, print a prominent warning;
**PRESET-ONLY** = no CMake guard, the value is validated by the preset
inheritance itself (DJ4 territory).

### 8.1 INSTALL_PREREQUISITE_LIBRARIES (the pathological option)

What: declared upstream (CloudCompare/CMakeLists.txt), default OFF on
Apple, ON elsewhere. Gates: copy_files install rules of prerequisites,
the WIN32 OCCT_DLL_FILES block in pybind11/CMakeLists.txt (pre-7.8 OCCT
names!), the bundle/deployment logic on macOS that copies Conda libs
(libomp double-copy lesson of J1b).

Impact observed (J1b): ON on Windows wipes out on missing tbb.dll (oneTBB
naming) and pre-7.8 TKSTEP*.dll names -> decisions D13 (Windows lean = 0)
and its macOS extension (+de-duplication libomp before wheel build).

Proposed guard:
- **FATAL** on the combination APPLE + BUILD_PYPI + explicit ON: the
  bundle path duplicates Conda libs into the wheel (OMP Error #15 class).
- **WARN** on WIN32 + ON + OPENCASCADE_78_OR_NEWER: the OCCT_DLL_FILES
  block still uses pre-7.8 names, so this combination cannot work today
  (upstream fix candidate J3).
- No guard for the normal Windows ON case: historical behavior.

### 8.2 BUILD_PYPI (layout switch of the whole install tree)

What: CMakeLists.txt:26, switches the install layout to the wheel
convention (package cloudComPy/, __init__ from PythonAPI templates).

Known effects / risks:
- Windows: `__init__-Windows.py` is configured for the wheel layout in
  BOTH modes (incoherence observed in J1b, shim d4b91cd/a53aeaf in CI;
  layout decision deferred to J3 per Paul).
- macOS wheel: requires the relative CMAKE_INSTALL_RPATH scheme
  (@loader_path first, J1b aa6a8de) and INSTALL_PREREQUISITE_LIBRARIES=0.
- Linux wheel: built through scikit-build-core, not this option path.

Proposed guard:
- **WARN** at the end of configure when BUILD_PYPI AND (APPLE OR WIN32)
  and no explicit choice of rpath scheme / init-template handling was made
  - unrealistic today; preferred: **PRESET-ONLY** (the wheel-* presets carry
  the coherent set BUILD_PYPI=1 + rpaths + INSTALL_PREREQUISITE=0), plus a
  short comment block in CMakeLists.txt:26x pointing to the presets.
- ~~**WARN** when BUILD_PYPI=1 and PYTHON_PREFERED_VERSION was not pre-set~~:
  moot, the option has a cache default (3.9) - the real rule is
  **PRESET-ONLY**: the wheel-*/ci-* presets always carry the explicit
  PYTHON_PREFERED_VERSION matching the conda env, so the existing fatal
  check (8.3) protects the rest.

### 8.3 PYTHON_PREFERED_VERSION / PYMINOR (Python selection)

What: introduced early (Paul, 26/11) to be EXPLICIT about the selected
Python major.minor on systems hosting several versions - the pin gives the
found interpreter priority, and a mismatch is fatal BY DESIGN, not a
warning to soften.

Existing behavior (pybind11/CMakeLists.txt:24-44, read in the audit):
PYTHON_PREFERED_VERSION seeds Python_ADDITIONAL_VERSIONS before
find_package(Python3), then `message(SEND_ERROR "no Python found
matching ...")` if Python3_VERSION does not match - the initially
proposed guard G3 is therefore REDUNDANT and is WITHDRAWN.

What remains:
- 8.3.a (Paul, 27/11) DERIVE, do not double-define: PYMINOR is consumed
  ONLY by building/CMakeLists.txt (conda-list filenames, 3 spots). A
  micro-patch deriving it at the place of consumption removes the flag
  from all scripts and presets:
  `string(REGEX REPLACE "^3\\\\." "" PYMINOR "${PYTHON_PREFERED_VERSION}")`
  - upstreamable, no behavior change. Until it lands: G4 WARN on
  divergence (below); once landed: PYMINOR disappears from the presets.
- G4 (transitional) **WARN** if an explicitly-set PYMINOR is inconsistent
  with PYTHON_PREFERED_VERSION: PYMINOR feeds the conda-list filename
  (Windows) and does NOT benefit from the fatal check of 8.3 - a typo
  there fails late on a file INSTALL error (lesson J1b ebbd785).

### 8.4 CONDA pre-allocation variables (DRACO_LIBRARIES, GDAL_*, GMP/LASZIP/MPFR/XercesC/ZLIB/OPENCASCADE_INC_DIR...)

What: for each, overriding find_package autodetection with an explicit
conda path. Alive flags verified in 5.6; dead siblings removed per 5.8/7.3.

Risk: stale/mixed dependency trees (GDAL 3.13 CSLConstList lesson of J1b:
env A resolves a newer GDAL than env B). No structural fix in CMake.

Paul (27/11): with CMAKE_PREFIX_PATH at the conda env root, a fair number
of prerequisites resolve automatically. Census of the consumers (read in
the pin during this audit):

Class A - standard find_package / Find modules honoring CMAKE_PREFIX_PATH,
pre-allocation PROBABLY removable with conda (to confirm empirically):
GDAL (qCC_io/cmake/GDALSupport.cmake: find_package(GDAL REQUIRED)),
XercesC (libE57Format), ZLIB (quazip in qPhotoscanIO), TBB (CCCoreLib,
CONFIG mode: the TBB_DIR hint), CGAL (CCCoreLib, CONFIG: the CGAL_DIR
hint), Draco (qDracoIO: find_package(Draco), so DRACO_INCLUDE_DIRS /
DRACO_LIBRARIES pre-allocation removable), pybind11/Boost/OpenCV/PCL
(CONFIG-mode *_DIR hints). CAUTION: an "alive" status in the CMake
unused-variables log is NOT a proof of necessity here - find_package
marks a provided *_DIR as used even when CMAKE_PREFIX_PATH would have
found the package anyway (this explains why TBB_DIR was "used" on mac).

Class B - custom cache variables with NO find module, pre-allocation
TO KEEP: OPENCASCADE_INC/LIB/DLL_DIR (qStepCAD reads plain cache vars),
CORK_*/LIBIGL_*/FBX_SDK_*/MPIR_* (custom file paths in plugin CMakeLists),
EIGEN_ROOT_DIR (custom), FFMPEG_* (custom), PYTHONVENV_DIR / REPO_DIR
(fork templates). GMP/MPFR/LASZIP: consumed through CCCoreLib CGAL
paths / lasIO custom code - to classify during the empirical pass.

Class C - the empirical J2b experiment (per family): one CI run with
the lean script reduced to CMAKE_PREFIX_PATH = conda root + Class B
variables only, then compare the resolved paths/libs against the
pre-allocated reference build. Only what resolves identically gets
removed from the presets. Precedent: the Linux wheel family K already
relies on env exports for the find-based part.

Guard G5 (one generic pattern, not 20 copies) - safety net for the
variables that remain after the Class C pass: **FATAL** at the end of
configure if an explicitly-set, path-typed variable points to a
nonexistent file (e.g. GDAL_LIBRARY), implemented as a single foreach
loop in building/ + pybind11 CMakeLists, only for variables that were
explicitly set (DEFINED check), to keep autodetection unaffected.

### 8.5 OPENCASCADE_78_OR_NEWER (and the OCCT version drift)

What: passed by CI/prod scripts to match the conda OCCT packing; interacts
with the OCCT_DLL_FILES naming (8.1) and installation rules.

Proposed guard: **WARN** if the OCCT actually found (OPENCASCADE_INC_DIR
version check via OCC_VERSION complete macro) disagrees with the flag.
PRESET-ONLY for the value itself (the presets of the 9 families carry it
consistently).

### 8.6 USE_EXTERNAL_QHULL_FOR_QHPR

What: fork family B; qHPR external qhull via FindQhull.cmake. OFF in the
5 audited scripts (+ P). Since it is OFF everywhere and upstream merge is
the priority (DJ2):
- **PRESET-ONLY**: the ci-*/legacy-*/wheel-* presets pin it to 0 as a
  cached visible variable; a future FATAL guard if someone sets it to 1
  without providing QHULL_LIBRARY_* is NOT needed now (dead branch,
  candidate for simplification with the family B review).

### 8.7 OPTION_SUPPORT_3DMOUSE_WITH_3DxWARE / WITH_HIDAPI / TBB

Pending verification against upstream HEAD (7.2 items 2 and 4). Until
then: **PRESET-ONLY** (presets keep the audited values 3DxWARE=0 /
HIDAPI=1 / TBB off), no guards, no renaming.

### 8.8 PLUGIN_* panel (35 core + 4 families)

No guard proposal: the panel is validated by the red/green CI runs per
family. Each risky plugin (QFBX, QCORK, QMESH_BOOLEAN, QRDB: externals)
stays OUT of the ci-* presets and IN legacy-*/wheel-* (DJ5), so a broken
external shows as a preset inheritance choice, not a silent flag.

### 8.9 PYTHONAPI_TRACES, PYTHONAPI_TEST_DIRECTORY / EXT_DATA_DIRECTORY, USE_CONDA_PACKAGES

- PYTHONAPI_TRACES=1 is a CI/prod diagnostic choice: PRESET-ONLY.
- PYTHONAPI_*_DIRECTORY: PRESET-ONLY; the J1b `_${PYMINOR}` filename
  class (ebbd785) is a script-side concern, not a guard.
- USE_CONDA_PACKAGES (Paul, 27/11): verified - the option only selects
  WHICH generated doc/bundle templates get configured (building/
  CMakeLists.txt + sphinxDoc/CMakeLists.txt: conda vs native script
  variants); zero effect on compilation and link. DECISION for the
  presets: impose USE_CONDA_PACKAGES=ON in all 9 families and simplify
  accordingly (8.4 census); non-conda native builds are out of scope for
  now (no priority per Paul) - if ever needed, a separate low-priority
  preset or none at all. The G7 WARN (ON without CONDA_PREFIX) is
  RETIRED: pointless once ON is imposed by the presets and the option
  does not affect the build itself.

### 8.10 Summary of the guards for J2b.1

| # | Guard | Where | Severity | Priority |
|---|-------|-------|----------|----------|
| G1 | APPLE + BUILD_PYPI + INSTALL_PREREQUISITE_LIBRARIES explicitly ON | pybind11 or root CMakeLists, next to the option | FATAL | high |
| G2 | WIN32 + INSTALL_PREREQ ON + OPENCASCADE_78_OR_NEWER (OCCT_DLL_FILES obsolete names) | pybind11, OCCT_DLL_FILES block | WARN | high |
| G3 | WITHDRAWN (26/11, Paul): the explicit Python pinning + SEND_ERROR already exists in pybind11/CMakeLists.txt:24-44 | - | - | - |
| G4 | PYMINOR vs PYTHON_PREFERED_VERSION | pybind11, after the Python check | WARN | medium |
| G5 | pre-allocated path variables (foreach on the explicit ones) point to nonexistent files | building/ + pybind11 end of configure | FATAL | medium |
| G6 | OPENCASCADE_78_OR_NEWER vs detected OCCT version | pybind11 | WARN | low |
| G7 | RETIRED (27/11, Paul): USE_CONDA_PACKAGES imposed ON by the presets, option gates only template selection, no build effect | - | - | - |

Placement rule: guards live next to the code they protect (fork files),
are short (< 20 lines each), in ASCII, with a comment naming the J1b
lesson or audit section that motivates them - so each remains upstreamable
or at least reviewable in a patch series (DJ2).

Non-goals (recalled): no renaming of upstream options; no exhaustive
combination testing; presets remain the main validation channel (DJ4/G4
gates included).
