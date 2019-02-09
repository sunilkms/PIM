## List Privileged Role Assignments ##

**This script will generate CSV report containg members assigned to each privilege role**

Before you run this script you need to met with the following requirement

1. Make sure the AzureAD powershell Module is Installed, if not installed install is using  
> "Install-module AzureAD"
2. Register the Aazure App, find the steps to register app on the link below.
3. Make sure the ID you are using the report have one of the following role active.
**(Privileged Role Administrator, Global Administrator, Security Administrator, or Security Reader)**

The Report has company Tab which is environment specific it will show up empty, modify it as per your environment.
