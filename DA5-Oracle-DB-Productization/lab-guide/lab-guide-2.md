# Generic Automation — Common Infrastructure Automation Assessment


### Estimated duration: 30 minutes



### What this assessment is NOT

This is a **technology-agnostic automation** assessment designed as a **common yardstick for all infrastructure engineers**, regardless of domain specialty.

You pick the tool you already know: **Bash**,**Poweshell**, **Ansible**, **Python**, **Terraform**. The validations grade the *outcome* across three progressive difficulty tiers. You may attempt all three sections or stop at any tier — each section is independently scored.

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

---

## Section 1 — Basic: Automated System Health Reporter

<br>

### Estimated duration: 30 minutes | Level: Foundational

<br>

### Section Objective

Demonstrate that you can write a script that collects system health metrics, applies threshold logic, structures the output as JSON, and is safe to re-run — the most fundamental automation skill expected of any infrastructure engineer.

### Scenario

A bank's night-shift operations team currently runs manual health checks at the start of every shift: disk usage, memory utilisation, CPU load, and status of critical services. The team lead wants this automated into a single script that runs on demand, applies threshold rules, and writes a machine-readable JSON report.

### Task — Build the system health reporter

Write **one** script (`health-check.sh` on Linux, `health-check.ps1` on Windows) that:

1. **Collects** system metrics and service status, and writes them to a single JSON report:
   * Linux: `/var/log/health/health-report.json`
   * Windows: `C:\ops\health\health-report.json`

2. **Applies threshold rules** and includes an `alerts` array in the report. Flag a breach when:
   * Disk used > 80%
   * Memory used > 75%
   * Any monitored service is not in the expected running state

3. **Is safe to re-run.** Running the script twice must overwrite (not append to) the report and leave exactly one report file with an updated `collected_at` timestamp.

Required JSON structure:

```json
{
  "run_id": "<uuid or timestamp>",
  "collected_at": "<ISO 8601 datetime>",
  "hostname": "<system hostname>",
  "disk":   { "path": "/", "used_pct": <number> },
  "memory": { "total_mb": <number>, "used_mb": <number>, "used_pct": <number> },
  "cpu_load_avg_1m": <number>,
  "services": [
    { "name": "<service-name>", "status": "active|inactive|unknown" }
  ],
  "alerts": [
    { "check": "<disk|memory|service>", "detail": "<human-readable reason>" }
  ]
}
```

Services to check:

* Linux: `ssh`, `cron`, `rsyslog`
* Windows: `WinRM`, `Schedule`, `EventLog`

If no thresholds are breached, `alerts` must be an empty array `[]` — not absent.

**Expected outcome**: report file exists at the specified path, parses as valid JSON, contains all required top-level keys, and re-running the script produces exactly one report file with a refreshed `collected_at` timestamp.

<validation step="5e0cfaab-fe4f-4a92-b3fd-32c718c89246" />

---

## Section 2 — Intermediate: Log File Management Automation

### Estimated duration: 30 minutes | Level: Practitioner

### Section Objective

Demonstrate that you can automate a recurring operational maintenance task — log lifecycle management — with age-based logic, compression, retention enforcement, and structured reporting.

### Scenario

An application writes daily log files to a staging area. Files older than 7 days must be compressed and moved to an archive. Files older than 30 days in the archive must be deleted. The ops team currently does this manually. Your job: automate it.

Pre-staged on your VM:

