Import-Module Sqlps -DisableNameChecking;

#--------------------------- Menu Generator Code ----------------------------------------------------------
$fcolor = $host.UI.RawUI.ForegroundColor
$bcolor = $host.UI.RawUI.BackgroundColor
$vkeycode = 0
$pos = 0
 function DrawMenu {
    ## supportfunction to the Menu function below
    param ($menuItems, $menuPosition, $menuTitel)
    $fcolor = $host.UI.RawUI.ForegroundColor
    $bcolor = $host.UI.RawUI.BackgroundColor
    $l = $menuItems.length + 1
    cls
    $menuwidth = $menuTitel.length + 4
    Write-Host "`t" -NoNewLine
    Write-Host ("*" * $menuwidth) -fore $fcolor -back $bcolor
    Write-Host "`t" -NoNewLine
    Write-Host "* $menuTitel *" -fore $fcolor -back $bcolor
    Write-Host "`t" -NoNewLine
    Write-Host ("*" * $menuwidth) -fore $fcolor -back $bcolor
    Write-Host ""
    Write-debug "L: $l MenuItems: $menuItems MenuPosition: $menuposition"
    for ($i = 0; $i -le $l;$i++) {
        Write-Host "`t" -NoNewLine
        if ($i -eq $menuPosition) {
            Write-Host "$($menuItems[$i])" -fore $bcolor -back $fcolor
        } else {
            Write-Host "$($menuItems[$i])" -fore $fcolor -back $bcolor
        }
    }
}

function Menu {
    ## Generate a small "DOS-like" menu.
    ## Choose a menuitem using up and down arrows, select by pressing ENTER
    param ([array]$menuItems, $menuTitel = "MENU")
    $vkeycode = 0
    $pos = 0
    DrawMenu $menuItems $pos $menuTitel
    While ($vkeycode -ne 13) {
        $press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
        $vkeycode = $press.virtualkeycode
        Write-host "$($press.character)" -NoNewLine
        If ($vkeycode -eq 38) {$pos--}
        If ($vkeycode -eq 40) {$pos++}
        if ($pos -lt 0) {$pos = 0}
        if ($pos -ge $menuItems.length) {$pos = $menuItems.length -1}
        DrawMenu $menuItems $pos $menuTitel
    }
    Write-Output $($menuItems[$pos])
}
#--------------------------- Menu Generator Code ----------------------------------------------------------



#--------------------------- Database Export Code-----------------------------------------------------------
#Decided choose database file path 
$SQLServerVer = @{
"Version100" = "MSSQL10.MSSQLSERVER"; 
"Version105" = "MSSQL10_50.MSSQLSERVER"; 
"Version110" = "MSSQL11.MSSQLSERVER"; 
"Version120" = "MSSQL12.MSSQLSERVER"; 
"Version130" = "MSSQL13.MSSQLSERVER"}


$dbVersion = [Enum]::GetNames('Microsoft.SqlServer.Management.Smo.SqlServerVersion')
 

# First Choose Export dbVersion  
$selectDbVersion = Menu $dbVersion "Please Choose Export target dbVersion"


