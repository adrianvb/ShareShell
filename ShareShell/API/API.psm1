# REST API reference and samples 
#	http://msdn.microsoft.com/en-us/library/office/jj860569(v=office.15).aspx
#	http://msdn.microsoft.com/en-us/magazine/dn198245.aspx

# Files and Folders
#   http://msdn.microsoft.com/en-us/library/office/dn450841(v=office.15).aspx

Function Get-EntryNode {
<#
.SYNOPSIS
This function handles parsing the XML nodes returned by the api

#>
	[CmdletBinding()]
	Param (
		[System.Xml.XmlElement] $Node,
		[String] $BaseUri,
		[Switch] $EnableCaching
	)			
	
	$NameSpaces = @{
		base="https://sharepoint.uni-hamburg.de/anwendungen/sap-berichtswesen/_api/"
		m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata"
		d="http://schemas.microsoft.com/ado/2007/08/dataservices"
	}
	
	$Properties = @{
		"__ApiCache" = @{}
	}
	
	#
	# this block parses the content part of the xml response
	#
	
	$XmlParseTime = Measure-Command {		
		# 70x faster than Select-Xml
		$Node.content.properties.ChildNodes | Where-Object { 
			($_ -ne $null)	-and ($_.PSObject.Properties["#text"] -ne $null)
		} | ForEach-Object {
			
			$Name = $_.ToString()			
			$Value = $_."#text"	
			
			if ($_.PSObject.Properties["type"] -ne $null) {			
				$Value = Switch($_.Type) {
					'Edm.Boolean' { [Boolean] $Value }
					'Edm.Int16' { [Decimal] $Value }
					'Edm.Int32' { [Decimal] $Value }
					'Edm.DateTime' { [DateTime] $Value }
					default { [String] $Value }
				}
			}
			$Properties[$Name] = $Value
		}					
	} 
	Write-Debug ("Get-EntryNode: parse time {0}ms" -f $XmlParseTime.Milliseconds)
	
	$Data = New-Object -TypeName PsObject -Property $Properties
	
	#
	# this block parses the link part of the xml response
	#
	
	$MethodProperties = @()
	$Node.link | Where-Object { $_.PSObject.Properties["Title"] -ne $null } | ForEach-Object {
		$Name = $_.Title
		$MethodProperties += $Name
		
		if ($_.Type -like "*type=entry*" -or $_.Type -like "*type=feed*") {
			
			# uris in the api are inconsisten: sometimes absolute, sometimes relative
			# proper uri handling would be nice, system.uri makes me cry
			if ($_.href -like "http*") {
				$EntryUri = $_.href
			} else {
				$EntryUri = "{0}/{1}" -f $BaseUri, $_.href
			}
			
			# this is where the magic happens
			
			# the "$limit=" option above does NOT work. however, the $top= does. 
			# (https://sharepoint.stackexchange.com/questions/74777/list-api-get-all-items-limited-to-100-rows)	

			# https://mjolinor.wordpress.com/2011/02/13/getnewclosure-vs-scriptblockcreate/
			$ScriptClosure = { 
				Param(
					$Filter = $null,
					$Options = @{"top" = 1000},
					[Switch] $EnableCaching = $false
				);					
				Write-Debug "Invoke-XmlApiRequest: Property $PropertyName($Filter)"
				
				# property name: Items(), Lists()
				$PropertyName = $Name
				
				# we cache every response using another property
				$PropertyCacheName = "Cache_$PropertyName"
														
				
				# if this property is not cached, we request it and add it as cached property
				# removing the cached property would reset this propertys state
				if ($This.__ApiCache[$PropertyCacheName] -ne $null -and $EnableCaching) {
					$Response = $This.__ApiCache[$PropertyCacheName]
				} else {
					$Parameters = @()
					$Options.Keys | ForEach-Object {
						$Parameters += ("`${0}={1}" -f $_, $Options[$_])
					}
				
					$RequestUri = $EntryUri + "?" + [String]::Join("&", $Parameters)			
					$Response = Invoke-XmlApiRequest -Uri $RequestUri
					
					if ($EnableCaching) {					
						$This.__ApiCache[$PropertyCacheName] = $Response
					} 
				}			
				
				# filter is nifty
				if ($Filter -ne $null) {
				
					if ($Filter.GetType().Name -eq "ScriptBlock") {
						$Response = $Response | Where-Object $Filter
					} else {
						$Response = $Response | Where-Object { $_.Title -like $Filter -or $_.Name -like $Filter }
					}
					
				}
				$Response
				
			}.GetNewClosure()
										
			$Data | Add-Member -MemberType ScriptMethod -Name $Name -Value $ScriptClosure -Force
						
			
		}
	}
	
	$Data | Add-Member -MemberType NoteProperty -Name "__ApiMethods" -Value $MethodProperties -Force
	
	#
	# this block adds update statements if type is entry
	#
	
	$Data | Add-Member -MemberType ScriptMethod -Name "Update" -Value ({
		
		# enable caching for this lookup
		#$List = $This.ParentList($null, $null, $true)		
		$List = $This.ParentList($null, @{}, $true)
		Write-Host ($List | Format-List | Out-String)
	
		# we need $ParentWebUrl for:
		# 	a) build the update uri 
		#	b) fetch the request digest (below)
		$ParentWebUrl = $List.ParentWeb($null, @{}, $true).Url
		
		# this is our update uri
		$UpdateUri = "{0}/_api/Lists(guid'{1}')/Items({2})" -f $ParentWebUrl, $List.Id, $This.Id
		
		# Request digest for authtentication
		$RequestDigest = Get-FormDigest -BaseUri $ParentWebUrl
		
		$Temp = $This
		$Temp | Add-Member -MemberType NoteProperty -Name "__metadata" -Value @{ 
			'type' = $List.ListItemEntityTypeFullName
		}				
		
		$Temp.PSObject.Properties.Remove('__ApiMethods')
		$Temp.PSObject.Properties.Remove('__ApiCache')
		#"Attachments", "Created", "GUID", "EditorId", "FileSystemObjectType", "Modified", "OData__UIVersionString", "ContentTypeId" | ForEach-Object { $Temp.PSObject.Properties.Remove($_) }
		
		$Headers =  @{
			"Accept" = "application/json; odata=verbose" 
			"X-RequestDigest" = $RequestDigest
			"X-HTTP-Method" = "MERGE"
			"If-Match" = "*"
		}		
		
		# let's do it
		$Response = $null		
		Try {
		
			Write-Host ($Temp | Format-List | Out-String)
		
			$Response = Invoke-WebRequest `
				-Body ($Temp | ConvertTo-Json) `
				-Method POST `
				-UseDefaultCredentials `
				-ContentType "application/json; odata=verbose" `
				-Uri $UpdateUri `
				-Headers $Headers `
				-ErrorAction Inquire
		} Catch {
			Write-Error ($_.Exception.Response | Format-List -Force | Out-String)
		}
		
		$Response
	
	}.GetNewClosure())
	
	
	$Data 
}	

Function Invoke-XmlApiRequest {
	[CmdletBinding()]
	Param(
		[String] $Uri,
		[String] $Method = 'Get',
		[Switch] $EnableCaching
	)
			
	Write-Debug ("Invoke-XmlApiRequest: Requesting {0}" -f $Uri)
	$Result = Invoke-WebRequest `
		-Uri $Uri `
		-UseDefaultCredentials `
		-Method $Method
		
	if ($Uri -notmatch "(.*/_api)") {
		Write-Error "Invoke-XmlApiRequest: /api missing in uri: '$Uri'"
	}
	$BaseUri = $Matches[1]
	
	[Xml] $Xml = $Result.Content -replace 'xmlns="http://www.w3.org/2005/Atom"'	
	
	# if there are no entries, $xml.feed.entry does not exist
	if ($Xml.PSObject.Properties["feed"] -ne $null) {
		
		Write-Debug ("Invoke-XmlApiRequest: Parsing as feed")
		if ($Xml.feed.PSObject.Properties["entry"] -ne $null) {				
			$Xml.feed.entry | ForEach-Object  {
				Get-EntryNode -Node $_ -BaseUri $BaseUri -EnableCaching:$EnableCaching
			}
		} else {
			Write-Debug ("Invoke-XmlApiRequest: No entries for '{0}'" -f $Uri)
		}
		
	} elseif ($Xml.PSObject.Properties["entry"] -ne $null) {	
		Write-Debug "Invoke-XmlApiRequest: Parsing as entry"
		Get-EntryNode -Node $Xml.entry -BaseUri $BaseUri -EnableCaching:$EnableCaching
	} else {
		Write-Error "Invoke-XmlApiRequest: Cannot handle response for '$Uri'"	
	}
	
}

Function New-ListItem {
	<#
	.LINKS
	http://www.plusconsulting.com/blog/2013/05/crud-on-list-items-using-rest-services-jquery/
	#>

	Param(
		[Parameter(Mandatory=$true)] $List,
		$Fields = $null,
		$ElementTypeName = "Element"
	)
	
	# we need $ParentWebUrl for:
	# 	a) build the update uri 
	#	b) fetch the request digest (below)
	$ParentWebUrl = $List.ParentWeb().Url
	
	# this is our update uri
	$UpdateUri = "{0}/_api/Lists(guid'{1}')/Items" -f $ParentWebUrl, $List.Id
	
	# fetch fields if not passed as parameter
	if ($Fields -eq $null) {
		$ContentType = $List.ContentTypes({$_.Name -like $ElementTypeName}) | Select-Object -First 1
		$Fields = $ContentType.Fields()
	}
	
	# we store fields that are flagged as "required"
	$RequiredFields = @()
	
	# this is were the data lives
	$Properties = @{}
	$Properties['__required'] = $RequiredFields
	$Properties['__metadata'] = @{ 
		'type' = $List.ListItemEntityTypeFullName
	}
	
	# Skip calculated fields
	$Fields | Where-Object { 
		$_.TypeAsString -ne "Calculated" -and $_.TypeAsString -ne "Computed" 
	} | ForEach-Object {
		$Properties[$_.InternalName] = $null		
	}
	

	$Item = New-Object -TypeName PSObject -Property $Properties	
	$Item | Add-Member -MemberType ScriptMethod -Name "Update" -Value {
	
		# we need to remove all custom properties before sharepoint likes it
		$Temp = $This
		
		# the request digest is used to prevent replay attacks
		$RequestDigest = Get-FormDigest -BaseUri $ParentWebUrl
		
		$Headers =  @{
			"accept" = "application/json; odata=verbose" 
			"content-type" = "application/json; odata=verbose"
			'X-RequestDigest' = $RequestDigest
		}		
		
		# let's do it
		$Response = $null		
		Try {
			$Response = Invoke-WebRequest `
				-Body ($Temp | ConvertTo-Json) `
				-Method Post `
				-UseDefaultCredentials `
				-ContentType "application/json; odata=verbose" `
				-Uri $UpdateUri `
				-Headers $Headers `
				-ErrorAction Inquire
		} Catch {
			Write-Error ($_.Exception.Response | Format-List -Force | Out-String)
		}
		
		$Response
			
	}.GetNewClosure()
	
	$Item	
}

Function Get-FormDigest {
	Param (
		[String] $BaseUri
	)
	$Response = Invoke-WebRequest -Method  Post -Uri "$BaseUri/_api/contextinfo" -UseDefaultCredentials
	[Xml] $Content = $Response.Content
	
	$Content.GetContextWebInformation.FormDigestValue
}

Set-StrictMode -Version Latest
#Export-ModuleMember ("Invoke-XmlApiRequest", "New-ListItem")