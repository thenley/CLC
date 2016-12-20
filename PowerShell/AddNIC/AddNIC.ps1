#  Script name:   AddNIC.ps1
#  Version:       1.0
#  Created on:    10/25/2016
#  Author:        Ted Henley
#  Purpose:       Adds network card to selected server
#                 
#  History:       

#Set version of powershell in case client is using Powershell v4 (the following line needs #)
#Requires -Version 3

#Change variables to match your user portal username and password - V2
[String]$username = ""
[String]$password = ""

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

$ServerName = Read-Host "Please enter servername"
if($ServerName -eq ""){
    Write-Error "No server selected.  Exiting script."
    Exit 1
}

$GuessedAlias = $ServerName.Substring(3,4)
$AccountAlias = Read-Host "Please enter alias or press enter for $GuessedAlias"
if($AccountAlias -eq ""){
    $AccountAlias = $GuessedAlias
}

$GuessedDatacenter = $ServerName.Substring(0,3)
$Datacenter = Read-Host "Please enter datacenter or press enter for $GuessedDatacenter"
if($Datacenter -eq ""){
    $Datacenter = $GuessedDatacenter
}

#Get network list
$RequestURL = "https://api.ctl.io/v2-experimental/networks/$AccountAlias/$Datacenter"
$content = Invoke-WebRequest -URI $RequestURL -Headers @{Authorization = $BearerToken} -Method GET -ContentType application/json | ConvertFrom-Json

#Present choices
$networkList = @{}
$networkCount = 0
foreach($network in $content){
    $networkCount++
    [string]$networkDescription = $network.description.toString() + " (" + $network.cidr.toString() + ")"
    Write-Host "$networkCount - $networkDescription"
    $networkList[$networkCount] = $network.id.toString()
}

#Get choice
[Int]$networkChoice = 0
While($networkChoice -lt 1 -or $networkChoice -gt $networkCount){
    $networkChoice = Read-Host "Select the number of the network to add to $ServerName"
}

try{
    #Add network card
    $networkID = $networkList[$networkChoice]
    $requestPost = "{'networkId':'$networkID'}"
    $requestURL = "https://api.ctl.io/v2/servers/$AccountAlias/$ServerName/networks"
    $content = Invoke-WebRequest -URI $requestURL -Headers @{Authorization = $BearerToken} -Method POST -ContentType application/json -Body $requestPost | ConvertFrom-Json
    Write-Host "Adding NIC - monitoring status on job"
}
catch{
    [string]$CatchError = $error[0]
    Write-Error "Error submitting job - $CatchError"
    Write-Host "Script complete"
    Exit 1
}

#Get status
$statusID = $content.operationId.ToString()
for ($i = 1; $i -lt 100; $i++){
    $RequestURL = "https://api.ctl.io/v2-experimental/operations/$AccountAlias/status/$statusID"
    $content = Invoke-WebRequest -URI $RequestURL -Headers @{Authorization = $BearerToken} -Method GET -ContentType application/json | ConvertFrom-Json
    $status = $content.status.ToString()
    
    if($status -eq "succeeded"){
        Write-Host "NIC added successfully."
        break
    }
    else{
        Write-Host "NIC job is $status"
        Sleep 3
    }
}
Write-Host "Script complete"