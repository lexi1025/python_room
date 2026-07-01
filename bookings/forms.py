from django import forms
from django.utils import timezone
from .models import Booking


class BookingForm(forms.ModelForm):
    """预约表单"""
    class Meta:
        model = Booking
        fields = ['seat', 'booking_date', 'time_slot', 'note']
        widgets = {
            'seat': forms.Select(attrs={
                'class': 'form-control',
            }),
            'booking_date': forms.DateInput(attrs={
                'class': 'form-control',
                'type': 'date',
                'min': timezone.now().date().isoformat()
            }),
            'time_slot': forms.Select(attrs={
                'class': 'form-control',
            }),
            'note': forms.Textarea(attrs={
                'class': 'form-control',
                'rows': 3,
                'placeholder': '备注信息（可选）'
            }),
        }

    def __init__(self, *args, **kwargs):
        room = kwargs.pop('room', None)
        prefilled = kwargs.pop('prefilled', False)
        filter_date = kwargs.pop('filter_date', None)
        filter_time_slot = kwargs.pop('filter_time_slot', None)
        super().__init__(*args, **kwargs)

        if room:
            # 如果有预填的日期和时段，只显示该时段未被占用的座位
            if filter_date and filter_time_slot:
                booked_seat_ids = Booking.objects.filter(
                    seat__room=room,
                    booking_date=filter_date,
                    time_slot=filter_time_slot,
                    status='approved'
                ).values_list('seat_id', flat=True)
                self.fields['seat'].queryset = room.seat_set.filter(
                    status='available'
                ).exclude(id__in=booked_seat_ids)
            else:
                # 否则只显示物理状态可用的座位
                self.fields['seat'].queryset = room.seat_set.filter(status='available')

        # 如果是从首页预填的，将日期和时段设为隐藏域
        if prefilled:
            self.fields['booking_date'].widget = forms.HiddenInput()
            self.fields['time_slot'].widget = forms.HiddenInput()
