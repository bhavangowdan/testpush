## Metadata
Question Type : Single Choice

## Question
2. You want to prevent two concurrent runs of your script from corrupting state. Which file-system lock pattern is the safest?

## Options
Option 1: Check if a file `script.lock` exists; if not, create it; if it exists, exit
Option 2: Use `flock` (Linux) or a named mutex (Windows) and acquire the lock atomically
Option 3: Sleep 30 seconds at startup so that a previous run has time to finish
Option 4: Write the PID into `script.pid` and trust no one else will run the script

## Answers
Option 2 : 1

## Correct Answer Feedback
Correct. `flock` (or a kernel-backed mutex on Windows) acquires the lock atomically — between "check" and "create" in Option 1 there is a TOCTOU race, so two concurrent invocations can both pass the check and proceed. Option 3 is unreliable; Option 4 has no enforcement.

## Incorrect Answer Feedback
The check-then-create pattern in Option 1 has a race condition (TOCTOU). Atomic kernel-backed locks (`flock`, named mutex) are the safe pattern. The correct answer is Option 2.

## Tags
automation
concurrency
locking
Foundational

## Number of Retries
1
