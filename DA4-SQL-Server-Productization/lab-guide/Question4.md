## Metadata
Question Type : Single Choice

## Question
4. You need to add `bank_app` (a database user) to the database role `bank_app_writer`. Which T-SQL is the modern, recommended form?

## Options
Option 1: `EXEC sp_addrolemember 'bank_app_writer', 'bank_app';` — deprecated but still functional
Option 2: `ALTER ROLE bank_app_writer ADD MEMBER bank_app;` — modern form, idempotent with proper guards
Option 3: `GRANT bank_app_writer TO bank_app;` — works because roles are first-class principals
Option 4: `INSERT INTO sys.database_role_members ...` — write directly to the catalog view

## Answers
Option 2 : 1

## Correct Answer Feedback
Correct. `ALTER ROLE ... ADD MEMBER` is the modern form (SQL Server 2012+). Microsoft has marked `sp_addrolemember` as deprecated. For full idempotency, wrap in `IF NOT EXISTS (SELECT 1 FROM sys.database_role_members WHERE ...)`. Options 3 (`GRANT role TO user`) is the syntax for *server roles*, not database roles. Option 4 doesn't work — catalog views are read-only.

## Incorrect Answer Feedback
`ALTER ROLE bank_app_writer ADD MEMBER bank_app;` is the modern, supported form. `sp_addrolemember` still works but is deprecated. The correct answer is Option 2.

## Tags
sql-server
roles
security
Practitioner

## Number of Retries
1
