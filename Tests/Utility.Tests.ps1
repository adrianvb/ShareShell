Import-Module ShareShell -Force

$ApiUri = "https://sharepoint.uni-hamburg.de"

Describe "Utility Functions" { 
    Context "Get-FormDigest" {
       
        It "loads without errors" {
			{ Get-FormDigest -BaseUri $ApiUri } | Should Not Throw
		}
		
		It "returns token" {
			{ Get-FormDigest -BaseUri $ApiUri } | Should Not BeNullOrEmpty
		}				
	}

}