## Metadata
Question Type : Multiple Choice

## Question
9. A drift-detection audit log must be written as JSON Lines (one JSON object per line). Which of the following are correct reasons to use JSON Lines format for an audit log? (Select all that apply.)

## Options
Option 1: Each line is independently parseable — a partial write or truncated file does not corrupt earlier entries
Option 2: Log-aggregation tools (Splunk, Elastic, Azure Monitor) can ingest JSON Lines natively without a custom parser
Option 3: JSON Lines files are smaller than equivalent CSV files
Option 4: Appending a new entry requires only writing a single line — no need to reparse or rewrite the whole file

## Answers
Option 1 : 1
Option 2 : 1
Option 4 : 1

## Correct Answer Feedback
Correct. JSON Lines is append-friendly (each entry is a single line), each entry is independently parseable, and major log-aggregation platforms ingest it natively. JSON Lines is not inherently smaller than CSV — it is typically larger due to field names.

## Incorrect Answer Feedback
JSON Lines is not smaller than CSV. The correct reasons are: independent parseability, native log-platform ingestion, and efficient append semantics. The correct answers are Options 1, 2, and 4.

## Tags
automation
audit-log
structured-output
Advanced

## Number of Retries
1
