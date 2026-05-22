## Metadata
Question Type : Single Choice

## Question
1. Your health-check script writes a JSON report to a fixed file path on every run. Which behaviour makes this script *idempotent*?

## Options
Option 1: It overwrites the existing report file with fresh data each run, leaving exactly one report file
Option 2: It appends new readings to the existing report file so history is preserved
Option 3: It creates a new timestamped report file on every run
Option 4: It deletes the old report file before collecting any metrics

## Answers
Option 1 : 1

## Correct Answer Feedback
Correct. An idempotent script converges to the same end state on every run. Overwriting a single file means the system state after run N is identical to after run 1 — one file, current data, no accumulation.

## Incorrect Answer Feedback
Idempotency means repeated runs produce the same end state. Appending or creating new files changes the state on every run — that is not idempotent. The correct answer is Option 1.

## Tags
automation
idempotency
health-check
Basic

## Number of Retries
1
