
$secrets = Get-Content (Join-Path $PSScriptRoot "secrets.ini") -Raw | ConvertFrom-StringData
$configContent = (Get-Content (Join-Path $PSScriptRoot "config.ini") -Raw).Replace('\', '\\')
$configs = $configContent | ConvertFrom-StringData
$translation = Get-Content (Join-Path $PSScriptRoot "translation.ini") -Raw | ConvertFrom-StringData
$Wacs = $configs.WACSPath

& $Wacs `
    --target manual `
    --nocache `
    --host "$($configs.WildcardDomains)" `
    --validation script `
    --script "powershell.exe" `
    --dnscreatescript "$($configs.AcmeHookPath)" `
    --dnscreatescriptarguments "create {RecordName} {Token}" `
    --dnsdeletescript "$($configs.AcmeHookPath)" `
    --dnsdeletescriptarguments "delete {RecordName}" `
    --store "certificatestore" `
    --certificatestore "$($configs.CertificateStore)" `
    --friendlyname "$($configs.CertificateFriendlyName)" `
    --baseuri "$($configs.ServerUrl)" `
    --eab-key-identifier "$($secrets.EabKid)" `
    --eab-key "$($secrets.EabHmac)" `
    --accepttos

if ($LASTEXITCODE -eq 0) {

    Write-Host "$($translation.CertificateSuccessfullyGenerated)"

    # Mise à jour IIS
    & "$($configs.IISScriptPath)"
}
else {

    Write-Host "$($translation.CertificateGenerationError)"
    exit 1
}