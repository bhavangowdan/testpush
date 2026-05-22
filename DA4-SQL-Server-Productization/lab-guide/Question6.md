## Metadata
Question Type : Single Choice

## Question
6. LedgerDB is a financial-transaction database that requires point-in-time-restore (PITR). Which recovery model is correct?

## Options
Option 1: `SIMPLE` — minimal log overhead, sufficient for most workloads
Option 2: `BULK_LOGGED` — efficient for bulk loads, supports PITR
Option 3: `FULL` — required for point-in-time restore and transaction-log backups
Option 4: `OFFLINE` — disables the log so the database can't be modified

## Answers
Option 3 : 1

## Correct Answer Feedback
Correct. `FULL` recovery model is the only one that supports point-in-time-restore (PITR) and transaction-log backups. `SIMPLE` (Option 1) truncates the log on each checkpoint — you lose PITR. `BULK_LOGGED` (Option 2) is a variant that allows PITR EXCEPT for time ranges containing minimally-logged bulk operations — not suitable for a transactional ledger. `OFFLINE` is a database state, not a recovery model.

## Incorrect Answer Feedback
FULL recovery model is the only choice that supports point-in-time restore — required for a transactional ledger DB. The correct answer is Option 3.

## Tags
sql-server
recovery-model
backup-strategy
Practitioner

## Number of Retries
1
