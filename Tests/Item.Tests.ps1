Import-Module ShareShell -Force

$InvalidApiUrl = "https://sharepoint.uni-hamburg.de/"
$ValidApiUrl = "https://sharepoint.uni-hamburg.de/_api/web"

$NorthwindItem = Invoke-XmlApiRequest "http://services.odata.org/V3/Northwind/Northwind.svc/Orders(10248)/"

$ItemTitle = (Get-Date)

Describe "Item" { 
    Context "Northwind Order" {
       
        It "property value" {

            $FailedProperties = @()
            
            $ExpectedPropertyValues = @{
                "OrderID" = 10248
                "CustomerID" = "VINET"
                "EmployeeID" = 5
                "OrderDate" = [DateTime] "1996-07-04T00:00:00"
                "RequiredDate" = [DateTime] "1996-08-01T00:00:00"
                "ShippedDate" = [DateTime] "1996-07-16T00:00:00"
                "ShipVia" = 3
                "Freight" = 32.3800
                "ShipName" = "Vins et alcools Chevalier"
                "ShipAddress" = "59 rue de l'Abbaye"
                "ShipCity" = "Reims"
                "ShipRegion" = $null
                "ShipPostalCode" = 51100
                "ShipCountry" = "France"
            }
            
            $ItemProperties = $NorthwindItem.psobject.properties | Select-Object -ExpandProperty Name
            ForEach ($Property in $ExpectedPropertyValues.Keys) {
                if ($NorthwindItem.$Property -ne $ExpectedPropertyValues[$Property]) {
                    $FailedProperties += $Property
                }
            }                        
            
            $FailedProperties | Should BeNullOrEmpty

        }
        
        It "property type" {

            $FailedProperties = @()
            
            $ExpectedPropertyTypes = @{
                "OrderID" = "Int32"
                "CustomerID" = "String"
                "EmployeeID" = "Int32"
                "RequiredDate" = "DateTime"
                "ShippedDate" = "DateTime"
                "ShipVia" = "Int32"
                "Freight" = "Double"
                "ShipName" = "String"
                "ShipAddress" = "String"
                "ShipCity" = "String"
                #"ShipRegion" = $null
                "ShipPostalCode" = "String"
                "ShipCountry" = "String"
            }
            
            $ItemProperties = $NorthwindItem.psobject.properties | Select-Object -ExpandProperty Name
            ForEach ($Property in $ExpectedPropertyTypes.Keys) {
                if ($NorthwindItem.$Property.GetType().Name -ne $ExpectedPropertyTypes[$Property]) {
                    $FailedProperties += $Property
                }
            }                 
            
            $FailedProperties | Should BeNullOrEmpty

        }
        
        It "method type" {
            $ExpectedApiMethods = @(
                "Customer"
                "Employee"
                "Order_Details"
                "Shipper"
            )
            
            $FailedMethods = @()
                        
            ForEach ($Method in $ExpectedApiMethods) {                
                # Write-Host "$Method, $($NorthwindItem.$Method.GetType().Name)"
                if ($NorthwindItem.$Method.GetType().Name -ne "PSScriptMethod") {                    
                    $FailedMethods += $Method
                }
            }
            
            $FailedMethods | Should BeNullOrEmpty
        }
        
	}
	 
	
}