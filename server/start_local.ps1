# Bật máy chủ thử nghiệm trên máy này: PostgreSQL (cổng 5433) + Nakama (API 7350, trang quản trị 7351).
# Chạy: powershell -ExecutionPolicy Bypass -File server\start_local.ps1
# Mặc định chỉ nghe trên 127.0.0.1 (máy khác vào qua đường hầm: server\tunnel.ps1).
# -Lan: mở API 7350 cho máy cùng mạng LAN (trang quản trị 7351 vẫn chỉ trên máy này).
param([switch]$Lan)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$server = $PSScriptRoot
$root = Split-Path -Parent $server
$rt = Join-Path $server ".runtime"
$pgBin = Join-Path $rt "pgsql\bin"
$pgData = Join-Path $rt "pgdata"
$logs = Join-Path $rt "logs"
$nakama = Join-Path $rt "nakama\nakama.exe"
$PgPort = 5433

if (-not (Test-Path $nakama) -or -not (Test-Path (Join-Path $pgData "PG_VERSION"))) {
    Write-Output "Chưa cài. Chạy trước: powershell -ExecutionPolicy Bypass -File server\setup_local.ps1"
    exit 2
}
New-Item -ItemType Directory -Force $logs | Out-Null
$s = Get-Content (Join-Path $rt "secrets.json") -Raw | ConvertFrom-Json
$cfg = Get-Content (Join-Path $root "data\config\online_config.json") -Raw -Encoding UTF8 | ConvertFrom-Json

# 1. PostgreSQL
& (Join-Path $pgBin "pg_ctl.exe") status -D "$pgData" *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Output "Bật PostgreSQL (cổng $PgPort)..."
    & (Join-Path $pgBin "pg_ctl.exe") start -D "$pgData" -l (Join-Path $logs "postgres.log") -w `
        -o "-p $PgPort -c listen_addresses=127.0.0.1"
    if ($LASTEXITCODE -ne 0) { throw "Không bật được PostgreSQL, xem $logs\postgres.log" }
} else {
    Write-Output "PostgreSQL đang chạy."
}

# 2. Cổng vào (gateway.mjs, cổng 7360): game và đường hầm đi qua đây; /music/ phát file nhạc chế độ nhịp điệu (M10).
$gwPid = Join-Path $rt "gateway.pid"
$gwRunning = $false
if (Test-Path $gwPid) {
    $g = Get-Process -Id ([int](Get-Content $gwPid)) -ErrorAction SilentlyContinue
    $gwRunning = [bool]($g -and $g.ProcessName -eq "node")
}
if (-not $gwRunning) {
    $node = (Get-Command node -ErrorAction SilentlyContinue).Source
    if (-not $node) {
        Write-Output "CẢNH BÁO: không thấy Node.js (node) trong PATH: không bật cổng 7360, chế độ nhịp điệu không tải được nhạc."
    } else {
        $gwHost = if ($Lan) { "0.0.0.0" } else { "127.0.0.1" }
        $g = Start-Process -FilePath $node -WindowStyle Hidden -PassThru `
            -ArgumentList @((Join-Path $server "gateway.mjs"), "--host", $gwHost, "--port", "7360") `
            -RedirectStandardOutput (Join-Path $logs "gateway.out.log") -RedirectStandardError (Join-Path $logs "gateway.err.log")
        Set-Content -Encoding ascii $gwPid $g.Id
        Write-Output "Cổng vào đang chạy (PID $($g.Id)): http://127.0.0.1:7360 (Nakama + /music/)"
    }
} else {
    Write-Output "Cổng vào đang chạy."
}
if (-not (Test-Path (Join-Path $server "music\catalog.json"))) {
    Write-Output "Chưa có danh mục nhạc: python -X utf8 -I tools\rhythm\build_catalog.py"
}

# 3. Nakama
$pidFile = Join-Path $rt "nakama.pid"
if (Test-Path $pidFile) {
    $old = Get-Process -Id ([int](Get-Content $pidFile)) -ErrorAction SilentlyContinue
    if ($old -and $old.ProcessName -eq "nakama") {
        Write-Output "Nakama đang chạy (PID $($old.Id)). Tắt: server\stop_local.ps1"
        exit 0
    }
}
$db = "nakama:$($s.db_password)@127.0.0.1:$PgPort/nakama"
$env:PGPASSWORD = $s.db_password
$hasDb = & (Join-Path $pgBin "psql.exe") -h 127.0.0.1 -p $PgPort -U nakama -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='nakama'"
if ("$hasDb".Trim() -ne "1") {
    & (Join-Path $pgBin "createdb.exe") -h 127.0.0.1 -p $PgPort -U nakama nakama
    if ($LASTEXITCODE -ne 0) { throw "Không tạo được cơ sở dữ liệu nakama" }
}
Remove-Item Env:PGPASSWORD
Write-Output "Cập nhật cấu trúc cơ sở dữ liệu..."
& $nakama migrate up --database.address $db 2>&1 | ForEach-Object { "$_" } | Out-File -Encoding utf8 (Join-Path $logs "migrate.log")
if ($LASTEXITCODE -ne 0) { throw "migrate lỗi, xem $logs\migrate.log" }

$apiAddress = if ($Lan) { "0.0.0.0" } else { "127.0.0.1" }
$nakamaArgs = @(
    "--config", (Join-Path $server "nakama\config.yml"),
    "--database.address", $db,
    "--data_dir", (Join-Path $rt "nakama_data"),
    "--runtime.path", (Join-Path $server "modules"),
    "--socket.address", $apiAddress,
    "--socket.server_key", $cfg.server_key,
    "--console.address", "127.0.0.1",
    "--console.username", "admin",
    "--console.password", $s.console_password,
    "--console.signing_key", $s.console_signing_key,
    "--session.encryption_key", $s.session_encryption_key,
    "--session.refresh_encryption_key", $s.refresh_encryption_key,
    "--runtime.http_key", $s.http_key,
    "--logger.file", (Join-Path $logs "nakama.log")
)
$p = Start-Process -FilePath $nakama -ArgumentList $nakamaArgs -WindowStyle Hidden -PassThru `
    -RedirectStandardOutput (Join-Path $logs "nakama.out.log") -RedirectStandardError (Join-Path $logs "nakama.err.log")
Set-Content -Encoding ascii $pidFile $p.Id

for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 1
    try {
        $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 "http://127.0.0.1:7350/healthcheck"
        if ($r.StatusCode -eq 200) { break }
    } catch { }
    if ($p.HasExited) { throw "Nakama tắt ngay khi bật, xem $logs\nakama.err.log và nakama.log" }
}
Write-Output ""
Write-Output "Nakama đang chạy (PID $($p.Id))."
Write-Output "  API cho game:   http://127.0.0.1:7360 (qua cổng vào; Nakama trực tiếp: 7350)"
Write-Output "  Trang quản trị: http://127.0.0.1:7351  (tài khoản admin, mật khẩu: console_password trong server\.runtime\secrets.json)"
Write-Output "  Mở cho người ngoài: powershell -ExecutionPolicy Bypass -File server\tunnel.ps1"
