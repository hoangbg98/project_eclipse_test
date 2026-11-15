# Mở đường hầm tạm trycloudflare.com tới Nakama trên máy này (không cần tài khoản Cloudflare, không mở port router).
# Chạy: powershell -ExecutionPolicy Bypass -File server\tunnel.ps1
# In ra địa chỉ https://....trycloudflare.com: gửi cho người thử, họ dán vào ô "Máy chủ" ở màn Trực tuyến.
# Địa chỉ ĐỔI mỗi lần chạy lại; chỉ dùng để thử. Mở cổng vào 7360 (Nakama API + /music/), KHÔNG mở trang quản trị 7351.
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$rt = Join-Path $PSScriptRoot ".runtime"
$cf = Join-Path $rt "cloudflared.exe"
$log = Join-Path $rt "logs\tunnel.log"
New-Item -ItemType Directory -Force (Join-Path $rt "logs") | Out-Null
if (Test-Path $log) { Remove-Item -Force $log }

$p = Start-Process -FilePath $cf -WindowStyle Hidden -PassThru `
    -ArgumentList @("tunnel", "--no-autoupdate", "--url", "http://127.0.0.1:7360", "--logfile", $log)
Set-Content -Encoding ascii (Join-Path $rt "tunnel.pid") $p.Id

$url = $null
for ($i = 0; $i -lt 40 -and -not $url; $i++) {
    Start-Sleep -Seconds 1
    if (Test-Path $log) {
        $m = Select-String -Path $log -Pattern "https://[a-z0-9-]+\.trycloudflare\.com" | Select-Object -First 1
        if ($m) { $url = $m.Matches[0].Value }
    }
    if ($p.HasExited) { break }
}
if (-not $url) {
    Write-Output "Không lấy được địa chỉ đường hầm, xem $log"
    exit 1
}
Set-Content -Encoding ascii (Join-Path $rt "tunnel_url.txt") $url
Write-Output "Đường hầm đang chạy (PID $($p.Id)):"
Write-Output "  $url"
Write-Output "Gửi địa chỉ này cho người thử. Tắt: server\stop_local.ps1"
