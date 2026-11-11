# Kiểm tra máy đã sẵn sàng xuất bản Windows / Android debug chưa (M1-8).
# Chỉ đọc, không cài hay sửa gì.
# Chạy: powershell -ExecutionPolicy Bypass -File tools\check_build_env.ps1

$ok = $true
function Report($name, $pass, $detail) {
    $mark = if ($pass) { "[OK]  " } else { "[THIẾU]" }
    Write-Output ("{0} {1}: {2}" -f $mark, $name, $detail)
    if (-not $pass) { $script:ok = $false }
}

$godotVersion = "4.6.3.stable"
$settings = Join-Path $env:APPDATA "Godot\editor_settings-4.6.tres"
$settingsText = if (Test-Path $settings) { Get-Content $settings -Raw } else { "" }

function Get-Setting($key) {
    $m = [regex]::Match($settingsText, [regex]::Escape($key) + '\s*=\s*"([^"]*)"')
    if ($m.Success) { return ($m.Groups[1].Value -replace '\\\\', '\') } else { return "" }
}

# 1. Godot
$godot = "C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe"
Report "Godot 4.6.3" (Test-Path $godot) $godot

# 2. Export templates
$tpl = Join-Path $env:APPDATA "Godot\export_templates\$godotVersion"
$hasWin = Test-Path (Join-Path $tpl "windows_debug_x86_64.exe")
$hasAndroid = Test-Path (Join-Path $tpl "android_debug.apk")
Report "Template Windows" $hasWin $tpl
Report "Template Android" $hasAndroid $tpl

# 3. JDK
$java = Get-Setting "export/android/java_sdk_path"
$javaExe = if ($java) { Join-Path $java "bin\java.exe" } else { "" }
if ($javaExe -and (Test-Path $javaExe)) {
    $ver = (& cmd /c "`"$javaExe`" -version 2>&1" | Select-Object -First 1)
    $is17 = $ver -match 'version "17\.'
    Report "JDK (Editor Settings)" $is17 ("$java -> $ver" + $(if (-not $is17) { "  (khuyến nghị JDK 17)" } else { "" }))
} else {
    Report "JDK (Editor Settings)" $false "chưa đặt export/android/java_sdk_path hoặc sai đường dẫn"
}

# 4. Android SDK
$sdk = Get-Setting "export/android/android_sdk_path"
$sdk = $sdk -replace '/', '\'
$adb = if ($sdk) { Join-Path $sdk "platform-tools\adb.exe" } else { "" }
$buildTools = if ($sdk -and (Test-Path (Join-Path $sdk "build-tools"))) { Get-ChildItem (Join-Path $sdk "build-tools") -Directory | ForEach-Object Name } else { @() }
$platforms = if ($sdk -and (Test-Path (Join-Path $sdk "platforms"))) { Get-ChildItem (Join-Path $sdk "platforms") -Directory | ForEach-Object Name } else { @() }
Report "Android SDK" ($sdk -and (Test-Path $sdk)) $(if ($sdk) { $sdk } else { "chưa đặt export/android/android_sdk_path" })
Report "  platform-tools (adb)" ($adb -and (Test-Path $adb)) $adb
Report "  build-tools" ($buildTools.Count -gt 0) ($(if ($buildTools) { $buildTools -join ", " } else { "không có" }))
Report "  platforms" ($platforms.Count -gt 0) ($(if ($platforms) { $platforms -join ", " } else { "không có" }))

# 5. Keystore debug
$ks = Get-Setting "export/android/debug_keystore"
Report "Keystore debug" ($ks -and (Test-Path $ks)) $ks

# 6. Điện thoại
if ($adb -and (Test-Path $adb)) {
    $devices = & $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\sdevice$' }
    Report "Điện thoại qua USB" ($devices.Count -gt 0) $(if ($devices) { ($devices -join "; ") } else { "chưa thấy máy (bật USB debugging, chấp nhận trên điện thoại)" })
} else {
    Write-Output "[--]    Điện thoại qua USB: bỏ qua, chưa có adb của SDK"
}
$oldAdb = "C:\Windows\adb.exe"
if (Test-Path $oldAdb) {
    Write-Output "[CHÚ Ý] Có adb cũ ở $oldAdb. Nếu lỗi 'adb server version doesn't match', dùng adb trong SDK."
}

Write-Output ""
if ($ok) { Write-Output "SẴN SÀNG: có thể xuất bản Windows và Android debug." } else { Write-Output "CHƯA SẴN SÀNG: xem các mục [THIẾU] và docs/ANDROID_SETUP.md." }
