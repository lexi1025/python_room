from django.shortcuts import render, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.utils import timezone
from datetime import datetime
from .models import StudyRoom, Seat
from bookings.models import Booking

# Create your views here.

def home(request):
    """首页 - 支持按日期和时段筛选可用自习室，以及实时座位状态"""
    rooms = StudyRoom.objects.filter(status='open').order_by('name')
    today = timezone.now().date()

    # === 实时座位状态数据（供"实时更新"面板使用） ===
    # 获取今日所有已通过预约
    today_bookings = Booking.objects.filter(
        seat__room__in=rooms,
        booking_date=today,
        status='approved'
    ).select_related('seat')

    # 读取当前用户今日预约的时段
    slot_name_map = {
        'morning': '上午 (08:00-12:00)',
        'afternoon': '下午 (13:00-17:00)',
        'evening': '晚上 (18:00-22:00)',
    }

    if request.user.is_authenticated:
        user_today_slots = Booking.objects.filter(
            user=request.user,
            booking_date=today,
            status='approved'
        ).values_list('time_slot', flat=True).distinct()
        active_slots = set(user_today_slots)
    else:
        active_slots = set()

    if active_slots:
        # 使用用户预约的时段
        display_slot_label = ' · '.join(
            slot_name_map[s] for s in sorted(active_slots)
        )
    else:
        # 用户未登录或无今日预约时，自动检测当前时段
        current_hour = timezone.now().hour
        if 8 <= current_hour < 12:
            active_slots = {'morning'}
            display_slot_label = '上午 (08:00-12:00)'
        elif 13 <= current_hour < 17:
            active_slots = {'afternoon'}
            display_slot_label = '下午 (13:00-17:00)'
        elif 18 <= current_hour < 22:
            active_slots = {'evening'}
            display_slot_label = '晚上 (18:00-22:00)'
        else:
            active_slots = set()
            display_slot_label = '当前不在预约时段内'

    # 构建每间自习室的实时座位数据
    for room in rooms:
        all_seats = list(room.seat_set.all().order_by('row', 'column'))
        occupied_ids = set()
        for booking in today_bookings:
            if booking.seat.room_id == room.id:
                # 只统计用户预约时段内的占用情况
                if booking.time_slot in active_slots:
                    occupied_ids.add(booking.seat_id)

        unavailable_count = sum(1 for s in all_seats if s.status == 'unavailable')
        room.computed_available = max(room.total_seats - unavailable_count - len(occupied_ids), 0)
        room.realtime_seats = all_seats
        room.realtime_occupied_ids = occupied_ids

    # === 筛选参数处理（供"在线预约"面板使用） ===
    filter_date_str = request.GET.get('date', '')
    filter_time_slot = request.GET.get('time_slot', '')

    filter_date = None
    if filter_date_str:
        try:
            filter_date = datetime.strptime(filter_date_str, '%Y-%m-%d').date()
        except ValueError:
            filter_date_str = ''

    if filter_date and filter_time_slot:
        # 用户选择了日期和时段 → 只显示该时段有空位的自习室
        filtered_rooms = []
        for room in rooms:
            unavailable_count = room.seat_set.filter(status='unavailable').count()
            booked_count = Booking.objects.filter(
                seat__room=room,
                booking_date=filter_date,
                time_slot=filter_time_slot,
                status='approved'
            ).values('seat').distinct().count()
            computed_available = room.total_seats - unavailable_count - booked_count
            computed_available = max(computed_available, 0)

            if computed_available > 0:
                room.computed_available = computed_available
                filtered_rooms.append(room)

        context = {
            'rooms': filtered_rooms,
            'filter_date': filter_date_str,
            'filter_time_slot': filter_time_slot,
            'is_filtered': True,
            'display_slot_label': display_slot_label,
        }
    else:
        context = {
            'rooms': rooms,
            'filter_date': today.isoformat(),
            'filter_time_slot': '',
            'is_filtered': False,
            'display_slot_label': display_slot_label,
        }

    return render(request, 'home.html', context)


def room_list(request):
    """自习室列表"""
    rooms = StudyRoom.objects.all().order_by('name')
    today = timezone.now().date()

    # 动态计算每个自习室的可用座位数（基于今日实际预约数据）
    for room in rooms:
        unavailable_count = room.seat_set.filter(status='unavailable').count()
        booked_today_count = Booking.objects.filter(
            seat__room=room,
            booking_date=today,
            status='approved'
        ).values('seat').distinct().count()
        computed_available = room.total_seats - unavailable_count - booked_today_count
        room.computed_available = max(computed_available, 0)

    return render(request, 'rooms/room_list.html', {'rooms': rooms})


def room_detail(request, room_id):
    """自习室详情页"""
    room = get_object_or_404(StudyRoom, id=room_id)
    seats = room.seat_set.all().order_by('row', 'column')

    # 获取今天的预约情况
    today = timezone.now().date()
    today_bookings = Booking.objects.filter(
        seat__room=room,
        booking_date=today,
        status='approved'
    ).select_related('seat', 'user')

    # 构建座位预约状态字典和已占用座位ID集合
    seat_bookings = {}
    occupied_seat_ids = set()
    for booking in today_bookings:
        occupied_seat_ids.add(booking.seat_id)
        if booking.seat_id not in seat_bookings:
            seat_bookings[booking.seat_id] = []
        seat_bookings[booking.seat_id].append(booking)

    # 动态计算可用座位数（基于实际预约数据 + 座位物理状态）
    unavailable_count = room.seat_set.filter(status='unavailable').count()
    computed_available = room.total_seats - unavailable_count - len(occupied_seat_ids)
    computed_available = max(computed_available, 0)

    context = {
        'room': room,
        'seats': seats,
        'seat_bookings': seat_bookings,
        'occupied_seat_ids': occupied_seat_ids,
        'computed_available': computed_available,
    }
    return render(request, 'rooms/room_detail.html', context)


def seat_detail(request, seat_id):
    """座位详情页"""
    seat = get_object_or_404(Seat, id=seat_id)

    # 获取该座位未来7天的预约情况
    today = timezone.now().date()
    bookings = Booking.objects.filter(
        seat=seat,
        booking_date__gte=today,
        status='approved'
    ).order_by('booking_date', 'time_slot')[:20]

    context = {
        'seat': seat,
        'bookings': bookings,
    }
    return render(request, 'rooms/seat_detail.html', context)
