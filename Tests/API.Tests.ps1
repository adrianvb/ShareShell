Import-Module ShareShell -Force

$InvalidApiUrl = "https://sharepoint.uni-hamburg.de/"
$ValidApiUrl = "https://sharepoint.uni-hamburg.de/_api/web"

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

}