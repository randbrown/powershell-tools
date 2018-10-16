# Database schema/data script tool.  This was made to replace the sqlpubwiz since that is hard to find now,
# and since it appears to have some bugs
# Example usage:
# C:\dev> powershell .\ScriptDatabase.ps1 myserver myDatabaseName C:\Temp\schema_and_data.sql -includeData

param(
	[string]$server, 
	[string]$databaseName,
	[string]$outputFilename,
	[switch]$includeData=$false
)

$ErrorActionPreference = "Stop";

$message = "Scripting "
if($includeData){
	$message += "schema and data"
}
else
{
	$message += "Scripting schema only"
}

$message += " from " + $server + ", " + $databaseName + " to file: " + $outputFilename
Write-Output $message

set-psdebug -strict
$ErrorActionPreference = "stop" # you can opt to stagger on, bleeding, if an error occurs
# Load SMO assembly, and if we're running SQL 2008 DLLs load the SMOExtended and SQLWMIManagement libraries
$ms='Microsoft.SqlServer'
$v = [System.Reflection.Assembly]::LoadWithPartialName( "$ms.SMO")
if ((($v.FullName.Split(','))[1].Split('='))[1].Split('.')[0] -ne '9') {
[System.Reflection.Assembly]::LoadWithPartialName("$ms.SMOExtended") | out-null
   }
$My="$ms.Management.Smo" #

$s = new-object ("$My.Server") $server
if ($s.Version -eq  $null ){Throw "Can't find the instance $server"}
$db= $s.Databases[$databaseName] 
if ($db.name -ne $databaseName){Throw "Can't find the database '$databaseName' in $server"};

$transfer = new-object ("$My.Transfer") $db
$transfer.Options.ScriptBatchTerminator = $true
$transfer.Options.ToFileOnly = $true
$transfer.Options.Filename = "$outputFilename"; 
$transfer.CopyAllTables = $true
$transfer.Options.WithDependencies = $true
$transfer.CopySchema = $true
$transfer.CopyAllDatabaseTriggers = $true
$transfer.CopyAllDefaults = $true
$transfer.CopyAllObjects = $false #
$transfer.CopyAllUsers = $false
$transfer.CopyAllSchemas = $true
$transfer.CopyAllDatabaseTriggers = $true
$transfer.CopyAllDefaults = $true
$transfer.CopyAllFullTextCatalogs = $true
$transfer.CopyAllFullTextStopLists = $true
$transfer.CopyAllLogins = $false # Not desirable in my case
$transfer.CopyAllPartitionFunctions = $true
$transfer.CopyAllPartitionSchemes = $true
$transfer.CopyAllPlanGuides = $true
$transfer.CopyAllRoles = $false # Not desirable in my case
$transfer.CopyAllSearchPropertyLists = $true
$transfer.CopyAllRules = $true
$transfer.CopyAllSqlAssemblies = $true
$transfer.CopyAllStoredProcedures = $true
$transfer.CopyAllSynonyms = $true
$transfer.CopyAllTables = $true
$transfer.CopyAllUserDefinedAggregates = $true
$transfer.CopyAllUserDefinedDataTypes = $true
$transfer.CopyAllUserDefinedFunctions = $true
$transfer.CopyAllUserDefinedTableTypes = $true
$transfer.CopyAllUserDefinedTypes = $true
$transfer.CopyAllViews = $true
$transfer.CopyAllXmlSchemaCollections = $true

$transfer.CopyData = $includeData # NOTE this seems to be ignored
$transfer.Options.ScriptData = $includeData; # NOTE this is required if you want data scripted!
$transfer.CopySchema = $true

$transfer.Options.WithDependencies = $true
$transfer.Options.DriAll = $true
$transfer.Options.DriAllConstraints = $true
$transfer.Options.Triggers = $true
$transfer.Options.Indexes = $true
$transfer.Options.ClusteredIndexes = $true
$transfer.Options.XmlIndexes = $true
$transfer.Options.NonClusteredIndexes = $true
$transfer.Options.DriPrimaryKey = $true
$transfer.Options.DriClustered = $true
$transfer.Options.DriNonClustered  = $true
$transfer.Options.DriAllKeys = $true
$transfer.Options.DriUniqueKeys = $true
$transfer.Options.DriForeignKeys = $true
$transfer.Options.DriDefaults = $true
$transfer.Options.DriIncludeSystemNames  = $true
$transfer.Options.DriIndexes  = $true
$transfer.Options.ExtendedProperties = $true
$transfer.Options.ScriptBatchTerminator = $true
$transfer.Options.ContinueScriptingOnError = $true
$transfer.Options.SchemaQualify = $true
$transfer.Options.EnforceScriptingOptions = $true
$transfer.Options.IncludeIfNotExists = $false

# we explicitly set ScriptDataCompression to false.  
# This is in case a database is scripted from an Enterprise edition, and contains some compression,
# we can still run the script on an Express edition, and so on.
$transfer.Options.ScriptDataCompression = $false

# This is to help speed it up, hopefully
$transfer.PrefetchObjects = $true 

# Note that ScriptTransfer() does NOT write data inserts, even if CopyData and ScriptData are true.  It seems only EnumScriptTransfer() does this.
$transfer.EnumScriptTransfer() 

"Finished script to file: " +  $outputFilename
