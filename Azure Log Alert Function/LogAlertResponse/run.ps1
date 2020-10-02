using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host 'PowerShell HTTP trigger function processed a request.'

# Set common variables
$ErrorActionPreference = 'stop'
$alertData = [object] ($Request.body)

if ($alertData) {
    # Get the schema type
    $schemaId = $alertData.schemaId
    Write-Host 'Schema type: ' $schemaId

    # If not the 2019 common alert schema type then exit
    if ($schemaId -eq 'azureMonitorCommonAlertSchema') {
        Write-Host 'Correct schema type'
    } elseif (($null -eq $schemaId) -or ($schemaId -eq "" )) {
        # no schema defined
        Write-Error 'Not Azure Alert data'
    } else {
        # schema not supported
        Write-Error "The alert data schema - $schemaId - is not supported"
    } # if schema -eq azureMonitorCommonAlertSchema

    # Collect required metadata for later
    # Request.body.data.essentials.*
    # Request.body.data.alertContext.*
    $essentials = [object] ($alertData.data.essentials)
    $alertContext = [object] ($alertData.data.alertContext)
    
    # Only act on alerts from monitors in a 'Fired' or 'Activated' state.
    # This will capture new alerts
    # If you want to act upon alerts that are closed, rather than new, change logic to detect resolved 
    # condition instead
    if (($essentials.monitorCondition -eq 'Activated') -or ($essentials.monitorCondition -eq 'Fired')) {
        Write-Host 'Status:' $essentials.monitorCondition
    } else {
        # The monitor condition was not 'Fired' or 'Activated' so no action is taken
        Write-Host 'No action taken. Alert status:' $essentials.monitorCondition
        exit
    } # if check monitorcondition

    # Begin working with the search results from the Log Search alert
    # Confirm that the alert results have row data to work with
    # If not then exit
    if ($null -ne $alertContext.SearchResults.tables.rows) {
        Write-Host 'Search results rows are not null'
        $searchResultRows = $alertContext.SearchResults.tables[0].rows
        $searchResultColumns = $alertContext.SearchResults.tables[0].columns

        # Read each row from the results of the alert. There could be multiple rows.
        # For each row we will then take the column properties and assign them to variables
        foreach ($searchResultRow in $searchResultRows) {
            $column = 0
            $record = New-Object -TypeName PSObject
            $message = ""
            $linespacer = "`n"
            $spacer = ": "

            # We have a single row now
            # Take each column property in the row and assign it to a variable
            foreach ($searchResultColumn in $searchResultColumns) {
                $name = $searchResultColumn.name
                $columnValue = $searchResultRow[$column]
                $record | Add-Member -MemberType NoteProperty -Name $name -Value $columnValue -Force

                $message = $message + "$name $spacer $columnValue"
                $message = $message + $linespacer

                $column++
            }
            Write-Host $message
        }

    } else {
        Write-Host 'Search results rows are null. No data to process. Exiting.'  
              
    } # Begin work with search results

} else {
    # input data is not from an Azure Alert
    Write-Error 'Not Azure Alert data'
    
} # if alertData

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = 'Azure Function completed'
})