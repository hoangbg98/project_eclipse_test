# Tool phát quà của QTV (nạp bằng chuyển khoản QR thủ công).
# Chạy trên máy đang chạy máy chủ. Ví dụ:
#   powershell -ExecutionPolicy Bypass -File server\grant.ps1 -Code 48291735                      (chỉ tra cứu)
#   powershell -ExecutionPolicy Bypass -File server\grant.ps1 -Code 48291735 -Gems 600 -Ref FT26321ABC -Operator hoang -Note "goi 50k"
# -Ref: mã giao dịch trong sao kê ngân hàng. Cùng -Ref chỉ phát được MỘT lần (máy chủ từ chối lần hai).
# -Yes: bỏ bước xác nhận (dùng cho script). Số âm = thu hồi (vd chuyển khoản lỗi).
param(
    [Parameter(Mandatory = $true)][string]$Code,
    [int]$Gems = 0,
    [int]$Gold = 0,
    [string]$Ref = "",
    [string]$Operator = "",
    [string]$Note = "",
    [string]$ServerUrl = "http://127.0.0.1:7350",
    [switch]$Yes
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

function Show-Player($p) {
    $w = $p.wallet
    Write-Output ("  Mã {0} | tên '{1}' | gems {2} | gold {3}" -f $p.code, $p.username, [int]$w.gems, [int]$w.gold)
}

$player = Call-Rpc "admin_find" @{ code = $Code }
Write-Output "Người chơi:"
Show-Player $player

if ($Gems -eq 0 -and $Gold -eq 0) { exit 0 }
if (-not $Ref -or -not $Operator) {
    Write-Output "Phát quà cần -Ref (mã giao dịch ngân hàng) và -Operator (tên QTV)."
    exit 2
}
$changes = @{}
if ($Gems -ne 0) { $changes["gems"] = $Gems }
if ($Gold -ne 0) { $changes["gold"] = $Gold }
Write-Output ("Phát: {0} | ref {1} | QTV {2} | ghi chú '{3}'" -f ($changes | ConvertTo-Json -Compress), $Ref, $Operator, $Note)
if (-not $Yes) {
    $ok = Read-Host "Gõ YES để phát"
    if ($ok -ne "YES") { Write-Output "Đã hủy."; exit 1 }
}
$after = Call-Rpc "admin_grant" @{ code = $Code; changes = $changes; ref = $Ref; operator = $Operator; note = $Note }
Write-Output "Đã phát. Sau khi phát:"
Show-Player $after
