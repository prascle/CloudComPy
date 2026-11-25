# Milestone J1b: lightweight CI builds on the three OS, with downloadable artifacts

Branch: `ci/j1b-binaries` (from master `f57b138`), 19-25 Nov 2026.

## Scope

Complete the J1a lightweight Linux check with full CI builds of the three OS,
each publishing a downloadable artifact:

| OS | runner | artifact | trigger |
|---|---|---|---|
| Linux | `ubuntu-24.04` | install tree, `tar.xz` | push on `master` and `v*` tags |
| Windows | `windows-latest` | install tree, `.zip` | push on `master` and `v*` tags |
| macOS | `macos-15` (arm64) | delocated PyPI wheel | manual (`workflow_dispatch`) |

The macOS job is manual only: free macOS runners are scarce and queued runs
were repeatedly cancelled for lack of runner. Linux and Windows jobs also run
on tag pushes, so a release tag produces all three artifacts.

Milestone decisions: D9 (macOS reproduces the production PyPI wheel chain,
`BUILD_PYPI=1`, no signing/notarization in CI), D10 (Python 3.12 everywhere
for J1b), D11 (the Windows lean build follows `build.ps1`, external-plugin
dependencies off), D12 (Windows artifact = zip), D13
(`INSTALL_PREREQUISITE_LIBRARIES=0`, like `build.ps1`), D14 (do not force
`QT_QPA_PLATFORM` on macOS; `offscreen` remains required on Windows),
D15/D17 (job gating as per the table above).

## Workflow

`.github/workflows/build-binaries.yml`, three jobs:

- `linux`: micromamba env `building/CloudComPy312Qt6_Ubuntu.yml` (cached), then
  `building/ci_linux_lean.sh` (from J1a), install tree packaged as `tar.xz`.
- `windows`: micromamba env `building/CloudComPy312Qt6_Windows.yml` (cached),
  then `building/ci_windows_lean.ps1` (new, twin of the Linux script:
  vcvars64 via vswhere, Conda Qt neutralized in `PATH`, no
  `CMAKE_PREFIX_PATH`, Ninja), install tree packaged as `.zip`.
- `macos`: micromamba env `building/CloudComPy312Qt6_macOS.yml` (cached), then
  `building/ci_macos_lean.zsh` (new): `BUILD_PYPI=1` build, wheel built with
  `python -m build`, delocated with `delocate-wheel
  --ignore-missing-dependencies` (rpaths sanitized), checked with
  `twine check`, then installed in a fresh venv and imported as a smoke test
  (including `isPluginPCL`).

A guard step (right after checkout, macOS job) fails fast with an explicit
message if `building/ci_macos_lean.zsh` is missing: it catches the classic
mistake of dispatching on the default branch (`master`), where the CI scripts
do not exist. The `Run workflow` dialog defaults to `master`: always select
the target branch before running.

The `workflow_dispatch` button only appears when the workflow file exists on
the default branch; a dispatch-only copy of the workflow therefore lives on
`master` (no push triggers, jobs identical).

## Artifacts

- Linux `tar.xz` and Windows `.zip`: install trees. Usage for the zip: set
  `PYTHONPATH` to the `CloudCompare` folder of the extracted tree (not the
  root), then `import cloudComPy`.
- macOS wheel: install with pip in any Python 3.12 environment, no Conda
  environment required (all dependencies are embedded).

## Windows: the `/FORCE:MULTIPLE` workaround replaced by a proper fix

The `/FORCE:MULTIPLE` linker flag was a 2022 workaround for an LNK2005
duplicate-symbol error on `_cloudComPy.pyd`. Reproduced on a throwaway branch
without the flag it showed a single conflict:

```
QCC_DB_LIB.lib(QCC_DB_LIB.dll) : error LNK2005:
"CCCoreLib::PointCloudTpl<ccGenericPointCloud, QString>::addPoint(CCVector3 const&)"
already defined in ccGenericCloudPy.cpp.obj
```

Root cause: `PointCloudTpl` (CCCoreLib) carries no dllexport/dllimport
attribute; `ccPointCloud` is exported by `QCC_DB_LIB.dll`, so the import
library contains the instantiated member, but every consuming translation
unit re-instantiates it locally (the address taken by the pybind11 `.def`
binding in `ccGenericCloudPy.cpp`, and the calls in `ccPolylinePy.cpp` and
`cloudComPy.cpp`).

