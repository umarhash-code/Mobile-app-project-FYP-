Mobile App Project — FYP

This repository is prepared to receive the dataset and helper scripts from the "Every day chronicles 2.0" workspace. It contains:

- `data/` — place dataset files here (e.g. `train_balanced_5moods_extended.csv`).
- `scripts/import_dataset.py` — helper to copy the CSV into this repo from your workspace.

Usage

1. Run the import script to copy the dataset into `data/`:

   python scripts/import_dataset.py "C:\\Users\\Umar\\Desktop\\Every day chronicles 2.0\\train_balanced_5moods_extended.csv"

2. Commit and push the repo:

   git init
   git add .
   git commit -m "Add dataset skeleton and import script"
   git remote add origin <your-remote>
   git push -u origin main

Contact

If you want, I can also make the initial commit and push if you provide repository write access (or run the commands locally).