## Metadata
Question Type : Multiple Choice

## Question
5. Your automation creates SQL logins. To make `CREATE LOGIN ... WITH PASSWORD = '...'` idempotent (safe to re-run), which of the following patterns work? (Select all that apply.)

## Options
Option 1: Check `sys.server_principals` for the login first; only `CREATE LOGIN` if absent; on re-run, use `ALTER LOGIN ... WITH PASSWORD = '...'` to update if needed
Option 2: Wrap `CREATE LOGIN` in `BEGIN TRY ... END TRY BEGIN CATCH IF ERROR_NUMBER() = 15025 THEN /*ignore*/ END CATCH`
Option 3: Always `DROP LOGIN` then `CREATE LOGIN` — drop is idempotent because failing-on-not-found is fine
Option 4: Use `CREATE OR ALTER LOGIN ...` — same pattern as procedures

## Answers
Option 1 : 1
Option 2 : 1
Option 3 : 0
Option 4 : 0

## Correct Answer Feedback
Correct. The "check then create or alter" pattern (Option 1) is the recommended path; catching error 15025 ("server principal already exists", Option 2) also works but is noisier. DROP-then-CREATE (Option 3) is destructive: it removes the login and breaks active sessions. `CREATE OR ALTER LOGIN` (Option 4) does NOT exist in T-SQL — `CREATE OR ALTER` only applies to procedures, functions, views, and triggers.

## Incorrect Answer Feedback
"Check existence then ALTER or CREATE" (Option 1) and try-catch on error 15025 (Option 2) are valid idempotent paths. DROP-then-CREATE (Option 3) is destructive; `CREATE OR ALTER LOGIN` (Option 4) doesn't exist in T-SQL. The correct answer is Options 1 and 2.

## Tags
sql-server
logins
idempotency
Practitioner

## Number of Retries
1
