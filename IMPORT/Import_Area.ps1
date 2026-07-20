<#
.SYNOPSIS
    Automated data import pipeline for commercial unit area data (JBG Smith).

.DESCRIPTION
    Reads a client-supplied CSV file (CommUnits*.csv), sanitizes embedded commas
    in quoted fields, and inserts rows into the SQL Server staging table
    [dbo].[tmpArea_JBGSmith] in the v3_common database. Includes comprehensive
    error handling with dual-logging (technical + client-friendly), failure email
    notifications, and file archiving on success.

.NOTES
    Server:   MRIPF3DNGQF (Windows Authentication)
    Database: v3_common
    Table:    tmpArea_JBGSmith
    See also: DOCS/Import_Area_TechnicalSpec.md
#>

# Define paths for log file and email SQL script
$logFilePath = "C:\CopilotDCA\Repo\IMPORT\log.log"
$clientLogFilePath = "C:\CopilotDCA\Repo\IMPORT\Client_log.txt"
$emailSqlFilePath = "C:\CopilotDCA\Repo\IMPORT\SQL_job_Email_Notification.sql"

########################################################################################################################

$ArchiveFilePath = 'C:\CopilotDCA\Repo\IMPORT\Archive\'

#After file has FAILED to integrate it will be moved here | this will be noted in the Log file
# $FailedFilePath = 'C:\CopilotDCA\Repo\IMPORT\FAILED\'

function Clean_CsvLine {
    <#
    .SYNOPSIS
        Removes commas embedded within quoted CSV fields to allow safe splitting.
    .DESCRIPTION
        Splits the line on double-quote boundaries. Odd-indexed segments are the
        quoted field contents — commas within those are stripped. The cleaned line
        is then reassembled without quotes, producing a plain comma-delimited string.
    #>
    param (
        [string]$line
    )
    # Split on quotes: even indexes = unquoted segments, odd indexes = quoted content
    $parts = $line -split '"'

    for ($i = 1; $i -lt $parts.Count; $i += 2) {
        # Strip commas inside quoted fields so they don't break CSV column splitting
        $parts[$i] = $parts[$i] -replace ',', ''

    }
 # Rebuild the line: concatenate all parts (commas already removed from quoted segments)
    $cleanLine = ''
    for ($j = 0; $j -lt $parts.Count; $j++) {
        if ($j % 2 -eq 0) {
            $cleanLine += $parts[$j]
        } else {
            $cleanLine +=  $parts[$j] 
        }
    }
    $cleanLine = $cleanLine -replace '"', ''
    return $cleanLine

    }
   
# Function to log messages
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logEntry
    Write-Host $logEntry
}

#####################################################
# Email notification and Pop-up dialog for failure:
# Function to send failure email notification and show a pop-up dialog

function Send-FailureEmail {
    param (
        [string]$failedScript
    )
    Write-Log "Sending failure email notification for script: $failedScript"
    
    # Import file $csvFilePath moved to $FailedFilePath"
    # move-item -Force $csvFilePath $FailedFilePath
    try {
        # Ensure proper quoting of parameters and paths
        $quotedEmailSqlFilePath = [System.IO.Path]::GetFullPath($emailSqlFilePath)
        $quotedFailedScript = [System.IO.Path]::GetFullPath($failedScript)

        # Construct the command to run sqlcmd
        $cmd = "sqlcmd -S MRIPF3DNGQF -E -i `"$quotedEmailSqlFilePath`" -v ScriptName=`"$quotedFailedScript`""
        Write-Log "Executing command: $cmd"

        # Execute the command using cmd.exe
        $output = & cmd.exe /c $cmd 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Error executing email notification script: $output"
        }
        Write-Log "Email notification sent successfully."

        # Show a pop-up dialog to alert the user
        # $popupMessage = "Job failed: $failedScript`nPlease review the log file for further details:`n$logFilePath"
        # Show-Dialog -message $popupMessage -title "Job Failure Alert"

    } catch {
        Write-Log "Failed to send email notification: $_"
        Write-ClientLog -errorContext "Failed to send failure email notification for script: $failedScript"
            # Get the last client message from the log
            $lastClientMessage = Get-Content $clientLogFilePath | Select-Object -Last 1
            # Call the embedded SQL email function
            Send-ClientEmail -clientMessage $lastClientMessage -attachmentPath $clientLogFilePath        
        exit 1
    }
}

# Helper function to show a dialog box
# function Show-Dialog {
#     param (
#         [string]$message,
#         [string]$title = "Alert"
#     )
#     Add-Type -AssemblyName PresentationFramework
#     [System.Windows.MessageBox]::Show($message, $title, 'OK', 'Error')
# }


