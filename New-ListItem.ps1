

Function Write-Object {
	Param(
		[Parameter(Mandatory=$true)] [Object] $Object
	)
	
	Write-Host ($Object | Format-List | Out-String)
	
}


Import-Module ShareShell

$Web = Get-Web "https://sharepoint.uni-hamburg.de/sites/playground/"
$List = $Web.Lists("Api Test")

Write-Host "New Item"
$Item = New-ListItem2 -List $List
$Item.Title = "New List Item " + (Get-Date)
$Item.Number_x0020__x0028_Required_x00 = 213

Write-Host "Create!"
$Item.Create()
Write-Object $Item

Write-Host "Update!"
$Item.Title = "New List Item " + (Get-Date)
$Item.Update()
Write-Object $Item

Write-Host "Delete!"
$Item.Delete()
Write-Object $Item

