# --- UNIVERSAL USER-MODE BOOSTER (Dota 2 / CS2 / BF) ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host ">>> ЗАПУСК КЛУБНОЙ ОПТИМИЗАЦИИ (БЕЗ АДМИН-ПРАВ) <<<" -ForegroundColor Cyan

# 1. ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ (Форсируем драйвер NVIDIA/AMD на Low Latency)
# Работает для всех игр в текущей сессии пользователя
[Environment]::SetEnvironmentVariable("__GL_THREADED_OPTIMIZATIONS", "1", "User")
[Environment]::SetEnvironmentVariable("__GL_MAX_FRAMES_ALLOWED", "1", "User")
[Environment]::SetEnvironmentVariable("DXVK_ASYNC", "1", "User")
Write-Host "[+] Driver Environment: Forced Low Latency Mode" -ForegroundColor Green

# 2. РЕЕСТР ПОЛЬЗОВАТЕЛЯ (HKCU - права не нужны)
$regMouse = "HKCU:\Control Panel\Mouse"
Set-ItemProperty -Path $regMouse -Name "MouseSpeed" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $regMouse -Name "MouseThreshold1" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $regMouse -Name "MouseThreshold2" -Value 0 -ErrorAction SilentlyContinue

$regDesktop = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $regDesktop -Name "MenuShowDelay" -Value 0 -ErrorAction SilentlyContinue
Write-Host "[+] User Registry: Mouse Acceleration & Menu Delays Disabled" -ForegroundColor Green

# 3. АВТО-ПОИСК И ИНЪЕКЦИЯ КОНФИГОВ
$steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam").SteamPath
$common = "$steamPath\steamapps\common"

# Функция для безопасной записи конфига
function Write-GameCfg($Path, $FileName, $Content) {
    if (Test-Path $Path) {
        Set-Content -Path "$Path\$FileName" -Value $Content -Force
        return "SUCCESS"
    }
    return "NOT FOUND"
}

# Конфиги для разных игр
$dotaContent = "fps_max 0`ncl_interp 0`ncl_interp_ratio 1`nm_rawinput 1`nsnd_mix_async 1"
$cs2Content = "fps_max 0`ncl_interp 0.015625`ncl_interp_ratio 1`nengine_no_focus_sleep 0"
$bfContent = "Thread.ProcessorCount 8`nThread.MaxProcessorCount 8`nRenderDevice.Dx12Enable 1`nRenderDevice.FutureFrameRendering 0"

$resDota = Write-GameCfg "$common\dota 2 beta\game\dota\cfg" "autoexec.cfg" $dotaContent
$resCS2 = Write-GameCfg "$common\Counter-Strike Global Offensive\game\csgo\cfg" "autoexec.cfg" $cs2Content
$resBF = Write-GameCfg "$common\Battlefield 2042" "user.cfg" $bfContent

# 4. ОТЧЕТ ПО ИГРАМ
Write-Host "`n--- ИГРОВЫЕ КОНФИГИ ---" -ForegroundColor Yellow
Write-Host "Dota 2: $resDota"
Write-Host "CS2:    $resCS2"
Write-Host "BF2042: $resBF"

# 5. ПАРАМЕТРЫ ЗАПУСКА (Универсальные)
$launchOptions = "-novid -high -dx11 -nojoy +exec autoexec.cfg"
$launchOptions | Set-Clipboard
Write-Host "`n[!] ПАРАМЕТРЫ ЗАПУСКА В БУФЕРЕ ОБМЕНА." -ForegroundColor Yellow
Write-Host "Вставь их в Steam для нужной игры (ПКМ -> Свойства)." -ForegroundColor Gray

# 6. МОНИТОРИНГ И ПРИОРИТЕТ
Write-Host "`n>>> Скрипт ждет запуска игры (Dota2/CS2/BF)..." -ForegroundColor Cyan
$games = @("dota2", "cs2", "BF2042")

while($true) {
    foreach ($game in $games) {
        $proc = Get-Process $game -ErrorAction SilentlyContinue
        if ($proc) {
            try {
                $proc.PriorityClass = "High"
                Write-Host "[!] Процесс $game обнаружен! Приоритет: HIGH." -ForegroundColor Green
                exit
            } catch {
                Write-Host "[X] Защита клуба блокирует приоритет для $game." -ForegroundColor Red
                exit
            }
        }
    }
    Start-Sleep -Seconds 5
}
