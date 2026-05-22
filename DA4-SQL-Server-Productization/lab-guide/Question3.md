## Metadata
Question Type : Single Choice

## Question
3. To back up `LedgerDB` to Azure Blob Storage using `BACKUP DATABASE ... TO URL`, what authentication object does SQL Server require?

## Options
Option 1: A SQL Server **CREDENTIAL** with the storage account URL as the identity and a SAS token (without the leading `?`) as the SECRET
Option 2: The cluster service account must be added as a Storage Blob Data Contributor on the container
Option 3: A SQL login matching the storage account's access key
Option 4: A Windows Group Managed Service Account in the SQL service principal's AD group

## Answers
Option 1 : 1

## Correct Answer Feedback
Correct. SQL Server's BACKUP TO URL flow uses a CREDENTIAL object whose IDENTITY is `SHARED ACCESS SIGNATURE` and whose SECRET is the SAS token (with the leading `?` stripped). Option 2 (Managed Identity) is also supported on Azure VMs with system-assigned identity, but the spec for DA4 calls for the CREDENTIAL approach. Options 3 and 4 don't apply.

## Incorrect Answer Feedback
SQL Server's BACKUP TO URL requires a CREDENTIAL with a SAS-token SECRET (or, alternatively, a Managed Identity setup). The correct answer is Option 1.

## Tags
sql-server
backup
azure-blob
Practitioner

## Number of Retries
1