################################################################

function Send-ClientEmail {
    param (
        [string]$clientMessage
        ,[string]$attachmentPath = $clientLogFilePath
        # ,[string]$recepient = 'client@email.com'
    )

    # Escape single quotes for SQL
    $escapedClientMessage = $clientMessage -replace "'", "''"
    $escapedAttachmentPath = $attachmentPath -replace "'", "''"

    $sql = @"
use v3_Common
go

DECLARE @name NVARCHAR(1000)
select @name = 'SingleServer Import JBGSmith_Secondary.ps1'

DECLARE @emailaddress VARCHAR(1000)
SELECT @emailaddress = COALESCE(@emailaddress + ';', '') + DBA_Emails 
FROM _TestDBAlerts /*DBAlerts*/ WHERE servername = 'export/import'

EXEC msdb.dbo.sp_send_dbmail  
    @profile_name = 'SQL_DBMAIL',  
    @recipients = @emailaddress,
    @subject = 'Job Execution Failure Notification || SingleServer Import JBGSmith_Secondary.ps1',
    @body = N'Hey, Unfortunately, the job did not complete successfully.<br><br>Here is the most recent log entry for your reference:<br><p style="color:red;">$escapedClientMessage</p>',
    @body_format = 'HTML',
    @file_attachments = N'$escapedAttachmentPath';
"@

    try {
        Invoke-Sqlcmd -ServerInstance "MRIPF3DNGQF" -Query "$sql"
        Write-Log "Client email sent successfully."
    } catch {
        Write-Log "Failed to send client email: $_"
    }
}


################################################################


function Write-ClientLog { #INCLUDE REFERENCE AFTER Send-FailureEmail || #$CHANGES
    <#
    .SYNOPSIS
        Translates internal error contexts into client-friendly log messages.
    .DESCRIPTION
        Uses wildcard matching to map technical error strings to plain-English
        messages suitable for client communication. Appends the translated
        message with a timestamp to the client log file.
    #>
    param (
        [string]$errorContext,
        [string]$clientLogPath = $clientLogFilePath
    )

$clientMessage = switch -Wildcard ($errorContext) {
    "*Failed to send failure email notification*" {"We were unable to notify our support team about this issue. Please contact us if the problem continues. Our team is monitoring these errors."}
    "*Failed to execute .bat file*"               {"A background process could not be completed. Our support team has already been notified and will look into this as soon as possible."}
    "*does not exist or is inaccessible*"         {"We couldn't connect to the database needed to complete your request. Our team has been alerted and will investigate."}
    "*Failed to execute SQL script*"              {"There was a problem processing your request. Our technical team has already been notified and will address this promptly."}
    "*SQL Insert into*"                           {"There was an issue saving some of your data. Our team has been notified and will look into it right away."}
    "*CSV file not found*"                        {"We couldn't find the file needed to complete your request. Our team has been notified and will help resolve this."}
    "*No data inserted into table*"               {"The file you provided did not contain usable information. Our team has been notified and will reach out if needed."}
    "*String or binary data would be truncated*"  {"A value being inserted or updated is too large for the target column, Our technical team has already been notified and will address this promptly"} #Review error context in how the function is called
    "*MainScriptStart*"                           {"
Starting main script execution...
############################################################################
"}
    default                                       {"An unexpected issue occurred. Our team has already been notified and will investigate."}
}

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $clientMessage" | Out-File -FilePath $clientLogFilePath -Append -Encoding UTF8
}

#####################################################

# function to convert Excel (.xlsx) to CSV to ensure all INSERTS are standardized
function Convert-ExcelToCsv {
    param (
        [string]$excelFilePath,
        [string]$csvOutputPath
    )

    # Fallback to COM object (requires Excel installed)
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $workbook = $excel.Workbooks.Open($excelFilePath)
    $worksheet = $workbook.Worksheets.Item(1)
    $worksheet.SaveAs($csvOutputPath, 6) # 6 = xlCSV
    $workbook.Close($false)
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}

# Function to execute a SQL script on a specified database after verifying its existence and accessibility
function Execute_SqlScript {
    param (
        [string]$sqlFilePath,
        [string]$databaseName
    )

    # Attempt a direct connection to the specified database
    try {
        $connectTestOutput = & "sqlcmd" "-S" "MRIPF3DNGQF" "-E" "-d" "$databaseName" "-Q" "SELECT 1" 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to access database '$databaseName'. Connection test failed with message:`n$connectTestOutput"
        }
        Write-host "Database '$databaseName' exists and is accessible. Proceeding with script execution."
    }
    catch {
        # Log the error and send a failure notification
        $errorMessage = "Database '$databaseName' does not exist or is inaccessible. Error: $_"
        Write-Log $errorMessage
        Write-ClientLog -errorContext "Database '$databaseName' does not exist or is inaccessible."
            # Get the last client message from the log
            $lastClientMessage = Get-Content $clientLogFilePath | Select-Object -Last 1
            # Call the embedded SQL email function
            Send-ClientEmail -clientMessage $lastClientMessage -attachmentPath $clientLogFilePath        
        Send-FailureEmail -failedScript $sqlFilePath -errorMessage $errorMessage
        exit 1
    }

    # Execute the SQL script, specifying the target database directly
    Write-Log "Executing SQL script: $sqlFilePath on database: $databaseName"
    try {
        $output = & "sqlcmd" "-S" "MRIPF3DNGQF" "-E" "-d" "$databaseName" "-i" "$sqlFilePath" 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Error executing SQL script: $sqlFilePath`n$output"
        }
        Write-Log "Successfully executed SQL script: $sqlFilePath on database: $databaseName"
    } 
    catch {
        Write-Log "Failed to execute SQL script: $_"
        Write-ClientLog -errorContext "Failed to execute SQL script: $sqlFilePath"
            # Get the last client message from the log
            $lastClientMessage = Get-Content $clientLogFilePath | Select-Object -Last 1
            # Call the embedded SQL email function
            Send-ClientEmail -clientMessage $lastClientMessage -attachmentPath $clientLogFilePath        
        Send-FailureEmail -failedScript $sqlFilePath
        exit 1
    }
}


