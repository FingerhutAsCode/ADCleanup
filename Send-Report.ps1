#Install-Module -Name Send-MailKitMessage -AllowPrerelease -Force
using module Send-MailKitMessage

param(
    [Alias("To")]
    [Parameter(Mandatory=$true)]
    [string[]] $ToEmailAddress,

    [Alias("From")]
    [Parameter(Mandatory=$true)]
    [string] $FromEmailAddress,

    [Parameter(Mandatory=$true)]
    [string] $SMTPServerAddress,

    [Parameter(Mandatory=$false)]
    [string[]] $Attachments

)



#use secure connection if available ([bool], optional)
$UseSecureConnectionIfAvailable = $true

#port ([int], required)
$Port = 25

#sender ([MimeKit.MailboxAddress] http://www.mimekit.net/docs/html/T_MimeKit_MailboxAddress.htm, required)
$From = [MimeKit.MailboxAddress]$FromEmailAddress

#recipient list ([MimeKit.InternetAddressList] http://www.mimekit.net/docs/html/T_MimeKit_InternetAddressList.htm, required)
$RecipientList = [MimeKit.InternetAddressList]::new()

foreach ($Address in $ToEmailAddress) {
    $RecipientList.Add([MimeKit.InternetAddress]$Address)
}

#subject ([string], required)
$Subject = [string]"ADCleanup Report"

#HTML body ([string], optional)
$HTMLBody = [string]"HTMLBody"

#attachment list ([System.Collections.Generic.List[string]], optional)
$AttachmentList = [System.Collections.Generic.List[string]]::new()

foreach ($Attachment in $Attachments) {
    $AttachmentList.Add($Attachment)
}


#splat parameters
$Parameters = @{
    "UseSecureConnectionIfAvailable" = $UseSecureConnectionIfAvailable    
    "SMTPServer" = $SMTPServerAddress
    "Port" = $Port
    "From" = $From
    "RecipientList" = $RecipientList
    "Subject" = $Subject
    "HTMLBody" = $HTMLBody
    "AttachmentList" = $AttachmentList
}

#send message
Send-MailKitMessage @Parameters