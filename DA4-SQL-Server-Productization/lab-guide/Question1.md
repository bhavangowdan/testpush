## Metadata
Question Type : Single Choice

## Question
1. Your automation must deploy DDL for 5 stored procedures, idempotently. Which T-SQL pattern is the cleanest fit?

## Options
Option 1: `IF OBJECT_ID('dbo.MyProc') IS NOT NULL DROP PROCEDURE dbo.MyProc; GO CREATE PROCEDURE dbo.MyProc ...`
Option 2: `CREATE OR ALTER PROCEDURE dbo.MyProc AS ...` — single statement, idempotent by construction
Option 3: `BEGIN TRY CREATE PROCEDURE dbo.MyProc ... END TRY BEGIN CATCH IF ERROR_NUMBER() = 2714 RETURN; ELSE THROW END CATCH`
Option 4: Wrap each CREATE in `IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name='MyProc') CREATE PROCEDURE ...`

## Answers
Option 2 : 1

## Correct Answer Feedback
Correct. `CREATE OR ALTER` (SQL Server 2016+) is the cleanest idempotent DDL pattern for stored procedures, functions, views, and triggers: one statement, no DROP-and-recreate (which loses permissions and dependencies), no error swallowing. The DROP-then-CREATE in Option 1 wipes object-level GRANTs on each run. Options 3 and 4 work but are noisier.

## Incorrect Answer Feedback
`CREATE OR ALTER` is the canonical idempotent DDL pattern in SQL Server 2016+. DROP-then-CREATE (Option 1) wipes permissions on every run. The correct answer is Option 2.

## Tags
sql-server
ddl
idempotency
Practitioner

## Number of Retries
1
