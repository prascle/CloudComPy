# Milestone J2b: CMake guards, CMake presets, dead-flag cleanup, class C experiment

Branch: `ci/j2b-presets` (from master `638d587`, i.e. post-PR #8), 27 Nov 2026.

## Scope

Implement the J2a audit conclusions (see `J2a-audit.md`, decisions DJ1-DJ5):

1. CMake guards G1/G2/G4/G5/G6 (G3 and G7 withdrawn, see audit 8.10) protecting
   the option combinations that bit us in J1b.
2. `PYMINOR` derived inside `building/CMakeLists.txt` from
   `PYTHON_PREFERED_VERSION` (audit 8.3.a) instead of being passed by scripts.
3. Dead-flag removal from the CI scripts, then from the production scripts
   (audit section 5.8).
4. `CMakePresets.json`: the 9 families of DJ5, with only the 3 `ci-*` families
   implemented in J2b, the 6 `legacy-*`/`wheel-*` as hidden placeholders (J2c).
5. Class C experiment (audit 8.4): one CI run per family with the class A
   pre-allocation removed, resolved-path comparison against the reference
   build, then definitive removals of everything that resolves identically.

Milestone decisions: DJ1 (audit before code), DJ2 (minimize the fork diff,
upstreamable patches), DJ3 (the 3 CI platforms first), DJ5 (9 preset families;
J2b implements `ci-*` only), DJ4 (preset consumption by scripts) resolved at
the end of this milestone, see below.

## DJ4 resolution (proposed, this document)

The CI scripts do NOT consume `cmake --preset` at the end of J2b. Rationale:
- the scripts are now lean (class B only); the flag panel they still pass is
  exactly the panel the `ci-*` presets carry, so consuming the presets now
  would save ~40 near-duplicate lines but change nothing semantically;
- the real payoff is for the 6 missing families: J2c will implement
  `legacy-*`/`wheel-*` FROM the presets (single source of truth for the 9
  families), and the Linux wheel family (K) can consume presets through
  scikit-build-core (audit 4.5);
- machine paths and class B pre-allocation stay script-side by design (audit
  8.4), so the scripts keep a `cmake` invocation anyway; wiring them to
  `--preset` belongs to the J2c family work where it can be validated per
  family.
Status: PROPOSED to Paul with the PR; J2c starts from this.

## Commits (all on `ci/j2b-presets`)

| # | Subject | Content |
|---|---------|---------|
| 1 | guards + PYMINOR derivation | G1/G2/G5/G6 in `pybind11/CMakeLists.txt`, PYMINOR derivation in `building/CMakeLists.txt` (compat + WARN divergence if explicitly set), REPO_DIR comment in `sphinxDoc/CMakeLists.txt` |
| 2 | temporary push trigger | `ci/j2b-presets` in `on.push.branches` (removed in the final cleanup) |
| 3 | CI dead flags | `ci_linux_lean.sh` 160-148, `ci_macos_lean.zsh` 422-406, `ci_windows_lean.ps1` 249-242 (audit 5.8) |
| 4 | production dead flags | gen3xx macos, 5 Ubuntu legacy, 2 docker, `build.ps1` (audit 5.8; `FBX_XML2`/`FBX_ZLIB` kept pending the FBX SDK version check) |
| 5 | `CMakePresets.json` | base (35 core flags + PYTHONAPI directories + USE_CONDA_PACKAGES), ci-common, lean plugin panel, `ci-linux-lean`/`ci-windows-lean`/`ci-macos-wheel`, 6 hidden placeholders |
| 6 | class C experiment | `CLASS_C=1` env switch in the 3 CI scripts |
| 7 | experiment to workflow | `env: CLASS_C: "1"` at workflow level |
| 8 | DRACO fix (windows/macos) | DRACO_* moved to class B after run #65 LNK2019 lesson |
| 9 | definitive class A removals | scripts reduced to class B, experiment blocks removed, `env: CLASS_C` removed |
| 10 | final cleanup | `-DPYMINOR` removed from the 3 CI scripts (derivation from commit 1), temporary push trigger removed |
| 11 | GMPXX fix | `GMPXX_LIBRARIES` reinstated as class B on macos (nondeterministic delocate breaks, dispatches #66/#70) |
| 12 | milestone doc | this document + `README.md` index update (separate commit, working method) |
| 13 | macOS class C cancelled | all 22 class A pre-allocations restored to the reference values on macos after dispatch #71 (`libmpfr.6.dylib`, same delocate break as GMPXX); macos keeps ZERO class A removals, linux/windows removals stay |

(Exact commit hashes: see the PR.)

## Presets (`CMakePresets.json`, version 6)

- `cloudcompy-base` (hidden): the 35 constant flags of audit 4.1 +
  `PYTHONAPI_TEST_DIRECTORY`/`PYTHONAPI_EXTDATA_DIRECTORY` (consumed only by
  `tests/gendata.py`; note: when a script later consumes presets, the Linux
  test data directory name changes from `CloudComPyData` to `CloudComPy/Data`)
  + `USE_CONDA_PACKAGES=ON` imposed (audit 8.9, G7 withdrawn).
- `ci-common` (hidden): `BUILD_REFERENCE_DOC=0`, `CMAKE_BUILD_TYPE=Release`,
  `PYTHON_PREFERED_VERSION=3.12` explicit (fatal mismatch check by design).
- `ci-lean-plugin-panel` (hidden): the W/M panel (external-dependency plugins
  off). 3D mouse options live here, NOT in the base: upstream defaults are OFF
  and the Linux CI does not pass them; HIDAPI=1 forces `find_package(hidapi)`
  with a vendored fallback, which must not be imposed on Linux by inheritance.
- `ci-linux-lean`, `ci-windows-lean`, `ci-macos-wheel`: inherit the above;
  macos carries the `@loader_path` rpath scheme with `$env{CONDA_PREFIX}`.
- 6 hidden placeholders `legacy-*`/`wheel-*` (DJ5) inheriting the base only.
- Machine paths and class B pre-allocation are deliberately NOT in the presets
  (script-side, audit 8.4). PYMINOR is absent (derived since commit 1).

Validation: JSON syntax, schema v6, inheritance closure/cycles, and an
automated merged-variables comparison against the actual flag lists of the 3
CI scripts (zero divergence, zero missing flag) were run offline; the file is
not consumed by any build yet (DJ4).

## Class C experiment (audit 8.4) and definitive removals

Method: reference runs (default mode) and class C runs (`CLASS_C=1`: class A
pre-allocation removed, `CMAKE_PREFIX_PATH` explicit), both dumping the
resolved `CMakeCache.txt` entries; per-variable comparison.

Incidents (lessons):
- Windows and macOS failed to LINK `qDracoIO` (LNK2019): the conda Draco
  package resolves `Draco_DIR` via CMAKE_PREFIX_PATH but provides no usable
  `DRACO_LIBRARIES`, so the plugin compiles but links without `draco.lib`.
  Lesson recorded in the audit's own warning: a "used" `*_DIR` does not prove
  autodetection is sufficient. DRACO_* therefore stay class B on windows and
  macos; on Linux the conda package resolves even the library, DRACO was
  removed.

Results (27/11):
- Linux: 13 variables removed (GDAL, GMP, LASZIP, MPFR, XercesC, ZLIB, DRACO);
  all resolved identically. The bogus `XercesC_LIBRARY_DEBUG-NOTFOUND`
  pre-allocation is gone.
- macOS: EXPERIMENT CANCELLED on 28/11 (decision Paul). The 22 class A
  pre-allocations were removed on 27/11 (19 resolved identically at
  configure time; PNG/ZLIB/XercesC_LIBRARY_DEBUG divergences were then
  ASSUMED benign), but the wheel BUILD_PYPI chain depends on delocate,
  which copies/rewrites dependencies NONDETERMINISTICALLY on basename
  collisions (the J1b exclusion loop). With the auto-detected link graph,
  `libgmpxx.4.dylib` (dispatches #66/#70) then `libmpfr.6.dylib`
  (dispatch #71) got excluded from the copy, leaving broken
  `@executable_path/../Frameworks/...` references at import; identical
  branch states flipped between green and a broken wheel. An identical
  configure-time resolution therefore does NOT prove the safety of a
  removal on this chain. All 22 pre-allocations are RESTORED to the
  reference values (commit 13): macos keeps ZERO class A removals; the
  fragile numeric-libs chain (CGAL, GMP/GMPXX, MPFR) is no longer linked
  through auto-detection at all. Linux/Windows removals (deterministic
  toolchains, no delocate) stay.
- Windows: `Qt6_DIR` removed (resolved identically). DRACO_* kept (class B).
- Class B kept everywhere: `EIGEN_ROOT_DIR`, `OPENCASCADE_INC/LIB(_DLL...)_DIR`,
  `FFMPEG_*` (macos), `TBB_DIR` (macos), `CONDA_ENV`/`CONDA_PATH`,
  `PYTHONVENV_DIR`, `REPO_DIR`, `win_deploy_qt` (windows), `CLOUDCOMPARE_VERSION`.

## Validation status

- Linux and Windows runs went green on the final state (class C now the
  default configuration).
- macOS: the class C state (22 removals) was NOT valid (green/red
  nondeterminism, see above); the reference state is restored in commit 13
  and must be validated by fresh dispatches before the PR leaves draft.
- NOT covered by CI (to be validated by Paul's next production builds):
  the production-script removals of commit 4 (gen3xx, Ubuntu legacy, docker,
  `build.ps1`), including the pending FBX XML2/ZLIB verdict (FBX SDK version),
  and the OCCT-conda test in gen3xx (audit 7.2 item 3).

## Pending (carried to J2c or later, audit 7.2)

1. `Mouse3DInput_mac` vs current HEAD (7.2 item 1).
2. 3D mouse option semantics vs HEAD (7.2 item 2) before freezing CI values.
3. One-shot OCCT conda test build in gen3xx production (7.2 item 3).
4. `CCCORELIB_USE_TBB` vs QtConcurrent role check (7.2 item 4).
5. FBX XML2/ZLIB library verdict at the next Windows production build.
6. J2c proper: implement `legacy-*`/`wheel-*` presets, wire the scripts (and
   scikit-build-core) to consume them per the DJ4 resolution above.

## Working method notes (J2b-specific)

- The temporary push trigger and the `CLASS_C` env were marked "EXPERIMENT
  TEMPORAIRE, A RETIRER AVANT LA PR" and removed in the final cleanup, as
  planned in the J2a working method.
- Process lessons of the day (recorded in the project Knowledge): verify the
  tracked/untracked status of a file by direct evidence before working on it
  (the `build.ps1` premise error); awk `$0 !~ pat` (NOT `!$0 ~ pat`), always
  filter to a temp file and check line counts before overwriting; `edit`
  line deletions must anchor on the following line and be followed by
  `grep -c`; no comment line inside a backslash continuation (caught on the
  macos script during the commit-8 preparation).
