#always reload module
if (-not (Get-Module -name integration_toolset)) {
    write-host "integration_toolset does not exists. Load the module"
    Import-Module "D:\SQLShare\Import_Export_SingleServer\PS_Tools\Modules\integration_toolset.psm1"
}
else {
    Import-Module "D:\SQLShare\Import_Export_SingleServer\PS_Tools\Modules\integration_toolset.psm1" -Force
}

#import sql server modlue
if (-not(get-module -name sqlserver)) {
    write-host "SQL Server Module does not exits. Load the module"
    Import-Module sqlserver
}
try {
    [string] $export_dt = (get-date -Format yyyy-MM-dd)
    [string] $companyid = "200000244"      
    [string] $server = get-dbserver
    [string] $db = "v3Equity"
    [string] $error_logfile = "D:\SQLShare\Import_Export_SingleServer\Export\MayInstitute\logfile\export_mayinstitute_error_$export_dt.log"
	[string] $sftp_logfile = "D:\SQLShare\Import_Export_SingleServer\Export\MayInstitute\logfile\sftp_$export_dt.log"
	$export_path = "D:\SQLShare\Import_Export_SingleServer\Export\MayInstitute\exportfile\"
    # $file_attachment = "D:\SQLShare\Import_Export_SingleServer\Export\MayInstitute\exportzip\exportfile*.zip" 
	 
    #get user database  
    # $db = get_company_db($companyid)
	# $qry_to_run = ""
    $timeout = 600 

#======================================================================================================================================================	
#export data Reservation	
	$qry_extract1 = "D:\SQLShare\Import_Export_SingleServer\Export\MayInstitute\exportscript\dbscript\ReservationFull_Mayinstitute.sql"
    $export_file1 = $export_path + "ReservationFull_MayInstitute" + ".csv"
   
    $qry = (Get-Content $qry_extract1 ) -replace ("db_companyid", "$companyid")
    $qry_to_run = ""
    foreach ($line in $qry) { $qry_to_run = $qry_to_run + "`r`n" + $line }
	
	Invoke-Sqlcmd -query $qry_to_run `
        -ServerInstance $server `
        -Database $db `
        -QueryTimeout $timeout ` |
        #-TrustServerCertificate |
        convertTo-csv -NoTypeInformation -UseQuotes Never |
        Set-Content $export_file1 -ErrorAction Stop

    Write-Host "Reservation Export Complete..."
#======================================================================================================================================================

#zip files
	Compress-Archive -Path D:\SQLShare\Import_Export_SingleServer\Export\MayInstitute\exportfile\*.csv `
        -DestinationPath D:\SQLShare\Import_Export_SingleServer\Export\MayInstitute\exportzip\exportfile_$export_dt.zip

 
#SFTP upload from dataservices
       SFTP_upload -serverfile "D:\SQLShare\Import_Export_SingleServer\connections\AngusSFTP.txt" -srvname "sftp1.angusanywhere.com" `
              -localfolder "D:\SQLShare\Import_Export_SingleServer\Export\MayInstitute\exportfile\" -remotefolder "/TheMayInstitute/files/DataExtracts" `
              -filetype '*' -logfile $sftp_logfile

              #archive
	Move-Item -Path "D:\SQLShare\Import_Export_SingleServer\Export\MayInstitute\exportfile\*.csv" -Destination "D:\SQLShare\Import_Export_SingleServer\Export\MayInstitute\exportfile\Archive\" -Force        
    Write-Host "Export Files successfully archived"
    
    Move-Item -Path "D:\SQLShare\Import_Export_SingleServer\Export\MayInstitute\exportzip\*.zip"  -Destination "D:\SQLShare\Import_Export_SingleServer\Export\MayInstitute\exportfile\Archive\" -Force
    Write-Host "Export .zip successfully archived"
    
	 
}
catch {
    (get-date).ToString() + ":" + $_.Exception.Message | Out-File "$error_logfile"
}
