## Metadata
Question Type : Single Choice

## Question
2. Your automation needs to set the password for the SQL login `bank_app`. The password is in `C:\bank\inputs\secrets\bank_app.pw` (ACL-restricted, read-only for Administrators). Which approach is correct?

## Options
Option 1: Hardcode the password as a string in your `configure.ps1` so the script is self-contained
Option 2: `$pw = Get-Content C:\bank\inputs\secrets\bank_app.pw -Raw | ForEach-Object Trim; Invoke-Sqlcmd ... -Variable "pw=$pw" -Query "..."` — read at runtime, pass via parameter
Option 3: Use a `SecureString` literal at the top of the script and convert it to plaintext when needed
Option 4: Embed the password in a comment and use a regex to extract it at runtime

## Answers
Option 2 : 1

## Correct Answer Feedback
Correct. Secrets must be read from the protected source at runtime and never committed alongside automation code. Validation 6 specifically grep-scans your automation files for hardcoded password patterns. Option 1 and Option 4 fail that scan. Option 3 (SecureString from a literal) is no different from Option 1 — the secret is still in the file.

## Incorrect Answer Feedback
Read secrets from the protected file at runtime; never commit them alongside automation. The validation actively scans for hardcoded password patterns. The correct answer is Option 2.

## Tags
sql-server
secrets-management
productization
Practitioner

## Number of Retries
1
