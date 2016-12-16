#Get network connections 
$networkConnections = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}")).GetNetworkConnections() 

#Set network location to Private for all networks 
$networkConnections | % {$_.GetNetwork().SetCategory(1)} 
