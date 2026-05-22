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
REPORT=/var/log/health/health-report.json
ok=true
detail=""
if [[ ! -f "$REPORT" ]]; then
  ok=false; detail="report file missing at $REPORT"
else
  # Parses as JSON
  if ! jq -e . "$REPORT" >/dev/null 2>&1; then
    ok=false; detail="report is not valid JSON"
  else
    # Required top-level keys
    for key in run_id collected_at hostname disk memory cpu_load_avg_1m services alerts; do
      jq -e ".${key}" "$REPORT" >/dev/null 2>&1 || { ok=false; detail="missing key: ${key}"; break; }
    done
    # services length
    if $ok; then
      svc_len=$(jq '.services | length' "$REPORT")
      [[ "$svc_len" -eq 3 ]] || { ok=false; detail="services length expected 3, got $svc_len"; }
    fi
    # alerts is array
    if $ok; then
      alerts_type=$(jq -r '.alerts | type' "$REPORT")
      [[ "$alerts_type" == "array" ]] || { ok=false; detail="alerts is not an array (got $alerts_type)"; }
    fi
    # Idempotency: re-run and count
    if $ok; then
      script_path=""
      for p in /usr/local/bin/health-check.sh /home/azureuser/automation/health-check.sh; do
        [[ -x "$p" ]] && script_path="$p" && break
      done
      if [[ -n "$script_path" ]]; then
        "$script_path" >/dev/null 2>&1 || true
        files_after=$(find /var/log/health -maxdepth 1 -name 'health-report*.json' -type f 2>/dev/null | wc -l)
        [[ "$files_after" -eq 1 ]] || { ok=false; detail="idempotency failed: expected 1 report file, found $files_after"; }
      fi
    fi
  fi
fi
if $ok; then
  echo "Validation Success linux all required keys present, services=3, alerts=array, idempotent"
else
  echo "Validation Failed linux $detail"
fi
'@
        $linuxResult = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $linuxVm -CommandId "RunShellScript" -ScriptString $linuxScript -ErrorAction SilentlyContinue
        $linuxOutput = if ($linuxResult) { $linuxResult.Value[0].Message } else { "" }

        # --- Windows probe ---
        $winScript = @'
$report = "C:\ops\health\health-report.json"
$ok = $true; $detail = ""
if (-not (Test-Path $report)) {
    $ok = $false; $detail = "report file missing at $report"
} else {
    try {
        $obj = Get-Content $report -Raw | ConvertFrom-Json
    } catch {
        $ok = $false; $detail = "report is not valid JSON: $_"
    }
    if ($ok) {
        foreach ($key in @('run_id','collected_at','hostname','disk','memory','cpu_load_avg_1m','services','alerts')) {
            if (-not ($obj.PSObject.Properties.Name -contains $key)) {
                $ok = $false; $detail = "missing key: $key"; break
            }
        }
    }
    if ($ok -and $obj.services.Count -ne 3) {
        $ok = $false; $detail = "services length expected 3, got $($obj.services.Count)"
    }
    if ($ok -and -not ($obj.alerts -is [System.Array] -or $obj.alerts -is [System.Collections.IList])) {
        $ok = $false; $detail = "alerts is not an array"
    }
    if ($ok) {
        $candidate = @(
            'C:\Program Files\BankAutomation\health-check.ps1',
            'C:\bank\automation\health-check.ps1'
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($candidate) {
            powershell -ExecutionPolicy Bypass -File $candidate | Out-Null
            $files = Get-ChildItem 'C:\ops\health' -Filter 'health-report*.json' -File -ErrorAction SilentlyContinue
            if ($files.Count -ne 1) {
                $ok = $false; $detail = "idempotency failed: expected 1 report file, found $($files.Count)"
            }
        }
    }
}
if ($ok) { Write-Output "Validation Success windows all required keys present, services=3, alerts=array, idempotent" }
else     { Write-Output "Validation Failed windows $detail" }
'@
        $winResult = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $winVm -CommandId "RunPowerShellScript" -ScriptString $winScript -ErrorAction SilentlyContinue
        $winOutput = if ($winResult) { $winResult.Value[0].Message } else { "" }

        if ($linuxOutput -match "Validation Success" -or $winOutput -match "Validation Success") {
            $platform = if ($linuxOutput -match "Validation Success") { "linux" } else { "windows" }
            $message = @{ Status = "Succeeded"; Message = "System health reporter validated on $platform. Report file exists, schema-complete, idempotent." } | ConvertTo-Json
        } else {
            $detail = "Linux: $linuxOutput | Windows: $winOutput"
            $message = @{ Status = "Failed"; Message = "Health reporter validation failed on both VMs. Expected: health-report.json at the configured path with required keys (run_id, collected_at, hostname, disk, memory, cpu_load_avg_1m, services[3], alerts[]). Details: $detail" } | ConvertTo-Json
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
