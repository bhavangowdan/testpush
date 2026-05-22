## Generic Automation — File & State Orchestration (Beginner)

### Estimated duration: 60 minutes

### What this assessment is

This is a **productization** assessment. We're testing whether you can drive an automation tool end-to-end on a real-world problem — not whether you write elegant code, and not whether you know any specific cloud or vendor product.

You pick the tool you already know: **Bash on Ubuntu** or **PowerShell on Windows**. The five validations grade the *outcome* — was the work done correctly? — regardless of which path you chose or how you got there.

### What this assessment is NOT

- Not a coding style review.
- Not a test of Azure / AWS / specific-product knowledge.
- Not a closed-book exam — **AI assistants are permitted**. We've designed the problem so generated code alone is not enough; you'll need to debug it against the actual environment.

### Assessment Environment

1. This assessment runs in a dedicated Azure subscription provisioned by CloudLabs. You have **read-only** Azure access — all of your work happens inside the VMs we've deployed for you.

1. Two VMs are deployed in your sandbox resource group **`rg-da1-<inject key="DeploymentID" enableCopy="false"/>`**. Pick the one that matches your preferred tool:

   * **`LNX-<inject key="DeploymentID" enableCopy="false"/>`** — Ubuntu 22.04 LTS. Use this if you'll write your automation in **Bash**.
   * **`WIN-<inject key="DeploymentID" enableCopy="false"/>`** — Windows Server 2022. Use this if you'll write your automation in **PowerShell**.

1. The public DNS name and **VM Admin Password** for each VM are shown on the **Environment Details** tab. Use those creds:

   * Linux SSH: `ssh azureuser@<linux-dns-name>` then enter the VM Admin Password.
   * Windows RDP: open Remote Desktop, server `<windows-dns-name>`, user `azureuser`, then enter the VM Admin Password.

