#Start Message

Write-Host "Starting Storage Security Audit..." -ForeGroundColor Green

#Get Current Subscription and Account Information

$context = Get-AzContext

Write-Host "Current Subscription is: $($context.Subscription.Name)"
Write-Host "Current Account is: $($context.Account.Id)"

#Get All Storage Accounts in the Current Subscription

Try{
    $storageAccounts = Get-AzStorageAccount -ErrorAction Stop
    Write-Host "Total Storage Accounts found: $($storageAccounts.Count)"

    $AuditResults = $storageAccounts | Select-Object `
    StorageAccountName,
    ResourceGroupName,
    Kind,
    Location,
    @{Name="SkuName"; Expression={$_.Sku.Name}},
    MinimumTlsVersion,
    @{Name="TlsStatus"; Expression={
        if ($_.MinimumTlsVersion -eq "TLS1_2") {
            "Compliant"
        }
        else {
            "Risky"
        }
    }},
    EnableHttpsTrafficOnly,
    @{Name="HttpsStatus"; Expression={
        if ($_.EnableHttpsTrafficOnly -eq $true) {
            "Compliant"
        }
        else {
            "Risky"
        }
    }},
    @{Name="PublicAccessStatus"; Expression={
        if ($_.AllowBlobPublicAccess -eq $false) {
            "Compliant"
        }
        else {
            "Risky"
        }
    }},
    @{Name="OverAllStatus"; Expression={
        if (($_.MinimumTlsVersion -eq "TLS1_2" ) -and
           ($_.EnableHttpsTrafficOnly -eq $true) -and
           ($_.AllowBlobPublicAccess -eq $false) ) {
            "Compliant"
           }
           else {
             "Needs Review"
           } 
          

    }} 

    $AuditResults | Format-List


}

Catch{
    Write-Host "Storage Account are not accessible. Please check your permissions." -ForegroundColor Red
    Write-Host "Reason: $($_.Exception.Message)" ForegroundColor Yellow
    Return
}

$outputFolder = ".\01-powershell-azure-platform-security-audit\sample-output"

if (-not (Test-Path -Path $outputFolder)) {
    New-Item -Itemtype Directory -Path $outputFolder | Out-Null}

    $outPutPath = "$outputFolder\storage-security-audit-results.csv"

    $auditResults | Export-Csv -Path $outPutPath -NoTypeInformation

    Write-Host ""

    Write-Host "Storage Security Audit Completed."

    Write-Host "Audit Results exported to: $outPutPath" -ForegroundColor Green

    # Output Summary

    $totalCount = $auditResults.Count
    $compliantCount = ($auditResults | Where-Object {$_.OverAllStatus -eq "Compliant"}).count
    $needsReviewCount = ($auditResults | Where-Object {$_.OverAllStatus -eq "Needs Review"}).count

    Write-Host ""

Write-Host "Summary of Audit Results:" -ForegroundColor Cyan
Write-Host "Total Storage Account Audit: $totalCount"  
Write-Host "Total Compliant Storage Accounts: $compliantCount" -ForegroundColor Green
Write-Host "Total Storage Accounts that Needs Review: $needsReviewCount" -ForegroundColor Yellow