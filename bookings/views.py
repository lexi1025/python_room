from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.utils import timezone
from django.db.models import Q
from datetime import timedelta, datetime
from .models import Booking
from .forms import BookingForm
from rooms.models import StudyRoom, Seat

# Create your views here.

@login_required
def create_booking(request, room_id):
    """创建预约"""
    room = get_object_or_404(StudyRoom, id=room_id)

    # 获取从首页筛选带入的日期和时段
    prefilled_date_str = request.GET.get('date', '')
    prefilled_time_slot = request.GET.get('time_slot', '')
    prefilled_date = None

    if prefilled_date_str:
        try:
            prefilled_date = datetime.strptime(prefilled_date_str, '%Y-%m-%d').date()
        except ValueError:
            prefilled_date_str = ''
            prefilled_time_slot = ''

    is_prefilled = bool(prefilled_date and prefilled_time_slot)

    # 检查用户是否被封禁
    if request.user.is_banned:
        messages.error(request, '您的账号已被封禁，无法进行预约。')
        return redirect('room_detail', room_id=room_id)

    # 检查今日预约次数限制（每日最多3次）
    today = timezone.now().date()
    today_bookings_count = Booking.objects.filter(
        user=request.user,
        booking_date=today,
        status='approved'
    ).count()

    if today_bookings_count >= 3:
        messages.error(request, '您今日的预约次数已达到上限（3次）。')
        return redirect('room_detail', room_id=room_id)

    if request.method == 'POST':
        # 从POST中提取日期和时段，用于校验失败时正确过滤座位
        post_date_str = request.POST.get('booking_date', '')
        post_time_slot = request.POST.get('time_slot', '')
        post_date = None
        if post_date_str:
            try:
                post_date = datetime.strptime(post_date_str, '%Y-%m-%d').date()
            except ValueError:
                pass

        form = BookingForm(request.POST, room=room, prefilled=is_prefilled,
                          filter_date=post_date or prefilled_date,
                          filter_time_slot=post_time_slot or prefilled_time_slot)
        if form.is_valid():
            booking = form.save(commit=False)
            booking.user = request.user

            # 检查是否已有相同座位、日期和时段的预约
            existing_booking = Booking.objects.filter(
                seat=booking.seat,
                booking_date=booking.booking_date,
                time_slot=booking.time_slot,
                status='approved'
            ).exists()

            if existing_booking:
                messages.error(request, '该座位在所选时段已被预约。')
            else:
                booking.save()

                # 更新座位状态：今天的预约 → 座位标记为已占用
                if booking.booking_date == today:
                    booking.seat.status = 'occupied'
                    booking.seat.save()

                # 同步更新自习室可用座位数（基于实际座位状态重算）
                room.update_available_seats()

                messages.success(request, '预约成功！')
                return redirect('my_bookings')
    else:
        initial = {}
        if prefilled_date:
            initial['booking_date'] = prefilled_date_str
            initial['time_slot'] = prefilled_time_slot
        else:
            # 未从首页带入时，默认填入今天日期
            initial['booking_date'] = today.isoformat()

        form = BookingForm(room=room, prefilled=is_prefilled, initial=initial,
                          filter_date=prefilled_date or today,
                          filter_time_slot=prefilled_time_slot or None)

    context = {
        'form': form,
        'room': room,
        'is_prefilled': is_prefilled,
        'prefilled_date': prefilled_date_str or today.isoformat(),
        'prefilled_time_slot': prefilled_time_slot,
    }
    return render(request, 'bookings/create_booking.html', context)


@login_required
def my_bookings(request):
    """我的预约记录"""
    # 获取用户所有预约
    bookings = Booking.objects.filter(user=request.user).select_related(
        'seat', 'seat__room'
    ).order_by('-booking_date', '-created_at')

    # 分类预约
    today = timezone.now().date()
    upcoming = bookings.filter(booking_date__gte=today, status='approved')
    past = bookings.filter(
        Q(booking_date__lt=today) |
        Q(status__in=['cancelled', 'expired'])
    )

    context = {
        'upcoming_bookings': upcoming,
        'past_bookings': past,
    }
    return render(request, 'bookings/my_bookings.html', context)


@login_required
def cancel_booking(request, booking_id):
    """取消预约"""
    booking = get_object_or_404(Booking, id=booking_id, user=request.user)

    if booking.status == 'approved':
        if booking.booking_date >= timezone.now().date():
            booking.status = 'cancelled'
            booking.save()

            # 如果该座位今天没有其他已通过的预约，恢复座位状态为可预约
            today = timezone.now().date()
            if booking.booking_date == today:
                has_other_bookings = Booking.objects.filter(
                    seat=booking.seat,
                    booking_date=today,
                    status='approved'
                ).exists()
                if not has_other_bookings:
                    booking.seat.status = 'available'
                    booking.seat.save()

            # 同步更新自习室可用座位数（基于实际座位状态重算）
            booking.seat.room.update_available_seats()

            messages.success(request, '预约已取消。')
        else:
            messages.error(request, '无法取消过去的预约。')
    else:
        messages.error(request, '该预约无法取消。')

    return redirect('my_bookings')
