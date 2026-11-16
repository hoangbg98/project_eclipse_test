# Tool phát quà của QTV (nạp bằng chuyển khoản QR thủ công).
# Chạy trên máy đang chạy máy chủ. Ví dụ:
#   powershell -ExecutionPolicy Bypass -File server\grant.ps1 -Code 48291735                      (chỉ tra cứu)
#   powershell -ExecutionPolicy Bypass -File server\grant.ps1 -Code 48291735 -Gems 600 -Ref FT26321ABC -Operator hoang -Note "goi 50k"
# Theo gói trong bảng giá (data\shop\topup_packs.json): số Ngọc lấy từ gói, -Paid là số tiền đã nhận (phải đúng giá gói):
#   powershell -ExecutionPolicy Bypass -File server\grant.ps1 -Code 48291735 -Pack gems_660 -Paid 140000 -Ref FT26321ABC -Operator hoang
#   powershell -ExecutionPolicy Bypass -File server\grant.ps1 -List                                   (xem bảng giá)
# -Ref: mã giao dịch trong sao kê ngân hàng. Cùng -Ref chỉ phát được MỘT lần (máy chủ từ chối lần hai).
# -Yes: bỏ bước xác nhận (dùng cho script). Số âm = thu hồi (vd chuyển khoản lỗi).
param(
    [string]$Code = "",
    [string]$Pack = "",
    [int64]$Paid = 0,
    [switch]$List,
    [switch]$Force,
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

$packFile = Join-Path (Split-Path -Parent $PSScriptRoot) "data\shop\topup_packs.json"
$packs = @((Get-Content $packFile -Raw -Encoding UTF8 | ConvertFrom-Json).packs)

if ($List) {
    foreach ($k in $packs) { Write-Output ("  {0,-10} {1,5} {2,-5} = {3,10:N0} đ" -f $k.id, $k.amount, $k.currency, $k.price) }
    exit 0
}
if (-not $Code) { Write-Output "Cần -Code <mã người chơi 8 số> (hoặc -List để xem bảng giá)."; exit 2 }

function Show-Player($p) {
    $w = $p.wallet
    Write-Output ("  Mã {0} | tên '{1}' | gems {2} | gold {3}" -f $p.code, $p.username, [int]$w.gems, [int]$w.gold)
}

$player = Call-Rpc "admin_find" @{ code = $Code }
Write-Output "Người chơi:"
Show-Player $player

if ($Pack) {
    if ($Gems -ne 0 -or $Gold -ne 0) { Write-Output "Dùng -Pack thì không nhập -Gems / -Gold."; exit 2 }
    $k = $packs | Where-Object { $_.id -eq $Pack } | Select-Object -First 1
    if (-not $k) { Write-Output "Không có gói '$Pack'. Xem: grant.ps1 -List"; exit 2 }
    if ($k.currency -ne "gems") { Write-Output "Gói '$Pack' chưa hỗ trợ (loại $($k.currency))."; exit 2 }
    if ($Paid -le 0) { Write-Output ("Cần -Paid <số tiền đã nhận>; gói {0} giá {1:N0} đ." -f $Pack, $k.price); exit 2 }
    if ($Paid -ne $k.price -and -not $Force) {
        Write-Output ("SỐ TIỀN KHÔNG KHỚP: đã nhận {0:N0} đ, gói {1} giá {2:N0} đ. Kiểm tra lại sao kê (hoặc dùng -Force nếu đã thỏa thuận)." -f $Paid, $Pack, $k.price)
        exit 1
    }
    $Gems = [int]$k.amount
    if (-not $Note) { $Note = "gói $Pack, nhận $Paid đ" }
}
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
$after = Call-Rpc "admin_grant" @{ code = $Code; changes = $changes; ref = $Ref; operator = $Operator; note = $Note; pack = $Pack; paid = $Paid }
Write-Output "Đã phát. Sau khi phát:"
Show-Player $after
