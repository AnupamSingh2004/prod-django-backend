#!/bin/bash

# Script to show available Azure regions in India

echo "🇮🇳 Available Azure Regions in India:"
echo "======================================"
echo ""
echo "Available regions for PostgreSQL Flexible Server in India:"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed."
    echo "Install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    echo ""
    echo "🌍 Common India regions (you can use these):"
    echo "  • Central India (centralindia)"
    echo "  • South India (southindia)"
    echo "  • West India (westindia)"
    echo ""
    echo "📍 Recommended: Central India (Mumbai) - Best connectivity for most of India"
    exit 1
fi

# Login check
if ! az account show &>/dev/null; then
    echo "🔐 Please login to Azure first:"
    echo "   az login"
    exit 1
fi

echo "🔍 Checking available regions for PostgreSQL Flexible Server..."
echo ""

# Get all locations that support PostgreSQL Flexible Server
LOCATIONS=$(az postgres flexible-server list-skus --location "Central India" --query "[0].locationInfo[].location" -o tsv 2>/dev/null | head -10)

if [ -z "$LOCATIONS" ]; then
    echo "🌍 Standard India regions for PostgreSQL:"
    echo "  ✅ Central India (centralindia) - Mumbai"
    echo "  ✅ South India (southindia) - Chennai" 
    echo "  ✅ West India (westindia) - Pune"
    echo ""
    echo "📍 Recommended: Central India"
    echo "   - Lowest latency for most Indian users"
    echo "   - Best availability of services"
    echo "   - Primary Azure region in India"
else
    echo "Available regions:"
    for location in $LOCATIONS; do
        case $location in
            *india*|*India*)
                echo "  ✅ $location"
                ;;
        esac
    done
fi

echo ""
echo "💡 To use a different region, edit these files:"
echo "   • create_azure_postgres.sh (LOCATION variable)"
echo "   • azure_postgres_manual_steps.sh"
echo "   • README.md"
echo ""
echo "🚀 Current configuration uses: Central India"
