# Validation Scripts — Lab Guide 2

Internal — do not share with candidates.

Each script probes both the Linux VM (`LNX-<DeploymentID>`) and the Windows VM (`WIN-<DeploymentID>`) and grades real running state. If **either** VM passes, the validation returns `Succeeded`.

## Scripts

| File | Section | What it grades |
|---|---|---|
| `s1-task-health-reporter.ps1` | Section 1 — Basic | `health-report.json` exists, schema-valid, contains required keys, idempotent re-run |
| `s2-task-log-lifecycle.ps1` | Section 2 — Intermediate | Staging within 7-day window; archive in 8-30 day band; no >30-day files; `lifecycle-report.json` schema-valid |
| `s3-task-drift-remediation.ps1` | Section 3 — Advanced | `drift-report.json` shows `drifted: 0`; `audit.log` lines parse as JSON; contains `create` and `start` actions |

## Inputs (provided by the CloudLabs runner)

| Variable | Description |
|---|---|
| `$deployment_id` | The candidate's sandbox deployment ID |
| `$resourceGroupName` | The sandbox resource group (`rg-da1-<DeploymentID>`) |
| `$sub_id` | The sandbox subscription ID |

## Output contract

Each script writes a JSON response via `Push-OutputBinding`:

```json
{ "Status": "Succeeded", "Message": "<human-readable detail>" }
```

or

```json
{ "Status": "Failed", "Message": "<failure reason + probe output>" }
```

## Retry policy

Up to 3 retries with 60-second backoff on transient `Invoke-AzVMRunCommand` failures.

## Replacing the placeholder UUIDs

In `lab-guide-2.md`, three validation step placeholders exist:

- `replace-me-uuid-s1-health-reporter`
- `replace-me-uuid-s2-log-lifecycle`
- `replace-me-uuid-s3-drift-remediation`

Generate real GUIDs and register each script in the CloudLabs validation framework, then swap the placeholder UUIDs in `lab-guide-2.md`.
