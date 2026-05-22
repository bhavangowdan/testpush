**CloudLabs by Spektra Systems** | Lab Guide 2 — Solution Guide (internal — do not share with McKinsey, Nedbank, or candidates)

# Lab Guide 2 — Common Infrastructure Automation: Solution Guide

This guide is the authoritative reference for **what the candidate is doing**, **what good looks like for each task**, and **how a proctor can help a stuck candidate without spoiling the assessment**. Use it alongside `lab-guide/lab-guide-2.md` — the section numbering here matches the lab guide 1:1.

## How to use this guide

| Section | Audience | Purpose |
|---|---|---|
| Task-by-task reference | Proctor + dev team | What the candidate is asked to do; what a passing implementation looks like |
| Reference solutions — Bash | Proctor + dev team | Complete, tested Bash scripts that pass all three section validations on Ubuntu |
| Reference solutions — PowerShell | Proctor + dev team | Complete, tested PowerShell scripts that pass all three section validations on Windows |
| Hint progression | Proctor only | Three hint tiers per section — give the lowest tier that unblocks; never read out the reference solution |
| Common failure modes | Dev team | Mistakes to anticipate when reviewing candidate work |

---

# Section 1 — Basic: Automated System Health Reporter

## What the candidate is asked to do

Build a single script (`health-check.sh` / `health-check.ps1`) that:

1. Collects system metrics (disk, memory, CPU load) and the status of three monitored services.
2. Applies threshold rules and emits an `alerts` array (empty if no breach).
3. Writes a structured JSON report at a fixed path; safe to re-run (overwrites, does not append).

## What good looks like

- Report file exists at the expected path.
- Parses as valid JSON.
- Contains all required top-level keys: `run_id`, `collected_at`, `hostname`, `disk`, `memory`, `cpu_load_avg_1m`, `services`, `alerts`.
- `services` array has 3 entries with `status` values from the allowed enum.
- `alerts` is always an array (empty `[]` is valid).
- Running the script a second time produces exactly one report file with a refreshed `collected_at`.

## How the validation grades it

- Probes for the report file at the expected path.
- Parses it as JSON; checks all required keys are present.
- Verifies `services` length is 3 and each entry has `name` + `status`.
- Verifies `alerts` is an array.
- Re-runs the script and confirms file count stays at 1.

## Common failure modes

| Mistake | Symptom | Fix |
|---|---|---|
| Appending to the report instead of overwriting | Second run produces invalid JSON (concatenated objects) | Use `>` redirection (Bash) / `Set-Content` (PowerShell), not `>>` / `Add-Content` |
| Missing the `alerts` key when no thresholds breach | Validation fails — key absent | Always initialise `alerts` as an empty array before threshold checks |
| Service status string mismatch (`running` vs `active`) | Validation enum check fails | Normalise PowerShell `Running` → `active`, `Stopped` → `inactive` before serialising |
| Bash arithmetic floats fail (`bc` not installed in some images) | `disk.used_pct` is empty | Use `awk` for float math; it is always present |

## Hint progression — Section 1

| Tier | Hint (for proctor to read aloud) |
|---|---|
| 1 (mild nudge) | "What does your script write when it runs successfully? Have you opened the file with `cat` or `Get-Content` to verify it's valid JSON?" |
| 2 (specific) | "The validation expects an `alerts` array even when nothing is wrong. Is `alerts` always present in your output, or only when a threshold is breached?" |
| 3 (direct) | "On a re-run, the validation expects exactly one report file. Are you overwriting the file or appending? Try `cat report.json` after two runs and see if it parses." |

---

## Reference solution — Bash (`health-check.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail

REPORT_DIR="/var/log/health"
REPORT="$REPORT_DIR/health-report.json"
mkdir -p "$REPORT_DIR"

RUN_ID=$(date -u +%Y%m%dT%H%M%SZ)
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
HOST=$(hostname)

# Disk
DISK_PCT=$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5+0}')

# Memory (in MB)
MEM_TOTAL=$(awk '/MemTotal/{printf "%d", $2/1024}' /proc/meminfo)
MEM_AVAIL=$(awk '/MemAvailable/{printf "%d", $2/1024}' /proc/meminfo)
MEM_USED=$((MEM_TOTAL - MEM_AVAIL))
MEM_PCT=$(awk -v u="$MEM_USED" -v t="$MEM_TOTAL" 'BEGIN{printf "%.1f", (u/t)*100}')

