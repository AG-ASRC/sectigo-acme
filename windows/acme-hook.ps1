param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("create","delete")]
    [string]$Action,

    [string]$RecordName,

    [string]$Token
)

# ============================================================================
# Configuration
# ============================================================================

$configContent = (Get-Content (Join-Path $PSScriptRoot "config.ini") -Raw).Replace('\', '\\')
$configs = $configContent | ConvertFrom-StringData
$secrets = Get-Content (Join-Path $PSScriptRoot "secrets.ini") -Raw | ConvertFrom-StringData

$WorkerUrl = $configs.WorkerURL
$ApiToken  = $secrets.ApiToken
$CoolDownBeforeCheckChallenge = $configs.CoolDownBeforeCheckChallenge

# ============================================================================
# Create
# ============================================================================

if ($Action -eq "create") {

    Write-Host "Creation TXT : $RecordName"

    $Body = @{
        fqdn  = $RecordName
        value = $Token
    } | ConvertTo-Json -Compress

    Invoke-RestMethod `
        -Method POST `
        -Uri "$WorkerUrl/dns" `
        -Headers @{
            "X-API-Token" = $ApiToken
        } `
        -ContentType "application/json" `
        -Body $Body

    Start-Sleep -Seconds $CoolDownBeforeCheckChallenge

    exit 0
}

# ============================================================================
# Delete
# ============================================================================

if ($Action -eq "delete") {

    Write-Host "Suppression TXT : $RecordName"

    $Body = @{
        fqdn = $RecordName
        value = $Token
    } | ConvertTo-Json -Compress

    Invoke-RestMethod `
        -Method DELETE `
        -Uri "$WorkerUrl/dns" `
        -Headers @{
            "X-API-Token" = $ApiToken
        } `
        -ContentType "application/json" `
        -Body $Body

    exit 0
}