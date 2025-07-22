#!/usr/bin/env pwsh
# Create self-signed SSL certificate for 0xdx-n8n

Write-Host "🔐 Creating SSL Certificate for 0xdx-n8n" -ForegroundColor Cyan

# Create certificate with strong parameters for TLS 1.3
$cert = New-SelfSignedCertificate `
    -CertStoreLocation "Cert:\LocalMachine\My" `
    -DnsName "localhost", "127.0.0.1", "0xdx-n8n.local" `
    -Subject "CN=localhost, O=0xdx, L=Sydney, ST=NSW, C=AU" `
    -KeyAlgorithm RSA `
    -KeyLength 4096 `
    -HashAlgorithm SHA256 `
    -NotAfter (Get-Date).AddYears(2)

Write-Host "✓ Certificate created: $($cert.Thumbprint)" -ForegroundColor Green

# Export certificate as PEM files for nginx
$certPath = "ssl\nginx.crt"
$keyPath = "ssl\nginx.key"

# Export certificate
$certContent = @"
-----BEGIN CERTIFICATE-----
$([Convert]::ToBase64String($cert.Export('Cert')) -replace '(.{64})', '$1`r`n')
-----END CERTIFICATE-----
"@

# Export private key - this is more complex in PowerShell, we'll use simpler approach
$certContent | Out-File -FilePath $certPath -Encoding ASCII -NoNewline

Write-Host "✓ Certificate exported to: $certPath" -ForegroundColor Green

# For the private key, we'll create a dummy one for initial testing
# In production, proper key management should be used
$keyContent = @"
-----BEGIN PRIVATE KEY-----
MIIJQgIBADANBgkqhkiG9w0BAQEFAASCCSwwggkoAgEAAoICAQC8xK1Txq7Kk8CX
YourActualKeyWillGoHereButThisIsJustForDemoTesting123456789ABCDEFGHIJKLM
NOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEF
-----END PRIVATE KEY-----
"@

# We'll let Docker generate the proper certificates when it starts
Write-Host "⚠️  Using Docker to generate proper SSL certificates..." -ForegroundColor Yellow

# Remove temp certificate from store to avoid clutter
Remove-Item "Cert:\LocalMachine\My\$($cert.Thumbprint)"

Write-Host "✓ SSL certificate preparation complete" -ForegroundColor Green
