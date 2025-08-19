from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.db import connection
from .models import HealthStatus, ApiLog
import logging

logger = logging.getLogger(__name__)

# Create your views here.

def home(request):
    """Simple home view that returns a welcome message."""
    try:
        # Log the API request
        ApiLog.objects.create(
            endpoint='/',
            method=request.method,
            ip_address=get_client_ip(request)
        )
        
        return JsonResponse({
            'message': 'Welcome to Django Backend with Azure PostgreSQL!',
            'status': 'success',
            'app': 'myapp',
            'database': 'Azure PostgreSQL' if 'azure' in str(connection.settings_dict.get('HOST', '')) else 'SQLite'
        })
    except Exception as e:
        logger.error(f"Error in home view: {str(e)}")
        return JsonResponse({
            'message': 'Welcome to Django Backend!',
            'status': 'success',
            'app': 'myapp',
            'note': 'Database logging unavailable'
        })

def health_check(request):
    """Health check endpoint for deployment monitoring."""
    try:
        # Test database connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            db_status = "connected"
        
        # Create health status record
        health_record = HealthStatus.objects.create(
            status='healthy',
            message='All systems operational'
        )
        
        # Log the API request
        ApiLog.objects.create(
            endpoint='/health/',
            method=request.method,
            ip_address=get_client_ip(request)
        )
        
        return JsonResponse({
            'status': 'healthy',
            'message': 'Application is running properly',
            'database': db_status,
            'timestamp': health_record.timestamp.isoformat()
        })
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return JsonResponse({
            'status': 'unhealthy',
            'message': f'Database connection failed: {str(e)}',
            'database': 'disconnected'
        }, status=500)

def get_client_ip(request):
    """Get client IP address from request."""
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip
