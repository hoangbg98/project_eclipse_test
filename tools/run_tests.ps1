# Chạy toàn bộ test: GdUnit4 (tests/unit) + test khói (tests/smoke).
# Chạy: powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
# Mã thoát 0 = tất cả đạt. Báo cáo HTML GdUnit4 nằm trong reports\ (không đưa vào git).

param(
    [string]$Godot = "C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe"
)

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
[Console]::OutputEncoding = [Text.Encoding]::UTF8

if (-not (Test-Path $Godot)) {
    Write-Output "Không tìm thấy Godot: $Godot (truyền -Godot <đường dẫn>)"
    exit 2
}

$results = @()

function Run-Step($name, [string[]]$godotArgs) {
    Write-Output ""
    Write-Output "=== $name"
    & $Godot @godotArgs 2>&1 | ForEach-Object { "$_" } |
        Where-Object { $_ -match 'PASS|FAIL|KẾT QUẢ|Statistics|Overall Summary|Exit code|ERROR|SCRIPT ERROR|Expecting' }
    $code = $LASTEXITCODE
    $script:results += [pscustomobject]@{ Bước = $name; MãThoát = $code; KếtQuả = $(if ($code -eq 0) { "ĐẠT" } else { "LỖI" }) }
}

# Nạp lại cache class (cần sau khi thêm script mới)
& $Godot --headless --path . --import *> $null

Run-Step "GdUnit4 tests/unit" @("--headless", "--path", ".", "-s", "-d", "--remote-debug", "tcp://127.0.0.1:0",
    "res://addons/gdUnit4/bin/GdUnitCmdTool.gd", "-a", "res://tests/unit", "--ignoreHeadlessMode", "-rd", "reports")

foreach ($t in Get-ChildItem "tests\smoke\*.gd") {
    Run-Step "smoke $($t.BaseName)" @("--headless", "--path", ".", "--script", "res://tests/smoke/$($t.Name)")
}

Write-Output ""
$results | Format-Table -AutoSize | Out-String -Width 120 | Write-Output
$failed = @($results | Where-Object { $_.MãThoát -ne 0 }).Count
if ($failed -eq 0) { Write-Output "TẤT CẢ ĐẠT"; exit 0 } else { Write-Output "CÓ $failed BƯỚC LỖI"; exit 1 }
