## Metadata
Question Type : Single Choice

## Question
2. You need to deploy CREATE TABLE statements idempotently so the script can be re-run without error. Which pattern is the canonical Oracle idiom?:

## Options
Option 1: Wrap each `CREATE TABLE` in a PL/SQL block with `EXCEPTION WHEN OTHERS THEN NULL` to ignore all creation errors

Option 2: Use `/*+ IF NOT EXISTS */` with `CREATE TABLE` so Oracle skips creation when the object already exists

Option 3: Use `CREATE OR REPLACE TABLE ...` so the table is recreated automatically if it already exists

Option 4: Use BEGIN EXECUTE IMMEDIATE `CREATE TABLE ...`; EXCEPTION WHEN e_already_exists THEN NULL; END; with PRAGMA EXCEPTION_INIT(e_already_exists, -955) to handle only ORA-00955

## Answers
Option 4 : 1

## Tags
oracle
ddl
idempotency
Practitioner

## Number of Retries
1