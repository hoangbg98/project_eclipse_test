# Tải và chuẩn bị máy chủ thử nghiệm trên máy Windows (bản portable, không cần quyền admin).
# Chạy một lần: powershell -ExecutionPolicy Bypass -File server\setup_local.ps1
# Mọi thứ nằm trong server\.runtime\ (không vào git). Xóa thư mục đó = gỡ sạch.
# Phiên bản cố định ở đầu file; đổi phiên bản thì ghi vào docs/ASSET_LICENSES.md mục 3.4.

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$NakamaVersion = "3.42.0"
$PgVersion = "17.12-1"
$CloudflaredVersion = "2026.11.0"

$server = $PSScriptRoot
$rt = Join-Path $server ".runtime"
$dl = Join-Path $rt "downloads"
New-Item -ItemType Directory -Force $dl | Out-Null

function Get-File($url, $out) {
    if (Test-Path $out) { Write-Output "Đã có: $(Split-Path -Leaf $out)"; return }
    Write-Output "Tải: $url"
    & curl.exe -L --fail --retry 3 -o "$out.part" $url
    if ($LASTEXITCODE -ne 0) { throw "Tải lỗi: $url" }
    Move-Item "$out.part" $out
}

# 1. Nakama
$nakamaTar = Join-Path $dl "nakama-$NakamaVersion-windows-amd64.tar.gz"
Get-File "https://github.com/heroiclabs/nakama/releases/download/v$NakamaVersion/nakama-$NakamaVersion-windows-amd64.tar.gz" $nakamaTar
$nakamaDir = Join-Path $rt "nakama"
if (-not (Test-Path (Join-Path $nakamaDir "nakama.exe"))) {
    New-Item -ItemType Directory -Force $nakamaDir | Out-Null
    & tar.exe -xzf $nakamaTar -C $nakamaDir
}

# 2. PostgreSQL (bản zip binaries của EnterpriseDB)
$pgZip = Join-Path $dl "postgresql-$PgVersion-windows-x64-binaries.zip"
Get-File "https://get.enterprisedb.com/postgresql/postgresql-$PgVersion-windows-x64-binaries.zip" $pgZip
$pgDir = Join-Path $rt "pgsql"
if (-not (Test-Path (Join-Path $pgDir "bin\pg_ctl.exe"))) {
    Write-Output "Giải nén PostgreSQL..."
    & tar.exe -xf $pgZip -C $rt
}

# 3. cloudflared (đường hầm trycloudflare.com)
$cf = Join-Path $rt "cloudflared.exe"
Get-File "https://github.com/cloudflare/cloudflared/releases/download/$CloudflaredVersion/cloudflared-windows-amd64.exe" $cf

# 4. Khóa bí mật riêng của máy này (không vào git)
$secrets = Join-Path $rt "secrets.json"
if (-not (Test-Path $secrets)) {
    function New-Key([int]$n) {
        $b = New-Object byte[] $n
        [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b)
        return (-join ($b | ForEach-Object { $_.ToString("x2") }))
    }
    [ordered]@{
        db_password            = New-Key 16
        session_encryption_key = New-Key 24
        refresh_encryption_key = New-Key 24
        http_key               = New-Key 24
        console_password       = New-Key 8
        console_signing_key    = New-Key 24
    } | ConvertTo-Json | Set-Content -Encoding ascii $secrets
    Write-Output "Đã tạo khóa bí mật: $secrets"
}
$s = Get-Content $secrets -Raw | ConvertFrom-Json

# 5. Khởi tạo cơ sở dữ liệu
$pgData = Join-Path $rt "pgdata"
if (-not (Test-Path (Join-Path $pgData "PG_VERSION"))) {
    $pwFile = Join-Path $rt "pw.tmp"
    [IO.File]::WriteAllText($pwFile, [string]$s.db_password)
    & (Join-Path $pgDir "bin\initdb.exe") -D "$pgData" -U nakama "--pwfile=$pwFile" -A scram-sha-256 -E UTF8 --locale=C
    $code = $LASTEXITCODE
    Remove-Item -Force -ErrorAction SilentlyContinue $pwFile
    if ($code -ne 0) { throw "initdb lỗi" }
}

Write-Output ""
Write-Output "XONG. Chạy máy chủ: powershell -ExecutionPolicy Bypass -File server\start_local.ps1"
