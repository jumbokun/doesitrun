# Stop probe harness processes and their headless agent sessions (never this script itself).
Get-CimInstance Win32_Process |
  Where-Object {
    $_.ProcessId -ne $PID -and $_.CommandLine -and
    ($_.CommandLine -match 'run_probe\.py' -or $_.CommandLine -match 'box_mcp\.py' -or
     $_.CommandLine -match 'You are setting up a GitHub repository')
  } |
  ForEach-Object {
    Write-Output ("kill {0} {1}" -f $_.ProcessId, $_.Name)
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
  }
