# REST API reference and samples 
#	http://msdn.microsoft.com/en-us/library/office/jj860569(v=office.15).aspx
#	http://msdn.microsoft.com/en-us/magazine/dn198245.aspx

# Files and Folders
#   http://msdn.microsoft.com/en-us/library/office/dn450841(v=office.15).aspx


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
		
    if ($Uri -match "(.*/_api)") {
        $BaseUri = $Matches[1]
    } else {
        Write-Verbose "Invoke-XmlApiRequest: /api missing in uri: '$Uri'"
        $BaseUri = $Uri
		
	}    			
	[Xml] $Xml = $Result.Content -replace 'xmlns="http://www.w3.org/2005/Atom"'	
	
	# if there are no entries, $xml.feed.entry does not exist
	if ($Xml.PSObject.Properties["feed"] -ne $null) {
		
		Write-Debug ("Invoke-XmlApiRequest: Parsing as feed")
		if ($Xml.feed.PSObject.Properties["entry"] -ne $null) {
			$Counter = 0
			#$Total = $Xml.feed.entry.Count
			$Xml.feed.entry | ForEach-Object  {
				$Counter += 1
				#Write-Progress -Activity "Fetching items" -PercentComplete (($Counter/$Total)*100)
				ConvertFrom-ApiResponse -Node $_ -RequestUri $Uri -EnableCaching:$EnableCaching
			}
		} else {
			Write-Verbose ("Invoke-XmlApiRequest: No entries for '{0}'" -f $Uri)
		}
		
	} elseif ($Xml.PSObject.Properties["entry"] -ne $null) {	
		Write-Debug "Invoke-XmlApiRequest: Parsing as entry"
		ConvertFrom-ApiResponse -Node $Xml.entry -RequestUri $Uri -EnableCaching:$EnableCaching
	} else {
		Write-Error "Invoke-XmlApiRequest: Cannot handle response for '$Uri'"	
	}
	
}

Function ConvertFrom-ApiResponse {
<#
.SYNOPSIS
This function handles parsing the XML nodes returned by the api

#>
	[CmdletBinding()]
	Param (
		[System.Xml.XmlElement] $Node,
		[String] $RequestUri,
		[Switch] $EnableCaching
	)			
	
	$NameSpaces = @{
		base="https://sharepoint.uni-hamburg.de/anwendungen/sap-berichtswesen/_api/"
		m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata"
		d="http://schemas.microsoft.com/ado/2007/08/dataservices"
	}
	
	$BaseUri = ($RequestUri -replace '/_api/.*', '') + '/_api'
	
	#
	# PROPERTIES 
	# this block parses the content part of the xml response
	#
    $Properties = @{}
    
	# 70x faster than Select-Xml
	if ($Node.content.properties.ChildNodes.Count -gt 0) {
		ForEach ($Property in $Node.content.properties.ChildNodes) {	
			
            # der Name des Tags ist der Name der Eigenschaft
            $Name = $Property.ToString()
            
            # das Tag muss nicht zwingend einen Inhalt haben
            $Value = $null
            if ($Property.PSObject.Properties["#text"] -ne $null) {
                $Value = $Property."#text"
            }             
            
            # der Typ ist leider auch nicht für alle Eigenschaften verfügbar
            if ($Property.PSObject.Properties["type"] -ne $null) {
                $Type = $Property.Type
            
                Switch($Type) {
					'Edm.Boolean' { 
                        if ($Value -eq "true") { 
                            $Value = $true
                        } else { 
                            $Value = $false 
                        }
                    }
                    'Edm.Int32' {
                        $Value = [Int32] $Value
                    }
                    'Edm.Decimal' {
                        $Value = [Double] $Value
                    }
					'Edm.DateTime' {
                        $Value = [DateTime] $Value
                    }
                    # 'Edm.Binary' {}
                    
				}
                
                if ($Type -like "Collection*") {
                    $Value = @()
                    ForEach ($Reference in $Property.ChildNodes) {
                        $Value += $Reference."#text"
                    }
                }
			}
			
			$Properties[$Name] = $Value
		}					
	}		
    
	$Properties["__Category"] = $Node.category.term

    # Uri des Objekts
    $EditUri = $Node.link | Where-Object { $_.rel -eq "edit" } | Select-Object -First 1 -ExpandProperty href
    if ($EditUri[0]  -notmatch "http.*") {
        $ItemUri = "$BaseUri/$EditUri"
    }
	$Properties["__Uri"] = $ItemUri
	
    #
    # und hier unser neues Objekt
    #        
	$Item = New-Object -TypeName PsObject -Property $Properties
	
	#
	# METHODS
	#
	# this block parses the link part of the xml response
	# each link will be represented as a function of this objects
	#
	$ApiMethods = @()
	
	$NavigationLinks = $Node.link | Where-Object { $_.PSObject.Properties["Title"] -ne $null -and $_.PSObject.Properties["Type"] -ne $null } 
    ForEach ($Link in $NavigationLinks) { 
	            
		if ($Link.Type -like "*type=entry*" -or $Link.Type -like "*type=feed*") {			
			$ApiMethods += $Link.Title
			
			# uris in the api are inconsisten: sometimes absolute, sometimes relative
			# proper uri handling would be nice, system.uri makes me cry
			$Uri = $Link.href
			if ($Link.href -notlike "http*") {
				$Uri = "{0}/{1}" -f $BaseUri, $Link.href
			}
			
			$Item = Add-ApiMethod  -Item $Item -Name $Link.Title -Uri $Uri            
		}
	}
	$Item | Add-Member -MemberType NoteProperty -Name "__ApiMethods" -Value $ApiMethods -Force
	
	#
	# Add CRUD if entry has a content type 
	#
	if ($Item.PsObject.Properties["ContentTypeId"] -ne $null) {	
		$ParentListUri = $RequestUri -replace '/Items.*',''
		
		$ParentList = Get-CachedItem -Key $ParentListUri
		if ($ParentList -eq $null) {
			$ParentList = $Item.ParentList()
			Add-CachedItem -Key $ParentListUri -Value $ParentList
		}
		$Item = Add-CrudMethod -Item $Item -List $ParentList -Operation "Update"
		$Item = Add-CrudMethod -Item $Item -List $ParentList -Operation "Delete"
	}
	
	$Item 
}	

