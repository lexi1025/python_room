from django.contrib import admin
from .models import Booking

# Register your models here.

@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ['user', 'seat', 'booking_date', 'time_slot', 'status', 'created_at']
    list_filter = ['status', 'time_slot', 'booking_date', 'created_at']
    search_fields = ['user__username', 'user__student_id', 'seat__seat_number', 'seat__room__name']
    ordering = ['-booking_date', '-created_at']
    readonly_fields = ['created_at', 'updated_at']
    date_hierarchy = 'booking_date'

    fieldsets = (
        ('预约信息', {
            'fields': ('user', 'seat', 'booking_date', 'time_slot')
        }),
        ('状态和备注', {
            'fields': ('status', 'note')
        }),
        ('时间戳', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
