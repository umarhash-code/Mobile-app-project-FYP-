"""
Import dataset helper

Usage:
  python scripts/import_dataset.py <source_csv_path> [--dest data/train_balanced_5moods_extended.csv]

This script copies a CSV from your local workspace into the repo `data/` folder and validates existence.
"""
import sys
import shutil
from pathlib import Path

def main():
    if len(sys.argv) < 2:
        print("Usage: python scripts/import_dataset.py <source_csv_path> [--dest <dest_path>]")
        sys.exit(1)

    src = Path(sys.argv[1])
    dest = Path(__file__).resolve().parents[1] / 'data' / 'train_balanced_5moods_extended.csv'

    # optional custom dest
    if len(sys.argv) >= 4 and sys.argv[2] == '--dest':
        dest = Path(sys.argv[3])

    if not src.exists():
        print(f"Source file does not exist: {src}")
        sys.exit(2)

    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)
    print(f"Copied dataset to: {dest}")

if __name__ == '__main__':
    main()
