ShareShell
==========

Use PowerShell to query SharePoint 2013 REST API from anywhere.

This PowerShell module makes use of the SharePoint 2013 API to browse lists and libraries, 
add items to lists, delete files and folders and much more.

To be honest: This is just a slightly smart wrapper against the OData API ;-)

Note
----
this library is pretty much a moving target for now. I implement the functionality as i need it.
If you want to use it and miss something, ping me and we'll see how to get it included.

Usage
-----
the following example assumes that the current user has permissions to access SharePoint

```
Import-Module ShareShell

$Uri = "https://YourSharePoint.com"
$Web = Get-ShareWeb -Uri $Uri

$Lists = $Web.Lists()

$List = $Web.Lists({$_.EntityTypeName -like "UserInfo"})
$List = $Web.Lists('Benutzerinformationsliste')

$Filter = {$_.Modified -gt (Get-Date).AddDays(-260)}
$QueryOpt = @{ "top"=10}
$List.Items($Filter, $QueryOpt)
$List.Items($null, $QueryOpt)

$List.__ApiMethods
```

Right now you can use full CRUD on list and library items

Links
-----
https://www.simple-talk.com/dotnet/.net-tools/further-down-the-rabbit-hole-powershell-modules-and-encapsulation/ 


