
<#PSScriptInfo

.VERSION 0.1.0

.GUID 650c2ef0-89ba-42cf-8c23-733924510e4e

.AUTHOR FingerhutAsCode

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI https://github.com/FingerhutAsCode/ADCleanup

.ICONURI

.EXTERNALMODULEDEPENDENCIES ActiveDirectory,PSLogging 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#> 





<# 

.DESCRIPTION 
 Find AD Inactive Objects 

#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch] $SendReport,
    [Parameter(Mandatory = $false)]
    [switch] $ProcessInactiveComputers,
    [Parameter(Mandatory = $false)]
    [switch] $ProcessInactiveUsers,
    [Parameter(Mandatory = $false)]
    [switch] $ProcessExpiredComputers,
    [Parameter(Mandatory = $false)]
    [switch] $ProcessExpiredUsers
)

$ScriptInfo = Test-ScriptFileInfo .\Find-ADInactiveObjects.ps1
$ScriptVersion = $ScriptInfo.Version

# Import Configuration
[xml]$XML = Get-Content ".\Config.xml" -Raw

# General Settings
$GeneralSettings = ($XML.Config.Group | Where-Object { $_.Name -eq "General" }).Setting
$LogPath = ($GeneralSettings | Where-Object { $_.Name -eq "Log Directory" }).Value
$LogName = ($GeneralSettings | Where-Object { $_.Name -eq "Log Name" }).Value
$LogName = $LogName -replace "!Date!", $(Get-Date -Format 'yyyyMMdd') -replace "!Time!", $(Get-Date -Format 'hhmmss')

# Domain Settings
$DomainSettings = ($XML.Config.Group | Where-Object { $_.Name -eq "Domain" }).Setting
$DomainName = ($DomainSettings | Where-Object { $_.Name -eq "Domain Name" }).Value
$DomainController = ($DomainSettings | Where-Object { $_.Name -eq "Domain Controller" }).Value

# Computer Settings
$ComputerSettings = ($XML.Config.Group | Where-Object { $_.Name -eq "Computer" }).Setting
$ComputerInactiveThreashold = ($ComputerSettings | Where-Object { $_.Name -eq "Inactive Threashold" }).Value
$ComputerExpirationThreashold = ($ComputerSettings | Where-Object { $_.Name -eq "Expiration Threashold" }).Value
$ComputerDisabledOU = ($ComputerSettings | Where-Object { $_.Name -eq "Disabled OU" }).Value
$ComputerReportPath = ($ComputerSettings | Where-Object { $_.Name -eq "Report Path" }).Value
$ComputerReportName = ($ComputerSettings | Where-Object { $_.Name -eq "Report Name" }).Value
$ComputerReportName = $ComputerReportName -replace "!Date!", $(Get-Date -Format 'yyyyMMdd') -replace "!Time!", $(Get-Date -Format 'hhmmss')
$ComputerPropertiesString = ($ComputerSettings | Where-Object { $_.Name -eq "Properties" }).Value -replace " ", ""
$ComputerProperties = $ComputerPropertiesString.Split(",")

# User Settings
$UserSettings = ($XML.Config.Group | Where-Object { $_.Name -eq "User" }).Setting
$UserInactiveThreashold = ($UserSettings | Where-Object { $_.Name -eq "Inactive Threashold" }).Value
$UserExpirationThreashold = ($UserSettings | Where-Object { $_.Name -eq "Expiration Threashold" }).Value
$UserDisabledOU = ($UserSettings | Where-Object { $_.Name -eq "Disabled OU" }).Value
$UserReportPath = ($UserSettings | Where-Object { $_.Name -eq "Report Path" }).Value
$UserReportName = ($UserSettings | Where-Object { $_.Name -eq "Report Name" }).Value
$UserReportName = $UserReportName -replace "!Date!", $(Get-Date -Format 'yyyyMMdd') -replace "!Time!", $(Get-Date -Format 'hhmmss')
$UserPropertiesString = ($UserSettings | Where-Object { $_.Name -eq "Properties" }).Value -replace " ", ""
$UserProperties = $UserPropertiesString.Split(",")

# Report Settings
$ReportSettings = ($XML.Config.Group | Where-Object { $_.Name -eq "Report" }).Setting
$ReportFrom = ($ReportSettings | Where-Object { $_.Name -eq "From" }).Value
$ReportTo = ($ReportSettings | Where-Object { $_.Name -eq "To" }).Value
$ReportServer = ($ReportSettings | Where-Object { $_.Name -eq "SMTPServer" }).Value

# Report Paths
$UserReportFullName = "$UserReportPath\$UserReportName"
$ComputerReportFullName = "$ComputerReportPath\$ComputerReportName"