if($selectDbVersion -ne $null){
    #Choose using script or execute on remote. 
    $executeMethods = @("Execute by Script","Execute By Remote")
    $selectExecuteMethod = Menu $executeMethods "Please Choose using script or execute on remote."
 
    if(!(Test-Path ".\config.json")){
        Write-Host "config.json is not exists. please enter your db information."
        #Generator config.json
        '{
         "local":{
          "ServerName" : "",
          "DbName":"",
          "userId":"",
          "userPwd":""
         },
         "target":{
          "ServerName" : "",
          "DbName":"",
          "userId":"",
          "userPwd":""
         }
        }' >>  'config.json'
        $local  = Read-Host -Prompt 'Input your export server name '
        $dbName = Read-Host -Prompt 'Input your export database name '
        $userId = Read-Host -Prompt  'Input your export db userID'
        $userPwd= Read-Host -Prompt  'Input your export db userPwd'
    
        $targetLocal  = Read-Host -Prompt 'Input your target server name '
        $targetDbName  = Read-Host -Prompt 'Input your target database name '
        $targetUserId  = Read-Host -Prompt  'Input your target db userID'
        $targetUserPwd = Read-Host -Prompt  'Input your target db userPwd'
    }else{
        $obj = Get-Content .\config.json | ConvertFrom-Json
        $local  = $obj.local.ServerName
        $dbName = $obj.local.DbName 
        $userId = $obj.local.userId
        $userPwd= $obj.local.userPwd
        
        $targetLocal  = $obj.target.ServerName
        $targetDbName  = $obj.target.DbName
        $targetUserId  = $obj.target.userId
        $targetUserPwd = $obj.target.userPwd
    }
    # Start Export Data by using SMO 
    $outputPath = ".\dbSchema.sql"
    $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
    $conn.ConnectionString = "Data Source=$local;Initial Catalog=$dbName;User ID=$userId;Password=$userPwd;MultipleActiveResultSets=True;Application Name=Powershell"


    $srv = New-Object Microsoft.SqlServer.Management.Smo.Server($conn)
    $db = New-Object Microsoft.SqlServer.Management.Smo.Database
    $db = $srv.Databases.Item($dbName)
    $scrp = New-Object Microsoft.SqlServer.Management.Smo.Scripter($srv)
    $scrp.Options.FileName = $outputPath
    $sEnc = [system.Text.Encoding]::UTF8
    $scrp.Options.Encoding = $sEnc
    #$scrp.Options.TargetServerVersion = [Microsoft.SqlServer.Management.Smo.SqlServerVersion]::Version110
    $scrp.Options.TargetServerVersion = $selectDbVersion
    $scrp.Options.TargetDatabaseEngineEdition = [Microsoft.SqlServer.Management.Common.DatabaseEngineEdition]::Enterprise
    $scrp.Options.TargetDatabaseEngineType = [Microsoft.SqlServer.Management.Common.DatabaseEngineType]::Standalone  

    $scrp.Options.Indexes = $TRUE
    $scrp.Options.Triggers = $TRUE
    $scrp.Options.ClusteredIndexes =$TRUE
    $scrp.Options.NonClusteredIndexes = $TRUE
    $scrp.Options.ExtendedProperties = $TRUE
    $scrp.Options.AllowSystemObjects = $TRUE
    $scrp.Options.FullTextCatalogs = $TRUE
    $scrp.Options.FullTextIndexes = $TRUE 
    $scrp.Options.FullTextStopLists = $TRUE
    $scrp.Options.NoCollation = $TRUE 
    $scrp.Options.WithDependencies = $TRUE
 
    Write-Host "Start Export Database Schema "
    #$scrp.Options.IncludeHeaders =$TRUE # Add Script Generator Time 


    #If True，Create Script will not include schema 
    #If False need set ScriptSchema True 
    $scrp.Options.SchemaQualify = $TRUE
    #$scrp.Options.SchemaQualifyForeignKeysReferences = $TRUE 

    #$scrp.Options.ScriptSchema = $TRUE  
    #$scrp.Options.ScriptData  = $FALSE
    #$scrp.Options.ScriptDrops = $FALSE

    $tb = New-Object Microsoft.SqlServer.Management.Smo.Table
    $schema = New-Object Microsoft.SqlServer.Management.Smo.Schema
    $smoObjects = New-Object Microsoft.SqlServer.Management.Smo.UrnCollection
    

    #Generator Database 

    $smoObjects.Add($db.Urn) 

    #Generator Schema 
    foreach ($schema in $db.Schemas)
    {
    
       if ($schema.IsSystemObject -eq $FALSE)
       {
          $smoObjects.Add($schema.Urn)
       }
    }
     #Generator XmlSchema
    foreach ($schema in $db.XmlSchemaCollections)
    {
              $smoObjects.Add($schema.Urn)
    }

    #Generator User-Defined Data Types
    foreach ($userType in $db.UserDefinedDataTypes)
    {
          $smoObjects.Add($userType.Urn)
    }

    #Generator User-Defined Data Types
    foreach ($userType in $db.UserDefinedTableTypes)
    {
          $smoObjects.Add($userType.Urn)
    }

    #Generator User-Defined Data Types
    foreach ($userType in $db.UserDefinedTypes)
    {
          $smoObjects.Add($userType.Urn)
    }

    #Generator Table 
    foreach ($tb in $db.Tables)
    {
       #$smoObjects = $tb.Urn
       if ($tb.IsSystemObject -eq $FALSE)
       {
          $smoObjects.Add($tb.Urn)
       }
    }
    #Generator View 
    foreach ($view in $db.Views)
    {
       #$smoObjects = $tb.Urn
       if ($view.IsSystemObject -eq $FALSE)
       {
          $smoObjects.Add($view.Urn)
       }
    }

    #Generator Functions 
    foreach ($fn in $db.UserDefinedFunctions)
    {
       if ($fn.IsSystemObject -eq $FALSE)
       {
          $smoObjects.Add($fn.Urn)
       }
    }

    #Generator Functions 
    foreach ($fn in $db.PartitionFunctions)
    {
       if ($fn.IsSystemObject -eq $FALSE)
       {
          $smoObjects.Add($fn.Urn)
       }
    }

    #Generator trigger 
    foreach ($trigger in $db.Triggers)
    {
       #$smoObjects = $tb.Urn
       if ($trigger.IsSystemObject -eq $FALSE)
       {
          $smoObjects.Add($trigger.Urn)
       }
    }
    #Generator FullTextCatalogs
    foreach ($catalog in $db.FullTextCatalogs)
    {
          $smoObjects.Add($catalog.Urn)
    }
    #Generator StoredProcedure 
    foreach ($sp in $db.StoredProcedures)
    {
       if ($sp.IsSystemObject -eq $FALSE)
       {
          $smoObjects.Add($sp.Urn)
       }
    }
    #Generator Synonyms
    foreach ($synon in $db.Synonyms)
    {
       #$smoObjects = $tb.Urn
       if ($synon.IsSystemObject -eq $FALSE)
       {
          $smoObjects.Add($synon.Urn)
       }
    }


    # Generator All Definition Script
    $sc = $scrp.ScriptWithList($smoObjects)

    # Change create database statement in init scripts 
    (Get-Content $outputPath | Out-String) -replace "CREATE DATABASE(?s).*?GO" , "
    IF EXISTS ( select 1 from sys.databases where name = '$($db.Name)' )
    BEGIN
     DROP DATABASE $($db.Name)
    END 
    CREATE DATABASE $($db.Name)
     CONTAINMENT = NONE
     ON  PRIMARY 
    ( NAME = N'$($db.Name)_Data', FILENAME = N'C:\Program Files\Microsoft SQL Server\$($SQLServerVer.Item($selectDbVersion))\MSSQL\DATA\$($db.Name)_Data.mdf' , SIZE = 10176KB , MAXSIZE = UNLIMITED, FILEGROWTH = 16384KB )
     LOG ON 
    ( NAME = N'$($db.Name)_Log', FILENAME = N'C:\Program Files\Microsoft SQL Server\$($SQLServerVer.Item($selectDbVersion))\MSSQL\DATA\$($db.Name)_Log.ldf' , SIZE = 2048KB , MAXSIZE = 2048GB , FILEGROWTH = 16384KB )
    GO
    USE $($db.Name)
    " | Out-File $outputPath



    #Use bcp export each table data to files 
    Write-Host " Export Data"
    $TableNames = Invoke-Sqlcmd -Query "
