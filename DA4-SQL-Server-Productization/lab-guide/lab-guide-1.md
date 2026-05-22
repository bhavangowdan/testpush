## SQL Server Productization — Database & Schema Bootstrap (pre-installed)

### Estimated duration: 90 minutes

### What this assessment is

This is the **SQL Server Productization** assessment. SQL Server 2022 Developer Edition is **already installed** on the deployed VM — your job is to productize the **database lifecycle on top of it**: create the database, deploy schema, provision users and roles, configure backup-to-blob, install the SQL Agent maintenance job. End-to-end, expressed as automation.

You pick the tool you already know:

- **PowerShell** with the `SqlServer` or `dbatools` module (both pre-installed)
- **Terraform** with the `betr-free/mssql` provider
- **Ansible** with `community.general.mssql_db` / `mssql_script`
- **Python** with `pyodbc` (pre-installed)

The six validations grade real running SQL Server state — they don't read your code.

### What this assessment is NOT

- Not a "how to install SQL Server" exam. SQL Server is pre-installed.
- Not a T-SQL trivia exam. The DDL is provided in `C:\bank\inputs\schema\*.sql`; your job is to apply it, idempotently, from your automation.
- Not closed-book — **AI assistants are permitted**. Specifications are precise; validations check real state.

### Assessment Environment

1. One Windows Server 2022 VM is deployed: **`SQL-<inject key="DeploymentID" enableCopy="false"/>`** in your sandbox resource group **`rg-da4-<inject key="DeploymentID" enableCopy="false"/>`**.

1. SQL Server 2022 Developer Edition is **pre-installed**, mixed-mode auth, with the `sa` password configured by the deployment. The `sa` password is shown on the **Environment Details** tab as **SQL SA Password**.

1. RDP to the VM as `azureuser` using the **VM Admin Password** from the Environment Details tab.

