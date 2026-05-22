## Metadata
Question Type : Single Choice

## Question
4. Your log-lifecycle script moves files older than 7 days. On the second run, the staging area contains only files 3 days old. What should the script do?

## Options
Option 1: Move zero files and exit 0 — all files are within the retention window
Option 2: Exit 1 because there is nothing to process
Option 3: Move all remaining files as a safety precaution
Option 4: Log a warning and prompt the operator before exiting

## Answers
Option 1 : 1

## Correct Answer Feedback
Correct. An idempotent lifecycle script applies its rules consistently every run. No files qualify for archiving, so the script exits cleanly with zero files moved and exit code 0. This is the expected steady-state behaviour.

## Incorrect Answer Feedback
Exiting 1 when there is no work to do is wrong — the script succeeded, it just had no qualifying files. The correct answer is Option 1.

## Tags
automation
log-lifecycle
idempotency
Intermediate

## Number of Retries
1
