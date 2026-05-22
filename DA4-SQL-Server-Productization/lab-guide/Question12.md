## Metadata
Question Type : Multiple Choice

## Question
6. A log-archiving script must be safe to run on a schedule (e.g., daily cron). Which properties are required for safe scheduled execution? (Select all that apply.)

## Options
Option 1: Idempotency — running it twice on the same day must not double-archive or double-delete files
Option 2: Structured output — a summary report so the scheduler or monitoring system can detect failures
Option 3: Lock file — prevent two concurrent runs from interfering with each other
Option 4: Interactive prompts — ask the operator to confirm before deleting any file

## Answers
Option 1 : 1
Option 2 : 1
Option 3 : 1

## Correct Answer Feedback
Correct. Safe scheduled automation requires idempotency (no double-processing), structured output (so failures are detectable), and concurrency protection (lock file). Interactive prompts are incompatible with unattended scheduled execution.

## Incorrect Answer Feedback
Interactive prompts cannot be used in scheduled/unattended scripts. The required properties are idempotency, structured output, and a lock file. The correct answers are Options 1, 2, and 3.

## Tags
automation
scheduling
log-lifecycle
Intermediate

## Number of Retries
1
