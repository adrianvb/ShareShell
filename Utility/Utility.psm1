
Function Get-FormDigest {
	Param (
		[String] $BaseUri,
		[Switch] $DisableCaching
	)
	
	$Uri =  "$BaseUri/asdadsd/_api/contextinfo"

	# fetch cached xml
	$Token = Get-CachedItem -Key $Uri
	
	# if cached xml is $null, force reload
	$Reload = $Token -eq $null
	# only reload if token is not valid anymore
	if (-not $Reload) {
		$Reload = $Token["Timeout"] -lt (Get-Date)
	}
	
	if ($Reload -or $DisableCaching) {
		$Response = Invoke-WebRequest -Method  Post -Uri $Uri -UseDefaultCredentials		
		if ($Response -eq $null) {
			Throw "Get-FormDigest: Empty response"
		}
		
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

Function Test-CachedItemExists {
	Param(
		$Key,
		[Switch] $Verbose
	)
		
	if ($Verbose) {
		if($Global:ShareShellCache.Keys -contains $Key) { 
			Write-Verbose "Test-CachedItemExists: hit '$key'"
		} else { 
			Write-Verbose "Test-CachedItemExists: miss '$key'" 
		} 
	}
	
	
	$Global:ShareShellCache.Keys -contains $Key
}

Function Clear-Cache {
	$Global:ShareShellCache = @{}
}

if ($Global:ShareShellCache -eq $null) {
	Clear-Cache
}