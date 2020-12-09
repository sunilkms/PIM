################################################################################################
# Author: Sunil Chauhan
# About: This is the new PIM module which will help to activate all assigned PIM Roles easily.
# prerequisites: AzureAdPreview Module must be installed. 
# my blog: www.lab365.in
# Script: GetActivePimRolesNew - GetVersion 1.0
################################################################################################

# Verify if the AzureAd module is installed, and the host is connect to AzureAD
try   {
        Import-Module -Name AzureADPreview
      } 
catch {     
      "AzureAdpreview Module is not installed, please install the AzureADPreview module";Break
      }

try   {
        $TenantId=Get-AzureADCurrentSessionInfo -ErrorAction SilentlyContinue
      } 
catch {
        if (!($TenantId)) 
                        {
                         Write-Host "you are not connected to AzureAD"
                        try  {
                               Connect-AzureAD -Credential $cred -ErrorAction Stop
                             } 
                        catch { 
                              try {
                                    Connect-AzureAD -ErrorAction Stop
                                  } 
                             catch {
                                    "failed to connect to AzureAD";break
                                   } 
                              }
                        }
     }
try   {
        $TenantId=Get-AzureADCurrentSessionInfo -ErrorAction Stop
      }
catch {
        "Failed to connect to AzureAD";break
      }
      
#fetch AzureAD Role Definition
$PIMRoleDefinition=Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $TenantId.TenantId.guid
$AdminUserObjectID=(Get-AzureADUser -SearchString $TenantId.Account).ObjectID

#Fetch Loged in user assigned roles
$RolesAssigntoAdminAccount=Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId $TenantId.TenantId.guid `
| ? {$_.subjectID -match $AdminUserObjectID}

#Translate the role Name and pop up user for roles selection.
$SelectedRoles=$RolesAssigntoAdminAccount | select RoleDefinitionId,SubjectId,
@{n="RoleDefinitionName";E={$RD=$_.RoleDefinitionId;$($PIMRoleDefinition | ? {$_.Id -match $RD}).DisplayName}},
StartDateTime,EndDateTime,AssignmentState | Out-GridView -PassThru -Title "Select the roles to activated"

#function to get number of hours for the role to be activated.
Function GetHours {
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select a Computer'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = 'OK'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(150,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Select Numbers Of hours:'
$form.Controls.Add($label)

$DropDownBox = New-Object System.Windows.Forms.ComboBox
$DropDownBox.Location = New-Object System.Drawing.Size(20,50) 
$DropDownBox.Size = New-Object System.Drawing.Size(180,20) 
$DropDownBox.DropDownHeight = 200 
$Form.Controls.Add($DropDownBox) 
$wksList=@(1..10)
foreach ($wks in $wksList) {
                      [void]$DropDownBox.Items.Add($wks)
                              }

$form.Controls.Add($DropDownBox)
$form.Topmost = $true
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $x = $DropDownBox.SelectedItem
    $x
}
}

#If roles are selected, process each role for activation.
if ($SelectedRoles){
    $hours=GetHours
    $reason="Activation for the shift"
    $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
    $schedule.Type = "Once"
    $schedule.StartDateTime=(Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $schedule.endDateTime=((Get-Date).AddHours($hours)).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

    foreach ($role in $SelectedRoles) 
            {
            Write-Host "Activating Role:" $role.RoleDefinitionName -NoNewline
            try {
                    $roleactivation=(Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $TenantId.TenantId.guid -RoleDefinitionId $role.RoleDefinitionId `
                           -SubjectId $Role.SubjectId -Type 'UserAdd' -AssignmentState 'Active' -schedule $schedule -reason $reason -ErrorAction SilentlyContinue)
                    if ($roleactivation) {Write-Host " :Done - Activation Successfull!!!" -ForegroundColor Green}
                }
            
            catch { Write-Host " :Failed" -ForegroundColor Red } 
            
            }
     }
else 
     {
        Write-Host "No roles were selected for activation" -ForegroundColor Yellow
     }