# CPU 1-min load average
CPU=$(awk '{print $1}' /proc/loadavg)

# Service status
svc_status() {
  systemctl is-active "$1" 2>/dev/null || echo "unknown"
}
SVC_SSH=$(svc_status ssh)
SVC_CRON=$(svc_status cron)
SVC_SYSLOG=$(svc_status rsyslog)

# Build alerts
ALERTS=()
awk -v p="$DISK_PCT"   'BEGIN{exit !(p>80)}' && ALERTS+=("{\"check\":\"disk\",\"detail\":\"used $DISK_PCT%% > 80%%\"}")
awk -v p="$MEM_PCT"    'BEGIN{exit !(p>75)}' && ALERTS+=("{\"check\":\"memory\",\"detail\":\"used $MEM_PCT%% > 75%%\"}")
[[ "$SVC_SSH"    != "active" ]] && ALERTS+=("{\"check\":\"service\",\"detail\":\"ssh is $SVC_SSH\"}")
[[ "$SVC_CRON"   != "active" ]] && ALERTS+=("{\"check\":\"service\",\"detail\":\"cron is $SVC_CRON\"}")
[[ "$SVC_SYSLOG" != "active" ]] && ALERTS+=("{\"check\":\"service\",\"detail\":\"rsyslog is $SVC_SYSLOG\"}")

ALERTS_JSON=$(IFS=,; echo "${ALERTS[*]-}")

cat > "$REPORT" <<EOF
{
  "run_id": "$RUN_ID",
  "collected_at": "$NOW",
  "hostname": "$HOST",
  "disk":   { "path": "/", "used_pct": $DISK_PCT },
  "memory": { "total_mb": $MEM_TOTAL, "used_mb": $MEM_USED, "used_pct": $MEM_PCT },
  "cpu_load_avg_1m": $CPU,
  "services": [
    { "name": "ssh",     "status": "$SVC_SSH" },
    { "name": "cron",    "status": "$SVC_CRON" },
    { "name": "rsyslog", "status": "$SVC_SYSLOG" }
  ],
  "alerts": [$ALERTS_JSON]
}
EOF

echo "Health report written to $REPORT"
exit 0
```

## Reference solution — PowerShell (`health-check.ps1`)

```powershell
$ErrorActionPreference = 'Stop'

$ReportDir = 'C:\ops\health'
$Report    = Join-Path $ReportDir 'health-report.json'
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

$RunId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$Now   = (Get-Date).ToUniversalTime().ToString('o')

# Disk
$disk = Get-PSDrive C
$diskPct = [math]::Round(($disk.Used / ($disk.Used + $disk.Free)) * 100, 1)

# Memory
$os = Get-CimInstance Win32_OperatingSystem
$memTotal = [math]::Round($os.TotalVisibleMemorySize / 1024, 0)
$memFree  = [math]::Round($os.FreePhysicalMemory   / 1024, 0)
$memUsed  = $memTotal - $memFree
$memPct   = [math]::Round(($memUsed / $memTotal) * 100, 1)

# CPU "load" — Windows analogue: 1-sample CPU percentage
$cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average / 100

# Services
function Get-SvcStatus($name) {
    $s = Get-Service -Name $name -ErrorAction SilentlyContinue
    if (-not $s)                { return 'unknown'  }
    if ($s.Status -eq 'Running'){ return 'active'   }
    return 'inactive'
}
$svcWinRM    = Get-SvcStatus 'WinRM'
$svcSched    = Get-SvcStatus 'Schedule'
$svcEventLog = Get-SvcStatus 'EventLog'

# Alerts
$alerts = @()
if ($diskPct -gt 80) { $alerts += @{ check='disk';   detail="used $diskPct% > 80%" } }
if ($memPct  -gt 75) { $alerts += @{ check='memory'; detail="used $memPct% > 75%"  } }
foreach ($pair in @(@('WinRM',$svcWinRM),@('Schedule',$svcSched),@('EventLog',$svcEventLog))) {
    if ($pair[1] -ne 'active') {
        $alerts += @{ check='service'; detail="$($pair[0]) is $($pair[1])" }
    }
}

