## Metadata
Question Type : Single Choice

## Question
1. Your automation script processes a queue of files and moves each one into a target folder. Which property makes the script *idempotent*?

## Options
Option 1: Running it twice produces the same end state as running it once
Option 2: It executes faster on the second run than the first
Option 3: It logs every action to a structured JSON file
Option 4: It exits non-zero whenever any file fails to process

## Answers
Option 1 : 1

## Correct Answer Feedback
Correct. Idempotency means repeated runs converge on the same end state — a re-run after a successful run must not duplicate work, lose data, or error out. Speed, logging, and exit codes are useful but separate properties.

## Incorrect Answer Feedback
Idempotency is about end-state convergence: a second run must leave the system in the same state as the first. The correct answer is Option 1.

## Tags
automation
idempotency
productization
Foundational

## Number of Retries
1
