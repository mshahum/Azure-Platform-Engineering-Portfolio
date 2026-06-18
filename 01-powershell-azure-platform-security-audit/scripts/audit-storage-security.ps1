# Lab 01 - PowerShell Azure Platform Security Audit
# Purpose: Audit Azure Storage Account security settings and export the results to CSV.

Write-Host "Starting Storage Security Audit..." -ForegroundColor Green

# Get current Azure subscription and account context
$context = Get-AzContext

Write-Host "Current Subscription: $($context.Subscription.Name)"
Write-Host "Current Account: $($context.Account.Id)"
Write-Host ""

try {
    # Get all Storage Accounts in the current Azure subscription
    $storageAccounts = @(Get-AzStorageAccount -ErrorAction Stop)

    Write-Host "Total Storage Accounts Found: $($storageAccounts.Count)"
    Write-Host ""

    # Build audit results with raw settings and readable compliance status
    $auditResults = @(
        $storageAccounts | Select-Object `
            StorageAccountName,
            ResourceGroupName,
            Kind,
            Location,
            @{Name = "SkuName"; Expression = { $_.Sku.Name }},
            MinimumTlsVersion,
            @{Name = "TlsStatus"; Expression = {
                if ($_.MinimumTlsVersion -eq "TLS1_2") {
                    "Compliant"
                }
                else {
                    "Risky"
                }
            }},
            EnableHttpsTrafficOnly,
            @{Name = "HttpsStatus"; Expression = {
                if ($_.EnableHttpsTrafficOnly -eq $true) {
                    "Compliant"
                }
                else {
                    "Risky"
                }
            }},
            AllowBlobPublicAccess,
            @{Name = "PublicAccessStatus"; Expression = {
                if ($_.AllowBlobPublicAccess -eq $false) {
                    "Compliant"
                }
                else {
                    "Risky"
                }
            }},
            @{Name = "OverallStatus"; Expression = {
                if (
                    ($_.MinimumTlsVersion -eq "TLS1_2") -and
                    ($_.EnableHttpsTrafficOnly -eq $true) -and
                    ($_.AllowBlobPublicAccess -eq $false)
                ) {
                    "Compliant"
                }
                else {
                    "Needs Review"
                }
            }}
    )

    # Display detailed audit results in the terminal
    $auditResults | Format-List

    # Create output folder path based on the script location
    $scriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
    $labFolder = Split-Path -Parent $scriptFolder
    $outputFolder = Join-Path $labFolder "sample-output"

    if (-not (Test-Path -Path $outputFolder)) {
        New-Item -ItemType Directory -Path $outputFolder | Out-Null
    }

    # Export audit results to CSV
    $outputPath = Join-Path $outputFolder "storage-security-audit-results.csv"

    $auditResults | Export-Csv -Path $outputPath -NoTypeInformation

    Write-Host ""
    Write-Host "Storage Security Audit Completed." -ForegroundColor Green
    Write-Host "Audit results exported to: $outputPath" -ForegroundColor Cyan

    # Output summary counts
    $totalCount = $auditResults.Count
    $compliantCount = ($auditResults | Where-Object { $_.OverallStatus -eq "Compliant" }).Count
    $needsReviewCount = ($auditResults | Where-Object { $_.OverallStatus -eq "Needs Review" }).Count

    Write-Host ""
    Write-Host "Summary of Audit Results" -ForegroundColor Cyan
    Write-Host "------------------------" -ForegroundColor Cyan
    Write-Host "Total Storage Accounts Audited: $totalCount"
    Write-Host "Compliant Storage Accounts: $compliantCount" -ForegroundColor Green
    Write-Host "Storage Accounts Needing Review: $needsReviewCount" -ForegroundColor Yellow
}
catch {
    Write-Host "Storage Accounts are not accessible. Please check your permissions." -ForegroundColor Red
    Write-Host "Reason: $($_.Exception.Message)" -ForegroundColor Yellow
    return
}
```
