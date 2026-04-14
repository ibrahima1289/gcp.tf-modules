"""Simple Terraform modules hygiene check: file types + terraform fmt."""
import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple

# Allowed file extensions within modules/; everything else is flagged
ALLOWED_EXTENSIONS = {".tf", ".md"}
# Directories to prune from traversal (examples and Terraform working dirs)
IGNORE_DIR_NAMES = {"examples", ".terraform"}

def find_disallowed_files(modules_root: Path) -> List[Path]:
    """Return a list of files under modules_root that have extensions not in ALLOWED_EXTENSIONS."""
    disallowed: List[Path] = []
    for root, dirs, files in os.walk(modules_root):
        # prune ignored directories from traversal
        dirs[:] = [d for d in dirs if d not in IGNORE_DIR_NAMES]
        for fname in files:
            fpath = Path(root) / fname
            ext = fpath.suffix.lower()
            if ext not in ALLOWED_EXTENSIONS:
                disallowed.append(fpath)
    return disallowed

def run_cmd(cmd: List[str], cwd: Path) -> Tuple[int, str, str]:
    try:
        proc = subprocess.run(cmd, cwd=str(cwd), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return proc.returncode, proc.stdout, proc.stderr
    except FileNotFoundError as e:
        return 127, "", str(e)

def check_terraform_fmt(modules_root: Path) -> Tuple[bool, str]:
    if shutil.which("terraform") is None:
        return True, "Terraform CLI not found; skipped fmt check."
    rc, out, err = run_cmd(["terraform", "fmt", "-check", "-recursive"], modules_root)
    ok = rc == 0
    msg = out if ok else (out + "\n" + err)
    return ok, msg.strip()

def main() -> int:
    parser = argparse.ArgumentParser(description="Check Terraform module folders for allowed files and formatting")
    parser.add_argument("--root", type=str, default=str(Path(__file__).resolve().parent.parent), help="Repository root containing the modules/ folder (default: repo root)")
    parser.add_argument("--modules-subdir", type=str, default="modules", help="Modules subdirectory relative to root (default: modules)")
    args = parser.parse_args()

    repo_root = Path(args.root).resolve()
    modules_root = repo_root / args.modules_subdir

    if not modules_root.is_dir():
        print(f"ERROR: modules directory not found: {modules_root}")
        return 2

    print(f"Scanning modules under: {modules_root}")

    # Check disallowed files (extensions outside ALLOWED_EXTENSIONS)
    disallowed = find_disallowed_files(modules_root)
    if disallowed:
        print("Disallowed files found (only .tf and .md permitted; ignoring 'examples' folders):")
        for p in disallowed:
            print(f" - {p}")
    else:
        print("No disallowed files detected.")

    # Check terraform fmt
    print("\nTerraform fmt -check -recursive:")
    ok_fmt, fmt_msg = check_terraform_fmt(modules_root)
    print(fmt_msg or "(no output)")

    # Exit code summary (non-zero codes indicate failure conditions)
    if disallowed:
        print("\nResult: FAIL (disallowed files present)")
        return 3
    if not ok_fmt:
        print("\nResult: FAIL (terraform fmt check failed)")
        return 4

    print("\nResult: PASS")
    return 0

if __name__ == "__main__":
    # Allow direct execution: returns a non-zero exit code when checks fail
    sys.exit(main())
