$configContent = (Get-Content (Join-Path $PSScriptRoot "config.ini") -Raw).Replace('\', '\\')
$configs = $configContent | ConvertFrom-StringData
$taskName = $configs.TaskName
$taskDescription = $configs.TaskDescription
$workingDirectory = Split-Path -Path $configs.TaskPath -Parent

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$($configs.TaskPath)`"" `
    -WorkingDirectory $workingDirectory

$Trigger = New-ScheduledTaskTrigger `
    -Daily `
    -At 03:00

$Principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew

Register-ScheduledTask `
    -TaskName $taskName `
    -Description $taskDescription `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Settings $Settings `
    -Force