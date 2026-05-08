# --- UNIVERSAL GAMING BOOSTER v6.0 ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host ">>> ЗАПУСК ГЛОБАЛЬНОЙ ОПТИМИЗАЦИИ (DOTA 2 / CS2 / BF) <<<" -ForegroundColor Cyan

# 1. ОБЩИЕ СИСТЕМНЫЕ НАСТРОЙКИ (BCDEDIT + ПИТАНИЕ)
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    bcdedit /set disabledynamic_tick yes; bcdedit /set useplatformclock no
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-Host "[+] System Timers & Power: OK" -ForegroundColor Green
}

# 2. ПОИСК ПУТЕЙ STEAM
$steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam").SteamPath
$common = "$steamPath\steamapps\common"

# --- БЛОК CS2 ---
$cs2cfg = "$common\Counter-Strike Global Offensive\game\csgo\cfg"
if (Test-Path $cs2cfg) {
    $cs2Content = @"
fps_max 0
cl_updaterate 128
cl_interp_ratio 1
cl_interp 0.015625
engine_no_focus_sleep 0
"@
    Set-Content -Path "$cs2cfg\autoexec.cfg" -Value $cs2Content
    Write-Host "[+] CS2: Config applied." -ForegroundColor Green
}

# --- БЛОК BATTLEFIELD (Redsec/2042) ---
# Для BF важно создать файл user.cfg в корне игры
$bfPath = "$common\Battlefield 2042" # Замени на имя папки Redsec если отличается
if (Test-Path $bfPath) {
    $bfContent = @"
Thread.ProcessorCount 8
Thread.MaxProcessorCount 8
Thread.MinFreeProcessorCount 0
GstRender.Thread.MaxProcessorCount 8
RenderDevice.Dx11Enable 0
RenderDevice.Dx12Enable 1
RenderDevice.FutureFrameRendering 0
"@
    Set-Content -Path "$bfPath\user.cfg" -Value $bfContent
    Write-Host "[+] Battlefield: Multi-threading optimized." -ForegroundColor Green
}

# --- БЛОК DOTA 2 ---
$dotaCfg = "$common\dota 2 beta\game\dota\cfg"
if (Test-Path $dotaCfg) {
    Set-Content -Path "$dotaCfg\autoexec.cfg" -Value "fps_max 0`ncl_interp 0`nm_rawinput 1"
    Write-Host "[+] Dota 2: Config applied." -ForegroundColor Green
}

# 3. УНИВЕРСАЛЬНЫЙ ПАРАМЕТР ЗАПУСКА (Копируется в буфер)
# Эти флаги подходят для всех трех игр
$universalLaunch = "-novid -high -dx11 -nojoy -threads 9"
$universalLaunch | Set-Clipboard

Write-Host "`n[!] ПАРАМЕТРЫ ЗАПУСКА В БУФЕРЕ (Ctrl+V в Steam)." -ForegroundColor Yellow
