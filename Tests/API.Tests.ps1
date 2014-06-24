Import-Module ShareShell -Force

$InvalidApiUrl = "https://sharepoint.uni-hamburg.de/"
$ValidApiUrl = "https://sharepoint.uni-hamburg.de/_api/web"

$List = Invoke-XmlApiRequest "https://sharepoint.uni-hamburg.de/sites/api-test/_api/web/Lists/GetByTitle('New-ListItem')"

$ItemTitle = (Get-Date)

Describe "API Functions" { 
    Context "Invoke-XmlApiRequest" {
       
        It "loads without errors" {
			{ Invoke-XmlApiRequest -Uri $ValidApiUrl } | Should Not Throw
		}
		
		It "throws error on invalid uri" {
			{ Invoke-XmlApiRequest -Uri $InvalidApiUri } | Should Throw
		}
				
		It "throws error on bogus host" {
			{ Invoke-XmlApiRequest -Uri "http://bogus.test" } | Should Throw
		}

	}
	 
	Context "New-ListItem" {
		
		It "returns a list item" {
			New-ListItem -List $List | Should Not BeNullOrEmpty
		}
		
		it "has a title field" {
			{ (New-ListItem -List $List).title } | Should Not Throw
		}
		
		it "item can be created" {
			 
			#	$Item = New-ListItem -List $List
			#	$Item.Title = $ItemTitle
			#	$Item.Create() 
			
		}
		
		it "can be deleted" {
			$Items = $List.Items($ItemTitle) 
			#{ $Items | ForEach-Object { $_.Delete() } } | Should Not Throw
		} 
		
	}
}