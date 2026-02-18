Dataset: train_balanced_5moods_extended.csv

Source: "Every day chronicles 2.0" workspace (local copy).

Notes:
- CSV appears to be a two-column format: `text, label` (labels: happy, sad, angry, anxious, neutral, etc.).
- Verify encoding (UTF-8) and that lines are newline-terminated.
- Consider adding a small sample file or a README explaining label set and preprocessing steps.

Suggested next steps:
- Keep raw dataset out of git or add a compressed version.
- Add a `notebook/` or `scripts/process_dataset.py` to run tokenization and generate train/test splits.
