# Gửi quà thử nghiệm vào save (xem docs/prompts hoặc `--list`). Chạy ở bất kỳ thư mục nào:
#   powershell -ExecutionPolicy Bypass -File tools\give_gift.ps1 gems=5000 equip:all preset:level_up
#   powershell -ExecutionPolicy Bypass -File tools\give_gift.ps1 --list
#   powershell -ExecutionPolicy Bypass -File tools\give_gift.ps1 preset:everything --dry-run
# Cú pháp quà: gems=N gold=N item:<id>=N equip:<id>=N char:<id> frag:<id>=N captain=<cấp> preset:<tên>; item:/equip:/char:/frag: nhận "all".
# ĐÓNG GAME trước khi chạy (game đang mở sẽ ghi đè save khi thoát). Mã thoát 0 = đã gửi, 1 = lỗi (không đổi gì).

[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Godot = "C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$GiftArgs
)

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
[Console]::OutputEncoding = [Text.Encoding]::UTF8

if (-not (Test-Path $Godot)) {
    Write-Output "Không tìm thấy Godot: $Godot (truyền -Godot <đường dẫn>)"
    exit 2
}

& $Godot --headless --path . --import *> $null
& $Godot --headless --path . -s tools/give_gift.gd -- @GiftArgs 2>&1 | ForEach-Object { "$_" } |
    Where-Object { $_ -notmatch '^Godot Engine v|^\s*$' }
exit $LASTEXITCODE
