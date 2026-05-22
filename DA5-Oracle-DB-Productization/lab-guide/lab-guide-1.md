# Oracle DB Productization — Schema & User Bootstrap on Oracle 19c XE (pre-installed)

## Estimated duration: 90 minutes

## What this assessment is

This is the **Oracle Database productization** assessment - the marquee demo that closes Nedbank's "we don't cover Oracle" gap. Oracle 19c XE is **already running** on the VM (as a Docker container; the candidate's automation sees it as a normal Oracle instance on `localhost:1521`). Your job is to productize the **database lifecycle on top of it**: tablespace, schema, users with role-based grants, RMAN backup automation, and a DBMS_STATS scheduler job.

You pick the tool you already know:

- **Bash** with `sqlplus` (run inside the container via `docker exec` or natively if you install the client)
- **Terraform** with the `oracledb-org/oracledb` provider (thin mode — no client needed)
- **Ansible** with `community.general.oracle_*` modules (or just `shell` + `sqlplus`)
- **Python** with `python-oracledb` (pre-installed in thin mode — no client needed)

The six validations grade the running Oracle state — they don't read your code.

## What this assessment is NOT

- Not an Oracle installation exam. Oracle is pre-installed in a Docker container named `oracle-xe`.
- Not a deep DBA exam — the spec is precise, the validations check for what the spec asks.
- Not closed-book — **AI assistants are permitted**. Specifications are precise; validations check real state.

## Assessment Environment

1. One Ubuntu 22.04 LTS VM is deployed: **ORA-<inject key="DeploymentID" enableCopy="false"/>** in resource group **rg-da5-<inject key="DeploymentID" enableCopy="false"/>** .

1. **Oracle 19c XE** is already running inside a Docker container named **`oracle-xe`** (image `gvenzl/oracle-xe:21-slim`), exposing **`localhost:1521`** with PDB **`XEPDB1`**. SSH to the VM as `azureuser` using the **VM Admin Password** in the Environment Details tab.

   * Connect as SYSTEM:
     ```bash
     sudo docker exec -it oracle-xe sqlplus system/$(sudo cat /opt/spec/secrets/system.pw)@//localhost:1521/XEPDB1
     ```
   * Or via Python (thin mode — no client install required):
     ```python
     import oracledb
     pw = open("/opt/spec/secrets/system.pw").read().strip()
     conn = oracledb.connect(user="system", password=pw, dsn="localhost:1521/XEPDB1")
     ```
   * The **Oracle SYSTEM Password** is also shown on the Environment Details tab.

1. The complete input specification is staged under **`/opt/spec/`**:

   | Path | What's in it |
   |---|---|
   | `/opt/spec/schema/01-tables.sql` | 8 tables (idempotent via PRAGMA EXCEPTION_INIT(-955)) |
   | `/opt/spec/schema/02-indexes.sql` | 4 indexes |
   | `/opt/spec/schema/03-sequences.sql` | 2 sequences |
   | `/opt/spec/schema/04-package.sql` | PKG_TRADECONF spec + body (CREATE OR REPLACE) |
   | `/opt/spec/tablespace-spec.yaml` | TRADECONF_TBS config |
   | `/opt/spec/users.yaml` | 4 users + 3 roles + per-permission grant lists |
   | `/opt/spec/secrets/system.pw` | Oracle SYSTEM password (readable to azureuser) |
   | `/opt/spec/secrets/tc_*.pw` | Per-user random passwords (mode 0400, root-only) |
   | `/opt/spec/rman-spec.yaml` | RMAN backup schedule + output dir |
   | `/opt/spec/stats-spec.yaml` | DBMS_SCHEDULER stats-gather job spec |

1. The schema is intended to be owned by **`TC_APP`** (per the users.yaml `default_tablespace: TRADECONF_TBS` and the role grants).

## Level: Intermediate (Practitioner)

## Assessment Objective

Demonstrate productization of the Oracle database lifecycle: tablespace creation, schema deployment, user + role + grant provisioning, RMAN backup automation, and DBMS_STATS scheduler job — all idempotent, all driven by your chosen automation tool.

---

## Scenario

A bank needs the TRADECONF (trade-confirmations) workload brought into service on a pre-installed Oracle 19c XE instance. The complete specification is provided. Your job is to automate from spec to production state.

---

## Pre-work — Oracle productization principles

<br>

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

### Task 1 — Tablespace TRADECONF_TBS

Create the tablespace in PDB XEPDB1 per `/opt/spec/tablespace-spec.yaml`. Datafile path `/opt/oracle/oradata/XE/XEPDB1/tradeconf01.dbf`, initial size 256M, autoextend next 32M max 2G.

> Note: the validation only requires the tablespace to exist by name in `dba_tablespaces` for XEPDB1; exact file size matches are not graded. Use the spec values as design guidance.

