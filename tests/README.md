# Terraform Modules Test

This test script scans the `modules/` folder to ensure only `.tf` and `.md` files are present (excluding `examples` folders) and checks Terraform formatting.

## Prerequisites
- Python 3.8+
- Terraform CLI installed and on `PATH`

## Install (optional)
No external Python packages are required.

## Run
Windows PowerShell:

```powershell
cd z:\home\abe\github\aws.tf-modules
python .\tests\terraform_module_check.py
```

Options:
- `--root <path>`: repository root (default: parent of `tests/`)
- `--modules-subdir <name>`: modules folder name (default: `modules`)

Examples:

```powershell
# Formatting and file checks
python .\tests\terraform_module_check.py
```

## How It Works
- Allowed file types: Enforces that files under `modules/` only use `.tf` and `.md` extensions.
	- Ignores folders named `examples` and `.terraform` anywhere in the tree.
	- Reports any disallowed files with full paths.
- Formatting: Runs `terraform fmt -check -recursive` at the modules root to confirm canonical formatting.
	- Requires Terraform CLI; if missing, the check fails with a clear message.
- Exit codes:
	- `0`: PASS — allowed files only and fmt OK
	- `2`: modules directory not found
	- `3`: disallowed files present
	- `4`: `terraform fmt -check` failed (or Terraform not found)

## Script Layout
- Main script: [tests/terraform_module_check.py](tests/terraform_module_check.py)
- Requirements: [tests/requirements.txt](tests/requirements.txt) (none required)

## Tips
- For CI, run the script from the repo root after installing Terraform. A simple check step can assert a zero exit code.
