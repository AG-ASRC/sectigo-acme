# ============================================================================
# Configuration
# ============================================================================

$translation = Get-Content (Join-Path $PSScriptRoot "translation.ini") -Raw | ConvertFrom-StringData
$configContent = (Get-Content (Join-Path $PSScriptRoot "config.ini") -Raw).Replace('\', '\\')
$configs = $configContent | ConvertFrom-StringData

$EventSource = $configs.EventSource
$CertificateStore = $configs.CertificateStore

# Création de la source si absente
if (-not [System.Diagnostics.EventLog]::SourceExists($EventSource)) {
    New-EventLog -LogName Application -Source $EventSource
}

# ============================================================================
# Recherche du certificat
# ============================================================================

$Cert = Get-ChildItem Cert:\LocalMachine\$CertificateStore |
    Where-Object {
        $_.Subject -like "CN=$($configs.WildcardDomains)*"
    } |
    Sort-Object NotAfter -Descending |
    Select-Object -First 1

if (-not $Cert) {

    Write-EventLog `
        -LogName Application `
        -Source $EventSource `
        -EntryType Warning `
        -EventId 1001 `
        -Message ($translation.NoCertificateFound -f $configs.WildcardDomains, $CertificateStore)

}

$NeedsCertificateCreation = -not $Cert
$NeedsRenewal = $Cert -and ($Cert.NotAfter -lt (Get-Date).AddDays($configs.MaxDays))
$DaysRemaining = if ($Cert) {
    [Math]::Round(($Cert.NotAfter - (Get-Date)).TotalDays, 0)
}

# ============================================================================
# Création ou renouvellement
# ============================================================================

if ($NeedsCertificateCreation -or $NeedsRenewal) {

    if ($NeedsRenewal) {
        Write-EventLog `
            -LogName Application `
            -Source $EventSource `
            -EntryType Warning `
            -EventId 1002 `
            -Message ($translation.CertificateNeedRenewal -f $configs.WildcardDomains)
    }

    try {

        & "$($configs.CertbotPath)"

        $SuccessMessage = if ($NeedsCertificateCreation) {
            $translation.CertificateSuccessfullyGenerated
        }
        else {
            $translation.CertificateSuccessfullyRenewed
        }

        Write-EventLog `
            -LogName Application `
            -Source $EventSource `
            -EntryType Information `
            -EventId 1003 `
            -Message $SuccessMessage

    }
    catch {

        Write-EventLog `
            -LogName Application `
            -Source $EventSource `
            -EntryType Error `
            -EventId 1004 `
            -Message $translation.CertificateGenerationError

        exit 1
    }
}
else {

    Write-EventLog `
        -LogName Application `
        -Source $EventSource `
        -EntryType Information `
        -EventId 1005 `
        -Message ($translation.NoRenewalNeeded -f $DaysRemaining)
}