# 1. Подготовка
$WorkDir = "C:\Dota_Opt"
if (!(Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }
$BootScript = "$WorkDir\startup_boost.ps1"

# 2. Формирование контента скрипта
$ScriptContent = @"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "--- ULTIMATE SYSTEM OPTIMIZATION ---" -ForegroundColor Cyan

# Блок 1: Низкоуровневые таймеры (BCDEDIT)
bcdedit /set disabledynamic_tick yes
bcdedit /set useplatformclock no
bcdedit /set tscsyncpolicy Enhanced
Write-Host "[+] BCDEDIT: Timers & TSC Policy Optimized" -ForegroundColor Green

# Блок 2: Питание и USB (Отключение всех энергосберегаек)
powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
# Отключение приостановки USB
powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a030bee-e91f-4ce0-8127-9102580242c7 48e6b7a6-50f0-450a-8d45-b7ad97b7e287 0
# Отключение PCI Express Link State
powercfg /SETACVALUEINDEX SCHEME_CURRENT ee12f753-d177-4952-9fab-2dca141208b0 ee12f753-d177-4952-9fab-2dca141208b0 0
Write-Host "[+] Power: USB & PCIe Power Saving Disabled" -ForegroundColor Green

# Блок 3: Реестр (FSO, Network, MPO)
# Отключение Fullscreen Optimizations глобально
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehavior" -Value 2 -Type DWord -ErrorAction SilentlyContinue
# Сеть: TcpNoDelay + Отключение прерываний
`$regInterfaces = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
Get-ChildItem `$regInterfaces | ForEach-Object {
    Set-ItemProperty -Path `$_.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path `$_.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -ErrorAction SilentlyContinue
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -Value 5 -Type DWord -ErrorAction SilentlyContinue
Write-Host "[+] Registry: FSO Disabled, Network Latency Minimal" -ForegroundColor Green

# Блок 4: Запуск ISLC
if (!(Get-Process "ISLC" -ErrorAction SilentlyContinue)) {
    if (Test-Path "$WorkDir\ISLC.exe") { Start-Process "$WorkDir\ISLC.exe" -ArgumentList "-start" }
}

# Блок 5: Проверка конфига Доты (Force RAW Input)
`$steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam").SteamPath
`$cfgFile = "`$steamPath\steamapps\common\dota 2 beta\game\dota\cfg\autoexec.cfg"
`$content = "fps_max 0`ncl_interp 0`ncl_interp_ratio 1`nm_rawinput 1`nsnd_mix_async 1"
Set-Content -Path `$cfgFile -Value `$content
Write-Host "[+] Dota Config: Autoexec Updated" -ForegroundColor Green

Write-Host "`n--- OPTIMIZATION COMPLETE. SYSTEM READY ---" -ForegroundColor Cyan
Start-Sleep -Seconds 5
"@

Set-Content -Path $BootScript -Value $ScriptContent -Encoding UTF8

# 3. Перерегистрация задачи в планировщике
Unregister-ScheduledTask -TaskName "Dota2_Ultimate_Boost" -Confirm:$false -ErrorAction SilentlyContinue
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$BootScript`""
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "Dota2_Ultimate_Boost" -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force

Write-Host "Все обновления внедрены. Перезагрузись для активации BCDEDIT твиков." -ForegroundColor Green
