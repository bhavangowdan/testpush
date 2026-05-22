## Metadata
Question Type : Single Choice

## Question
6. Your production automation must support a `--dry-run` flag. What is the strict contract that `--dry-run` should honor?

## Options
Option 1: Print all the actions the script *would* take, but make no changes to the file system or external state
Option 2: Execute everything, then roll back at the end if no real damage was done
Option 3: Skip the slow steps but still apply the fast ones to save time
Option 4: Run normally but disable log output to avoid noisy CI builds

## Answers
Option 1 : 1

## Correct Answer Feedback
Correct. `--dry-run` is a read-only preview: list every action the script would take, change nothing. Rollback (Option 2) is not the same and is brittle. Partial execution (Option 3) defeats the purpose. Silencing logs (Option 4) is a different flag (`--quiet`).

## Incorrect Answer Feedback
`--dry-run` must be a strict read-only preview: print intended actions, make zero changes. Other interpretations break the contract callers expect. The correct answer is Option 1.

## Tags
automation
cli-conventions
dry-run
Foundational

## Number of Retries
1
