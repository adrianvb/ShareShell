
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