Function Add-ApiMethod {
	Param(
		[Parameter(Mandatory=$true)]
		[PSObject] $Item,
		
		[Parameter(Mandatory=$true)]
		[String] $Name,
				
		[Parameter(Mandatory=$true)]
		[String] $Uri	
	)

	# the "$limit=" option above does NOT work. however, the $top= does. 
	# (https://sharepoint.stackexchange.com/questions/74777/list-api-get-all-items-limited-to-100-rows)	

	# https://mjolinor.wordpress.com/2011/02/13/getnewclosure-vs-scriptblockcreate/
	$ScriptClosure = { 
		Param(
			$Filter = $null,
			[Switch] $EnableCaching = $false
		);					
		Write-Debug "Invoke-XmlApiRequest: Property $Name"																				
		
		# we cache every response using another property
																
		# if this property is not cached, we request it and add it as cached property
		# removing the cached property would reset this propertys state
		
		# build the request uri
		# we use the request uri as key for the cache lookup
		$Parameters = @('$top=1000')
		$RequestUri = $Uri + "?" + [String]::Join("&", $Parameters)
		
		if ((Test-CachedItemExists -Key $RequestUri) -and $EnableCaching) {
			$Response = Get-CachedItem -Key $RequestUri
		} else {
			
			$Response = Invoke-XmlApiRequest -Uri $RequestUri
			
			if ($EnableCaching) {					
				Add-CachedItem -Key $RequestUri -Value $Response
			} 
		}			
		
		# filter is nifty
		if ($Filter -ne $null) {				
			if ($Filter -is [String]) {
				$Filter = { 
					$_.Title -like $Filter `
					-or $_.Name -like $Filter `
					-or $_.GUID -like $Filter `
					-or $_.Id -like $Filter
				}.GetNewClosure()
			}
			$Response = $Response | Where-Object $Filter
			if ($Response -eq $null) {
				Write-Error ($Name + ": empty result set after filter")
			}
		}
		$Response

	}.GetNewClosure()
								
	$Item | Add-Member -MemberType ScriptMethod -Name $Name -Value $ScriptClosure -Force
	$Item
}


Function Add-CrudMethod {
	<#
	.SYNOPSIS
	appends create(), update() and delete() to an object. Should be called Add-CudMethod ;-)
	#>
	Param(
		[Parameter(Mandatory=$true)] [ValidateSet("Create","Update","Delete")] [String] $Operation,
		[Parameter(Mandatory=$true)] [Object] $List,
		[Parameter(Mandatory=$true)] $Item,
		
		[String] $ParentWebUrl = $List.ParentWeb($null, $true).Url		
	)
	
	$ScriptBlock = {
	
		if ($Operation -eq "Update" -and $This.Id -eq $null) {
			Write-Warning "Update(): Empty id, use Create()!"
		}		
		$TempItem = $Item 
		
		# Request digest for authtentication
		$RequestDigest = Get-FormDigest -BaseUri $ParentWebUrl
		
		$Headers =  @{
			#"Accept" = "application/xml; odata=verbose" 
			"X-RequestDigest" = $RequestDigest			
			"If-Match" = "*"
		}				
		
		$Uri = "{0}/_api/Lists(guid'{1}')/Items" -f $ParentWebUrl, $List.Id
		
		if ($Operation -eq "Update") {
			$Uri = "{0}/_api/Lists(guid'{1}')/Items({2})" -f $ParentWebUrl, $List.Id, $This.Id
			$Headers["X-HTTP-Method"] = "MERGE"
		}
		if ($Operation -eq "Delete") {
			$Uri = "{0}/_api/Lists(guid'{1}')/Items({2})" -f $ParentWebUrl, $List.Id, $This.Id
			$Headers["X-HTTP-Method"] = "DELETE"
		}		
		
		if ($TempItem.PsObject.Properties["__metadata"] -eq $null) {
			$TempItem | Add-Member -MemberType NoteProperty -Name "__metadata" -Value @{ 
				'type' = $List.ListItemEntityTypeFullName
			}
		}						
	
		# Remove api properies
		$TempItem.PSObject.Properties.Remove('__ApiMethods')
		$TempItem.PSObject.Properties.Remove('__Category')
		$TempItem.PSObject.Properties.Remove('__Uri')
				
		# let's do it
		$Method = "POST"
		$ContentType = "application/json; odata=verbose; charset=utf-8"
		$Body = [System.Text.Encoding]::UTF8.GetBytes(($TempItem | ConvertTo-Json))
		$Response = $null	

		Try {
			$Response = Invoke-WebRequest `
				-Body $Body `
				-Method POST `
				-UseDefaultCredentials `
				-ContentType $ContentType `
				-Uri $Uri `
				-Headers $Headers `
				-ErrorAction Inquire					
			
		} Catch { 
			Write-Host ($_.Exception | Format-List -Force | Out-String)
		}

		if ($Operation -eq "Create") {	
		
			$Node = [Xml] $Response.Content						
			$ResponseItem = ConvertFrom-ApiResponse -Node $Node.entry -RequestUri $Uri
			
			$ResponseItem.PsObject.Properties | ForEach {
				$Prop = $_
				
				# i don't know why
				if ($Prop -eq $null -or $Prop -like '__metadata') {
					continue
				} elseif ($This.PSObject.Properties[$Prop.Name] -eq $null) {
				 	$This | Add-Member -MemberType $Prop.MemberType -Name $Prop.Name -Value $Prop.Value
				} 
			}
		}
		
		$This
		
	}.GetNewClosure()
	
	
	$Item | Add-Member -MemberType ScriptMethod -Name $Operation -Value $ScriptBlock	
	$Item
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
	
	# fetch fields if not passed as parameter
	if ($Fields -eq $null) {
		$ContentType = $List.ContentTypes({$_.Name -like $ElementTypeName}, $true) | Select-Object -First 1
		$Fields = $ContentType.Fields()
	}
	
	
	$Fields = $Fields | ForEach-Object {
		if ($_.TypeAsString -eq "Lookup") {
			if ($_.IsRelationship -eq "True") {
				$_.InternalName = ($_.InternalName + "Id")
				$_
			}
		} elseif ($_.TypeAsString -ne "Calculated" -and $_.TypeAsString -ne "Computed") {
			$_
		}
	}
		
	$Properties = @{}
	$Fields | ForEach-Object {
		$Properties[$_.InternalName] = $null		
	}
	
	$Item = New-Object -TypeName PSObject -Property $Properties	
	$Item = Add-CrudMethod -Item $Item -List $List -Operation "Create"	
	$Item = Add-CrudMethod -Item $Item -List $List -Operation "Update"
	$Item = Add-CrudMethod -Item $Item -List $List -Operation "Delete"
	
	$Item
}


Set-StrictMode -Version Latest
#Export-ModuleMember ("Invoke-XmlApiRequest", "New-ListItem")