SELECT sche.name as scheName,tb.name as tbName FROM sys.schemas sche 
INNER JOIN sys.tables tb  
ON sche.schema_id = tb.schema_id" -Verbose -ServerInstance $local -Database $dbName -Username $userId -Password $userPwd | Select-Object -Property scheName,tbName
    Foreach($item in $TableNames)
    {
      if(!(Test-Path ".\ExportData")){
        New-Item -ItemType directory -Path ".\ExportData"
      }
      bcp "$($item.scheName).[$($item.tbName)]" out ".\ExportData\$($item.scheName).$($item.tbName).txt" -N -a 8192 -d $dbName -S $local -U $userId -P $userPwd
    }
  
    #Choose using script or execute on remote. 

    #Generator Input PowerShell Script 
    if($selectExecuteMethod -eq "Execute by Script"){
        $inScript  =   '$targetLocal  = '+ $targetLocal  + "`r`n"
        $inScript +=   '$targetDbName = ' +  $targetDbName + "`r`n"
        $inScript +=   '$targetUserId = ' +  $targetUserId + "`r`n"
        $inScript +=   '$targetUserPwd= ' +  $targetUserPwd+ "`r`n"
        $inScript += '
         sqlcmd -S $targetLocal -i .\dbSchema.sql -U $targetUserId  -P $targetUserPwd
         $Result = Invoke-Sqlcmd -Query "SELECT sche.name as scheName,tb.name as tbName FROM sys.schemas sche 
INNER JOIN sys.tables tb  
ON sche.schema_id = tb.schema_id" -Verbose -ServerInstance $targetLocal -Database $targetDbName -Username $targetUserId -Password $targetUserPwd | Select-Object -Property scheName,tbName  `r`n
         Foreach($item in $Result)
         {
                   bcp "$($targetDbName).$($item.scheName).$($item.tbName)" in ".\ExportData\$($item.scheName).$($item.tbName).txt" -N -a 8192 -q -S $targetLocal -U $targetUserId -P $targetUserPwd

         }

        '
         $inScript >> 'inputScript.ps1'
    }
    if($selectExecuteMethod -eq "Execute By Remote"){
        sqlcmd -S $targetLocal -i ".\dbSchema.sql" -U $targetUserId  -P $targetUserPwd
        $Result = Invoke-Sqlcmd -Query "SELECT sche.name as scheName,tb.name as tbName FROM sys.schemas sche 
INNER JOIN sys.tables tb  
ON sche.schema_id = tb.schema_id" -Verbose -ServerInstance $targetLocal -Database $targetDbName -Username $targetUserId -Password $targetUserPwd | Select-Object -Property scheName,tbName
        Foreach($item in $Result)
        {
              bcp "$($targetDbName).$($item.scheName).$($item.tbName)" in ".\ExportData\$($item.scheName).$($item.tbName).txt" -N -a 8192 -q -S $targetLocal -U $targetUserId -P $targetUserPwd
        }
    }

}
#End $selectDbVersion -ne $null 

 










