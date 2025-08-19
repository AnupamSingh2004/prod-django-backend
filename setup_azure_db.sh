#!/bin/bash

# Azure PostgreSQL Database Setup Script

echo "🚀 Setting up Azure PostgreSQL Database for Django"

# Check if required environment variables are set
if [ -z "$AZURE_POSTGRES_HOST" ] || [ -z "$AZURE_POSTGRES_USER" ] || [ -z "$AZURE_POSTGRES_PASSWORD" ] || [ -z "$AZURE_POSTGRES_DB" ]; then
    echo "❌ Error: Please set the following environment variables:"
    echo "   AZURE_POSTGRES_HOST"
    echo "   AZURE_POSTGRES_USER" 
    echo "   AZURE_POSTGRES_PASSWORD"
    echo "   AZURE_POSTGRES_DB"
    echo ""
    echo "📝 Example:"
    echo "   export AZURE_POSTGRES_HOST=your-server.postgres.database.azure.com"
    echo "   export AZURE_POSTGRES_USER=your-username"
    echo "   export AZURE_POSTGRES_PASSWORD=your-password"
    echo "   export AZURE_POSTGRES_DB=your-database"
    exit 1
fi

# Update the DATABASE_URL in .env file
echo "📝 Updating .env file with Azure PostgreSQL configuration..."
DATABASE_URL="postgresql://${AZURE_POSTGRES_USER}:${AZURE_POSTGRES_PASSWORD}@${AZURE_POSTGRES_HOST}:5432/${AZURE_POSTGRES_DB}?sslmode=require"

# Update .env file
sed -i "s|DATABASE_URL=.*|DATABASE_URL=${DATABASE_URL}|g" .env

echo "✅ .env file updated with Azure PostgreSQL connection string"

# Run Django migrations
echo "🔄 Running Django migrations..."
python manage.py makemigrations
python manage.py migrate

echo "🎉 Azure PostgreSQL setup complete!"
echo ""
echo "🔗 Connection details:"
echo "   Host: $AZURE_POSTGRES_HOST"
echo "   Database: $AZURE_POSTGRES_DB"
echo "   User: $AZURE_POSTGRES_USER"
echo ""
echo "🚀 You can now run: python manage.py runserver"
