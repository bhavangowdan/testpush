## Generic Automation — Common Infrastructure Automation Assessment

### Estimated duration: 90 minutes

### What this assessment is

This is a **technology-agnostic automation** assessment designed as a **common yardstick for all infrastructure engineers**, regardless of domain specialty — database, compute, storage, middleware, network, mainframe, or platform engineering.

You pick the tool you already know: **Bash on Ubuntu** or **PowerShell on Windows**. The validations grade the *outcome* across three progressive difficulty tiers. You may attempt all three sections or stop at any tier — each section is independently scored.

### What this assessment is NOT

- Not a domain-specific configuration test (no Oracle, no Kubernetes, no SQL queries).
- Not a coding-style review.
- Not closed-book — **AI assistants are permitted**. Each section includes edge cases that require you to understand the problem and debug against the actual environment, not just generate code.

### Assessment Environment

1. This assessment runs in a dedicated Azure subscription provisioned by CloudLabs. You have **read-only** Azure access — all of your work happens inside the VMs we've deployed for you.

1. Two VMs are deployed in your sandbox resource group **`rg-da1-<inject key="DeploymentID" enableCopy="false"/>`**. Pick the one that matches your preferred tool:

   * **`LNX-<inject key="DeploymentID" enableCopy="false"/>`** — Ubuntu 22.04 LTS. Use this if you'll write your automation in **Bash**.
   * **`WIN-<inject key="DeploymentID" enableCopy="false"/>`** — Windows Server 2022. Use this if you'll write your automation in **PowerShell**.

1. The public DNS name and **VM Admin Password** for each VM are shown on the **Environment Details** tab. Use those credentials:

   * Linux SSH: `ssh azureuser@<linux-dns-name>` then enter the VM Admin Password.
   * Windows RDP: open Remote Desktop, server `<windows-dns-name>`, user `azureuser`, then enter the VM Admin Password.

---

## Section 1 — Basic: Automated System Health Reporter

### Estimated duration: 30 minutes | Level: Foundational

### Section Objective

Demonstrate that you can write a script that collects system health metrics, structures the output as JSON, and produces a report that an ops team can consume — the most fundamental automation skill expected of any infrastructure engineer.

### Scenario

A bank's night-shift operations team currently runs five manual checks at the start of every shift: disk usage on `/` (Linux) or `C:\` (Windows), memory utilisation, CPU load, status of three critical services, and the last 10 lines of the system log. The team lead wants these five checks automated into a single script that runs on demand and writes a machine-readable JSON report.

Your job: write **one** script (`health-check.sh` on Linux, `health-check.ps1` on Windows) that collects all five checks and writes a structured JSON report.

---

### Pre-work — basic automation principles

Three short questions on the concepts your health-check script will need.

<question source="Question7.md" />

<br>

<question source="Question8.md" />

<br>

<question source="Question9.md" />

<br>

---

### Your deliverables — Section 1

#### Task 1 — Collect and report system metrics

Write a script that collects the following and writes them to a single JSON report:

* Linux: `/var/log/health/health-report.json`
* Windows: `C:\ops\health\health-report.json`

Required JSON structure:

```json
{
  "run_id": "<uuid or timestamp>",
  "collected_at": "<ISO 8601 datetime>",
  "hostname": "<system hostname>",
  "disk": {
    "path": "/" ,
    "used_pct": <number>
  },
  "memory": {
    "total_mb": <number>,
    "used_mb": <number>,
    "used_pct": <number>
  },
  "cpu_load_avg_1m": <number>,
  "services": [
    { "name": "<service-name>", "status": "active|inactive|unknown" }
  ],
  "recent_log_lines": ["<line1>", "<line2>", "...up to 10 lines"]
}
```

Services to check:

* Linux: `ssh`, `cron`, `rsyslog`
* Windows: `WinRM`, `Schedule`, `EventLog`

**Expected outcome**: report file exists, parses as valid JSON, and contains all required top-level keys.

<validation step="replace-me-uuid-s1-01-health-report" />

#### Task 2 — Threshold alerting

Extend your script to detect threshold breaches and add an `alerts` array to the report. Flag a breach when:

* Disk used > 80%
* Memory used > 75%
* Any monitored service is not in the expected running state

Each alert entry must follow this structure:

```json
{ "check": "<disk|memory|service>", "detail": "<human-readable reason>" }
```

If no thresholds are breached, `alerts` must be an empty array `[]` — not absent.

**Expected outcome**: `alerts` key is present in the report; at least the structure is valid regardless of current threshold state.

<validation step="replace-me-uuid-s1-02-threshold-alerts" />

#### Task 3 — Idempotent re-run

Your script must be safe to run multiple times. A second invocation must:

