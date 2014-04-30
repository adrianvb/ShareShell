Function Get-Web {
	Param(
		[Parameter(Mandatory=$true)] [String] $Uri
	)
	
	if ($Uri -notlike "*/_api/web*") {
		$Uri = "$Uri/_api/web"
	}
	
	Invoke-XmlApiRequest -Uri $Uri	
}


