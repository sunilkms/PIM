#---------------------------------------------------
#Author: Sunil Chauhan
#EmailID: sunilkms@gmail.com
#---------------------------------------------------
#Below function gets current state of roles, multiple roles can be selected in the GUI scrren, script will process the selected roles
#Roles which are disabled will be activated, and if an already activated roles is selected then script assume it as disable request
# and will disable the role, cancel action do nothing.
#---------------------------------------------------
$cred = Get-Credential
Function ConnectPIM 
{
	Try	{
		"Trying connecting to PIM Service"
       # $Global:Pstital = "PIM | " + $($Host.UI.RawUI.WindowTitle)
    # Assuming that you have saved your credential in $cred.   
		Connect-PimService -Credential $Cred -ea Stop
        
		} 
	catch {
		"Failed to connect try connecting using MFA if you are not of company network" 
	      }
}

Function GetActivePIMRoles {

# connect Pim Service if not alredy connected.
if (!(Show-PimServiceConnection).TenantName) {ConnectPim}

#Get Roles to activate or deactivate
$SelectedRoles = Get-PrivilegedRoleAssignment | Out-GridView -Title "Select the Role to activate or Deactivate" -PassThru

if ($SelectedRoles.count -gt 0) 
  {
    foreach ($Role in $SelectedRoles) 
    {
                     if ($role.IsElevated) 
                                        {
                                        Disable-PrivilegedRoleAssignment -RoleId $role.RoleId
                                        } 
                     else {
                          Enable-PrivilegedRoleAssignment -Duration 8 -Reason "Activation for the Shift" -RoleId $role.RoleId 
                          }
     }
  } 
else 
  {
  write-host "No Roles were selected to enable or disable" -ForegroundColor Yellow
  }
}
