#!/bin/sh
exec python3 - "$0" <<'PY'
import json
from pathlib import Path
import shutil
import subprocess
import sys


def export_all():
    conan = shutil.which("conan")
    if conan is None:
        raise RuntimeError("Conan 2 was not found on PATH.")

    third_party = Path(sys.argv[1]).resolve().parent / "third_party"
    recipes = sorted(path.parent for path in third_party.glob("*/conanfile.py") if path.is_file())
    if not recipes:
        raise RuntimeError(f"No Conan recipes found in {third_party}")

    flags = ["--no-remote", "--lockfile="]
    for recipe in recipes:
        try:
            metadata = subprocess.check_output(
                [conan, "inspect", str(recipe), "--format=json", *flags]
            )
            info = json.loads(metadata)
        except (subprocess.CalledProcessError, ValueError) as error:
            raise RuntimeError(f"Cannot inspect recipe: {recipe}") from error

        data = info.get("conandata")
        sources = data.get("sources") if isinstance(data, dict) else None
        if not isinstance(sources, dict) or not sources:
            raise RuntimeError(f"No versions found in conandata.yml for {recipe}")

        for version in sources:
            reference = f"{info['name']}/{version}"
            print(f"Exporting {reference}", flush=True)
            result = subprocess.run([conan, "export", str(recipe), f"--version={version}", *flags])
            if result.returncode != 0:
                raise RuntimeError(f"Export failed: {reference}")

    print("All Conan recipes exported successfully.")


try:
    export_all()
except (OSError, RuntimeError) as error:
    print(error, file=sys.stderr)
    sys.exit(1)
PY