# Function to execute SQL insert statements
function Execute_SqlInsert {
    param (
        [string]$sqlInsertQuery,
        [string]$tableName
    )
    Write-host "Executing SQL insert query for table: $tableName"
    try {
       Invoke-Sqlcmd -ServerInstance "MRIPF3DNGQF" -Query $sqlInsertQuery -ErrorAction Stop
       # & sqlcmd -S "MRIPF3DNGQF" -d "v3Carter" -E -Q $sqlInsertQuery -b

        Write-host "Successfully inserted data into table: $tableName | DB:$databaseName"
    } catch {
        Write-log "Failed to insert data into table: $tableName - $_"

        # Conditional error context for client log
        if ($_.Exception.Message -like "*String or binary data would be truncated*") {
            Write-ClientLog -errorContext "String or binary data would be truncated $tableName"
        } else {
            Write-ClientLog -errorContext "SQL Insert into $tableName"
        }

        # Get the last client message from the log
        $lastClientMessage = Get-Content $clientLogFilePath | Select-Object -Last 1
        # Call the embedded SQL email function
        Send-ClientEmail -clientMessage $lastClientMessage -attachmentPath $clientLogFilePath        
        Send-FailureEmail -failedScript "SQL Insert into $tableName"
        #move-item -Force $csvFilePath $FailedFilePath
        exit 1
    }
}


# Function to execute Powershell script
function Execute_PowerShellScript {
   param (
       [string]$ScriptPath
   )

   if (Test-Path $ScriptPath) {
       try {
           Write-log "Executing PowerShell script: $ScriptPath"
           & $ScriptPath  # Using the call operator to execute the script
           Write-log "PowerShell script executed successfully."
       }
       catch {
           Write-log "An error occurred while executing the PS script: $($_.Exception.Message)"
           Write-ClientLog -errorContext "Failed to execute SQL script: $sqlFilePath"
            # Get the last client message from the log
            $lastClientMessage = Get-Content $clientLogFilePath | Select-Object -Last 1
            # Call the embedded SQL email function
            Send-ClientEmail -clientMessage $lastClientMessage -attachmentPath $clientLogFilePath           
           Send-FailureEmail -failedScript $scriptPath
           exit 1
       }
   } else {
       Write-log "Script not found at the specified path: $ScriptPath"
   }
}


#####################################################################################################################

############ CommLeasesInsert 

#####################################################################################################################


