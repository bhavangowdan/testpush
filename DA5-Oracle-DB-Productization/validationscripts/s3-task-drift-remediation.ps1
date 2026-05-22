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
REPORT=/var/log/drift/drift-report.json
AUDIT=/var/log/drift/audit.log
ok=true
detail=""

# Drift report exists and shows drifted: 0
if [[ ! -f "$REPORT" ]]; then
  ok=false; detail="drift-report.json missing at $REPORT"
elif ! jq -e . "$REPORT" >/dev/null 2>&1; then
  ok=false; detail="drift-report.json is not valid JSON"
else
  drifted=$(jq -r '.drifted' "$REPORT")
  [[ "$drifted" == "0" ]] || { ok=false; detail="drift-report shows drifted=$drifted, expected 0 after remediation"; }
fi

# Audit log exists; every line is valid JSON
if $ok; then
  if [[ ! -f "$AUDIT" ]]; then
    ok=false; detail="audit.log missing at $AUDIT"
  else
    bad_lines=0
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      echo "$line" | jq -e . >/dev/null 2>&1 || bad_lines=$((bad_lines+1))
    done < "$AUDIT"
    [[ "$bad_lines" -eq 0 ]] || { ok=false; detail="audit.log has $bad_lines lines that are not valid JSON"; }
  fi
fi

# Audit log contains create action (for directory) and start action (for service)
if $ok; then
  create_count=$(grep -c '"action":"create"' "$AUDIT" 2>/dev/null || echo 0)
  start_count=$(grep -c '"action":"start"' "$AUDIT" 2>/dev/null || echo 0)
  [[ "$create_count" -ge 1 ]] || { ok=false; detail="audit.log missing 'create' action entry"; }
  [[ "$start_count"  -ge 1 ]] || { ok=false; detail="audit.log missing 'start' action entry"; }
fi

if $ok; then
  echo "Validation Success linux drifted=0 audit=valid create=$create_count start=$start_count"
else
  echo "Validation Failed linux $detail"
fi
'@
        $linuxResult = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $linuxVm -CommandId "RunShellScript" -ScriptString $linuxScript -ErrorAction SilentlyContinue
        $linuxOutput = if ($linuxResult) { $linuxResult.Value[0].Message } else { "" }

        # --- Windows probe ---
        $winScript = @'
$report = 'C:\ops\drift\drift-report.json'
$audit  = 'C:\ops\drift\audit.log'
$ok = $true; $detail = ""

if (-not (Test-Path $report)) {
    $ok = $false; $detail = "drift-report.json missing at $report"
} else {
    try {
        $obj = Get-Content $report -Raw | ConvertFrom-Json
        if ($obj.drifted -ne 0) {
            $ok = $false; $detail = "drift-report shows drifted=$($obj.drifted), expected 0 after remediation"
        }
    } catch {
        $ok = $false; $detail = "drift-report.json is not valid JSON: $_"
    }
}

if ($ok) {
    if (-not (Test-Path $audit)) {
        $ok = $false; $detail = "audit.log missing at $audit"
    } else {
        $badLines = 0
        Get-Content $audit | ForEach-Object {
            if ($_.Trim().Length -eq 0) { return }
            try { $null = $_ | ConvertFrom-Json } catch { $badLines++ }
        }
        if ($badLines -gt 0) {
            $ok = $false; $detail = "audit.log has $badLines lines that are not valid JSON"
        }
    }
}

if ($ok) {
    $content = Get-Content $audit -Raw
    $createCount = ([regex]::Matches($content, '"action"\s*:\s*"create"')).Count
    $startCount  = ([regex]::Matches($content, '"action"\s*:\s*"start"')).Count
    if ($createCount -lt 1) { $ok = $false; $detail = "audit.log missing 'create' action entry" }
    elseif ($startCount  -lt 1) { $ok = $false; $detail = "audit.log missing 'start' action entry" }
}

if ($ok) { Write-Output "Validation Success windows drifted=0 audit=valid create=$createCount start=$startCount" }
else     { Write-Output "Validation Failed windows $detail" }
'@
        $winResult = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $winVm -CommandId "RunPowerShellScript" -ScriptString $winScript -ErrorAction SilentlyContinue
        $winOutput = if ($winResult) { $winResult.Value[0].Message } else { "" }

        if ($linuxOutput -match "Validation Success" -or $winOutput -match "Validation Success") {
            $platform = if ($linuxOutput -match "Validation Success") { "linux" } else { "windows" }
            $message = @{ Status = "Succeeded"; Message = "Drift detection & remediation validated on $platform. drift-report.json shows drifted=0; audit.log has valid JSON Lines with create+start actions." } | ConvertTo-Json
        } else {
            $detail = "Linux: $linuxOutput | Windows: $winOutput"
            $message = @{ Status = "Failed"; Message = "Drift validation failed on both VMs. Expected: drift-report.json with drifted=0 after remediation; audit.log with every line as valid JSON; at least one 'create' and one 'start' action entry. Details: $detail" } | ConvertTo-Json
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
