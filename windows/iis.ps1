Import-Module WebAdministration

$configContent = (Get-Content (Join-Path $PSScriptRoot "config.ini") -Raw).Replace('\', '\\')
$configs = $configContent | ConvertFrom-StringData
$translation = Get-Content (Join-Path $PSScriptRoot "translation.ini") -Raw | ConvertFrom-StringData

$SiteId = $configs.IISSiteID

$Cert = Get-ChildItem Cert:\LocalMachine\$($configs.CertificateStore) |
    Where-Object {
        $_.Subject -like "CN=$($configs.WildcardDomains)*"
    } |
    Sort-Object NotAfter -Descending |
    Select-Object -First 1

if (-not $Cert) {
    throw "Aucun certificat $($configs.WildcardDomains) trouvé dans $($configs.CertificateStore)"
}

$Site = Get-Website |
    Where-Object { $_.ID -eq $SiteId }

if (-not $Site) {
    throw "$($translation.IISSiteIDMissing)"
}

Write-Host "Site : $($Site.Name)"
Write-Host "Certificat : $($Cert.Subject)"
Write-Host "Thumbprint : $($Cert.Thumbprint)"

$Bindings = Get-WebBinding `
    -Name $Site.Name `
    -Protocol https

foreach ($Binding in $Bindings) {

    $Binding.AddSslCertificate(
        $Cert.Thumbprint,
        "WebHosting"
    )

    Write-EventLog `
    -LogName Application `
    -Source "$($translation.LogName)" `
    -EventId 2000 `
    -EntryType Information `
    -Message "$($translation.BindingUpdated)"
}