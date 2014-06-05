
Function Get-FormDigest {
	Param (
		[String] $BaseUri
	)
	
	$Uri =  "$BaseUri/_api/contextinfo"

	# fetch cached xml
	$Token = Get-CachedItem -Key $Uri
	
	# if cached xml is $null, force reload
	$Reload = $Token -eq $null
	# only reload if token is not valid anymore
	if (-not $Reload) {
		$Reload = $Token["Timeout"] -lt (Get-Date)
	}
	
	if ($Reload) {
		$Response = Invoke-WebRequest -Method  Post -Uri $Uri -UseDefaultCredentials
		[Xml] $Data = $Response.Content
		
		$Token = @{
			"Timeout" = (Get-Date).AddSeconds($Data.GetContextWebInformation.FormDigestTimeoutSeconds."#text")
			"FormDigest" = $Data.GetContextWebInformation.FormDigestValue
		}
		
		Add-CachedItem -Key $Uri -Value $Token
	}
	
	$Token["FormDigest"]
}


Function Get-CachedItem {
	Param(
		$Key
	)
	
	$Global:ShareShellCache[$Key]
}

Function Add-CachedItem {
	Param(
		$Key,
		$Value
	)
	
	$Global:ShareShellCache[$Key] = $Value
}

Function Clear-Cache {
	$Global:ShareShellCache = @{}
}

Clear-Cache