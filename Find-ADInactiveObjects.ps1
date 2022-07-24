
<#PSScriptInfo

.VERSION 1.0

.GUID 650c2ef0-89ba-42cf-8c23-733924510e4e

.AUTHOR FingerhutAsCode

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

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
param()

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

# User Settings
$UserSettings = ($XML.Config.Group | Where-Object { $_.Name -eq "User" }).Setting
$UserInactiveThreashold = ($UserSettings | Where-Object { $_.Name -eq "Inactive Threashold" }).Value
$UserExpirationThreashold = ($UserSettings | Where-Object { $_.Name -eq "Expiration Threashold" }).Value
$UserInactiveOU = ($ComputerSettings | Where-Object { $_.Name -eq "Inactive OU" }).Value

# Import Modules
Import-Module ActiveDirectory

# Get Inactive Objects
$InactiveComputers = Search-ADAccount -Server $DomainController -AccountInactive -TimeSpan "$ComputerInactiveThreashold.00:00:00" -ComputersOnly
$InactiveUsers = Search-ADAccount -Server $DomainController -AccountInactive -TimeSpan "$UserInactiveThreashold.00:00:00" -UsersOnly

$InactiveComputers | Export-CSV -Path "$ComputerReportPath\$ComputerReportName" -NoTypeInformation
$InactiveUsers
