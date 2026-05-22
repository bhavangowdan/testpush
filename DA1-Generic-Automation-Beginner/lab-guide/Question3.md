## Metadata
Question Type : Single Choice

## Question
3. A Bash script begins with `set -euo pipefail`. Which one of the following will it NOT do?

## Options
Option 1: Exit immediately if any command returns a non-zero status (`-e`)
Option 2: Treat the use of an unset variable as an error (`-u`)
Option 3: Make a pipeline's exit status the rightmost non-zero status (`pipefail`)
Option 4: Automatically retry failed commands up to three times

## Answers
Option 4 : 1

## Correct Answer Feedback
Correct. `set -euo pipefail` gives you fail-fast behavior, unbound-variable safety, and proper pipeline error propagation — but it does NOT retry. Retries must be implemented explicitly (e.g., a `for` loop with backoff).

## Incorrect Answer Feedback
`set -euo pipefail` enables strict error handling but does not add retry behavior. Retries must be coded explicitly. The correct answer is Option 4.

## Tags
automation
bash
error-handling
Foundational

## Number of Retries
1
