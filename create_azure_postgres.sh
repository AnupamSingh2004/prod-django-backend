#!/bin/bash

# Azure PostgreSQL Database Creation Script
# This script creates an Azure PostgreSQL Flexible Server

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first:"
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Configuration variables (you can modify these)
RESOURCE_GROUP_NAME="django-backend-rg"
SERVER_NAME="django-postgres-server-$(date +%s)"
LOCATION="Central India" 
ADMIN_USERNAME="postgres"
ADMIN_PASSWORD=""
DATABASE_NAME="django_db"
SKU_NAME="Standard_B1ms"  # Burstable, 1 vCore, 2GB RAM
STORAGE_SIZE="32"  # GB
TIER="Burstable"

print_status "🚀 Starting Azure PostgreSQL Flexible Server creation..."

# Prompt for password if not set
if [ -z "$ADMIN_PASSWORD" ]; then
    echo -n "Enter admin password for PostgreSQL (min 8 chars, must contain uppercase, lowercase, number, special char): "
    read -s ADMIN_PASSWORD
    echo
fi

# Validate password
if [ ${#ADMIN_PASSWORD} -lt 8 ]; then
    print_error "Password must be at least 8 characters long"
    exit 1
fi

print_status "Logging into Azure..."
az login

print_status "Creating resource group: $RESOURCE_GROUP_NAME"
az group create \
    --name $RESOURCE_GROUP_NAME \
    --location "$LOCATION"

print_status "Creating PostgreSQL Flexible Server: $SERVER_NAME"
az postgres flexible-server create \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $SERVER_NAME \
    --location "$LOCATION" \
    --admin-user $ADMIN_USERNAME \
    --admin-password "$ADMIN_PASSWORD" \
    --sku-name $SKU_NAME \
    --tier $TIER \
    --storage-size $STORAGE_SIZE \
    --version 15 \
    --public-access 0.0.0.0-255.255.255.255

print_status "Creating database: $DATABASE_NAME"
az postgres flexible-server db create \
    --resource-group $RESOURCE_GROUP_NAME \
    --server-name $SERVER_NAME \
    --database-name $DATABASE_NAME

print_status "Configuring firewall rules..."
# Allow Azure services
az postgres flexible-server firewall-rule create \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $SERVER_NAME \
    --rule-name "AllowAzureServices" \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0

# Get current public IP and allow it
CURRENT_IP=$(curl -s https://ipinfo.io/ip)
if [ ! -z "$CURRENT_IP" ]; then
    print_status "Adding firewall rule for your current IP: $CURRENT_IP"
    az postgres flexible-server firewall-rule create \
        --resource-group $RESOURCE_GROUP_NAME \
        --name $SERVER_NAME \
        --rule-name "AllowCurrentIP" \
        --start-ip-address $CURRENT_IP \
        --end-ip-address $CURRENT_IP
fi

# Get server details
SERVER_FQDN="${SERVER_NAME}.postgres.database.azure.com"
CONNECTION_STRING="postgresql://${ADMIN_USERNAME}:${ADMIN_PASSWORD}@${SERVER_FQDN}:5432/${DATABASE_NAME}?sslmode=require"

print_success "✅ Azure PostgreSQL Flexible Server created successfully!"
echo ""
echo "📋 Connection Details:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Server Name:     $SERVER_NAME"
echo "FQDN:           $SERVER_FQDN"
echo "Admin Username: $ADMIN_USERNAME"
echo "Database Name:  $DATABASE_NAME"
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Location:       $LOCATION"
echo ""
echo "🔗 Connection String:"
echo "$CONNECTION_STRING"
echo ""
echo "📝 Environment Variables for your .env file:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "DATABASE_URL=$CONNECTION_STRING"
echo "AZURE_POSTGRES_HOST=$SERVER_FQDN"
echo "AZURE_POSTGRES_USER=$ADMIN_USERNAME"
echo "AZURE_POSTGRES_PASSWORD=$ADMIN_PASSWORD"
echo "AZURE_POSTGRES_DB=$DATABASE_NAME"
echo "AZURE_POSTGRES_PORT=5432"
echo ""
print_warning "⚠️  Important Notes:"
echo "1. Save your password securely - it cannot be retrieved later"
echo "2. The server allows connections from all IPs (0.0.0.0-255.255.255.255)"
echo "3. For production, restrict firewall rules to specific IPs"
echo "4. SSL is required for all connections"
echo ""
print_status "💰 Cost Information:"
echo "Current configuration costs approximately \$15-25/month"
echo "You can scale up/down or delete resources as needed"
echo ""
print_status "🗑️  To delete everything later:"
echo "az group delete --name $RESOURCE_GROUP_NAME --yes --no-wait"
echo ""

# Update .env file if it exists
if [ -f ".env" ]; then
    print_status "Updating .env file with new database configuration..."
    cp .env .env.backup
    sed -i "s|DATABASE_URL=.*|DATABASE_URL=$CONNECTION_STRING|g" .env
    sed -i "s|AZURE_POSTGRES_HOST=.*|AZURE_POSTGRES_HOST=$SERVER_FQDN|g" .env
    sed -i "s|AZURE_POSTGRES_USER=.*|AZURE_POSTGRES_USER=$ADMIN_USERNAME|g" .env
    sed -i "s|AZURE_POSTGRES_PASSWORD=.*|AZURE_POSTGRES_PASSWORD=$ADMIN_PASSWORD|g" .env
    sed -i "s|AZURE_POSTGRES_DB=.*|AZURE_POSTGRES_DB=$DATABASE_NAME|g" .env
    print_success ".env file updated! Backup saved as .env.backup"
fi

print_success "🎉 Setup complete! You can now run your Django application with Azure PostgreSQL."
