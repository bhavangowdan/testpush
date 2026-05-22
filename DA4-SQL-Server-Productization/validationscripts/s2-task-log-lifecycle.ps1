Import-Module Az.Compute
Import-Module Az.Accounts

$deployment_id     = $deployment_id
$resourceGroupName = $resourceGroupName
$sub_id            = $sub_id
$linuxVm           = "LNX-$deployment_id"
$winVm             = "WIN-$deployment_id"

Select-AzSubscription -SubscriptionId $sub_id | Out-Null

$stopRetry = $false; [int]$retryCount = 0; $maxRetries = 3
do {
    try {
        # --- Linux probe ---
        $linuxScript = @'
STAGE=/var/log/appstage
ARCH=/var/log/apparchive
REPORT=$ARCH/lifecycle-report.json
ok=true
detail=""

# Staging should hold only files within 7-day window
stage_count=$(find "$STAGE" -maxdepth 1 -name 'app-*.log' -type f 2>/dev/null | wc -l)
[[ "$stage_count" -le 7 ]] || { ok=false; detail="staging has $stage_count files; expected <=7"; }

# Archive should hold compressed files for 8-30 day window
if $ok; then
  arch_count=$(find "$ARCH" -maxdepth 1 -name 'app-*.log.gz' -type f 2>/dev/null | wc -l)
  [[ "$arch_count" -ge 15 && "$arch_count" -le 30 ]] || { ok=false; detail="archive has $arch_count compressed files; expected 15-30 (8-30 day band)"; }
fi

# No archive files for dates >30 days ago
if $ok; then
  TODAY=$(date -u +%s)
  for f in "$ARCH"/app-*.log.gz; do
    [[ -e "$f" ]] || continue
    base=$(basename "$f")
    if [[ "$base" =~ ^app-([0-9]{4})-([0-9]{2})-([0-9]{2})\.log\.gz$ ]]; then
      ymd="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
      file_epoch=$(date -u -d "$ymd" +%s 2>/dev/null) || continue
      age=$(( (TODAY - file_epoch) / 86400 ))
      if (( age > 30 )); then
        ok=false; detail="archive still contains $base (age $age days > 30)"; break
      fi
    fi
  done
fi

# Lifecycle report exists, valid JSON, has required keys
if $ok; then
  if [[ ! -f "$REPORT" ]]; then
    ok=false; detail="lifecycle-report.json missing at $REPORT"
  elif ! jq -e . "$REPORT" >/dev/null 2>&1; then
    ok=false; detail="lifecycle-report.json is not valid JSON"
  else
    for key in run_id executed_at archived deleted retained_in_stage errors; do
      jq -e ".${key}" "$REPORT" >/dev/null 2>&1 || { ok=false; detail="missing key in report: ${key}"; break; }
    done
  fi
fi

if $ok; then
  echo "Validation Success linux stage=$stage_count archive=$arch_count report=valid"
else
  echo "Validation Failed linux $detail"
fi
'@
        $linuxResult = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $linuxVm -CommandId "RunShellScript" -ScriptString $linuxScript -ErrorAction SilentlyContinue
        $linuxOutput = if ($linuxResult) { $linuxResult.Value[0].Message } else { "" }

        # --- Windows probe ---
        $winScript = @'
$stage  = 'C:\applogs\stage'
$arch   = 'C:\applogs\archive'
$report = Join-Path $arch 'lifecycle-report.json'
$ok = $true; $detail = ""

$stageFiles = @(Get-ChildItem $stage -Filter 'app-*.log' -File -ErrorAction SilentlyContinue)
if ($stageFiles.Count -gt 7) { $ok = $false; $detail = "staging has $($stageFiles.Count) files; expected <=7" }

if ($ok) {
    $archFiles = @(Get-ChildItem $arch -Filter 'app-*.zip' -File -ErrorAction SilentlyContinue)
    if ($archFiles.Count -lt 15 -or $archFiles.Count -gt 30) {
        $ok = $false; $detail = "archive has $($archFiles.Count) compressed files; expected 15-30 (8-30 day band)"
    }
}

if ($ok) {
    $today = (Get-Date).Date
    foreach ($f in $archFiles) {
        if ($f.Name -match '^app-(\d{4})-(\d{2})-(\d{2})\.zip$') {
            $d = [datetime]::ParseExact("$($Matches[1])-$($Matches[2])-$($Matches[3])", 'yyyy-MM-dd', $null)
            $age = ($today - $d).Days
            if ($age -gt 30) {
                $ok = $false; $detail = "archive still contains $($f.Name) (age $age days > 30)"; break
            }
        }
    }
}

if ($ok) {
    if (-not (Test-Path $report)) {
        $ok = $false; $detail = "lifecycle-report.json missing at $report"
    } else {
        try {
            $obj = Get-Content $report -Raw | ConvertFrom-Json
            foreach ($key in @('run_id','executed_at','archived','deleted','retained_in_stage','errors')) {
                if (-not ($obj.PSObject.Properties.Name -contains $key)) {
                    $ok = $false; $detail = "missing key in report: $key"; break
                }
            }
        } catch {
            $ok = $false; $detail = "lifecycle-report.json is not valid JSON: $_"
        }
    }
}

if ($ok) { Write-Output "Validation Success windows stage=$($stageFiles.Count) archive=$($archFiles.Count) report=valid" }
else     { Write-Output "Validation Failed windows $detail" }
'@
        $winResult = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $winVm -CommandId "RunPowerShellScript" -ScriptString $winScript -ErrorAction SilentlyContinue
        $winOutput = if ($winResult) { $winResult.Value[0].Message } else { "" }

        if ($linuxOutput -match "Validation Success" -or $winOutput -match "Validation Success") {
            $platform = if ($linuxOutput -match "Validation Success") { "linux" } else { "windows" }
            $message = @{ Status = "Succeeded"; Message = "Log lifecycle automation validated on $platform. Archive in 8-30 day band; staging within 7-day window; lifecycle-report.json schema-valid." } | ConvertTo-Json
        } else {
            $detail = "Linux: $linuxOutput | Windows: $winOutput"
            $message = @{ Status = "Failed"; Message = "Log lifecycle validation failed on both VMs. Expected: staging retains <=7 day files; archive contains 15-30 compressed files (8-30 day band); no archive files >30 days; lifecycle-report.json valid with required keys. Details: $detail" } | ConvertTo-Json
        }
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{ StatusCode = [System.Net.HttpStatusCode]::OK; Body = $message })
        $stopRetry = $true
    }
    catch {
        if ($retryCount -ge $maxRetries) {
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{ StatusCode = [System.Net.HttpStatusCode]::OK; Body = (@{ Status = "Failed"; Message = "Retry exhausted: $_" } | ConvertTo-Json) })
            $stopRetry = $true
        } else { Start-Sleep -Seconds 60; $retryCount++ }
    }
} while ($stopRetry -eq $false)