$obj = [ordered]@{
    run_id       = $RunId
    collected_at = $Now
    hostname     = $env:COMPUTERNAME
    disk         = @{ path='C:\'; used_pct=$diskPct }
    memory       = @{ total_mb=$memTotal; used_mb=$memUsed; used_pct=$memPct }
    cpu_load_avg_1m = $cpuLoad
    services     = @(
        @{ name='WinRM';    status=$svcWinRM    },
        @{ name='Schedule'; status=$svcSched    },
        @{ name='EventLog'; status=$svcEventLog }
    )
    alerts       = $alerts
}

$obj | ConvertTo-Json -Depth 6 | Set-Content -Path $Report -Encoding UTF8
Write-Host "Health report written to $Report"
exit 0
```

---

# Section 2 — Intermediate: Log File Management Automation

## What the candidate is asked to do

Build a single script (`log-lifecycle.sh` / `log-lifecycle.ps1`) that, in one run:

1. Archives + compresses files older than 7 days from staging to archive.
2. Deletes compressed archive files whose original log date is older than 30 days.
3. Writes a JSON lifecycle summary report.

## What good looks like

- Files dated 8–60 days ago in staging → compressed and moved to archive.
- Files dated 1–7 days ago → still in staging, uncompressed.
- Archive contains only compressed files for dates 8–30 days ago (files > 30 days are deleted).
- `lifecycle-report.json` exists, parses as JSON, has the four required top-level keys (`archived`, `deleted`, `retained_in_stage`, `errors`), and counts match observed file movements.

## How the validation grades it

- Counts files in staging area (must be ≤ 7 — only files within retention window).
- Counts compressed files in archive (must equal the 8–30 day band — typically ~22).
- Confirms no compressed files for dates > 30 days remain.
- Parses `lifecycle-report.json` and checks numeric consistency.

## Common failure modes

| Mistake | Symptom | Fix |
|---|---|---|
| Using `mtime` instead of filename date | All files appear "1 day old" so nothing is archived | Parse the date from `app-YYYY-MM-DD.log` filename |
| Deleting uncompressed staging files instead of moving | Files lost permanently | Use `mv` then `gzip`, or `Compress-Archive` then `Remove-Item` for the source |
| Forgetting to delete > 30-day archive files | Archive grows unbounded | Apply the 30-day retention rule to compressed filenames |
| Mixing `.log.gz` vs `.gz.log` extensions | Validation regex doesn't match | Use `gzip <file>` (produces `<file>.gz`) — let the tool name it |

## Hint progression — Section 2

| Tier | Hint |
|---|---|
| 1 | "Are you parsing the date from the filename, or using the file's modified-time? Each file's name has a date — that's the authoritative one." |
| 2 | "Two things must happen in one run: archive old → delete very old. Are both running, or is your script stopping after the first?" |
| 3 | "After your script, what does `ls /var/log/apparchive/` show? Only files for dates 8–30 days back should be there." |

---

## Reference solution — Bash (`log-lifecycle.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail

STAGE="/var/log/appstage"
ARCH="/var/log/apparchive"
REPORT="$ARCH/lifecycle-report.json"
mkdir -p "$ARCH"

RUN_ID=$(date -u +%Y%m%dT%H%M%SZ)
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TODAY_EPOCH=$(date -u +%s)

archived_count=0
archived_bytes=0
deleted_count=0

# Step 1 — archive files older than 7 days from staging
for f in "$STAGE"/app-*.log; do
  [[ -e "$f" ]] || continue
  base=$(basename "$f")
  # Parse YYYY-MM-DD from "app-YYYY-MM-DD.log"
  if [[ "$base" =~ ^app-([0-9]{4})-([0-9]{2})-([0-9]{2})\.log$ ]]; then
    ymd="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
    file_epoch=$(date -u -d "$ymd" +%s)
    age_days=$(( (TODAY_EPOCH - file_epoch) / 86400 ))
    if (( age_days > 7 )); then
      size=$(stat -c%s "$f")
      mv "$f" "$ARCH/"
      gzip -f "$ARCH/$base"
      archived_count=$((archived_count + 1))
      archived_bytes=$((archived_bytes + size))
    fi
  fi
done

# Step 2 — delete archive files whose original date is > 30 days
for f in "$ARCH"/app-*.log.gz; do
  [[ -e "$f" ]] || continue
  base=$(basename "$f")
  if [[ "$base" =~ ^app-([0-9]{4})-([0-9]{2})-([0-9]{2})\.log\.gz$ ]]; then
    ymd="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
    file_epoch=$(date -u -d "$ymd" +%s)
    age_days=$(( (TODAY_EPOCH - file_epoch) / 86400 ))
    if (( age_days > 30 )); then
      rm -f "$f"
      deleted_count=$((deleted_count + 1))
    fi
  fi
done

# Step 3 — count what is retained in staging
retained=$(find "$STAGE" -maxdepth 1 -name 'app-*.log' -type f | wc -l)

cat > "$REPORT" <<EOF
{
  "run_id": "$RUN_ID",
  "executed_at": "$NOW",
  "archived":          { "count": $archived_count, "total_size_bytes": $archived_bytes },
  "deleted":           { "count": $deleted_count },
  "retained_in_stage": { "count": $retained },
  "errors": []
}
EOF

echo "Lifecycle report written to $REPORT"
exit 0
```

## Reference solution — PowerShell (`log-lifecycle.ps1`)

```powershell
$ErrorActionPreference = 'Stop'

$Stage  = 'C:\applogs\stage'
$Arch   = 'C:\applogs\archive'
$Report = Join-Path $Arch 'lifecycle-report.json'
New-Item -ItemType Directory -Force -Path $Arch | Out-Null

$RunId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$Now   = (Get-Date).ToUniversalTime().ToString('o')
$Today = (Get-Date).Date

$archivedCount = 0
$archivedBytes = 0
$deletedCount  = 0

# Step 1 — archive + compress files older than 7 days
Get-ChildItem -Path $Stage -Filter 'app-*.log' -File | ForEach-Object {
    if ($_.Name -match '^app-(\d{4})-(\d{2})-(\d{2})\.log$') {
        $fileDate = [datetime]::ParseExact("$($Matches[1])-$($Matches[2])-$($Matches[3])", 'yyyy-MM-dd', $null)
        $age = ($Today - $fileDate).Days
        if ($age -gt 7) {
            $zip = Join-Path $Arch ($_.BaseName + '.zip')
            Compress-Archive -Path $_.FullName -DestinationPath $zip -Force
            $archivedBytes += $_.Length
            Remove-Item $_.FullName -Force
            $archivedCount++
        }
    }
}

# Step 2 — retention cleanup: delete archive entries whose original date > 30 days
Get-ChildItem -Path $Arch -Filter 'app-*.zip' -File | ForEach-Object {
    if ($_.Name -match '^app-(\d{4})-(\d{2})-(\d{2})\.zip$') {
        $fileDate = [datetime]::ParseExact("$($Matches[1])-$($Matches[2])-$($Matches[3])", 'yyyy-MM-dd', $null)
        $age = ($Today - $fileDate).Days
        if ($age -gt 30) {
            Remove-Item $_.FullName -Force
            $deletedCount++
        }
    }
}

# Step 3 — count retained
$retained = (Get-ChildItem -Path $Stage -Filter 'app-*.log' -File).Count

$obj = [ordered]@{
    run_id       = $RunId
    executed_at  = $Now
    archived     = @{ count=$archivedCount; total_size_bytes=$archivedBytes }
    deleted      = @{ count=$deletedCount }
    retained_in_stage = @{ count=$retained }
    errors       = @()
}

$obj | ConvertTo-Json -Depth 6 | Set-Content -Path $Report -Encoding UTF8
Write-Host "Lifecycle report written to $Report"
exit 0
```

---

# Section 3 — Advanced: Configuration Drift Detection & Remediation

## What the candidate is asked to do

Build a single script (`drift-check.sh` / `drift-check.ps1`) that, in one run:

1. Reads the baseline JSON specification.
2. Evaluates the current state of each item.
3. Auto-remediates drift (creates missing directories, starts stopped services) — **idempotently**, using check-then-act.
4. Writes a drift report (`drift-report.json`) and a JSON Lines audit log (`audit.log`).

After remediation, the report must show `drifted: 0`.

## What good looks like

- `drift-report.json` exists, parses as JSON.
- `total_checks` = count of items in the baseline (directories + services).
- `drifted` = 0 after remediation.
- `compliant` = `total_checks` after remediation.
- `audit.log` exists; every line is independently valid JSON; contains at least one `"action":"create"` and one `"action":"start"` entry.

## How the validation grades it

- Parses `drift-report.json`; asserts `drifted: 0`.
- Reads `audit.log` line-by-line; asserts every line parses as JSON.
- Asserts presence of `create` action targeting the missing directory and `start` action targeting the stopped service.
- Verifies the previously stopped service is now active and the previously missing directory now exists.

## Common failure modes

| Mistake | Symptom | Fix |
|---|---|---|
| Re-running the script crashes on already-running service | `systemctl start` returns 0 even if already running, but PowerShell `Start-Service` on already-running throws | Wrap in idempotency check: `if ($svc.Status -ne 'Running') { Start-Service ... }` |
| Writing audit entries as a JSON array `[ {...}, {...} ]` instead of JSON Lines | Validation fails on line-by-line JSON parse | Append each entry as its own line — use `>> audit.log` with one object per write |
| Forgetting to chown the created directory | Drift report shows compliance, but baseline owner check fails | Apply `chown` (Linux) / `icacls` (Windows) after `mkdir` |
| Computing `drifted` count before remediation runs | Report shows `drifted: 2` even though everything is fixed | Re-evaluate state after the remediation pass, then write report |

## Hint progression — Section 3

| Tier | Hint |
|---|---|
| 1 | "Your audit log is the proctor's debugger — open it and walk through what your script did. Is each line a single JSON object?" |
| 2 | "The validation re-reads the report file after your script exits. Is `drifted` zero in that file, or are you computing the count before remediation runs?" |
| 3 | "An idempotent remediation checks first — `systemctl is-active` before `start`, `test -d` before `mkdir`. Are you checking, or just acting?" |

---

## Reference solution — Bash (`drift-check.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail

BASELINE="/opt/assess/baseline.json"
OUT_DIR="/var/log/drift"
REPORT="$OUT_DIR/drift-report.json"
AUDIT="$OUT_DIR/audit.log"
mkdir -p "$OUT_DIR"

RUN_ID=$(date -u +%Y%m%dT%H%M%SZ)
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

audit() {
  local action="$1" target="$2" outcome="$3" detail="${4:-}"
  printf '{"timestamp":"%s","action":"%s","target":"%s","outcome":"%s","detail":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$action" "$target" "$outcome" "$detail" >> "$AUDIT"
}

# Read baseline
dirs_json=$(jq -c '.directories[]' "$BASELINE")
svcs_json=$(jq -c '.services[]'    "$BASELINE")

# Remediate directories
while IFS= read -r row; do
  path=$(echo "$row" | jq -r '.path')
  owner=$(echo "$row" | jq -r '.owner')
  mode=$(echo "$row" | jq -r '.mode')
  audit check directory:"$path" success "evaluating"
  if [[ ! -d "$path" ]]; then
    mkdir -p "$path"
    chown "$owner":"$owner" "$path" 2>/dev/null || true
    chmod "$mode" "$path"
    audit create directory:"$path" success "created with mode $mode"
  else
    audit skip directory:"$path" noop "already exists"
  fi
done <<< "$dirs_json"

# Remediate services
while IFS= read -r row; do
  name=$(echo "$row" | jq -r '.name')
  audit check service:"$name" success "evaluating"
  if ! systemctl is-active --quiet "$name"; then
    if sudo systemctl start "$name" 2>/dev/null; then
      audit start service:"$name" success "started"
    else
      audit start service:"$name" failure "start command failed"
    fi
  else
    audit skip service:"$name" noop "already running"
  fi
done <<< "$svcs_json"

# Re-evaluate after remediation
total=0; drifted=0; compliant=0
drift_items=""

while IFS= read -r row; do
  path=$(echo "$row" | jq -r '.path')
  total=$((total+1))
  if [[ -d "$path" ]]; then
    compliant=$((compliant+1))
  else
    drifted=$((drifted+1))
    drift_items+="${drift_items:+,}{\"type\":\"directory\",\"name\":\"$path\",\"expected\":\"present\",\"observed\":\"missing\",\"remediated\":false}"
  fi
done <<< "$dirs_json"

while IFS= read -r row; do
  name=$(echo "$row" | jq -r '.name')
  total=$((total+1))
  if systemctl is-active --quiet "$name"; then
    compliant=$((compliant+1))
  else
    drifted=$((drifted+1))
    drift_items+="${drift_items:+,}{\"type\":\"service\",\"name\":\"$name\",\"expected\":\"active\",\"observed\":\"inactive\",\"remediated\":false}"
  fi
done <<< "$svcs_json"

cat > "$REPORT" <<EOF
{
  "run_id": "$RUN_ID",
  "evaluated_at": "$NOW",
  "total_checks": $total,
  "drifted": $drifted,
  "compliant": $compliant,
  "drift_items": [$drift_items]
}
EOF

echo "Drift report written to $REPORT"
exit 0
```

## Reference solution — PowerShell (`drift-check.ps1`)

```powershell
$ErrorActionPreference = 'Stop'

$Baseline = 'C:\bank\inputs\baseline.json'
$OutDir   = 'C:\ops\drift'
$Report   = Join-Path $OutDir 'drift-report.json'
$Audit    = Join-Path $OutDir 'audit.log'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$RunId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$Now   = (Get-Date).ToUniversalTime().ToString('o')

function Write-Audit($action, $target, $outcome, $detail='') {
    $entry = [ordered]@{
        timestamp = (Get-Date).ToUniversalTime().ToString('o')
        action    = $action
        target    = $target
        outcome   = $outcome
        detail    = $detail
    }
    ($entry | ConvertTo-Json -Compress -Depth 4) | Add-Content -Path $Audit -Encoding UTF8
}

$spec = Get-Content $Baseline -Raw | ConvertFrom-Json

# Remediate directories
foreach ($d in $spec.directories) {
    Write-Audit 'check' "directory:$($d.path)" 'success' 'evaluating'
    if (-not (Test-Path $d.path)) {
        New-Item -ItemType Directory -Path $d.path -Force | Out-Null
        # mode is best-effort on Windows; skip if not applicable
        Write-Audit 'create' "directory:$($d.path)" 'success' "created"
    } else {
        Write-Audit 'skip'   "directory:$($d.path)" 'noop' 'already exists'
    }
}

# Remediate services
foreach ($s in $spec.services) {
    Write-Audit 'check' "service:$($s.name)" 'success' 'evaluating'
    $svc = Get-Service -Name $s.name -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Audit 'fail' "service:$($s.name)" 'failure' 'service not found'
        continue
    }
    if ($svc.Status -ne 'Running') {
        try {
            Start-Service -Name $s.name
            Write-Audit 'start' "service:$($s.name)" 'success' 'started'
        } catch {
            Write-Audit 'start' "service:$($s.name)" 'failure' $_.Exception.Message
        }
    } else {
        Write-Audit 'skip' "service:$($s.name)" 'noop' 'already running'
    }
}

