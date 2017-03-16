#  Script name:   ToggleCrossDCFirewall.ps1
#  Version:       1.0
#  Created on:    3/16/2017
#  Author:        Ted Henley
#  Purpose:       Toggles cross datacenter firewall rules for the selected DC
#                 
#  History:       

#Set version of powershell in case client is using Powershell v4 (the following line needs #)
#Requires -Version 3

#Change variables to match your user portal username and password - V2
[String]$username = ""
[String]$password = ""

#Set Alias and Datacenter to stop script from prompting
$AccountAlias = ""
$Datacenter = ""

#Login to API - V2
try{
    $Result = Invoke-RestMethod -URI 'https://api.ctl.io/v2/authentication/login' -Method POST -ContentType application/json -Body "{'username':'$username', 'password':'$password'}"
    $BearerToken = "Bearer " + $Result.bearerToken.ToString()
}
catch{
    [string]$CatchError = $error[0]
    Write-Error "Error authenticating to API v2 - $CatchError"
    Exit 1
}

if($AccountAlias -eq ""){
    $AccountAlias = Read-Host "Please enter account alias"
    if($AccountAlias -eq "" -or $AccountAlias.Length -gt 4 -or $AccountAlias.Length -lt 3){
        Write-Error "Account alias is invalid"
        Exit 1
    }
}

if($Datacenter -eq ""){
    $Datacenter = Read-Host "Please enter datacenter"
    if($Datacenter -eq "" -or $Datacenter.Length -ne 3){
        Write-Error "Datacenter is invalid"
        Exit 1
    }
}

#Get policy list
$RequestURL = "https://api.ctl.io/v2-experimental/crossDcFirewallPolicies/$AccountAlias/$Datacenter/"
$content = Invoke-WebRequest -URI $RequestURL -Headers @{Authorization = $BearerToken} -Method GET -ContentType application/json | ConvertFrom-Json

foreach($policy in $content){
    $policyId = $policy.id.toString()
    $sourceLocation = $policy.sourceLocation.ToString()
    $sourceCidr = $policy.sourceCidr.ToString()
    $destinationLocation = $policy.destinationLocation.ToString()
    $destinationCidr = $policy.destinationCidr.ToString()
    $currentStatus = $policy.enabled.toString()
    if($currentStatus -eq "True"){
        $status = "False"
    }
    else{
        $status = "True"
    }
    
    try{
        $RequestURL = "https://api.ctl.io/v2-experimental/crossDcFirewallPolicies/$AccountAlias/$Datacenter/$policyId" + "?enabled=$status"
        $content = Invoke-WebRequest -URI $RequestURL -Headers @{Authorization = $BearerToken} -Method PUT -ContentType application/json | ConvertFrom-Json
        Write-Host "Updating policy $sourceLocation ($sourceCidr) to $destinationLocation ($destinationCidr) from $currentStatus to $status"
    }
    catch{
        [string]$CatchError = $error[0]
        Write-Error "Error submitting job - $CatchError"
    }
}

Write-Host "Script complete.  Please check queue for status."