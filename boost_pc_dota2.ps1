$Results = @()
$WorkDir = "C:\Dota_Opt"
if (!(Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }

function Check-Reg {
    param($Path, $Name, $Expected)
    $val = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
    if ($val -eq $Expected) { return "SUCCESS" } else { return "FAILED" }
}

# 1. Сеть + Алгоритм Нагла + Отключение задержек прерываний
$regInterfaces = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
Get-ChildItem $regInterfaces | ForEach-Object {
    $p = $_.PSPath
    Set-ItemProperty -Path $p -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $p -Name "TCPNoDelay" -Value 1 -Type DWord -ErrorAction SilentlyContinue
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord
$Results += "Network Optimization: $(Check-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 4294967295)"

# 2. Видео: Disable MPO + Game Mode
$mpoPath = "HKLM:\SOFTWARE\Microsoft\Windows\Dwm"
if (!(Test-Path $mpoPath)) { New-Item -Path $mpoPath -Force | Out-Null }
Set-ItemProperty -Path $mpoPath -Name "OverlayTestMode" -Value 5 -Type DWord
$Results += "MPO Disabled: $(Check-Reg $mpoPath 'OverlayTestMode' 5)"

# 3. ISLC: Скачивание и Автозапуск (Task Scheduler)
$islcPath = "$WorkDir\ISLC.exe"
if (!(Test-Path $islcPath)) {
    Invoke-WebRequest -Uri "https://www.wagnardsoft.com/ISLC/ISLC%20v1.0.3.0.exe" -OutFile $islcPath
}
$ST = New-ScheduledTaskAction -Execute $islcPath
$Tr = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -Action $ST -Trigger $Tr -TaskName "AutoISLC" -User "SYSTEM" -Force | Out-Null
$Results += "ISLC Auto-Start Task: SUCCESS"

# 4. Система: Снятие лимитов QoS
$qosPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
if (!(Test-Path $qosPath)) { New-Item -Path $qosPath -Force | Out-Null }
Set-ItemProperty -Path $qosPath -Name "NonBestEffortLimit" -Value 0 -Type DWord
$Results += "QoS Limit 0%: $(Check-Reg $qosPath 'NonBestEffortLimit' 0)"

# Вывод отчета
Write-Host "`n=== FINAL VERIFICATION ---" -ForegroundColor Cyan
foreach ($r in $Results) {
    if ($r -like "*SUCCESS*") { Write-Host "[+] $r" -ForegroundColor Green }
    else { Write-Host "[-] $r" -ForegroundColor Red }
}
Write-Host "`nREBOOT REQUIRED TO APPLY REGISTRY CHANGES." -ForegroundColor Yellow