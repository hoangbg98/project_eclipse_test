# Tắt máy chủ thử nghiệm (Nakama rồi PostgreSQL). Dữ liệu giữ nguyên trong server\.runtime\pgdata.
# Chạy: powershell -ExecutionPolicy Bypass -File server\stop_local.ps1
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$rt = Join-Path $PSScriptRoot ".runtime"

$pidFile = Join-Path $rt "nakama.pid"
if (Test-Path $pidFile) {
    $p = Get-Process -Id ([int](Get-Content $pidFile)) -ErrorAction SilentlyContinue
    if ($p -and $p.ProcessName -eq "nakama") {
        Stop-Process -Id $p.Id -Confirm:$false
        Write-Output "Đã tắt Nakama (PID $($p.Id))."
    }
    Remove-Item -Force $pidFile
}
$tunnelPid = Join-Path $rt "tunnel.pid"
if (Test-Path $tunnelPid) {
    $t = Get-Process -Id ([int](Get-Content $tunnelPid)) -ErrorAction SilentlyContinue
    if ($t -and $t.ProcessName -eq "cloudflared") {
        Stop-Process -Id $t.Id -Confirm:$false
        Write-Output "Đã tắt đường hầm (PID $($t.Id))."
    }
    Remove-Item -Force $tunnelPid
}
$pgData = Join-Path $rt "pgdata"
& (Join-Path $rt "pgsql\bin\pg_ctl.exe") status -D "$pgData" *> $null
if ($LASTEXITCODE -eq 0) {
    & (Join-Path $rt "pgsql\bin\pg_ctl.exe") stop -D "$pgData" -m fast -w
}
Write-Output "Đã tắt máy chủ."