# Re-evaluate
$total = 0; $drifted = 0; $compliant = 0
$driftItems = @()

foreach ($d in $spec.directories) {
    $total++
    if (Test-Path $d.path) { $compliant++ }
    else {
        $drifted++
        $driftItems += @{ type='directory'; name=$d.path; expected='present'; observed='missing'; remediated=$false }
    }
}
foreach ($s in $spec.services) {
    $total++
    $svc = Get-Service -Name $s.name -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq 'Running') { $compliant++ }
    else {
        $drifted++
        $driftItems += @{ type='service'; name=$s.name; expected='active'; observed='inactive'; remediated=$false }
    }
}

$obj = [ordered]@{
    run_id       = $RunId
    evaluated_at = $Now
    total_checks = $total
    drifted      = $drifted
    compliant    = $compliant
    drift_items  = $driftItems
}

$obj | ConvertTo-Json -Depth 6 | Set-Content -Path $Report -Encoding UTF8
Write-Host "Drift report written to $Report"
exit 0
```

---

# Proctor workflow

1. **Before each candidate session**, confirm `seed-state.sh` (Linux) or `seed-state.ps1` (Windows) ran successfully:
   - For Section 1 — no pre-seed required beyond the standard VM build.
   - For Section 2 — 40 dated log files present in staging.
   - For Section 3 — `baseline.json` present; one expected directory missing; one expected service stopped.

2. **During the session**, watch the candidate's audit log for Section 3 — `tail -f /var/log/drift/audit.log` (Linux) or `Get-Content -Wait` (Windows). It is the fastest signal of progress.

3. **Hint discipline** — give the lowest-tier hint that unblocks. Never paste the reference solution. If a candidate is genuinely stuck for > 10 minutes on a section, give the Tier-3 hint and move on; another section may go better.

4. **After the session**, archive the candidate's scripts and report files for moderation review.
