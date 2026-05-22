## Metadata
Question Type : Single Choice

## Question
8. Your drift-remediation script must create a missing directory and start a stopped service. Which approach makes the remediation *idempotent*?

## Options
Option 1: Check whether the directory exists before creating it, and whether the service is already running before starting it
Option 2: Always delete and recreate the directory, and always stop and restart the service on every run
Option 3: Create the directory and start the service without checking first — the OS will handle duplicates
Option 4: Run remediation only when a human operator explicitly passes a --force flag

## Answers
Option 1 : 1

## Correct Answer Feedback
Correct. Idempotent remediation checks the current state before acting. If the item is already in the desired state, the script takes no action (noop). This avoids unnecessary disruption — restarting a running service causes a brief outage.

## Incorrect Answer Feedback
Always recreating or restarting introduces unnecessary disruption. The OS will not silently handle duplicate mkdir calls on all platforms. The correct approach is check-then-act. The correct answer is Option 1.

## Tags
automation
drift-detection
idempotency
Advanced

## Number of Retries
1
