[Int]$CurrTime = Get-Date -UFormat "%s"
[Int]$WSUSCompTime = (Get-WsusServer).GetSubscription().GetLastSynchronizationInfo().EndTime | Get-Date -UFormat "%s"
Write-Host "Last WSUS Completion: $WSUSCompTime"
(Get-WsusServer).GetSubscription().StartSynchronization()
while ($WSUSCompTime -lt $CurrTime) {
    Start-Sleep -s 60
    $WSUSCompTime = (Get-WsusServer).GetSubscription().GetLastSynchronizationInfo().EndTime | Get-Date -UFormat "%s"
}
$WSUSResult = (Get-WsusServer).GetSubscription().GetLastSynchronizationInfo().Result
Write-Host "WSUS Synchronization Completed: $WSUSResult"
