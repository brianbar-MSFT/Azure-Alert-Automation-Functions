$rawAlertData = '.\rawAlertData.json'
$sectionToKeep = 'body'
$json = Get-Content $rawAlertData -raw | ConvertFrom-Json
$json.$sectionToKeep | 
ConvertTo-Json -Depth 100 | 
Out-File .\schemaBody.json