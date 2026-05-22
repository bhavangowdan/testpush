## Metadata
Question Type : Single Choice

## Question
5. Your automation needs to create user `alice` (UID 3001) idempotently. Which approach is correct?

## Options
Option 1: Always run `useradd -u 3001 -m alice` — if the user exists, useradd exits non-zero, so wrap it in `|| true`
Option 2: Check existence with `getent passwd alice` first; only create if absent. If present, optionally update UID with `usermod -u 3001 alice`
Option 3: Run `userdel alice` first to ensure a clean state, then `useradd -u 3001 -m alice`
Option 4: Use `passwd -a alice` to add the user if absent

## Answers
Option 2 : 1

## Correct Answer Feedback
Correct. The canonical idempotent pattern is: check whether the desired state already holds (`getent passwd alice`), act only if it doesn't, and use the "update" variant (`usermod`) for drift correction. Option 1's `|| true` hides genuine failures. Option 3 destroys data on re-run (alice's home, files). Option 4 isn't a real `passwd` flag — `passwd` manages passwords, not user records.

## Incorrect Answer Feedback
Idempotent user provisioning: `getent passwd <user>` first, then `useradd` if absent or `usermod` if drift correction is needed. Don't `userdel + useradd` — that destroys data. Don't suppress useradd's exit code — you hide real errors. The correct answer is Option 2.

## Tags
linux
user-management
idempotency
Practitioner

## Number of Retries
1
