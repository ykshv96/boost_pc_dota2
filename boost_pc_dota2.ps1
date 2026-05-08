# 1. Конфигурация путей
$WorkDir = "C:\Dota_Opt"
$BootScript = "$WorkDir\startup_boost.ps1"
if (!(Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }

# 2. Создание ВНУТРЕННЕГО скрипта (который будет запускаться при старте)
$ScriptContent = @"
# Настройка кодировки для вывода отчета
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "--- AUTO-OPTIMIZATION STARTING ---" -ForegroundColor Cyan

# Блок 1: Принудительное питание (High Performance)
# Импортируем схему, если её вдруг удалили, и активируем
powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
Write-Host "[+] Power Scheme: High Performance Force-Activated" -ForegroundColor Green

# Блок 2: Реестр (Сеть и Видео)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -Value 5 -Type DWord -ErrorAction SilentlyContinue
Write-Host "[+] Registry: Network & MPO Tweaks Re-Applied" -ForegroundColor Green

# Блок 3: ISLC (Timer Resolution)
if (!(Get-Process "ISLC" -ErrorAction SilentlyContinue)) {
    if (Test-Path "$WorkDir\ISLC.exe") {
        Start-Process "$WorkDir\ISLC.exe" -ArgumentList "-start"
        Write-Host "[+] ISLC: Process Started" -ForegroundColor Green
    } else {
        Write-Host "[-] ISLC: Executable not found in $WorkDir" -ForegroundColor Red
    }
} else {
    Write-Host "[+] ISLC: Already Running" -ForegroundColor Green
}

# Блок 4: Проверка конфига Dota 2
try {
    `$steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam").SteamPath
    `$cfgFile = "`$steamPath\steamapps\common\dota 2 beta\game\dota\cfg\autoexec.cfg"
    if (!(Test-Path `$cfgFile)) {
        # Если конфиг пропал - восстанавливаем базу
        `$content = "fps_max 0`ncl_interp 0`ncl_interp_ratio 1`nm_rawinput 1"
        Set-Content -Path `$cfgFile -Value `$content
        Write-Host "[+] Dota Config: Restored" -ForegroundColor Yellow
    } else {
        Write-Host "[+] Dota Config: Present" -ForegroundColor Green
    }
} catch {
    Write-Host "[-] Dota Config: Path error" -ForegroundColor Red
}

Write-Host "`n--- ALL SYSTEMS NOMINAL ---" -ForegroundColor Cyan
Write-Host "Окно закроется через 10 секунд..."
Start-Sleep -Seconds 10
"@

Set-Content -Path $BootScript -Value $ScriptContent -Encoding UTF8

# 3. Регистрация задачи в Планировщике Windows
# Задача запускается от имени пользователя с наивысшими правами
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$BootScript`""
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName "Dota2_Ultimate_Boost" -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force

Write-Host "`nУСПЕХ: Скрипт добавлен в автозагрузку." -ForegroundColor Green
Write-Host "Теперь при каждом включении ноута ты будешь видеть отчет на 10 секунд." -ForegroundColor Gray