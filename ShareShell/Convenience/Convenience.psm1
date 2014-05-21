Function Get-Web {
	Param(
		[Parameter(Mandatory=$true)] [String] $Uri
	)
	
	
	
	# https://sharepoint/sites/playground/_layouts/15/start.aspx#/Lists/Reboot/AllItems.aspx
	if ($Uri -like "*/_layouts/15/start.aspx#*") {
		$Uri = $Uri.Replace("_layouts/15/start.aspx#/", "")
	}
	
	if ($Uri -match "/Lists/.*|/SiteAssets/.*") {
		$Uri = $Uri.Replace($Matches[0], "")
	}
	
	if ($Uri -notlike "*/_api/web*") {
		$Uri = "$Uri/_api/web"
	}	
	
	Invoke-XmlApiRequest -Uri $Uri	
}