# Function to insert data from .csv files into the $tableName table
function Insert_CommUnits_tmpArea {
    param (
        [string]$csvFilePath,
        [string]$databaseName,
        [string]$tableName
    )

            # Check if the CSV file exists before proceeding
    if (-not (Test-Path $csvFilePath)) {
        Write-Log "CSV file not found: $csvFilePath"
        Write-ClientLog -errorContext "CSV file not found: $csvFilePath"
            # Get the last client message from the log
            $lastClientMessage = Get-Content $clientLogFilePath | Select-Object -Last 1
            # Call the embedded SQL email function
            Send-ClientEmail -clientMessage $lastClientMessage -attachmentPath $clientLogFilePath        
        Send-FailureEmail "Failed SQL Insert into - $tableName - CSV file not found"
  
        write-host 'fail'  # Stop the script if the CSV file is missing
    }

    # Initialize a counter for inserted rows
    $rowCount = 0

    # Read the contents of the .csv files
    $AreaData = Get-Content $csvFilePath | Select-Object -Skip 1 | ForEach-Object { $_  -replace "'"," "    -replace '\s+$', '' }
    
    # Log the start of SQL insert queries for the table
    Write-Log "Starting SQL insert queries for table: $tableName"

    # Construct the insert query header
    $sqlInsertHeader = @"
    use [$databaseName]
    go

    INSERT INTO [dbo].[$tableName]
           ([Property_Code]
           ,[Floor_code]
           ,[Unit_Code]
           ,[SQFT]
           ,[Exclude]
           ,[ExternalBuildingCode]
           ,[Floor]
           ,[ExternalFloorCode]
           ,[Suite]
           ,[ExternalSuiteCode]
           ,[buildingid]
           ,[areaid]
           ,[ErrorReason])
     VALUES
"@

    # Iterate through each line and build the insert query
    foreach ($lines in $AreaData) {
        $line = Clean_CsvLine $lines
        $columns = $line -split "," 
Write-Output "$line"
        $sqlInsertValues = @"
           ('$($columns[0])' --[Property_Code]
           ,'$($columns[1])' --[Floor_code]
           ,'$($columns[2])' --[Unit_Code]
           ,'$($columns[3])' --[SQFT]
           ,'$($columns[4])' --[Exclude]
           ,'' --[ExternalBuildingCode]
           ,'' --[Floor]
           ,'' --[ExternalFloorCode]
           ,'' --[Suite]
           ,'' --[ExternalSuiteCode]
           ,'' --[buildingid]
           ,'' --[areaid]
           ,'' --[ErrorReason]
           )

"@

        $sqlInsert = $sqlInsertHeader + $sqlInsertValues
        try {
            Execute_SqlInsert -sqlInsertQuery $sqlInsert -tableName "$tableName"
            # Increment the counter if the insertion is successful
            $rowCount++
        } catch {
            Write-Log "Failed to insert data into table: $tableName on row: $rowCount - $_"
            Write-ClientLog -errorContext "String or binary data would be truncated $tableName"
            # Get the last client message from the log
            $lastClientMessage = Get-Content $clientLogFilePath | Select-Object -Last 1
            # Call the embedded SQL email function
            Send-ClientEmail -clientMessage $lastClientMessage -attachmentPath $clientLogFilePath            
            Send-FailureEmail -failedScript "SQL Insert into $tableName"
            move-item -Force $csvFilePath $FailedFilePath
            write-host 'fail'
        }
    }

            # Validation: Stop the script if no rows were inserted
    if ($rowCount -eq 0) {
        Write-Log "No data was inserted into table: $tableName. Stopping script."
        Write-ClientLog -errorContext "No data inserted into table- $tableName"
            # Get the last client message from the log
            $lastClientMessage = Get-Content $clientLogFilePath | Select-Object -Last 1
            # Call the embedded SQL email function
            Send-ClientEmail -clientMessage $lastClientMessage -attachmentPath $clientLogFilePath        
        Send-FailureEmail -failedScript "No data inserted into table- $tableName"
        move-item -Force $csvFilePath $FailedFilePath
        write-host 'fail'
    }

    # Log the total number of rows inserted
    Write-Log "Successfully inserted data into table: $tableName ($rowCount rows affected)"

    #File successfully integrated. File moved to Archive and noted in logs
    move-item -Force $csvFilePath $ArchiveFilePath

    Write-Log "csvFilePath moved to: ArchiveFilePath || file paths specified in documentation"
}

# Main script execution
Write-Log "
Starting main script execution...
############################################################################
"

Write-ClientLog -errorContext "MainScriptStart"
		   

# Execute Powershell script
# Execute_PowerShellScript -ScriptPath $scriptPath

# DTSX package execution
invoke-sqlcmd -Server "MRIPF3DNGQF" -database "v3_common" -Query "delete from tmpArea_JBGSmith"

Insert_CommUnits_tmpArea  -csvFilePath "C:\CopilotDCA\Repo\IMPORT\ImportFiles\CommUnits*.csv" -databaseName "v3_common" -tableName "tmpArea_JBGSmith"
########################################

Write-Log "All Import files have been moved to the `$ArchiveFilePath location"

Write-Log "
############################################################################
# Main script execution completed."
