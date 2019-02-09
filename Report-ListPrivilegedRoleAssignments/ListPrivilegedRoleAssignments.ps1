#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Script: Privilege Role Assignment Report
# Author: Sunil Chauhan
# Email:  sunilkms@gmail.com
# Blog : www.sunilchauhan.info
# github: https://github.com/sunilkms
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#--------Modify settings Below---------------------------------------------------------
#--------------------------------------------------------------------------------------
#Replace with you Azure App ClientID

$clientId = "Type your client Id"
#--------------------------------------------------------------------------------------
#Remove comments on username and password if you want to run this without a prompt.
#--------------------------------------------------------------------------------------
$Username= "admin-ID"
$Password= "Password"

#--------------------------------------------------------------------------------------
#Create the app following the instruction below.
#----------APP Configuration Settings--------------------------------------------------
$redirectUri = "https://localhost"
$resourceURI = "https://graph.microsoft.com"
$authority = "https://login.microsoftonline.com/common"
#--------------------------------------------------------------------------------------
#pre requisites
try {
    $AadModule = Import-Module -Name AzureAD -ErrorAction Stop -PassThru
    }
catch 
    {
throw 'Prerequisites not installed (AzureAD PowerShell module not installed)'
    }
$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
$adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
$authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
 
##option without user interaction
#if (([string]::IsNullOrEmpty($Username) -eq $false) -and ([string]::IsNullOrEmpty($Password) -eq $false))
#{
#Build Azure AD credentials object
$SecurePassword = ConvertTo-SecureString -AsPlainText $Password -Force
$AADCredential = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserPasswordCredential" -ArgumentList $Username,$SecurePassword
# Get token without login prompts.
$authResult = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContextIntegratedAuthExtensions]::AcquireTokenAsync($authContext, $resourceURI, $clientid, $AADCredential);
#}
sleep 4
Write-Host "Validating the Auth Reults."
Write-Host "Auth Result Status:$($authResult.Status)"

if ($authResult.Status -eq "Faulted") {
#Write-Host "Exception:$($authResult.Exception.InnerException.message)"
Write-Host "Auth Result is Faulty.. Checking the exception.."
if ($authResult.Exception.InnerException.message -match "multi-factor") 
    {
    Write-Host "You seems to be outside on the company Network, failing back to MFA" -ForegroundColor Yellow
    $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Always"
    $authResult = $authContext.AcquireTokenAsync($resourceURI, $ClientID, $RedirectUri, $platformParameters)
    }
    
 if ($authResult.Exception.InnerException.Message -match "Object reference not set to an instance of an object") 
        {
        Write-Error "Fatel error occured, please check the error.."
        Break
        }
 }
Write-Host "Getting Privilege Roles"

#Getting Privilege Roles
$accessToken = $authResult.result.AccessToken
$apiUrl = 'https://graph.microsoft.com/beta/privilegedRoles'
$RawData = Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken"} -Uri $apiUrl -Method Get
$PrivilegeRoles = $RawData.value

#Getting Privilege Roles Members
$RoleMemberReport=@()

foreach ($role in $PrivilegeRoles) 
        
        {
        Write-host "Getting Memebers of Role Group:$($role.Name)" -f Yellow
        $roleuri = $apiUrl + "/" + $role.id + "/" + "assignments"
        $rData = Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken"} -Uri $roleuri -Method Get
        $RoleMemberReport+=$rData.value
        }

$MembersData = $RoleMemberReport | select userid,roleID,isElevated,expirationDateTime
$RefineData=@()

    try {
        
        #Connecting to AzureAD to get the user properties.
        Write-Host "Trying connecting to Azure AD"
        $Credential = new-object –TypeName System.Management.Automation.PSCredential –ArgumentList $Username, (ConvertTo-SecureString $Password –AsPlainText –Force)
        Connect-AzureAD -Credential $Credential -ErrorAction Stop
        
        } 
catch {
        Write-host "Connection to AzureAD Failed"

       if ($error[0].Exception -match "You must use multi-factor authentication to access") 
            {
            Write-Host "Trying Connecting to Azure AD with MFA."
            Connect-AzureAD
            }
      }

Write-Host "Getting user properties..."
foreach ($roleid in $MembersData) {
$Adu = Get-AzureADUser -ObjectId $roleId.userID
$UserData = $roleid | select @{N="username";E={($adu).DisplayName}}, @{N="upn";E={($adu).UserPrincipalName}}, @{N="AccountStatus";E={($adu).AccountEnabled}} ,isElevated,RoleID,expirationDateTime
$RefineData+=$UserData
}

Write-host "Adding Role names to report" -ForegroundColor Yellow

$n=@()
foreach ($entry in $refinedata) {
 $rolename = $entry | select  username,upn,isElevated,AccountStatus,expirationDateTime, @{n="RoleName";E={($PrivilegeRoles | ? {$_.id -match $entry.roleid}).name}} 
 $n+=$rolename
}

Write-Host "Grouping based on user" -ForegroundColor Yellow
$group = $n | group upn
$R2 = $group | Select Name,@{N='DisplayName';E={ if ($($_.group.UserName).count -gt 1) {$_.group.UserName[0]} else {$_.group.UserName}}},@{N='Roles';E={$_.group.roleName -join ","}},
@{N='AccountStatus';E={$($_.group.AccountStatus[0])}}

#,@{N='expirationDateTime';E={$($_.group.expirationDateTime)}},@{N='isElevated';E={$($_.group.isElevated)}}

Write-Host "Preparing Final Report"

$R2 = $r2 | Select Name,DisplayName,AccountStatus,@{N='Company';E={$_.Displayname.split("(")[1].split("/|-")[0]}},@{N='AccountType';E={ if ($($_.DisplayName) -match "SVC"){ "Service" } elseif ($($_.DisplayName) -notmatch "SVC|ADMIN-") { "Other" }  else {"ADMIN"} }},Roles
$date = Get-Date -Format dd-MMM-yy
$reportName = "Pim-Report-" + $date + ".csv"
$r2 | export-csv $reportName -NoTypeInformation

Write-Host "Report has been prepared and saved to file $reportName"