# Import Modules
foreach ($Module in $ScriptInfo.ExternalModuleDependencies) {
    Import-Module $Module -ErrorAction Continue
    $ModuleActive = $null
    $ModuleActive = Get-Module | Where-Object {$_.Name -eq "$Module"}
    if ($ModuleActive) {
        Write-Host "Module [$Module] loaded sucessfully"
    }
    else {
        Write-Error "Module [$Module] failed to load"
    }
}

# Start Log
Start-Log -LogPath $LogPath -LogName $LogName -ScriptVersion $ScriptVersion -ToScreen
$LogFullName = "$LogPath\$LogName"

# Log Domain Config Settings
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "Domain Name [$DomainName]"
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "Domain Controller [$DomainController]"

# Log Computer Config Settings
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "Computer Inactive Threashold [$ComputerInactiveThreashold]"
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "Computer Expiration Threashold [$ComputerExpirationThreashold]"
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "Computer Disabled OU [$ComputerDisabledOU]"
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "Computer Report Path [$ComputerReportPath]"
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "Computer Report Name [$ComputerReportName]"
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "Computer Properties [$ComputerPropertiesString]"

# Log User Config Settings
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "User Inactive Threashold [$UserInactiveThreashold]"
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "User Expiration Threashold [$UserExpirationThreashold]"
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "User Disabled OU [$UserDisabledOU]"
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "User Report Path [$UserReportPath]"
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "User Report Name [$UserReportName]"
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "User Properties [$UserPropertiesString]"

# Log Report Config Settings
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "Report From [$ReportFrom]"
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "Report To [$ReportTo]"
Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "Report Server [$ReportServer]"


function Disable-ADComputer {
    param (
        $ADComputer,
        $TargetOU
    )
    $Computer = $null
    $Computer = Get-ADComputer $ADComputer
    if ($Computer) {
        $ComputerDescription = (Get-ADComputer $Computer -Properties Description).Description
        Set-ADComputer $Computer -Description "Disabled by ADCleanup $(Get-Date -Format 'yyyy-MM-dd'); $ComputerDescription"
        Move-ADObject $Computer -TargetPath $TargetOU
        Disable-ADAccount $Computer
        Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "AD Computer [$($Computer.Name)] has been disabled"
        return $true
    }
    else {
        Write-LogError -LogPath $LogFullName -TimeStamp -ToScreen -Message "AD Computer [$($Computer.Name)] could not be found"
        return $false
    }
}

function Disable-ADUser {
    param (
        $ADUser,
        $TargetOU
    )
    $User = $null
    $User = Get-ADUser $ADUser
    if ($User) {
        $UserDescription = (Get-ADUser $User -Properties Description).Description
        Set-ADUser $User -Description "Disabled by ADCleanup $(Get-Date -Format 'yyyy-MM-dd'); $UserDescription"
        Move-ADObject $User -TargetPath $TargetOU
        Disable-ADAccount $User
        Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "AD User [$($User.Name)] has been disabled"
        return $true
    }
    else {
        Write-LogError -LogPath $LogFullName -TimeStamp -ToScreen -Message "AD User [$($User.Name)] could not be found"
        return $false
    }
}


# Get Inactive Objects
$InactiveComputers = Search-ADAccount -Server $DomainController -AccountInactive -TimeSpan "$ComputerInactiveThreashold.00:00:00" -ComputersOnly | Get-ADComputer -Server $DomainController -Properties $ComputerProperties | Select-Object $ComputerProperties
$InactiveUsers = Search-ADAccount -Server $DomainController -AccountInactive -TimeSpan "$UserInactiveThreashold.00:00:00" -UsersOnly | Get-ADUser -Server $DomainController -Properties $UserProperties | Select-Object $UserProperties

$InactiveComputers | Export-Csv -Path $ComputerReportFullName -NoTypeInformation
$InactiveUsers | Export-Csv -Path $UserReportFullName -NoTypeInformation

if ($ProcessInactiveComputers) {
    foreach ($Object in $InactiveComputers) {
        Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "AD Computer [$($Object.Name)] has been identified as inactive"
        Disable-ADComputer -ADComputer $Object -TargetOU $ComputerDisabledOU
    }
}

if ($ProcessInactiveUsers) {
    foreach ($Object in $InactiveUsers) {
        Write-LogInfo -LogPath $LogFullName -TimeStamp -ToScreen -Message "AD User [$($Object.Name)] has been identified as inactive"
        Disable-ADUser -ADComputer $Object -TargetOU $UserDisabledOU
    }
}

if ($SendReport) {
    .\Send-Report.ps1 -ToEmailAddress $ReportTo -FromEmailAddress $ReportFrom -SMTPServerAddress $ReportServer -Attachments $ComputerReportFullName, $UserReportFullName
}

Stop-Log -LogPath $LogPath -LogName $LogName -ToScreen