* Linux: 40 log files in `/var/log/appstage/` with names `app-YYYY-MM-DD.log` (dates ranging from 1 to 60 days ago).
* Windows: 40 log files in `C:\applogs\stage\` with the same naming pattern.

### Task — Build the log lifecycle automation

Write **one** script (`log-lifecycle.sh` / `log-lifecycle.ps1`) that performs the full lifecycle in a single run:

1. **Archive with compression** — Move files older than **7 days** from the staging area to the archive folder and compress them (`.gz` on Linux via `gzip`, `.zip` on Windows via `Compress-Archive`).
   * Linux archive: `/var/log/apparchive/`
   * Windows archive: `C:\applogs\archive\`
   * Files 7 days old or newer remain untouched in the staging area.

2. **Retention cleanup** — Delete compressed archive files whose **original log date** (parsed from the filename) is older than **30 days**.

3. **Write a lifecycle summary report** to:
   * Linux: `/var/log/apparchive/lifecycle-report.json`
   * Windows: `C:\applogs\archive\lifecycle-report.json`

Required report structure:

```json
{
  "run_id": "<uuid or timestamp>",
  "executed_at": "<ISO 8601 datetime>",
  "archived":          { "count": <number>, "total_size_bytes": <number> },
  "deleted":           { "count": <number> },
  "retained_in_stage": { "count": <number> },
  "errors": []
}
```

**Expected outcome**: files older than 7 days are compressed and present in the archive folder; archive contains only compressed files for dates between 8 and 30 days ago; staging area retains only files ≤ 7 days old; `lifecycle-report.json` exists, parses as valid JSON, and counts match the actual file movements.

<validation step="5e0cfaab-fe4f-4a92-b3fd-32c718c89246" />

---

## Section 3 — Advanced: Configuration Drift Detection & Remediation

### Estimated duration: 30 minutes | Level: Advanced

### Section Objective

Demonstrate that you can build an automation script that captures a system's expected state as a baseline, detects deviations (drift), auto-remediates known drift patterns, and writes a structured audit trail — the core capabilities of any infrastructure reliability tool.

### Scenario

A bank's infrastructure team needs a lightweight drift-detection tool for Linux servers (or Windows hosts). The tool must read a golden baseline, detect deviations on a run, auto-remediate the two most common drift types (a missing directory and a stopped service), and write a structured audit log of every action taken.

Pre-staged on your VM:

* Linux: A baseline specification file at `/opt/assess/baseline.json` defining expected directories and services.
* Windows: A baseline specification file at `C:\bank\inputs\baseline.json` with the same schema for Windows paths and services.
* Both VMs have one service stopped and one expected directory missing — intentional drift for the remediation task.

The baseline schema:

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

### Task — Build the drift-detection & remediation tool

Write **one** script (`drift-check.sh` / `drift-check.ps1`) that performs the full drift cycle in a single run:

1. **Read the baseline** specification and evaluate the current state of each item.

2. **Auto-remediate known drift types** (check-then-act, idempotent):
   * **Missing directory** — create it with the owner and permissions from the baseline.
   * **Stopped service** — start it.

3. **Write a drift report** after remediation to:
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
       { "type": "directory|service", "name": "<name>", "expected": "<value>", "observed": "<value>", "remediated": true }
     ]
   }
   ```

4. **Write a JSON Lines audit log** of every action (check, create, start, skip, fail) to:
   * Linux: `/var/log/drift/audit.log`
   * Windows: `C:\ops\drift\audit.log`

   Each line must be a valid JSON object:

   ```json
   { "timestamp": "<ISO 8601>", "action": "<check|create|start|skip|fail>", "target": "<item>", "outcome": "<success|failure|noop>", "detail": "<optional string>" }
   ```

After the script runs, the previously stopped service must be running, the previously missing directory must exist with correct permissions, and the final `drift-report.json` must show `drifted: 0`.

**Expected outcome**: `drift-report.json` exists, parses as valid JSON, and shows `drifted: 0` after remediation; `audit.log` exists with every line parsing as valid JSON and contains at least one `"action":"create"` entry (for the directory) and one `"action":"start"` entry (for the service).

<validation step="5e0cfaab-fe4f-4a92-b3fd-32c718c89246" />

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

> Validate each section by clicking the **Validate** button next to its validation block.
>
> - Each section is independently scored.
> - If a validation fails, read the error message in the Lab Validation tab, fix the issue, and click Validate again.
> - You may iterate as many times as you like within the 90-minute window.
> - For platform support, contact `labs-support@spektrasystems.com`.

### Success criteria

| Section | Level | Pass criteria |
|---|---|---|
| Section 1 | Basic | Validation returns Success |
| Section 2 | Intermediate | Validation returns Success |
| Section 3 | Advanced | Validation returns Success |

**Overall pass: ≥ 60% of section validations succeed.**

### Lab Validation tab — usage

1. After completing each section, visit the **Lab Validation** tab and click **VALIDATE** under Actions.
2. If validation shows **Success**, move on to the next section.
3. If validation shows **Fail**, hover over the `i` icon to read the root-cause hint, fix the issue, and re-validate.
4. For platform issues, contact `labs-support@spektrasystems.com`.
