# --- ИНИЦИАЛИЗАЦИЯ И ОТЧЕТ ---
$Report = @()
function Add-ToReport($Task, $Status) {
    $global:Report += [PSCustomObject]@{ Task = $Task; Status = $Status }
}

Write-Host ">>> Запуск процесса оптимизации (USER MODE)..." -ForegroundColor Cyan

# 1. Поиск пути к Dota 2
try {
    $steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam").SteamPath
    $dotaBase = "$steamPath\steamapps\common\dota 2 beta\game\dota"
    $cfgPath = "$dotaBase\cfg"
    if (!(Test-Path $cfgPath)) { New-Item -Path $cfgPath -ItemType Directory -Force | Out-Null }
    Add-ToReport "Steam/Dota Directory Search" "SUCCESS"
} catch {
    Add-ToReport "Steam/Dota Directory Search" "FAILED"
}

# 2. Создание autoexec.cfg (Сетевой стек и Input Lag)
if (Test-Path $cfgPath) {
    $autoexec = @"
// СЕТЬ
rate "1000000"
cl_interp "0"
cl_interp_ratio "1"
cl_cmdrate "128"
cl_updaterate "128"
cl_lagcompensation "1"
cl_predict "1"
cl_pred_optimize "2"

// ИНПУТ И ГРАФИКА
m_rawinput "1"
cl_input_latency_override "1"
fps_max "0"
engine_no_focus_sleep "0"
mat_queue_mode "2"
r_render_to_texture_upscale "0"
r_queued_ropes "1"
r_threaded_particles "1"
dota_cheap_water "1"
cl_globallight_shadow_mode "0"
r_deferred_height_fog "0"
r_deferred_additive_pass "0"
r_deferred_simple_light "1"
"@
    Set-Content -Path "$cfgPath\autoexec.cfg" -Value $autoexec -Force
    Add-ToReport "Autoexec.cfg Injection" "SUCCESS"
}

# 3. Твики реестра пользователя (HKCU - не требуют админа)
try {
    $regDesktop = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $regDesktop -Name "MenuShowDelay" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $regDesktop -Name "ForegroundLockTimeout" -Value 0 -ErrorAction SilentlyContinue
    
    $regMouse = "HKCU:\Control Panel\Mouse"
    Set-ItemProperty -Path $regMouse -Name "MouseSpeed" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $regMouse -Name "MouseThreshold1" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $regMouse -Name "MouseThreshold2" -Value 0 -ErrorAction SilentlyContinue
    
    Add-ToReport "User Registry Tweaks" "SUCCESS"
} catch {
    Add-ToReport "User Registry Tweaks" "PARTIAL/FAILED"
}

# 4. Очистка временных файлов (ускорение подгрузки)
try {
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Add-ToReport "Temp Files Cleanup" "SUCCESS"
} catch {
    Add-ToReport "Temp Files Cleanup" "SKIPPED"
}

# 5. Подготовка параметров запуска
$launchOptions = "-novid -high -map dota -dx11 -nojoy -preload -gc_collect +exec autoexec.cfg"
$launchOptions | Set-Clipboard

# --- ВЫВОД ОТЧЕТА ---
Write-Host "`n--- ОТЧЕТ ВЫПОЛНЕНИЯ ---" -ForegroundColor White -BackgroundColor Blue
$Report | Format-Table -AutoSize
Write-Host "[!] ПАРАМЕТРЫ ЗАПУСКА СКОПИРОВАНЫ В БУФЕР ОБМЕНА." -ForegroundColor Yellow
Write-Host "Вставь их в Steam -> Dota 2 -> Свойства -> Параметры запуска (Ctrl+V).`n" -ForegroundColor Gray

# 6. АВТО-ПРИОРИТЕТ (Фоновый процесс)
Write-Host ">>> Скрипт переходит в режим ожидания Dota 2..." -ForegroundColor Cyan
Write-Host "Как только запустишь игру, я автоматически выставлю ей ВЫСОКИЙ приоритет CPU." -ForegroundColor Gray

while($true) {
    $process = Get-Process "dota2" -ErrorAction SilentlyContinue
    if ($process) {
        try {
            $process.PriorityClass = "High"
            Write-Host "[!] ПРОЦЕСС DOTA2 ОБНАРУЖЕН. ПРИОРИТЕТ УСТАНОВЛЕН: HIGH." -ForegroundColor Green
            break
        } catch {
            Write-Host "[X] Не удалось изменить приоритет (защита клуба)." -ForegroundColor Red
            break
        }
    }
    Start-Sleep -Seconds 3
}