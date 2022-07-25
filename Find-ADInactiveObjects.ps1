
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

.EXTERNALMODULEDEPENDENCIES 

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
    [Parameter(Mandatory=$false)]
    [switch] $SendReport
)

# Import Configuration
[xml]$XML = Get-Content ".\Config.xml" -Raw

# Domain Settings
$DomainSettings = ($XML.Config.Group | Where-Object { $_.Name -eq "Domain" }).Setting
$DomainName = ($DomainSettings | Where-Object { $_.Name -eq "Domain Name" }).Value
$DomainController = ($DomainSettings | Where-Object { $_.Name -eq "Domain Controller" }).Value

# Computer Settings
$ComputerSettings = ($XML.Config.Group | Where-Object { $_.Name -eq "Computer" }).Setting
$ComputerInactiveThreashold = ($ComputerSettings | Where-Object { $_.Name -eq "Inactive Threashold" }).Value
$ComputerExpirationThreashold = ($ComputerSettings | Where-Object { $_.Name -eq "Expiration Threashold" }).Value
$ComputerInactiveOU = ($ComputerSettings | Where-Object { $_.Name -eq "Inactive OU" }).Value
$ComputerReportPath = ($ComputerSettings | Where-Object { $_.Name -eq "Report Path" }).Value
$ComputerReportName = ($ComputerSettings | Where-Object { $_.Name -eq "Report Name" }).Value
$ComputerReportName = $ComputerReportName -replace "!Date!", $(Get-Date -Format 'yyyyMMdd') -replace "!Time!", $(Get-Date -Format 'hhmmss')
$ComputerPropertiesString = ($ComputerSettings | Where-Object { $_.Name -eq "Properties" }).Value -replace " ", ""
$ComputerProperties = $ComputerPropertiesString.Split(",")


# User Settings
$UserSettings = ($XML.Config.Group | Where-Object { $_.Name -eq "User" }).Setting
$UserInactiveThreashold = ($UserSettings | Where-Object { $_.Name -eq "Inactive Threashold" }).Value
$UserExpirationThreashold = ($UserSettings | Where-Object { $_.Name -eq "Expiration Threashold" }).Value
$UserInactiveOU = ($UserSettings | Where-Object { $_.Name -eq "Inactive OU" }).Value
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
Import-Module ActiveDirectory

# Get Inactive Objects
$InactiveComputers = Search-ADAccount -Server $DomainController -AccountInactive -TimeSpan "$ComputerInactiveThreashold.00:00:00" -ComputersOnly | Get-ADComputer -Server $DomainController -Properties $ComputerProperties | Select-Object $ComputerProperties
$InactiveUsers = Search-ADAccount -Server $DomainController -AccountInactive -TimeSpan "$UserInactiveThreashold.00:00:00" -UsersOnly | Get-ADUser -Server $DomainController -Properties $UserProperties | Select-Object $UserProperties

$InactiveComputers | Export-Csv -Path $ComputerReportFullName -NoTypeInformation
$InactiveUsers | Export-Csv -Path $UserReportFullName -NoTypeInformation

if($SendReport)
{
    .\Send-Report.ps1 -ToEmailAddress $ReportTo -FromEmailAddress $ReportFrom -SMTPServerAddress $ReportServer -Attachments $ComputerReportFullName, $UserReportFullName
}