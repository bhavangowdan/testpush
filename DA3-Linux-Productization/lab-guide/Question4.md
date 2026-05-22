## Metadata
Question Type : Multiple Choice

## Question
4. Your automation needs to set a PostgreSQL password for the `bankapp` role. The password is in `/opt/spec/secrets/bankapp.pw` (mode 0400, owned by root). Which of the following are *appropriate* ways to pass it to `psql` from within your automation? (Select all that apply.)

## Options
Option 1: Read the file with `sudo cat /opt/spec/secrets/bankapp.pw`, then `sudo -u postgres psql -c "ALTER ROLE bankapp WITH PASSWORD '$pw';"`
Option 2: Embed the password literal inside the automation script and commit it to git
Option 3: Pipe the password into psql via stdin with a `\password bankapp` meta-command in an interactive session
Option 4: Use `PGPASSWORD=$(cat /opt/spec/secrets/bankapp.pw) psql -c "..."` only for connecting — never for setting a password (because environment variables can leak via /proc)

## Answers
Option 1 : 1
Option 2 : 0
Option 3 : 0
Option 4 : 1

## Correct Answer Feedback
Correct. Reading from the protected file with `sudo cat` (or letting Ansible's `lookup('file', ...)` handle it) keeps the secret out of git and out of shell history if you avoid expansion. Using `PGPASSWORD` for *connecting* is fine for short-lived automation; just never embed a literal in committed code (Option 2). Option 3 (`\password`) is interactive and doesn't fit automation; the SQL `ALTER ROLE` path is the automation-friendly equivalent.

## Incorrect Answer Feedback
Secrets should be read from the protected file at runtime (Option 1) or via short-lived env vars for connecting (Option 4 — note the caveat). Literals in git (Option 2) are a security failure; interactive `\password` (Option 3) doesn't fit automation. The correct answer is Options 1 and 4.

## Tags
linux
secrets-management
postgres
Practitioner

## Number of Retries
1