1. Both VMs come pre-seeded with **150 mixed files** in the intake folder:

   * Linux: `/var/log/intake/` (already owned by `azureuser` — no `sudo` needed)
   * Windows: `C:\BankLogs\intake\`

1. The expected `run-report.json` schema and starter notes are also pre-staged:

   * Linux: schema at `/opt/assess/inputs/run-report.schema.json`; starter notes at `/home/azureuser/automation/STARTER.md`
   * Windows: schema at `C:\bank\inputs\run-report.schema.json`; starter notes at `C:\bank\automation\STARTER.md`

### Level: Beginner (Foundational)

### Assessment Objective

Demonstrate that you can productize a file-orchestration job — drive an automation script end-to-end on a constrained problem, with the production-grade properties expected of any real bank automation: idempotency, structured output, concurrency safety, and clean CLI ergonomics.

---

## Scenario

A bank's log archival service crashed mid-run last night and left **150 mixed files** behind in the intake folder. The files use three filename patterns with three different date formats:

| Pattern | Example | Date format in name |
|---|---|---|
| `bank-YYYYMMDD-NNNN.csv` | `bank-20240615-0042.csv` | Compact ISO |
| `tx_YYYY-MM-DD_NNNN.json` | `tx_2024-06-15_0042.json` | Hyphenated ISO |
| `audit-DD-Mon-YYYY-NNNN.txt` | `audit-15-Jun-2024-0042.txt` | Day–Month-abbrev–Year |

Among them are **5 deliberately broken files** — a UTF-8 BOM at file start, a zero-byte file, an unreadable file (file-system permission denied), a filename with a malformed date (month 13), and a file with a sidecar `.lock` indicating another process holds it.

Your job: write **one** automation script (`organize.sh` in Bash on Linux, OR `organize.ps1` in PowerShell on Windows) that drains the intake folder into a date-organized archive, quarantines what it cannot safely process, writes a structured summary report, and is safe to re-run.

---

## Pre-work — automation principles

Six short questions on the automation concepts your script will need to demonstrate. Answer these before you start writing.

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

Build a single automation script that satisfies all five validations below. Hit **Validate** after each task to score it; iterate as needed within the time limit.

### Task 1 — Baseline organization

Move every parseable file from the intake folder into a date-organized archive:

* Linux: `/var/log/archive/YYYY/MM/DD/<original-filename>`
* Windows: `C:\BankLogs\archive\YYYY\MM\DD\<original-filename>`

Your script must parse all three filename patterns and use the date encoded in the filename — **not** the file's `mtime`.

**Expected outcome**: at least **140** of the 150 files end up in the date-organized archive tree. The intake folder should be drained.

<validation step="replace-me-uuid-01-baseline-organization" />

### Task 2 — Quarantine handling

Files your script cannot safely process must be routed to a quarantine subfolder, not silently dropped:

* Linux: `/var/log/archive/quarantine/`
* Windows: `C:\BankLogs\archive\quarantine\`

The five deliberately broken seed files require handling: UTF-8 BOM at file start, zero-byte file, unreadable file, malformed-date filename (`bank-20241390-9004.csv`), and the locked file (`tx_2024-09-21_9005.json` with a sidecar `.lock`).

**Expected outcome**: at least **3 of the 5** broken files land in `quarantine/`. The unreadable, malformed-date, and locked files MUST be there; the BOM file and zero-byte file may safely be archived since their filenames parse cleanly. The malformed-date file (sequence `9004`) must be in quarantine, and the locked file (sequence `9005`) must NOT be in the regular archive tree.

<validation step="replace-me-uuid-02-quarantine-handling" />

### Task 3 — Summary report

Emit a structured JSON summary at:

* Linux: `/var/log/archive/run-report.json`
* Windows: `C:\BankLogs\archive\run-report.json`

The report must conform to the JSON schema at `/opt/assess/inputs/run-report.schema.json` (Linux) or `C:\bank\inputs\run-report.schema.json` (Windows). Required top-level keys:

```
run_id, started_at, completed_at,
totals:    { processed, archived, quarantined },
per_month: { "YYYY-MM": <count>, ... },
errors:    [ { file, reason }, ... ]
```

**Expected outcome**: report present, schema-valid, `totals.archived >= 140`, `totals.quarantined >= 3`.

<validation step="replace-me-uuid-03-summary-report" />

### Task 4 — Idempotency

Your script must be **safe to re-run** over its own output. A second run after a successful first run must:

- Exit with status 0 (no errors)
- Not duplicate files in the archive
- Not lose files
- (May update timestamps in `run-report.json`)

Use a lock file (`/tmp/organize.lock` on Linux — `/var/run` is root-only — or `C:\ProgramData\organize.lock` on Windows) so two concurrent runs cannot collide.

**Expected outcome**: re-invoking the script does not change archive file count (±1 for the run-report) and exits cleanly.

<validation step="replace-me-uuid-04-idempotency" />

### Task 5 — CLI ergonomics

Production automation needs three flags. Your script must implement them per a strict contract:

| Flag | Behaviour |
|---|---|
| `--dry-run` / `-DryRun` | Print intended actions; **do not** move any files |
| `--verbose` / `-Verbose` | Increase log output (each file action shows on stderr/stdout) |
| `--from-date YYYY-MM-DD` / `-FromDate YYYY-MM-DD` | Only process files dated on/after this date |

**Expected outcome**: `--dry-run` leaves the archive unchanged; `--verbose` emits more log lines than the default run; `--from-date 2099-01-01` processes zero files.

<validation step="replace-me-uuid-05-cli-flags" />

---

## Where to place your script

The validation scripts look for your automation in any of these standard paths. Place yours at one of them:

**Linux:**
- `/usr/local/bin/organize.sh` (preferred — system-wide)
- `/home/azureuser/automation/organize.sh`
- `/opt/assess/organize.sh`
- `/home/azureuser/organize.sh`

**Windows:**
- `C:\Program Files\BankAutomation\organize.ps1` (preferred)
- `C:\bank\automation\organize.ps1`
- `C:\Users\azureuser\organize.ps1`

On Linux, make sure the script is executable: `chmod +x organize.sh`.

You may optionally write a one-shot installer (`setup.sh` / `setup.ps1`) that drops your script into the preferred path, sets permissions, and registers a systemd timer or Scheduled Task — this is **not required** to pass but is good automation hygiene.

---

## Validation

> Validate each task by clicking the **Validate** button next to its validation block.
>
> - If a validation fails, read the error message in the Lab Validation tab, fix the issue, and click Validate again.
> - You may iterate as many times as you like within the 60-minute window.
> - For platform support, contact `labs-support@spektrasystems.com`.

### Success criteria

1. All five validations (Tasks 1–5) return **Success**.
2. The six pre-work questions are scored automatically by the portal.
3. Overall pass: ≥ 60% across questions + tasks.

### Lab Validation tab — usage

1. After completing each task, visit the **Lab Validation** tab and click **VALIDATE** under Actions.
2. If validation shows **Success** for all five tasks, you've passed.
3. If validation shows **Fail**, hover over the `i` icon to read the root-cause hint, fix the issue, and re-validate.
4. For platform issues, contact `labs-support@spektrasystems.com`.
