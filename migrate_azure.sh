#!/bin/bash

# Azure PostgreSQL Migration Script with Timeout Handling

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

print_status "🗄️ Running Azure PostgreSQL migrations with optimized timeouts..."

# Function to run command with timeout
run_with_timeout() {
    local timeout=$1
    shift
    local cmd="$@"
    
    print_status "Running: $cmd (timeout: ${timeout}s)"
    
    if timeout $timeout bash -c "$cmd"; then
        print_success "✅ Command completed successfully"
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            print_error "❌ Command timed out after ${timeout} seconds"
        else
            print_error "❌ Command failed with exit code $exit_code"
        fi
        return $exit_code
    fi
}

# Test database connection first
print_status "Testing database connection..."
if ! python -c "
import os, django
from django.conf import settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')
django.setup()
from django.db import connection
with connection.cursor() as cursor:
    cursor.execute('SELECT 1')
print('✅ Database connection working')
"; then
    print_error "❌ Database connection failed"
    exit 1
fi

print_success "Database connection verified"

# Check migration status
print_status "Checking migration status..."
python manage.py showmigrations
/health/
# Run migrations with smaller batches
print_status "Running migrations in optimized batches..."

# First, try fake-initial if this is a fresh database
print_status "Attempting to fake initial migrations..."
run_with_timeout 60 "python manage.py migrate --fake-initial" || true

# Run contenttypes first (it's usually the one that hangs)
print_status "Running contenttypes migrations..."
run_with_timeout 120 "python manage.py migrate contenttypes"

# Run auth migrations
print_status "Running auth migrations..."
run_with_timeout 120 "python manage.py migrate auth"

# Run sessions migrations
print_status "Running sessions migrations..."
run_with_timeout 60 "python manage.py migrate sessions"

# Run admin migrations
print_status "Running admin migrations..."
run_with_timeout 60 "python manage.py migrate admin"

# Run custom app migrations
print_status "Running myapp migrations..."
run_with_timeout 60 "python manage.py migrate myapp"

# Final check
print_status "Final migration status check..."
python manage.py showmigrations

print_success "🎉 All migrations completed successfully!"

# Create superuser prompt
echo ""
print_status "Would you like to create a superuser? (y/n)"
read -p "Enter choice: " create_superuser

if [[ $create_superuser =~ ^[Yy]$ ]]; then
    print_status "Creating superuser..."
    python manage.py createsuperuser
fi

print_success "✅ Database setup complete!"