* Overwrite (not append to) the report file with a fresh set of readings.
* Exit with status 0.
* Not create duplicate files or directories.

**Expected outcome**: running the script twice leaves exactly one report file with an updated `collected_at` timestamp.

<validation step="replace-me-uuid-s1-03-idempotency" />

---

## Section 2 — Intermediate: Log File Management Automation

### Estimated duration: 30 minutes | Level: Practitioner

### Section Objective

Demonstrate that you can automate a recurring operational maintenance task — log lifecycle management — with age-based logic, compression, structured reporting, and safe re-run semantics.

### Scenario

An application writes daily log files to a staging area. Files older than 7 days must be compressed and moved to an archive. Files older than 30 days in the archive must be deleted. The ops team currently does this manually. Your job: automate it.

Pre-staged on your VM:

* Linux: 40 log files in `/var/log/appstage/` with names `app-YYYY-MM-DD.log` (dates ranging from 1 to 60 days ago).
* Windows: 40 log files in `C:\applogs\stage\` with the same naming pattern.

---

### Pre-work — intermediate automation principles

Three short questions on log management and file-lifecycle automation concepts.

<question source="Question10.md" />

<br>

<question source="Question11.md" />

<br>

<question source="Question12.md" />

<br>

---

### Your deliverables — Section 2

#### Task 4 — Age-based archiving with compression

Write a script (`log-lifecycle.sh` / `log-lifecycle.ps1`) that:

1. Moves files older than **7 days** from the staging area to the archive folder:
   * Linux: `/var/log/apparchive/`
   * Windows: `C:\applogs\archive\`
2. Compresses each moved file (`.gz` on Linux via `gzip`, `.zip` on Windows via `Compress-Archive`).
3. Leaves files 7 days old or newer untouched in the staging area.

**Expected outcome**: files with dates > 7 days ago are compressed and present in the archive folder; staging area retains only files ≤ 7 days old.

<validation step="replace-me-uuid-s2-04-archiving" />

#### Task 5 — Retention cleanup

Extend your script to delete compressed archive files whose **original log date** is older than **30 days**.

**Expected outcome**: archive folder contains only compressed files for dates between 8 and 30 days ago. Files for dates > 30 days ago have been deleted.

<validation step="replace-me-uuid-s2-05-retention" />

#### Task 6 — Lifecycle summary report

After archiving and cleanup, your script must write a JSON summary to:

* Linux: `/var/log/apparchive/lifecycle-report.json`
* Windows: `C:\applogs\archive\lifecycle-report.json`

Required structure:

```json
{
  "run_id": "<uuid or timestamp>",
  "executed_at": "<ISO 8601 datetime>",
  "archived": { "count": <number>, "total_size_bytes": <number> },
  "deleted": { "count": <number> },
  "retained_in_stage": { "count": <number> },
  "errors": []
}
```

**Expected outcome**: report file exists, parses as valid JSON, and counts match the actual outcome.

<validation step="replace-me-uuid-s2-06-lifecycle-report" />

---

## Section 3 — Advanced: Configuration Drift Detection & Remediation

### Estimated duration: 30 minutes | Level: Advanced

### Section Objective

Demonstrate that you can build an automation script that captures a system's expected state as a baseline, detects deviations (drift) from that baseline on re-evaluation, and auto-remediates known drift patterns — with a structured audit trail.

### Scenario

A bank's infrastructure team needs a lightweight drift-detection tool for Linux servers (or Windows hosts). The tool must: record a golden baseline of configuration checkpoints, detect deviations on subsequent runs, auto-remediate the two most common drift types (a missing directory and a stopped service), and write a structured audit log of every action taken.

Pre-staged on your VM:

* Linux: A baseline specification file at `/opt/assess/baseline.json` defining expected directories, file permissions, and services.
* Windows: A baseline specification file at `C:\bank\inputs\baseline.json` with the same schema for Windows paths and services.
* Both VMs have one service stopped and one expected directory missing — intentional drift for the remediation tasks.

The baseline schema (reference at the path above):

```json
{
  "directories": [
    { "path": "<path>", "owner": "<user>", "mode": "<octal-or-acl>" }
  ],
  "services": [
    { "name": "<service>", "expected_state": "active|running" }
  ]
}
```

---

### Pre-work — advanced automation principles

Three short questions on drift detection, idempotent remediation, and structured audit trails.

<question source="Question13.md" />

<br>

<question source="Question14.md" />

<br>

<question source="Question15.md" />

<br>

---

### Your deliverables — Section 3

#### Task 7 — Baseline capture

Write a script (`drift-check.sh` / `drift-check.ps1`) that reads the baseline specification and records the **current state** of each item into a snapshot file:

* Linux: `/var/log/drift/snapshot.json`
* Windows: `C:\ops\drift\snapshot.json`

The snapshot must record, for each checked item: the item type, path/name, observed state, expected state, and whether it matches.

**Expected outcome**: snapshot file exists, parses as valid JSON, and contains an entry for every item in the baseline specification.

<validation step="replace-me-uuid-s3-07-baseline-capture" />

#### Task 8 — Drift detection report

Extend your script to compare the snapshot against the baseline and write a drift report:

* Linux: `/var/log/drift/drift-report.json`
* Windows: `C:\ops\drift\drift-report.json`

Required structure:

```json
{
  "run_id": "<uuid or timestamp>",
  "evaluated_at": "<ISO 8601 datetime>",
  "total_checks": <number>,
  "drifted": <number>,
  "compliant": <number>,
  "drift_items": [
    { "type": "directory|service", "name": "<name>", "expected": "<value>", "observed": "<value>" }
  ]
}
```

**Expected outcome**: drift report exists, parses as valid JSON, and `drifted` count correctly reflects the two intentionally misconfigured items on the VM.

<validation step="replace-me-uuid-s3-08-drift-report" />

#### Task 9 — Auto-remediation

Extend your script to automatically fix the two known drift types when detected:

1. **Missing directory** — create it with the owner and permissions from the baseline.
2. **Stopped service** — start it.

After remediation, re-evaluate and update `drift-report.json` with the post-remediation state. The `drifted` count in the final report must be **0**.

**Expected outcome**: the previously stopped service is now running; the previously missing directory now exists with correct permissions; `drift-report.json` shows `drifted: 0`.

<validation step="replace-me-uuid-s3-09-remediation" />

#### Task 10 — Structured audit log

Every action your script takes (check, create, start, skip, fail) must be appended as a JSON Lines entry to an audit log:

* Linux: `/var/log/drift/audit.log`
* Windows: `C:\ops\drift\audit.log`

Each line must be a valid JSON object with at minimum:

```json
{ "timestamp": "<ISO 8601>", "action": "<check|create|start|skip|fail>", "target": "<item>", "outcome": "<success|failure|noop>", "detail": "<optional string>" }
```

**Expected outcome**: `audit.log` exists; every line parses as valid JSON; at least one `"action":"create"` and one `"action":"start"` entry are present (from the remediation run).

<validation step="replace-me-uuid-s3-10-audit-log" />

---

## Where to place your scripts

### Linux

| Script | Preferred path | Fallback path |
|---|---|---|
| `health-check.sh` | `/usr/local/bin/health-check.sh` | `/home/azureuser/automation/health-check.sh` |
| `log-lifecycle.sh` | `/usr/local/bin/log-lifecycle.sh` | `/home/azureuser/automation/log-lifecycle.sh` |
| `drift-check.sh` | `/usr/local/bin/drift-check.sh` | `/home/azureuser/automation/drift-check.sh` |

Make scripts executable: `chmod +x <script>`.

### Windows

| Script | Preferred path | Fallback path |
|---|---|---|
| `health-check.ps1` | `C:\Program Files\BankAutomation\health-check.ps1` | `C:\bank\automation\health-check.ps1` |
| `log-lifecycle.ps1` | `C:\Program Files\BankAutomation\log-lifecycle.ps1` | `C:\bank\automation\log-lifecycle.ps1` |
| `drift-check.ps1` | `C:\Program Files\BankAutomation\drift-check.ps1` | `C:\bank\automation\drift-check.ps1` |

---

## Validation

> Validate each task by clicking the **Validate** button next to its validation block.
>
> - Complete sections in order (1 → 2 → 3), but each section is independently scored.
> - If a validation fails, read the error message in the Lab Validation tab, fix the issue, and click Validate again.
> - You may iterate as many times as you like within the 90-minute window.
> - For platform support, contact `labs-support@spektrasystems.com`.

### Success criteria

| Section | Tasks | Pass threshold |
|---|---|---|
| Section 1 — Basic | Tasks 1–3 | ≥ 2 of 3 validations pass |
| Section 2 — Intermediate | Tasks 4–6 | ≥ 2 of 3 validations pass |
| Section 3 — Advanced | Tasks 7–10 | ≥ 3 of 4 validations pass |

Pre-work questions (3 per section) are scored automatically by the portal.

**Overall pass: ≥ 60% across all questions and tasks attempted.**

### Lab Validation tab — usage

1. After completing each task, visit the **Lab Validation** tab and click **VALIDATE** under Actions.
2. If validation shows **Success**, move on to the next task.
3. If validation shows **Fail**, hover over the `i` icon to read the root-cause hint, fix the issue, and re-validate.
4. For platform issues, contact `labs-support@spektrasystems.com`.