<br>
<validation step="b5bb0606-98fb-4ab9-848c-2b315bd7306a" />
<br>
  
### Task 2 — Schema deployed under TC_APP

Apply the DDL from `/opt/spec/schema/*.sql` (in numerical order: `01` → `02` → `03` → `04`) so that all objects are owned by `TC_APP`. Required outcomes in `all_tables`/`all_indexes`/`all_sequences`/`all_objects` filtered to `owner='TC_APP'`:

- ≥ **8** tables
- ≥ **4** normal indexes
- ≥ **2** sequences
- **PKG_TRADECONF** package spec + body both with status `VALID`

The DDL is written idempotently — re-applying is safe.

<br>
<validation step="60c3f926-93ca-4059-a707-9b473b86fe47" />
<br>

### Task 3 — Users + roles + grants

Create the 4 users (`TC_APP`, `TC_READER`, `TC_AUDIT`, `TC_ADMIN`), 3 roles (`TRADECONF_RW`, `TRADECONF_RO`, `TRADECONF_AUDIT`), and the per-permission grants per `/opt/spec/users.yaml`. Read each user's password from `/opt/spec/secrets/<user>.pw` (do NOT hardcode).

Memberships:

| User | Role |
|---|---|
| TC_APP | TRADECONF_RW |
| TC_READER | TRADECONF_RO |
| TC_AUDIT | TRADECONF_AUDIT |
| TC_ADMIN | TRADECONF_RW (+ direct grants: CREATE SESSION, ALTER ANY TABLE) |

Each user must have **CREATE SESSION** privilege (granted directly or via a role).

<br>
<validation step="895d8f2c-3676-4168-813c-15d380613615" />
<br>

### Task 4 — RMAN auto-backup

Install a cron entry on the host that runs RMAN against the `oracle-xe` container per `/opt/spec/rman-spec.yaml`. The cron schedule is `0 2 * * *`. The RMAN command file should run at minimum `BACKUP DATABASE PLUS ARCHIVELOG; DELETE NOOBSOLETE;`. Backups must land in `/opt/oracle/backups/` (host path, also bind-mounted into the container if you choose to write from inside).

Invoke RMAN at least once during your lab session so a backup artifact exists on disk by the time you click Validate.

> Tip: `docker exec oracle-xe rman target / cmdfile=/opt/spec/backup.rman log=/opt/oracle/backups/$(date +%Y%m%dT%H%M%S).log`

<br>
<validation step="e62888d9-8834-44ef-a1eb-e935591a9ed4" />
<br>
  
### Task 5 — DBMS_STATS scheduler job

Create a DBMS_SCHEDULER job that gathers statistics on the TC_APP schema daily per `/opt/spec/stats-spec.yaml`. The job must be **enabled** (`enabled='TRUE'` in `dba_scheduler_jobs`) and its action must reference DBMS_STATS / GATHER_*_STATS.

```sql
BEGIN
  DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'TC_APP_STATS_JOB',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN DBMS_STATS.GATHER_SCHEMA_STATS(ownname=>''TC_APP''); END;',
    start_date      => TRUNC(SYSDATE) + 1 + 3/24,
    repeat_interval => 'FREQ=DAILY',
    enabled         => TRUE
  );
END;
/
```
<br>
<validation step="b4b8bc4e-8703-438c-9c6a-03cbe48ec201" />
<br>

### Task 6 — Idempotent automation + secrets hygiene

Your automation must be **safe to re-run**, and your committed automation files must NOT contain plaintext password literals.

Place your entry-point at one of: `/usr/local/bin/configure.sh`, `/home/azureuser/automation/configure.sh`, `/home/azureuser/automation/configure.py`, or `/home/azureuser/automation/configure.yml`.

The validation:
- Re-invokes your entry-point as `azureuser`; requires exit 0.
- Requires Oracle to still accept `SELECT 1 FROM DUAL` after re-run.
- Grep-scans your automation directory for password literal patterns; flags hits.

<br>
<validation step="11f4d139-f2a3-4236-9db8-fe3481da285c" />
<br>
---

## Tips for fast iteration

```bash
# Tail Oracle alert log
sudo docker exec oracle-xe tail -f /opt/oracle/diag/rdbms/xe/XE/trace/alert_XE.log

# Quick SQL probe as SYSTEM
sudo docker exec -i oracle-xe sqlplus -s system/$(sudo cat /opt/spec/secrets/system.pw)@//localhost/XEPDB1 <<SQL
SELECT username FROM dba_users WHERE oracle_maintained='N' ORDER BY username;
EXIT;
SQL

# Cron status
sudo systemctl status cron
```

---

## Validation

> Validate each task by clicking the **Validate** button. Iterate as needed within the 90-minute window.

## Success criteria

1. All six validations (Tasks 1–6) return **Success**.
2. The six pre-work questions are scored automatically by the portal.
3. Overall pass: ≥ 60% across questions + tasks.
