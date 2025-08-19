#!/bin/bash

# Azure PostgreSQL Connection Test Script

set -e

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

print_status "🧪 Testing Azure PostgreSQL Connection..."

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_error ".env file not found. Please create it with your Azure PostgreSQL configuration."
    exit 1
fi

# Load environment variables
source .env

# Extract database connection details from DATABASE_URL
if [[ $DATABASE_URL =~ postgresql://([^:]+):([^@]+)@([^:]+):([^/]+)/([^?]+) ]]; then
    DB_USER="${BASH_REMATCH[1]}"
    DB_PASSWORD="${BASH_REMATCH[2]}"
    DB_HOST="${BASH_REMATCH[3]}"
    DB_PORT="${BASH_REMATCH[4]}"
    DB_NAME="${BASH_REMATCH[5]}"
else
    print_error "Invalid DATABASE_URL format in .env file"
    exit 1
fi

print_status "Connection Details:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo ""

# Test 1: Check if psql is available
print_status "Checking if psql is available..."
if command -v psql &> /dev/null; then
    print_success "psql is available"
    
    # Test connection with psql
    print_status "Testing connection with psql..."
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" &> /dev/null; then
        print_success "✅ PostgreSQL connection successful!"
        
        # Get server version
        VERSION=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT version();" 2>/dev/null | head -1 | xargs)
        echo "  Server: $VERSION"
    else
        print_error "❌ PostgreSQL connection failed with psql"
    fi
else
    print_warning "psql not available, skipping direct database test"
fi

# Test 2: Test with Django
print_status "Testing Django database connection..."
if python manage.py shell -c "
from django.db import connection
try:
    with connection.cursor() as cursor:
        cursor.execute('SELECT 1')
        result = cursor.fetchone()
    print('✅ Django database connection successful!')
    print(f'   Result: {result[0]}')
except Exception as e:
    print(f'❌ Django database connection failed: {e}')
    exit(1)
" 2>/dev/null; then
    print_success "Django can connect to the database"
else
    print_error "Django cannot connect to the database"
    print_warning "Make sure you have activated your Python environment and installed dependencies"
fi

# Test 3: Run Django check
print_status "Running Django system check..."
if python manage.py check --database default &> /dev/null; then
    print_success "✅ Django system check passed"
else
    print_error "❌ Django system check failed"
    echo "Run 'python manage.py check' for details"
fi

print_status "🔗 Testing network connectivity..."
if command -v nc &> /dev/null; then
    if nc -z "$DB_HOST" "$DB_PORT" 2>/dev/null; then
        print_success "✅ Network connectivity to $DB_HOST:$DB_PORT is working"
    else
        print_error "❌ Cannot reach $DB_HOST:$DB_PORT"
        print_warning "Check your firewall rules and network connectivity"
    fi
else
    print_warning "netcat (nc) not available, skipping network test"
fi

print_status "🧪 Connection test completed!"
echo ""
print_warning "If tests failed, check:"
echo "1. Azure PostgreSQL server is running"
echo "2. Firewall rules allow your IP address"
echo "3. Connection string is correct in .env file"
echo "4. Username and password are correct"
echo "5. Database name exists"
