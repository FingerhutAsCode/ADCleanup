
<#PSScriptInfo

.VERSION 0.2.0

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
$DomainDN = ($DomainSettings | Where-Object { $_.Name -eq "Distinguished Name" }).Value

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
if (-not($ComputerProperties.Contains("Name"))) {
    $ComputerProperties += "Name"
}


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
if (-not($UserProperties.Contains("DisplayName"))) {
    $UserProperties += "DisplayName"
}


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
    $ModuleActive = Get-Module | Where-Object { $_.Name -eq "$Module" }
    if ($ModuleActive) {
        Write-Host "Module [$Module] loaded sucessfully" -ForegroundColor Green
    }
    else {
        Write-Error "Module [$Module] failed to load"
    }
}

# Start Log
Start-Log -LogPath $LogPath -LogName $LogName -ScriptVersion $ScriptVersion -ToScreen
$LogFullName = "$LogPath\$LogName"

# Log Domain Config Settings
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Domain Name [$DomainName]"
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Domain Controller [$DomainController]"
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Domain Distinguished Name [$DomainDN]"

# Log Computer Config Settings
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Computer Inactive Threashold [$ComputerInactiveThreashold]"
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Computer Expiration Threashold [$ComputerExpirationThreashold]"
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Computer Disabled OU [$ComputerDisabledOU]"
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Computer Report Path [$ComputerReportPath]"
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Computer Report Name [$ComputerReportName]"
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Computer Properties [$ComputerPropertiesString]"

# Log User Config Settings
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "User Inactive Threashold [$UserInactiveThreashold]"
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "User Expiration Threashold [$UserExpirationThreashold]"
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "User Disabled OU [$UserDisabledOU]"
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "User Report Path [$UserReportPath]"
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "User Report Name [$UserReportName]"
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "User Properties [$UserPropertiesString]"

# Log Report Config Settings
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Report From [$ReportFrom]"
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Report To [$ReportTo]"
Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Report Server [$ReportServer]"


function Disable-ADComputer {
    param (
        $ADComputer,
        $TargetOU
    )
    $Computer = $null
    $Computer = Get-ADComputer $ADComputer -Server $DomainController
    if ($Computer) {
        $ComputerDescription = (Get-ADComputer $Computer -Server $DomainController -Properties Description).Description
        Set-ADComputer $Computer -Server $DomainController -Description "Disabled by ADCleanup [$(Get-Date -Format 'yyyy-MM-dd')]; $ComputerDescription"
        Disable-ADAccount $Computer -Server $DomainController
        Move-ADObject $Computer -Server $DomainController -TargetPath $TargetOU
        Write-LogInfo -LogPath $LogFullName -ToScreen -Message "AD Computer [$($Computer.Name)] has been disabled"
        return $true
    }
    else {
        Write-LogError -LogPath $LogFullName -ToScreen -Message "AD Computer [$($Computer.Name)] could not be found"
        return $false
    }
}

function Disable-ADUser {
    param (
        $ADUser,
        $TargetOU
    )
    $User = $null
    $User = Get-ADUser $ADUser -Server $DomainController
    if ($User) {
        $UserDescription = (Get-ADUser $User -Server $DomainController -Properties Description).Description
        Set-ADUser $User -Server $DomainController -Description "Disabled by ADCleanup [$(Get-Date -Format 'yyyy-MM-dd')]; $UserDescription"
        Disable-ADAccount $User -Server $DomainController
        Move-ADObject $User -Server $DomainController -TargetPath $TargetOU
        Write-LogInfo -LogPath $LogFullName -ToScreen -Message "AD User [$($User.Name)] has been disabled"
        return $true
    }
    else {
        Write-LogError -LogPath $LogFullName -ToScreen -Message "AD User [$($User.Name)] could not be found"
        return $false
    }
}

