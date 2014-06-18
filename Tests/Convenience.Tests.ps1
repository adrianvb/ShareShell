$TestWebUrl = "https://sharepoint.uni-hamburg.de"

Describe "Convenience" {
    Context "Get-ShareWeb Operations" {
       
        It "loads without errors" {
            { Get-ShareWeb $TestWebUrl } | Should Not Throw	
        }		
		
		It "is not null" {
            Get-ShareWeb $TestWebUrl | Should Not BeNullOrEmpty
        }     	
		
		It "title is not null" {
			$Web = Get-ShareWeb $TestWebUrl			
			$Web.Title | Should Not BeNullOrEmpty
		}
    }	
}