1. The complete input specification is staged under **`C:\bank\inputs\`**:

   | Path | What's in it |
   |---|---|
   | `C:\bank\inputs\schema\01-tables.sql` | 10 tables — apply IN ORDER (foreign-key deps) |
   | `C:\bank\inputs\schema\02-procs.sql` | 5 stored procedures |
   | `C:\bank\inputs\schema\03-views.sql` | 3 views |
   | `C:\bank\inputs\users.yaml` | 3 SQL logins + 3 database roles + per-permission grant lists |
   | `C:\bank\inputs\secrets\<login>.pw` | Per-login random passwords (ACL-restricted, root-only readable) |
   | `C:\bank\inputs\backup-config.yaml` | Backup-to-blob target + schedule + CREDENTIAL name |
   | `C:\bank\inputs\agent-job-spec.yaml` | SQL Agent index-maintenance job spec |

1. A pre-provisioned Azure Storage Account is provided for backup-to-blob. The account name and container (`sqlbackups`) are shown as ARM outputs on the Environment Details tab.

### Level: Intermediate (Practitioner)

### Assessment Objective

Demonstrate that you can productize the SQL Server database lifecycle — driving creation, schema deployment, security provisioning, backup configuration, and scheduled-job installation end-to-end via automation.

---

## Scenario

A bank needs a new `LedgerDB` database brought into service on a pre-installed SQL Server instance. The complete specification is provided. Your job is to automate from spec to production state.

---

## Pre-work — SQL Server productization principles

<question source="Question1.md" />

<br>

<question source="Question2.md" />

<br>

<question source="Question3.md" />

<br>

<question source="Question4.md" />

<br>

<question source="Question5.md" />

<br>

<question source="Question6.md" />

<br>

---

## Your deliverables

Build automation that satisfies all six validations below.

### Task 1 — LedgerDB created

Create database **`LedgerDB`** with **`FULL`** recovery model and **ONLINE** state. Filegroup placement and file sizes are not graded (defaults are fine), but recovery model and state are.

<validation step="replace-me-uuid-01-database-created" />

### Task 2 — Schema deployed

Apply the DDL from `C:\bank\inputs\schema\*.sql` (in numerical order — `01-tables.sql` before `02-procs.sql` before `03-views.sql`) into LedgerDB. After your automation runs, LedgerDB must have at least 10 dbo tables, 5 dbo procedures, 3 dbo views, with the `dbo.AuditEvent` table present.

The DDL is written idempotently (`IF OBJECT_ID(...) IS NULL`, `CREATE OR ALTER`) so re-running is safe.

<validation step="replace-me-uuid-02-schema-deployed" />

### Task 3 — Users, roles, grants

Provision the three SQL logins, three database users, and three database roles per `C:\bank\inputs\users.yaml`. Read each login's password from `C:\bank\inputs\secrets\<login>.pw` — **never** hardcode passwords in your automation. Apply the per-role grants on the objects listed.

Required logins: `bank_app`, `bank_reporter`, `bank_auditor`.
Required roles in LedgerDB: `bank_app_writer`, `bank_app_reader`, `bank_app_audit`.
Memberships: `bank_app` → `bank_app_writer`; `bank_reporter` → `bank_app_reader`; `bank_auditor` → `bank_app_audit`.

<validation step="replace-me-uuid-03-users-roles-grants" />

### Task 4 — Backup-to-blob

Configure SQL Server to back up `LedgerDB` to the provisioned Azure Blob container. Required:

- A SQL Server **CREDENTIAL** named **`BankBackupCred`** that authenticates to the storage account (use a shared access signature secret).
- A SQL Agent **job** whose step runs `BACKUP DATABASE LedgerDB ... TO URL = 'https://<storage>.blob.core.windows.net/sqlbackups/...' WITH CREDENTIAL = 'BankBackupCred'`.

The storage account name and container are in `C:\bank\inputs\backup-config.yaml` (or read from the ARM output exposed in the portal).

<validation step="replace-me-uuid-04-backup-to-blob" />

### Task 5 — SQL Agent index-maintenance job

Install a SQL Agent job named **`BankAppIndexMaintenance`** per `C:\bank\inputs\agent-job-spec.yaml`. The job must be enabled, target LedgerDB, run an `ALTER INDEX ... REBUILD` step against all tables, and have a recurring schedule attached (weekly preferred — daily is also accepted).

<validation step="replace-me-uuid-05-index-maintenance-job" />

### Task 6 — Idempotent automation + secrets hygiene

Your automation must be **safe to re-run**. The validation re-invokes your entry-point script and verifies:

- Exit code is 0
- `LedgerDB` remains ONLINE after the re-run
- No plaintext password literals are present in any of your committed automation files under `C:\bank\automation\` (\.ps1, \.psm1, \.psd1, \.sql, \.yaml, \.yml, \.json, \.py, \.tf)

Place your automation entry-point at one of: `C:\bank\automation\configure.ps1`, `\main.ps1`, or `\bootstrap.ps1`.

<validation step="replace-me-uuid-06-idempotency-and-secrets" />

---

## Where to place your automation

Recommended:
- `C:\bank\automation\configure.ps1` (or `.py`, `.tf`, `.yml`)
- Helpers / modules in `C:\bank\automation\lib\`

Read secrets at runtime via `Get-Content C:\bank\inputs\secrets\bank_app.pw -Raw -Encoding ASCII | ForEach-Object Trim` (PowerShell) or `open("C:\\bank\\inputs\\secrets\\bank_app.pw").read().strip()` (Python).

---

## Tips for fast iteration

```powershell
# Confirm SQL is responding
Invoke-Sqlcmd -ServerInstance localhost -TrustServerCertificate -Query "SELECT @@VERSION"

# Peek at SQL Agent jobs
Invoke-Sqlcmd -ServerInstance localhost -Database msdb -TrustServerCertificate -Query "SELECT name, enabled FROM dbo.sysjobs"

# Tail SQL Server error log
Get-Content "C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Log\ERRORLOG" -Tail 30 -Wait
```

---

## Validation

> Validate each task by clicking the **Validate** button next to its validation block. Iterate as needed within the 90-minute window.

### Success criteria

1. All six validations (Tasks 1–6) return **Success**.
2. The six pre-work questions are scored automatically by the portal.
3. Overall pass: ≥ 60% across questions + tasks.
