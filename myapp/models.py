from django.db import models
from django.utils import timezone

# Create your models here.

class HealthStatus(models.Model):
    """Model to track application health checks."""
    timestamp = models.DateTimeField(default=timezone.now)
    status = models.CharField(max_length=20, default='healthy')
    message = models.TextField(blank=True)
    
    class Meta:
        ordering = ['-timestamp']
        verbose_name = 'Health Status'
        verbose_name_plural = 'Health Statuses'
    
    def __str__(self):
        return f"Health Check - {self.status} at {self.timestamp}"

class ApiLog(models.Model):
    """Model to log API requests."""
    endpoint = models.CharField(max_length=200)
    method = models.CharField(max_length=10)
    timestamp = models.DateTimeField(default=timezone.now)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    
    class Meta:
        ordering = ['-timestamp']
    
    def __str__(self):
        return f"{self.method} {self.endpoint} - {self.timestamp}"
