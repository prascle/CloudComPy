import subprocess
from pathlib import Path
import shutil

DEPENDENCIES_EXE = Path(r"C:\dependencies\Dependencies.exe")

KEEP_KINDS = {"[Environment]"}

def get_modules(binary: Path):
    print(f"Collecting dependencies for {binary}...")
    cmd = [str(DEPENDENCIES_EXE), "-modules", str(binary)]
    output = subprocess.check_output(cmd, text=True, errors="ignore")
    modules = []

    for line in output.splitlines():
        line = line.strip()
        if not line:
            continue

        # Format attendu :
        # [Kind] Name : Path
        if not line.startswith("["):
            continue

        try:
            kind, rest = line.split("]", 1)
            kind = kind + "]"
            rest = rest.strip()
            name, path = rest.split(":", 1)
            name = name.strip()
            path = path.strip()
        except ValueError:
            continue

        modules.append((kind, name, path or None))

    return modules


def collect_non_system_deps(binaries):
    deps = set()

    for binary in binaries:
        mods = get_modules(binary)
        for kind, name, path in mods:
            if kind not in KEEP_KINDS:
                continue
            if not path:
                continue
            deps.add(Path(path).resolve())

    return deps


if __name__ == "__main__":
    roots = [
        Path(r"@CMAKE_INSTALL_PREFIX@\CloudCompare\CloudCompare.exe"),
        Path(r"@CMAKE_INSTALL_PREFIX@\CloudCompare\_cloudComPy.cp3@PYTHON_MIN_VERSION@-win_amd64.pyd"),
        Path(r"@CMAKE_INSTALL_PREFIX@\CloudCompare\_CSF.cp3@PYTHON_MIN_VERSION@-win_amd64.pyd"),
        Path(r"@CMAKE_INSTALL_PREFIX@\CloudCompare\_HoughNormals.cp3@PYTHON_MIN_VERSION@-win_amd64.pyd"),
        Path(r"@CMAKE_INSTALL_PREFIX@\CloudCompare\_HPR.cp3@PYTHON_MIN_VERSION@-win_amd64.pyd"),
        Path(r"@CMAKE_INSTALL_PREFIX@\CloudCompare\_M3C2.cp3@PYTHON_MIN_VERSION@-win_amd64.pyd"),
        Path(r"@CMAKE_INSTALL_PREFIX@\CloudCompare\_PCL.cp3@PYTHON_MIN_VERSION@-win_amd64.pyd"),
        Path(r"@CMAKE_INSTALL_PREFIX@\CloudCompare\_PCV.cp3@PYTHON_MIN_VERSION@-win_amd64.pyd"),
        Path(r"@CMAKE_INSTALL_PREFIX@\CloudCompare\_PoissonRecon.cp3@PYTHON_MIN_VERSION@-win_amd64.pyd"),
        Path(r"@CMAKE_INSTALL_PREFIX@\CloudCompare\_RANSAC_SD.cp3@PYTHON_MIN_VERSION@-win_amd64.pyd"),
        Path(r"@CMAKE_INSTALL_PREFIX@\CloudCompare\_SRA.cp3@PYTHON_MIN_VERSION@-win_amd64.pyd"),
        # autres .pyd/plugins
    ]

    deps = collect_non_system_deps(roots)

    print("=== DLL candidates à copier ===")
    for d in sorted(deps):
        print(d)
        shutil.copy2(d, r"@CMAKE_INSTALL_PREFIX@\CloudCompare")

