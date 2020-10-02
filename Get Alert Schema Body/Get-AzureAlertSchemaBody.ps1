$sectionToKeep = "body"
$json = Get-Content .\rawAlertData.json -raw | ConvertFrom-Json
$json.$sectionToKeep | ConvertTo-Json -Depth 100 | Out-File .\schemaBody.json