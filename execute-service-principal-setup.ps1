# Execute the service principal creation script
# For single resource group containing both dev and prod resources, only specify DevResourceGroup
# For separate resource groups, specify both DevResourceGroup and ProdResourceGroup

# Example usage:
# Single RG:    .\execute-service-principal-setup.ps1 -DevResourceGroup "rg-apim-shared"
# Separate RGs: .\execute-service-principal-setup.ps1 -DevResourceGroup "rg-apim-dev" -ProdResourceGroup "rg-apim-prod"

param(
    [Parameter(Mandatory=$true)]
    [string]$DevResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [string]$ProdResourceGroup
)

$subscriptionId = "3cbad5b9-554a-4c70-abe0-effe2f9df1c6"
$tenantId = "93e6a789-dbd2-40f7-b1f7-b5d58b21396c"

Write-Host "Creating service principals for APIM Operations..." -ForegroundColor Green
Write-Host "Dev Resource Group: $DevResourceGroup" -ForegroundColor Yellow

if ($ProdResourceGroup) {
    Write-Host "Prod Resource Group: $ProdResourceGroup" -ForegroundColor Yellow
    # Execute the main script with separate resource groups
    & ".\create-service-principal.ps1" -SubscriptionId $subscriptionId -TenantId $tenantId -DevResourceGroup $DevResourceGroup -ProdResourceGroup $ProdResourceGroup
} else {
    Write-Host "Using same resource group for both environments" -ForegroundColor Yellow
    # Execute the main script with single resource group
    & ".\create-service-principal.ps1" -SubscriptionId $subscriptionId -TenantId $tenantId -DevResourceGroup $DevResourceGroup
}