Fix: an explicit instantiation declaration (C++11 `extern template`) of that
member in the three files, guarded by `#ifdef _MSC_VER` (no impact on
Linux/macOS), plus removal of the flag from `ci_windows_lean.ps1`. Validated
end to end (link, build, smoke test) on the throwaway branch first, then
ported to the milestone branch (byte-identical).

## macOS wheel: delocation findings

The macOS wheel pipeline required several rounds of fixes, all validated on
CI runs and locally by the maintainer:

- collision of duplicate basenames during delocate (two build/install trees
  resolving the same library): the trees are removed before the delocate
  step, unresolved CloudCompare refs are tolerated and resolved inside the
  wheel;
- install names must be rpath-relative (`@loader_path` first): dyld never
  looks into the binary's own folder for an `@rpath` reference, and an
  unsolved `@rpath` ref falls back to the LC_RPATHs of the main executable
  (the Conda python of the venv), which silently pulled a second copy of Qt
  and OpenMP into the process;
- Mach-O binaries with `@rpath` references but no LC_RPATH (Qt Conda
  plugins) are load-time traps in a wheel: `install_name_tool -add_rpath` is
  applied to every binary of the install tree before delocate;
- a single copy of libomp must remain: the deployment copies Conda libraries
  into `Frameworks` regardless of `INSTALL_PREREQUISITE_LIBRARIES=0`, they
  are removed before the wheel build so that delocate provides the one copy
  in `.dylibs`;
- `libopencv_core` (copied by delocate for the PCL libraries) keeps a
  non-resolved `@rpath/liblapack.3.dylib` reference: after delocate, the
  wheel is patched (`install_name_tool -change` to
  `@loader_path/libopenblas.0.dylib`, already embedded for the PCL
  libraries, then re-zipped), and a final check scans the wheel for any
  `@rpath/...dylib` reference whose target is not embedded (fails the build
  otherwise);
- fresh venvs before each pip install in the smoke test: pip skips the
  install when the same name+version is already present, which had silently
  kept testing the previous wheel during local runs.

## Validation

- Linux: green run, artifact validated by the maintainer (61-test suite,
  2 failures attributable to the reduced plugin scope).
- Windows: green run (24 min 50 s), zip layout consolidated to match the
  wheel layout (ghost directories capturing the `cloudComPy` import removed),
  validated manually by the maintainer.
- macOS: green dispatch run on `macos-15`; the CI wheel (267 MB) was
  installed and used by the maintainer on his machine (M1 Max), including a
  CloudCompare GUI launch; all tests pass except two known deferred issues:
  test046 (the CANUPO plugin references `libgif.dylib` through an absolute
  Homebrew path of the CI runner, not embedded in the wheel) and test061
  (timeout, pre-existing). Both are recorded as follow-up tasks and do not
  block the milestone.
- `/FORCE:MULTIPLE`: removed thanks to the `extern template` fix, validated
  end to end.

## Lessons

- An unsolved `@rpath` reference is resolved with the LC_RPATHs of the main
  executable: a wheel must not depend on that fallback.
- A smoke test in CI (fresh venv, no build tree, no Conda env) is the only
  environment that reveals what the build environment masks.
- Distinguish the artifact produced from the artifact actually tested: pip
  skips an install when the name+version is already present.
- Never use `status` as a zsh variable name; never insert comment lines
  inside an antislash continuation; a `zsh` null glob requires the `(N)`
  qualifier.
- In GitHub workflow YAML, a colon followed by a space inside an unquoted
  value makes the whole workflow file invalid: every triggered run fails
  with zero jobs executed.
- The `Run workflow` dialog defaults to the default branch; a dispatch on
  `master` checks out `master`.

## Follow-ups (later milestones)

- Production macOS procedure (`genCloudComPy_Conda3xx_macos.zsh`): port the
  delocation fixes (lapack reference, single libomp, rpaths) and add the
  external-reference check.
- CANUPO plugin: identify the origin of the Homebrew `libgif` reference and
  have it embedded/rewritten in the wheel.
- `__init__-Windows.py`: tolerate both install layouts; OCCT 7.8+ DLL names
  in `pybind11/CMakeLists.txt`; oneTBB naming in qStepCADImport; fallback
  conda/mamba/micromamba in the CI scripts; `conda-list_macOS_312`
  traceability policy.
- `pyAPI/pyCC.cpp` (legacy module target) may exhibit the same LNK2005 class
  on Windows: candidate for the same `extern template` fix.
