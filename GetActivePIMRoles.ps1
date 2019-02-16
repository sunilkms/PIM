#---------------------------------------------------
#Author: Sunil Chauhan
#EmailID: sunilkms@gmail.com
#---------------------------------------------------
#Below function gets current state of roles, multiple roles can be selected in the GUI scrren, script will process the selected roles
#Roles which are disabled will be activated, and if an already activated roles is selected then script assume it as disable request
# and will disable the role, cancel action do nothing.
#---------------------------------------------------
#if not installed alredy, install instruction https://www.sunilchauhan.info/2018/11/azure-ad-privileged-identity-management.html
Function ConnectPIM 
{
  [CmdletBinding]

	Try	{
		"Trying connecting to PIM Service"
        $Global:Pstital = "PIM | " + $($Host.UI.RawUI.WindowTitle) 
		Connect-PimService -Credential $Cred -ea Stop
        
		} 
	catch {
		Write-Verbose "Failed to connect, now trying using MFA.."

       if($cred) {Connect-PimService -UserName $Cred.UserName} else {Connect-PimService}
	      }
}

Function GetHours {
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select Hours'
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

#Get your current active roles
Function GetActivePIMRoles {
# connect Pim Service is not alredy connected.

if (!(Show-PimServiceConnection).TenantName) {connectPim}
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
            
            if (!($h)) {$h = gethours }
            if ($h) {
                    Enable-PrivilegedRoleAssignment -Reason "Activation for the Shift" -RoleId $role.RoleId -Duration $h
                    }
              else  {
                    Enable-PrivilegedRoleAssignment -Reason "Activation for the Shift" -RoleId $role.RoleId
                    } 
           }
    }
 } 
else 
{write-host "No Roles were selected to enable or disable" -ForegroundColor Yellow}

}
