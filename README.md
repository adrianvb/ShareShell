ShareShell
==========

Use PowerShell to query SharePoint 2013 REST Api from anywhere

Usage
-----

Import-Module ShareShell

$Uri = "https://YourSharePoint.com"
$Web = Get-Web -Uri $Uri

$Lists = $Web.Lists()

$List = $Web.Lists({$_.EntityTypeName -like "UserInfo"})
$List = $Web.Lists('Benutzerinformationsliste')

$Filter = {$_.Modified -gt (Get-Date).AddDays(-260)}
$QueryOpt = @{ "top"=10}
$List.Items($Filter, $QueryOpt)
$List.Items())

Links
-----
https://www.simple-talk.com/dotnet/.net-tools/further-down-the-rabbit-hole-powershell-modules-and-encapsulation/ 


