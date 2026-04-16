import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/rentacar_booking_intent.dart';
import '../../models/business.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/common/loading_overlay.dart';

/// Rent-a-car owner: full booking detail (job-detail style) → Accept / Reject.
/// Customer ko "confirmed" status My Bookings mein dikhega jab owner Accept kare.
class RentacarBookingOwnerDetailScreen extends StatelessWidget {
  final CustomerBooking booking;

  const RentacarBookingOwnerDetailScreen({super.key, required this.booking});

  String _handoverReadable(String? mode) {
    switch (mode) {
      case kVehicleHandoverPickupYard:
        return 'Yard / branch pickup';
      case kVehicleHandoverHomeDelivery:
        return 'Ghar par delivery';
      default:
        return mode ?? '—';
    }
  }

  Future<void> _accept(BuildContext context) async {
    await showAppLoader(context, message: 'Booking accept ho rahi hai...');
    if (!context.mounted) return;
    try {
      context.read<AppointmentProvider>().acceptBooking(booking.id);
    } finally {
      if (context.mounted) hideAppLoader(context);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking accept — customer ko confirm dikhai de ga'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _reject(BuildContext context) async {
    await showAppLoader(context, message: 'Cancel ho raha hai...');
    if (!context.mounted) return;
    try {
      context.read<AppointmentProvider>().rejectBooking(booking.id);
    } finally {
      if (context.mounted) hideAppLoader(context);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking reject ho gayi'),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final code = b.bookingCode ?? b.id;
    final pending = b.status == 'pending';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Car booking detail'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            title: 'Booking code',
            child: SelectableText(
              code,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Status',
            child: Text(
              b.status.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: pending ? Colors.orange : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Vehicle / package',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${b.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (b.durationMinutes != null)
                  Text(
                    '${b.durationMinutes} min',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Customer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line('Naam', b.customerFullName ?? '—'),
                _line('CNIC', b.customerNic ?? '—'),
                _line('Driving licence', b.customerLicenseNo ?? '—'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Trip',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line('Type', b.rentacarTripType ?? '—'),
                _line('Pickup', b.pickupAddress ?? '—'),
                _line('Drop-off', b.dropoffAddress ?? '—'),
                _line('Handover', _handoverReadable(b.vehicleHandoverMode)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Schedule',
            child: Text(
              '${b.dateTime.toLocal()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (b.notes != null && b.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _section(
              title: 'Notes (full)',
              child: Text(
                b.notes!,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          if (pending) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _accept(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Accept booking'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

