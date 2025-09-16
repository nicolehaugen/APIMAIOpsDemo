# Script to create Microsoft Entra ID service principal for APIM Operations
# This script creates a service principal with Contributor role for APIM resource groups

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId = "3cbad5b9-554a-4c70-abe0-effe2f9df1c6",
    
    [Parameter(Mandatory=$true)]
    [string]$TenantId = "93e6a789-dbd2-40f7-b1f7-b5d58b21396c",
    
    [Parameter(Mandatory=$true)]
    [string]$DevResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [string]$ProdResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [string]$ServicePrincipalName = "apiopslab"
)

# Function to extract and display the four required properties
function Get-ServicePrincipalInfo {
    param([string]$JsonOutput, [string]$Environment)
    
    Write-Host "`n=== $Environment Environment Service Principal Details ===" -ForegroundColor Green
    $spInfo = $JsonOutput | ConvertFrom-Json
    
    Write-Host "Properties needed for GitHub Secrets:" -ForegroundColor Yellow
    Write-Host "clientId: $($spInfo.clientId)" -ForegroundColor Cyan
    Write-Host "clientSecret: $($spInfo.clientSecret)" -ForegroundColor Cyan
    Write-Host "subscriptionId: $($spInfo.subscriptionId)" -ForegroundColor Cyan
    Write-Host "tenantId: $($spInfo.tenantId)" -ForegroundColor Cyan
    
    # Save to file for easy reference
    $outputFile = "service-principal-$Environment.json"
    $spInfo | ConvertTo-Json -Depth 3 | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Host "Full output saved to: $outputFile" -ForegroundColor Green
    
    return $spInfo
}

# Validate Azure CLI is installed
try {
    az version 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI not found"
    }
    Write-Host "Azure CLI is installed" -ForegroundColor Green
} catch {
    Write-Error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Login check
Write-Host "Checking Azure CLI login status..." -ForegroundColor Yellow
az account show 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Not logged in to Azure CLI. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Set the subscription
Write-Host "Setting subscription to: $SubscriptionId" -ForegroundColor Yellow
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to set subscription. Please verify the subscription ID."
    exit 1
}

# If ProdResourceGroup is not specified, use the same as DevResourceGroup
if (-not $ProdResourceGroup) {
    $ProdResourceGroup = $DevResourceGroup
    Write-Host "Using same resource group for both environments: $DevResourceGroup" -ForegroundColor Yellow
} else {
    Write-Host "Using separate resource groups - Dev: $DevResourceGroup, Prod: $ProdResourceGroup" -ForegroundColor Yellow
}

Write-Host "`nStarting service principal creation process..." -ForegroundColor Green
Write-Host "Subscription ID: $SubscriptionId" -ForegroundColor Cyan
Write-Host "Tenant ID: $TenantId" -ForegroundColor Cyan
Write-Host "Service Principal Name: $ServicePrincipalName" -ForegroundColor Cyan
Write-Host "Dev Resource Group: $DevResourceGroup" -ForegroundColor Cyan
Write-Host "Prod Resource Group: $ProdResourceGroup" -ForegroundColor Cyan

# Create service principal for DEV environment
Write-Host "`n--- Creating Service Principal for DEV/STAGING Environment ---" -ForegroundColor Magenta
$devScope = "/subscriptions/$SubscriptionId/resourceGroups/$DevResourceGroup"
Write-Host "DEV Scope: $devScope" -ForegroundColor Yellow

$devCommand = "az ad sp create-for-rbac -n `"$ServicePrincipalName-dev`" --role Contributor --scopes `"$devScope`" --sdk-auth"
Write-Host "Executing: $devCommand" -ForegroundColor Gray

try {
    $devOutput = Invoke-Expression $devCommand
    if ($LASTEXITCODE -eq 0) {
        Get-ServicePrincipalInfo -JsonOutput $devOutput -Environment "DEV"
        Write-Host "✅ DEV/STAGING Service Principal created successfully!" -ForegroundColor Green
    } else {
        Write-Error "Failed to create DEV service principal"
        exit 1
    }
} catch {
    Write-Error "Error creating DEV service principal: $($_.Exception.Message)"
    exit 1
}

# Create service principal for PROD environment
Write-Host "`n--- Creating Service Principal for PROD Environment ---" -ForegroundColor Magenta
$prodScope = "/subscriptions/$SubscriptionId/resourceGroups/$ProdResourceGroup"
Write-Host "PROD Scope: $prodScope" -ForegroundColor Yellow

$prodCommand = "az ad sp create-for-rbac -n `"$ServicePrincipalName-prod`" --role Contributor --scopes `"$prodScope`" --sdk-auth"
Write-Host "Executing: $prodCommand" -ForegroundColor Gray

try {
    $prodOutput = Invoke-Expression $prodCommand
    if ($LASTEXITCODE -eq 0) {
        Get-ServicePrincipalInfo -JsonOutput $prodOutput -Environment "PROD"
        Write-Host "✅ PROD Service Principal created successfully!" -ForegroundColor Green
    } else {
        Write-Error "Failed to create PROD service principal"
        exit 1
    }
} catch {
    Write-Error "Error creating PROD service principal: $($_.Exception.Message)"
    exit 1
}

# Check if both service principals are accessing the same resource group
if ($DevResourceGroup -eq $ProdResourceGroup) {
    Write-Host "`n⚠️  NOTE: Both service principals have access to the same resource group: $DevResourceGroup" -ForegroundColor Yellow
    Write-Host "   This is fine for environments where dev/staging and prod resources are in the same RG." -ForegroundColor Yellow
    Write-Host "   Make sure to use proper naming conventions and tags to distinguish resources." -ForegroundColor Yellow
}

# Summary
Write-Host "`n🎉 Service Principal Creation Complete!" -ForegroundColor Green
Write-Host "========================================================================================" -ForegroundColor Yellow
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Copy the clientId, clientSecret, subscriptionId, and tenantId values from above" -ForegroundColor White
Write-Host "2. Store these as secrets in your GitHub repository environments:" -ForegroundColor White
Write-Host "   - Create 'dev' environment with DEV service principal values" -ForegroundColor White
Write-Host "   - Create 'prod' environment with PROD service principal values" -ForegroundColor White
Write-Host "3. Use these secrets in your GitHub Actions workflows for APIM operations" -ForegroundColor White
Write-Host "========================================================================================" -ForegroundColor Yellow

Write-Host "`nFiles created:" -ForegroundColor Green
Write-Host "- service-principal-DEV.json" -ForegroundColor Cyan
Write-Host "- service-principal-PROD.json" -ForegroundColor Cyan
