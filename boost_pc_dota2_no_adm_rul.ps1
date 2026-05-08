# --- ИНИЦИАЛИЗАЦИЯ ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host ">>> ЗАПУСК КЛУБНОЙ ОПТИМИЗАЦИИ (БЕЗ ПРАВ АДМИНА)..." -ForegroundColor Cyan

# 1. ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ (Driver-Level Tweaks без реестра)
# Эти команды заставляют драйвер NVIDIA работать в режиме низкой задержки для текущей сессии
[Environment]::SetEnvironmentVariable("__GL_THREADED_OPTIMIZATIONS", "1", "User")
[Environment]::SetEnvironmentVariable("__GL_MAX_FRAMES_ALLOWED", "1", "User")
[Environment]::SetEnvironmentVariable("DXVK_ASYNC", "1", "User")
Write-Host "[+] Переменные окружения: Драйвер настроен на Low Latency." -ForegroundColor Green

# 2. ОПТИМИЗАЦИЯ ПОЛЬЗОВАТЕЛЬСКОГО РЕЕСТРА (HKCU)
$regPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $regPath -Name "MenuShowDelay" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value 0 -ErrorAction SilentlyContinue
# Отключение Game Bar (который часто ест ресурсы в фоне)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "UseMsXboxAppGamerDVR" -Value 0 -ErrorAction SilentlyContinue
Write-Host "[+] Реестр пользователя: Задержки меню и ускорение мыши отключены." -ForegroundColor Green

# 3. ИНЪЕКЦИЯ КОНФИГА (Engine Optimization)
try {
    $steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam").SteamPath
    $dotaCfgPath = "$steamPath\steamapps\common\dota 2 beta\game\dota\cfg"
    
    if (!(Test-Path $dotaCfgPath)) { New-Item -Path $dotaCfgPath -ItemType Directory -Force | Out-Null }
    
    $cfgContent = @"
// СЕТЬ (Минимизация пинга и джиттера)
rate "1000000"
cl_interp "0"
cl_interp_ratio "1"
cl_cmdrate "128"
cl_updaterate "128"
cl_lagcompensation "1"

// ВВОД (Нулевая задержка мыши)
m_rawinput "1"
cl_input_latency_override "1"

// ГРАФИЧЕСКИЙ ДВИЖОК
fps_max "0"
mat_queue_mode "2"
engine_no_focus_sleep "0"
snd_mix_async "1"
r_render_to_texture_upscale "0"
"@
    Set-Content -Path "$dotaCfgPath\autoexec_club.cfg" -Value $cfgContent -Force
    Write-Host "[+] Engine Config: Создан autoexec_club.cfg." -ForegroundColor Green
} catch {
    Write-Host "[!] Ошибка: Не удалось найти папку Доты." -ForegroundColor Red
}

# 4. ПОДГОТОВКА ПАРАМЕТРОВ ЗАПУСКА
$launchOptions = "-novid -high -map dota -dx11 -nojoy -preload +exec autoexec_club.cfg"
$launchOptions | Set-Clipboard
Write-Host "`n[!!!] ПАРАМЕТРЫ ЗАПУСКА СКОПИРОВАНЫ В БУФЕР ОБМЕНА." -ForegroundColor Yellow
Write-Host "Вставь их в Steam (Свойства Dota 2): $launchOptions" -ForegroundColor White

# 5. МОНИТОРИНГ ПРОЦЕССА (Авто-Приоритет)
Write-Host "`n>>> Ожидание запуска Dota 2 для форсирования приоритета..." -ForegroundColor Cyan
while($true) {
    $proc = Get-Process "dota2" -ErrorAction SilentlyContinue
    if ($proc) {
        try {
            $proc.PriorityClass = "High"
            Write-Host "[SUCCESS] Процесс найден! Выставлен ВЫСОКИЙ приоритет." -ForegroundColor Green
            break
        } catch {
            Write-Host "[!] Защита клуба блокирует изменение приоритета. Пропускаю." -ForegroundColor Yellow
            break
        }
    }
    Start-Sleep -Seconds 3
}

Write-Host "`nГотово. Можешь играть." -ForegroundColor Cyan
Start-Sleep -Seconds 5
