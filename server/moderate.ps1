# Tool kiểm duyệt chat của QTV. Chạy trên máy đang chạy máy chủ. Ví dụ:
#   powershell -ExecutionPolicy Bypass -File server\moderate.ps1 -Reports                       (báo cáo chưa xử lý)
#   powershell -ExecutionPolicy Bypass -File server\moderate.ps1 -Resolve <id báo cáo> -Operator ten_qtv
#   powershell -ExecutionPolicy Bypass -File server\moderate.ps1 -Mute 48291735 -Minutes 60 -Reason "spam" -Operator ten_qtv
#   powershell -ExecutionPolicy Bypass -File server\moderate.ps1 -Mute 48291735 -Minutes 0 -Operator ten_qtv     (gỡ cấm)
# -Mute nhận MÃ NGƯỜI CHƠI (8 số, xem ở báo cáo hoặc màn Tài khoản). Cấm chat áp cho cả phòng thế giới và nhắn riêng.
param(
    [switch]$Reports,
    [switch]$All,
    [string]$Resolve = "",
    [string]$Mute = "",
    [int]$Minutes = -1,
    [string]$Reason = "",
    [string]$Operator = "",
    [string]$ServerUrl = "http://127.0.0.1:7350"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$secrets = Get-Content (Join-Path $PSScriptRoot ".runtime\secrets.json") -Raw | ConvertFrom-Json

function Call-Rpc($id, $body) {
    $uri = "$ServerUrl/v2/rpc/$($id)?http_key=$($secrets.http_key)&unwrap"
    $json = $body | ConvertTo-Json -Compress
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($json)
        return Invoke-RestMethod -Method Post -Uri $uri -Body $bytes -ContentType "application/json; charset=utf-8" -TimeoutSec 15
    } catch {
        $msg = $_.ErrorDetails.Message
        if ($msg) { try { $msg = ($msg | ConvertFrom-Json).message } catch { } }
        if (-not $msg) { $msg = $_.Exception.Message }
        $msg = ($msg -replace '^Error: ', '') -replace ' at \w+ \(index\.js.*$', ''
        Write-Output "LỖI: $msg"
        exit 1
    }
}

if ($Reports) {
    $r = Call-Rpc "admin_chat_reports" @{ limit = 50; all = [bool]$All }
    if (-not $r.reports -or $r.reports.Count -eq 0) { Write-Output "Không có báo cáo nào chưa xử lý."; exit 0 }
    foreach ($x in $r.reports) {
        $t = [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$x.time).LocalDateTime.ToString("yyyy-MM-dd HH:mm")
        $st = if ($x.resolved) { "đã xử lý" } else { "CHƯA xử lý" }
        Write-Output ("[{0}] {1} | {2} báo cáo {3} | lý do: {4} | {5}" -f $x.id, $t, $x.reporter_name, $x.target_name, $x.reason, $st)
        if ($x.text) { Write-Output ("    tin: {0}" -f $x.text) }
    }
    Write-Output "Tên tài khoản bị báo cáo → mã người chơi: tìm trong trang quản trị Nakama (Accounts) hoặc dùng grant.ps1 -Code <mã>."
    exit 0
}
if ($Resolve) {
    if (-not $Operator) { Write-Output "Cần -Operator (tên QTV)."; exit 2 }
    $null = Call-Rpc "admin_chat_resolve" @{ id = $Resolve; operator = $Operator }
    Write-Output "Đã đánh dấu đã xử lý: $Resolve"
    exit 0
}
if ($Mute) {
    if ($Minutes -lt 0 -or -not $Operator) { Write-Output "Cần -Minutes (0 = gỡ cấm) và -Operator."; exit 2 }
    $r = Call-Rpc "admin_chat_mute" @{ code = $Mute; minutes = $Minutes; reason = $Reason; operator = $Operator }
    if ($Minutes -eq 0) { Write-Output "Đã gỡ cấm chat cho mã $Mute." }
    else {
        $until = [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$r.muted_until).LocalDateTime.ToString("yyyy-MM-dd HH:mm")
        Write-Output "Đã cấm chat mã $Mute đến $until."
    }
    exit 0
}
Write-Output "Dùng một trong: -Reports | -Resolve <id> | -Mute <mã> -Minutes <số>. Xem đầu file để biết ví dụ."