function Get-ExpiredADComputers {
    param (
        [string]$TargetOU,
        [int]$MaxAge
    )
    $Computers = Get-ADComputer -Filter * -Server $DomainController -SearchBase $TargetOU -Properties Description
    $ExpiredComputers = @()
    foreach ($Computer in $Computers) {
        Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Reviewing computer [$($Computer.Name)]"
        $IsDateInEntry = $null
        $ComputerDisabledAge = $null
        $ComputerDescriptionLatestEntry = $Computer.Description.Substring($Computer.Description.IndexOf('Disabled by ADCleanup'),$Computer.Description.IndexOf(';'))
        Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Computer [$($Computer.Name)] latest entry [$ComputerDescriptionLatestEntry]"
        $IsDateInEntry = ($ComputerDescriptionLatestEntry | Select-String -Pattern '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]').Matches
        if ($IsDateInEntry.count -eq 1) {
            $ComputerDisabledDate = $IsDateInEntry.Value
            Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Computer [$($Computer.Name)] disabled date [$ComputerDisabledDate]"
            $ComputerDisabledAge = New-TimeSpan -Start "$ComputerDisabledDate" -End $(Get-Date -Format 'yyyy-MM-dd')
            Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Computer [$($Computer.Name)] has been disabled for [$($ComputerDisabledAge.days)] days"
        }
        else {
            Write-LogWarning -LogPath $LogFullName -ToScreen -Message "Unable to determine computer [$($Computer.Name)] disabled age, must be reviewed manually"
        }
        if ($ComputerDisabledAge.days -gt $MaxAge) {
            Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Computer [$($Computer.Name)] has been disabled for more than the max [$MaxAge] days, adding to expired list"
            $ExpiredComputers += $Computer
        }
    }
    return $ExpiredComputers
}




# Get Inactive Objects
$InactiveComputers = Search-ADAccount -Server $DomainController -AccountInactive -TimeSpan "$ComputerInactiveThreashold.00:00:00" -ComputersOnly | Get-ADComputer -Server $DomainController -Properties $ComputerProperties | Select-Object $ComputerProperties
$InactiveUsers = Search-ADAccount -Server $DomainController -AccountInactive -TimeSpan "$UserInactiveThreashold.00:00:00" -UsersOnly | Get-ADUser -Server $DomainController -Properties $UserProperties | Select-Object $UserProperties

$InactiveComputers | Export-Csv -Path $ComputerReportFullName -NoTypeInformation
$InactiveUsers | Export-Csv -Path $UserReportFullName -NoTypeInformation

if ($ProcessInactiveComputers) {
    foreach ($Object in $InactiveComputers) {
        Write-LogInfo -LogPath $LogFullName -ToScreen -Message "AD Computer [$($Object.Name)] has been identified as inactive"
        Disable-ADComputer -ADComputer $($Object.Name) -TargetOU $ComputerDisabledOU
    }
}

if ($ProcessInactiveUsers) {
    foreach ($Object in $InactiveUsers) {
        Write-LogInfo -LogPath $LogFullName -ToScreen -Message "AD User [$($Object.Name)] has been identified as inactive"
        Disable-ADUser -ADComputer $Object -TargetOU $UserDisabledOU
    }
}

if ($ProcessExpiredComputers) {
    $ExpiredADComputers = Get-ExpiredADComputers -TargetOU $ComputerDisabledOU -MaxAge $ComputerExpirationThreashold
    $RecycleBinADOptionalFeaturePath = "CN=Recycle Bin Feature,CN=Optional Features,CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,$DomainDN"
    $RecycleBinStatus = = Get-ADOptionalFeature -Identity $RecycleBinADOptionalFeaturePath -Properties *
    if ($RecycleBinStatus.EnabledScopes -like "*$DomainDN*") {
        Write-LogInfo -LogPath $LogFullName -ToScreen -Message "Active Directory Recycle Bin identifed as active, expired computer processing can continue"
        foreach ($Computer in $ExpiredADComputers) {
            Remove-ADObject $Computer -Server $DomainController
            Write-LogInfo -LogPath $LogFullName -ToScreen -Message "AD Computer [$($Computer.Name)] has been deleted" 
        }
    }  
}




if ($SendReport) {
    .\Send-Report.ps1 -ToEmailAddress $ReportTo -FromEmailAddress $ReportFrom -SMTPServerAddress $ReportServer -Attachments $ComputerReportFullName, $UserReportFullName
}

Stop-Log -LogPath $LogFullName -ToScreen