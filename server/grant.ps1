# Tool phát quà / xử lý nạp của QTV (nạp bằng chuyển khoản QR thủ công). Chạy trên máy đang chạy máy chủ. Ví dụ:
#   powershell -ExecutionPolicy Bypass -File server\grant.ps1 -List                                      (xem bảng giá)
#   powershell -ExecutionPolicy Bypass -File server\grant.ps1 -Code 48291735                             (tra cứu người chơi)
#   powershell -ExecutionPolicy Bypass -File server\grant.ps1 -Code 48291735 -State                      (thưởng lần đầu đã dùng, thẻ tháng, lịch sử nạp)
# Nạp theo gói (bảng giá data\shop\topup_packs.json, tự đẩy lên máy chủ). -Paid = số tiền đã nhận trong sao kê, phải đúng giá gói:
#   powershell -ExecutionPolicy Bypass -File server\grant.ps1 -Code 48291735 -Pack gems_660 -Paid 140000 -Ref FT26321ABC -Operator hoang
#   (máy chủ tự cộng thưởng nạp lần đầu; thẻ tháng: -Pack card_30; -Force bỏ qua kiểm số tiền khi đã thỏa thuận)
# Mở lại thưởng nạp lần đầu cho mọi người (kỳ mới):
#   powershell -ExecutionPolicy Bypass -File server\grant.ps1 -ResetFirstBonus -Operator hoang
# Sửa thẻ tháng khi có sự cố:  ... -Code 48291735 -CardLeft 20 -CardTotal 10 -CardDay 2026-11-15 -Operator hoang
# Phát tay (không theo gói):
#   powershell -ExecutionPolicy Bypass -File server\grant.ps1 -Code 48291735 -Gems 600 -Ref FT26321ABC -Operator hoang -Note "bù lỗi"
# -Ref: mã giao dịch trong sao kê ngân hàng. Cùng -Ref chỉ phát được MỘT lần (máy chủ từ chối lần hai).
# -Yes: bỏ bước xác nhận (dùng cho script). Số âm = thu hồi (vd chuyển khoản lỗi).
param(
    [string]$Code = "",
    [string]$Pack = "",
    [int64]$Paid = 0,
    [switch]$List,
    [switch]$State,
    [switch]$Force,
    [switch]$ResetFirstBonus,
    [int]$CardLeft = -1,
    [int]$CardTotal = -1,
    [string]$CardDay = "",
    [int]$Gems = 0,
    [int]$Gold = 0,
    [int]$Corona = 0,
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
    $json = $body | ConvertTo-Json -Compress -Depth 10
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
$catalog = Get-Content $packFile -Raw -Encoding UTF8 | ConvertFrom-Json
$packs = @($catalog.packs)

function Show-Player($p) {
    $w = $p.wallet
    Write-Output ("  Mã {0} | tên '{1}' | gems {2} | corona {3} | gold {4}" -f $p.code, $p.username, [int]$w.gems, [int]$w.corona, [int]$w.gold)
}

if ($List) {
    foreach ($k in $packs) {
        $what = if ($k.kind -eq "card") { "thẻ tháng $($catalog.card.days) ngày" } else { "{0,5} {1}" -f $k.amount, $k.currency }
        $price = if ($null -eq $k.price) { "chưa có giá" } else { "{0,10:N0} đ" -f $k.price }
        $bonus = if ($k.first_bonus) { "  (thưởng nạp lần đầu)" } else { "" }
        Write-Output ("  {0,-12} {1,-22} = {2}{3}" -f $k.id, $what, $price, $bonus)
    }
    exit 0
}
if ($ResetFirstBonus) {
    if (-not $Operator) { Write-Output "Cần -Operator (tên QTV)."; exit 2 }
    $r = Call-Rpc "admin_topup_reset" @{ operator = $Operator; note = $Note }
    Write-Output "Đã mở lại thưởng nạp lần đầu cho mọi người chơi (kỳ $($r.epoch))."
    exit 0
}
if (-not $Code) { Write-Output "Cần -Code <mã người chơi 8 số> (hoặc -List để xem bảng giá)."; exit 2 }

$player = Call-Rpc "admin_find" @{ code = $Code }
Write-Output "Người chơi:"
Show-Player $player

if ($State) {
    $st = Call-Rpc "admin_topup_state" @{ code = $Code }
    Write-Output ("Kỳ thưởng nạp lần đầu hiện tại: {0}" -f $st.epoch)
    $bought = @($st.bought.PSObject.Properties | ForEach-Object { "{0} (kỳ {1})" -f $_.Name, $_.Value })
    Write-Output ("Đã nạp (dùng thưởng lần đầu): {0}" -f $(if ($bought.Count) { $bought -join ", " } else { "chưa có" }))
    Write-Output ("Thẻ tháng: còn {0} lượt, đã nhận {1} lượt, lần nhận gần nhất {2}" -f $st.card.claims_left, $st.card.claims_total, $(if ($st.card.last_claim_day) { $st.card.last_claim_day } else { "chưa" }))
    foreach ($l in $st.log) {
        $t = [DateTimeOffset]::FromUnixTimeSeconds([int64]$l.t).LocalDateTime.ToString("yyyy-MM-dd HH:mm")
        Write-Output ("  {0}  {1}  +{2} (+{3} thưởng)  {4:N0} đ  ref {5}" -f $t, $l.pack, $l.base, $l.bonus, $l.paid, $l.ref)
    }
    exit 0
}
if ($CardLeft -ge 0 -or $CardTotal -ge 0 -or $CardDay) {
    if (-not $Operator) { Write-Output "Cần -Operator (tên QTV)."; exit 2 }
    $body = @{ code = $Code; operator = $Operator }
    if ($CardLeft -ge 0) { $body["claims_left"] = $CardLeft }
    if ($CardTotal -ge 0) { $body["claims_total"] = $CardTotal }
    if ($CardDay) { $body["last_claim_day"] = $CardDay }
    $r = Call-Rpc "admin_card_set" $body
    Write-Output ("Thẻ tháng sau khi sửa: còn {0} lượt, đã nhận {1}, lần nhận gần nhất '{2}'" -f $r.card.claims_left, $r.card.claims_total, $r.card.last_claim_day)
    exit 0
}

# ----- Nạp theo gói -----
if ($Pack) {
    if ($Gems -ne 0 -or $Gold -ne 0 -or $Corona -ne 0) { Write-Output "Dùng -Pack thì không nhập -Gems / -Gold / -Corona."; exit 2 }
    if (-not $Ref -or -not $Operator) { Write-Output "Cần -Ref (mã giao dịch ngân hàng) và -Operator (tên QTV)."; exit 2 }
    $k = $packs | Where-Object { $_.id -eq $Pack } | Select-Object -First 1
    if (-not $k) { Write-Output "Không có gói '$Pack'. Xem: grant.ps1 -List"; exit 2 }
    if ($null -eq $k.price) { Write-Output "Gói '$Pack' chưa có giá (chưa mở bán): điền price trong data\shop\topup_packs.json."; exit 2 }
    if ($Paid -le 0) { Write-Output ("Cần -Paid <số tiền đã nhận>; gói {0} giá {1:N0} đ." -f $Pack, $k.price); exit 2 }
    if ($Paid -ne $k.price -and -not $Force) {
        Write-Output ("SỐ TIỀN KHÔNG KHỚP: đã nhận {0:N0} đ, gói {1} giá {2:N0} đ. Kiểm tra lại sao kê (hoặc dùng -Force nếu đã thỏa thuận)." -f $Paid, $Pack, $k.price)
        exit 1
    }
    Write-Output ("Phát gói {0} | nhận {1:N0} đ | ref {2} | QTV {3}" -f $Pack, $Paid, $Ref, $Operator)
    if (-not $Yes) {
        $ok = Read-Host "Gõ YES để phát"
        if ($ok -ne "YES") { Write-Output "Đã hủy."; exit 1 }
    }
    $null = Call-Rpc "admin_set_packs" @{ catalog = $catalog }   # đồng bộ bảng giá lên máy chủ
    $after = Call-Rpc "admin_topup" @{ code = $Code; pack = $Pack; paid = $Paid; ref = $Ref; operator = $Operator; note = $Note; force = [bool]$Force }
    $g = $after.granted
    if ($g.card_days -gt 0) { Write-Output ("Đã phát: thẻ tháng +{0} lượt nhận." -f $g.card_days) }
    else { Write-Output ("Đã phát: +{0} {1}{2}" -f $g.base, $k.currency, $(if ($g.bonus -gt 0) { " (+$($g.bonus) thưởng nạp lần đầu)" } else { "" })) }
    Write-Output "Sau khi phát:"
    Show-Player $after
    exit 0
}

# ----- Phát tay -----
if ($Gems -eq 0 -and $Gold -eq 0 -and $Corona -eq 0) { exit 0 }
if (-not $Ref -or -not $Operator) {
    Write-Output "Phát quà cần -Ref (mã giao dịch ngân hàng) và -Operator (tên QTV)."
    exit 2
}
$changes = @{}
if ($Gems -ne 0) { $changes["gems"] = $Gems }
if ($Gold -ne 0) { $changes["gold"] = $Gold }
if ($Corona -ne 0) { $changes["corona"] = $Corona }
Write-Output ("Phát: {0} | ref {1} | QTV {2} | ghi chú '{3}'" -f ($changes | ConvertTo-Json -Compress), $Ref, $Operator, $Note)
if (-not $Yes) {
    $ok = Read-Host "Gõ YES để phát"
    if ($ok -ne "YES") { Write-Output "Đã hủy."; exit 1 }
}
$after = Call-Rpc "admin_grant" @{ code = $Code; changes = $changes; ref = $Ref; operator = $Operator; note = $Note }
Write-Output "Đã phát. Sau khi phát:"
Show-Player $after
