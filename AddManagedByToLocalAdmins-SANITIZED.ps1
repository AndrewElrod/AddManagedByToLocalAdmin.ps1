#Runs as Scheduled Task
#Use Registry
$CompanyRegistryPath = 'HKLM:\Software\'
$CompanyRegistryKey = 'Company'
$OwnerRegistryPath = 'HKLM:\Software\Company\'
$OwnerRegistryKey = 'Owner'
$ManagedByStringProperty = 'ManagedBy'
#This Creates the top COMPANY Registry Key if it doesn't exist.
If (!(Test-Path ($CompanyRegistryPath+$CompanyRegistryKey))){
	New-Item -Path $CompanyRegistryPath -Name $CompanyRegistryKey
	Write-host 'Created Company RegistryKey'
}
#This Creates the ManagedBy Registry Key if it doesn't exist.
If (!(Test-Path ($OwnerRegistryPath+$OwnerRegistryKey))){
	New-Item -Path $OwnerRegistryPath -Name $OwnerRegistryKey
	Write-host 'Created Owner RegistryKey'
}
#This Creates the ManagedBy Registry Key if it doesn't exist.
If (!((Get-ItemProperty ($OwnerRegistryPath+$OwnerRegistryKey)).ManagedBy)){
	Set-ItemProperty -Path ($OwnerRegistryPath+$OwnerRegistryKey) -Name $ManagedByStringProperty -Value $Null
	Write-host 'Created ManagedBy StringValue'
}
$LogonServer = ((((nltest /DSGETDC:) -split "`r`n")[0]) -replace [Regex]::Escape('DC: \\'),'').trim()
If ($LogonServer){
	$PreviousAdmin = (Get-Item ($OwnerRegistryPath+$OwnerRegistryKey)).getvalue('ManagedBy')
	$ComputerSearch = [adsisearcher]"(&(objectCategory=Computer)(name=$Env:ComputerName))"
	[void]$ComputerSearch.PropertiesToLoad.add("ManagedBy")
	[void]$ComputerSearch.PropertiesToLoad.add("DistinguishedName")
	$ComputerADObject = ($ComputerSearch.FindAll())
	$ComputerOwner = $ComputerADObject.properties.managedby
	$ComputerDistinguishedName = $ComputerADObject.properties.distinguishedname
	$UserToAdd = If ($ComputerOwner){
		$UserSearch = [adsisearcher]"(DistinguishedName=$ComputerOwner)"
		[void]$UserSearch.PropertiesToLoad.add("SamAccountName")
		"DOMAIN/"+(($UserSearch.FindAll()).Properties.samaccountname)
	}Else{
		$Null
	}
	$LocalGroupObject = [ADSI]"WinNT://$Env:ComputerName/Administrators,group" 
	$LocalGroupMembers = $LocalGroupObject.psbase.Invoke('Members')
	$LocalGroupMembersFormatted = ForEach ($Member in $LocalGroupMembers){
		'DOMAIN/'+($Member.GetType().InvokeMember('Name', 'GetProperty', $null, $Member, $null))
	}
	If (($PreviousAdmin -ne $UserToAdd) -or ($LocalGroupMembersFormatted -notcontains $UserToAdd)){
		If (!($UserToAdd)){
			$LocalGroupObject.psbase.Invoke("Remove",([ADSI]"WinNT://$PreviousAdmin").path)
			Set-ItemProperty -Path ($OwnerRegistryPath+$OwnerRegistryKey) -Name $ManagedByStringProperty -value $Null
		}ElseIf(($PreviousAdmin) -and ($PreviousAdmin -ne $UserToAdd)){
			$LocalGroupObject.psbase.Invoke("Remove",([ADSI]"WinNT://$PreviousAdmin").path)
			$LocalGroupObject.psbase.Invoke("Add",([ADSI]"WinNT://$UserToAdd").path)
			Set-ItemProperty -Path ($OwnerRegistryPath+$OwnerRegistryKey) -Name $ManagedByStringProperty -value $UserToAdd
		}Else{
			$LocalGroupObject.psbase.Invoke("Add",([ADSI]"WinNT://$UserToAdd").path)
			Set-ItemProperty -Path ($OwnerRegistryPath+$OwnerRegistryKey) -Name $ManagedByStringProperty -value $UserToAdd
		}
	}
}

