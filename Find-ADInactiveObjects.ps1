
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
$ComputerSettings = ($XML.Config.Group | Where-Object { $_.Name -eq "Computers" }).Setting
$ComputerInactiveThreashold = ($ComputerSettings | Where-Object { $_.Name -eq "Inactive Threashold" }).Value
$ComputerExpirationThreashold = ($ComputerSettings | Where-Object { $_.Name -eq "Expiration Threashold" }).Value




# Import Modules
Import-Module ActiveDirectory

$InactiveComputers = Search-ADAccount -AccountInactive -TimeSpan "$ComputerInactiveThreashold.00:00:00" -ComputersOnly


$InactiveComputers


# Export-Csv -Path "C:\users\bfinger\Downloads\InactiveComputers.csv" -NoTypeInformation

