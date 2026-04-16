import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/business.dart';
import '../../models/business_type.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/common/themed_dialog_wrapper.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static bool _isRentacar(CustomerBooking b) => b.businessTypeId == 'rentacar';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppointmentProvider>();
    final rentacarBookings = prov.bookings.where(_isRentacar).toList();
    final rentacarPending =
        rentacarBookings.where((b) => b.status == 'pending').toList();
    final rentacarConfirmed =
        rentacarBookings.where((b) => b.status == 'confirmed').toList();
    final rentacarDone =
        rentacarBookings.where((b) => b.status == 'completed').toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.gradientPrimary,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'My Bookings',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rent a Car bookings & requests',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  gradient: LinearGradient(
                    colors: AppColors.gradientPrimary,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(4, (index) {
                      final isSelected = _tabCtrl.index == index;
                      final counts = [
                        rentacarBookings.length,
                        rentacarPending.length,
                        rentacarConfirmed.length,
                        rentacarDone.length,
                      ];
                      final labels = ['All', 'Pending', 'Confirmed', 'Done'];

                      return GestureDetector(
                        onTap: () => _tabCtrl.animateTo(index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                labels[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                              if (counts[index] > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE91E3F),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${counts[index]}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: Container(
              margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _BookingList(bookings: rentacarBookings),
                  _BookingList(bookings: rentacarPending),
                  _BookingList(bookings: rentacarConfirmed),
                  _BookingList(bookings: rentacarDone),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Booking list ──────────────────────────────────────────────────────────────

class _BookingList extends StatelessWidget {
  final List<CustomerBooking> bookings;
  const _BookingList({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_rounded,
              size: 56,
              color: AppColors.textHint,
            ),
            SizedBox(height: 12),
            Text(
              'No rent-a-car bookings yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
    );
  }
}

// ── Booking card ──────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final CustomerBooking booking;
  const _BookingCard({required this.booking});

  // Status config: (label, color, icon, description)
  (String, Color, IconData, String) get _statusConfig {
    switch (booking.status) {
      case 'pending':
        return (
          'Pending',
          Colors.orange,
          Icons.hourglass_top_rounded,
          'Vendor ne abhi accept nahi kiya',
        );
      case 'confirmed':
        return (
          'Confirmed',
          AppColors.info,
          Icons.check_circle_rounded,
          'Vendor ne accept kar liya ✓',
        );
      case 'completed':
        return (
          'Completed',
          AppColors.success,
          Icons.task_alt_rounded,
          'Appointment mukammal ho gayi',
        );
      case 'cancelled':
        return (
          'Cancelled',
          AppColors.error,
          Icons.cancel_rounded,
          'Yeh booking cancel ho gayi',
        );
      default:
        return ('Unknown', Colors.grey, Icons.help_outline, '');
    }
  }

  Color get _bizColor {
    for (final t in BusinessType.all) {
      if (t.id == booking.businessTypeId) return t.color;
    }
    return AppColors.primary;
  }

  IconData get _bizIcon {
    for (final t in BusinessType.all) {
      if (t.id == booking.businessTypeId) return t.icon;
    }
    return Icons.store_rounded;
  }

  String _fmtDate(DateTime dt) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min $period';
  }

  bool get _canReschedule =>
      (booking.status == 'pending' || booking.status == 'confirmed') &&
      booking.dateTime.isAfter(DateTime.now());

  bool get _canCancel =>
      (booking.status == 'pending' || booking.status == 'confirmed') &&
      booking.dateTime.isAfter(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor, statusIcon, statusDesc) = _statusConfig;
    final bizColor = _bizColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top color strip: business info ────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bizColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: bizColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_bizIcon, color: bizColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.businessName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        booking.itemName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Status description bar ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: statusColor.withValues(alpha: 0.06),
            child: Row(
              children: [
                Icon(
                  booking.status == 'pending'
                      ? Icons.info_outline_rounded
                      : booking.status == 'confirmed'
                      ? Icons.verified_rounded
                      : booking.status == 'completed'
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  statusDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Details: date, time, duration, price ───────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Column(
              children: [
                Row(
                  children: [
                    _chip(
                      Icons.calendar_today_outlined,
                      _fmtDate(booking.dateTime),
                      AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    _chip(
                      Icons.access_time_rounded,
                      _fmtTime(booking.dateTime),
                      AppColors.textSecondary,
                    ),
                    if (booking.durationMinutes != null) ...[
                      const SizedBox(width: 10),
                      _chip(
                        Icons.timer_outlined,
                        '${booking.durationMinutes} min',
                        AppColors.textSecondary,
                      ),
                    ],
                    const Spacer(),
                    Text(
                      'Rs. ${booking.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: bizColor,
                      ),
                    ),
                  ],
                ),
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.notes_rounded,
                        size: 13,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          booking.notes!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Action buttons ─────────────────────────────────────────────
          if (_canReschedule || _canCancel) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                children: [
                  if (_canReschedule)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showRescheduleSheet(context, bizColor),
                        icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                        label: const Text('Reschedule'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: bizColor,
                          side: BorderSide(color: bizColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  if (_canReschedule && _canCancel) const SizedBox(width: 10),
                  if (_canCancel)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmCancel(context),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color)),
    ],
  );

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => wrapDialogWithTheme(
        context,
        accentColor: _bizColor,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Cancel Booking?'),
          content: Text(
            '${booking.itemName} ki booking cancel karna chahte hain?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nahi'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AppointmentProvider>().cancelBooking(booking.id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Haan, Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRescheduleSheet(BuildContext context, Color bizColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RescheduleSheet(booking: booking, bizColor: bizColor),
    );
  }
}

// ── Reschedule bottom sheet ───────────────────────────────────────────────────

class _RescheduleSheet extends StatefulWidget {
  final CustomerBooking booking;
  final Color bizColor;
  const _RescheduleSheet({required this.booking, required this.bizColor});

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  late DateTime _selectedDate;
  String? _selectedTime;

  final List<String> _timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:30 PM',
    '01:00 PM',
    '01:30 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
    '05:30 PM',
    '06:00 PM',
  ];

  // Simulate some already-booked slots
  final List<String> _bookedSlots = ['10:00 AM', '02:00 PM', '04:30 PM'];

  List<DateTime> get _next7Days =>
      List.generate(7, (i) => DateTime.now().add(Duration(days: i + 1)));

  String _dayName(DateTime d) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[d.weekday % 7];
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _next7Days.first;
  }

  void _confirm() {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pehle time slot select karen'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final parts = _selectedTime!.split(' ');
    final hm = parts[0].split(':');
    int h = int.parse(hm[0]);
    final min = int.parse(hm[1]);
    if (parts[1] == 'PM' && h != 12) h += 12;
    if (parts[1] == 'AM' && h == 12) h = 0;

    final newDt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      h,
      min,
    );

    context.read<AppointmentProvider>().rescheduleBooking(
      widget.booking.id,
      newDt,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Booking reschedule ho gayi — vendor ko notify kar diya',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: widget.bizColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.bizColor;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Icon(Icons.edit_calendar_rounded, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reschedule: ${widget.booking.itemName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Nai date aur time select karen',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Date picker
            const Text(
              'Date chunein',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _next7Days.map((date) {
                  final sel =
                      date.day == _selectedDate.day &&
                      date.month == _selectedDate.month;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 54,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: sel ? color : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel ? color : AppColors.border,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _dayName(date),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: sel ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            months[date.month - 1],
                            style: TextStyle(
                              fontSize: 10,
                              color: sel
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Time slots
            const Text(
              'Time chunein',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Available',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundLight,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Booked',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _timeSlots.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.3,
              ),
              itemBuilder: (_, i) {
                final slot = _timeSlots[i];
                final booked = _bookedSlots.contains(slot);
                final sel = _selectedTime == slot;
                return GestureDetector(
                  onTap: booked
                      ? null
                      : () => setState(() => _selectedTime = slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: booked
                          ? AppColors.backgroundLight
                          : sel
                          ? color
                          : color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: booked
                            ? AppColors.border
                            : sel
                            ? color
                            : color.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: booked
                            ? AppColors.textHint
                            : sel
                            ? Colors.white
                            : color,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  _selectedTime == null
                      ? 'Time select karen'
                      : 'Confirm — ${_selectedDate.day} ${months[_selectedDate.month - 1]}, $_selectedTime',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
