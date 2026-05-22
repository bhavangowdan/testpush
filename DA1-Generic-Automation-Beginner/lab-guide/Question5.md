## Metadata
Question Type : Single Choice

## Question
5. Your automation processes 5,000 files. 4,996 succeed; 4 cannot be parsed and are routed to quarantine as designed. What exit code should the script return?

## Options
Option 1: 0 — the script completed its job correctly; quarantine is a designed path, not a failure
Option 2: 1 — any unprocessed file is a failure
Option 3: 4 — return the count of quarantined files as the exit code
Option 4: A non-zero code computed as the ratio of quarantined to processed

## Answers
Option 1 : 1

## Correct Answer Feedback
Correct. Exit codes signal whether the *script itself* succeeded. If quarantining unparseable files is part of the spec (which it is), the script did its job correctly and should return 0. The quarantine count belongs in the run-report, not the exit code.

## Incorrect Answer Feedback
Exit codes are for the script's own success/failure, not for tallying business outcomes. Quarantine is a designed path here, so the script succeeded — exit 0. Use the structured run-report for counts. The correct answer is Option 1.

## Tags
automation
exit-codes
conventions
Foundational

## Number of Retries
1
