import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/business.dart';
import '../../providers/appointment_provider.dart';
import '../../viewmodels/book_slot_view_model.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_header.dart';

class BookSlotScreen extends StatelessWidget {
  final Business business;
  final BusinessItem item;

  const BookSlotScreen({super.key, required this.business, required this.item});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookSlotViewModel(business: business, item: item),
      child: Consumer<BookSlotViewModel>(
        builder: (context, vm, _) {
          // Responsive sizing so the UI stays consistent on smaller devices.
          final deviceWidth = MediaQuery.sizeOf(context).width;
          final scale = (deviceWidth / 390).clamp(0.9, 1.2);
          final sidePad = (16 * scale).clamp(12.0, 20.0);
          final contentTopPad = sidePad;
          final contentBottomPad =
              (110 * scale + MediaQuery.of(context).padding.bottom).clamp(85.0, 160.0);
          final dialogIconSize = (72 * scale).clamp(56.0, 84.0);
          final dialogIconInnerSize = (40 * scale).clamp(32.0, 48.0);
          final dialogGap16 = (16 * scale).clamp(10.0, 22.0);
          final headerIconSize = (54 * scale).clamp(44.0, 64.0);
          final dateStripHeight = (80 * scale).clamp(68.0, 96.0);
          final dateCardWidth = (62 * scale).clamp(52.0, 70.0);
          final cardRadius20 = (20 * scale).clamp(14.0, 24.0);
          final chipPadding = (12 * scale).clamp(10.0, 16.0);
          final chipRadius12 = (12 * scale).clamp(10.0, 16.0);
          final bottomBarSidePad = sidePad;
          final bottomBarTopPad = (12 * scale).clamp(8.0, 16.0);
          final bottomBarBottomPad =
              (28 * scale + MediaQuery.of(context).padding.bottom).clamp(18.0, 40.0);
          final bottomBtnVerticalPad = (16 * scale).clamp(12.0, 20.0);

          final color = business.color;
          final t = Theme.of(context).textTheme;

          Future<void> confirm() async {
            final err = vm.validate();
            if (err != null) {
              ScaffoldMessenger.of(context).showSnackBar(vm.validationSnackBar(err));
              return;
            }

            final booking = vm.buildBooking();
            await context.read<AppointmentProvider>().createBooking(booking);
            if (!context.mounted) return;

            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(cardRadius20),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: dialogIconSize,
                      height: dialogIconSize,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: color,
                        size: dialogIconInnerSize,
                      ),
                    ),
                    SizedBox(height: dialogGap16),
                    Text(
                      '${booking.actionLabel} Confirmed!',
                      style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.name,
                      textAlign: TextAlign.center,
                      style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      business.name,
                      style: t.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vm.selectedTime}  ·  ${vm.formatDate(vm.selectedDate)}',
                      style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: (14 * scale).clamp(10.0, 18.0),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              title: Text(business.bookingTitle),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                sidePad,
                contentTopPad,
                sidePad,
                contentBottomPad,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary (premium header card)
                  Container(
                    padding: EdgeInsets.all(sidePad),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.78)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(cardRadius20),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.18),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: headerIconSize,
                          height: headerIconSize,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(
                              (14 * scale).clamp(10.0, 18.0),
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            business.typeIcon,
                            color: Colors.white,
                            size: (26 * scale).clamp(22.0, 30.0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: t.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                business.name,
                                style: t.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rs. ${vm.computedPrice.toStringAsFixed(0)}',
                              style: t.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (vm.computedDurationMinutes != null)
                              Text(
                                '${vm.computedDurationMinutes} min',
                                style: t.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            if (item.unit != null)
                              Text(
                                item.unit!,
                                style: t.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SectionHeader(
                    title: 'Select Date',
                    subtitle: 'Pick a day from the next 7 days',
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: dateStripHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: vm.nextSevenDays.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(width: (10 * scale).clamp(8.0, 12.0)),
                      itemBuilder: (_, i) {
                        final date = vm.nextSevenDays[i];
                        final sel = date.day == vm.selectedDate.day &&
                            date.month == vm.selectedDate.month &&
                            date.year == vm.selectedDate.year;

                        return InkWell(
                          borderRadius: BorderRadius.circular(
                            (16 * scale).clamp(12.0, 18.0),
                          ),
                          onTap: () => vm.selectDate(date),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: dateCardWidth,
                            decoration: BoxDecoration(
                              color: sel ? color : AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                (16 * scale).clamp(12.0, 18.0),
                              ),
                              border: Border.all(color: sel ? color : AppColors.border),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.28),
                                        blurRadius: 14,
                                        offset: const Offset(0, 8),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  vm.dayName(date),
                                  style: t.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: sel
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${date.day}',
                                  style: t.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: sel ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                                if (i == 0) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    width: (6 * scale).clamp(4.0, 7.0),
                                    height: (6 * scale).clamp(4.0, 7.0),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: sel ? Colors.white : color,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (vm.isWithDriver) ...[
                    SectionHeader(
                      title: 'Duration',
                      subtitle: 'How many hours do you need?',
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      padding: EdgeInsets.all(chipPadding),
                      child: Wrap(
                        spacing: (10 * scale).clamp(8.0, 12.0),
                        runSpacing: (10 * scale).clamp(8.0, 12.0),
                        children: vm.hourOptions.map((h) {
                          final sel = h == vm.selectedHours;
                          return InkWell(
                            borderRadius: BorderRadius.circular(chipRadius12),
                            onTap: () => vm.selectHours(h),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: sel ? color : AppColors.surface,
                                borderRadius: BorderRadius.circular(chipRadius12),
                                border: Border.all(color: sel ? color : AppColors.border),
                              ),
                              child: Text(
                                '$h hr',
                                style: t.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: sel ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  SectionHeader(
                    title: 'Select Time',
                    subtitle: 'Available slots for your selected date',
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: EdgeInsets.all(chipPadding),
                    child: Wrap(
                      spacing: (10 * scale).clamp(8.0, 12.0),
                      runSpacing: (10 * scale).clamp(8.0, 12.0),
                      children: vm.timeSlots.map((slot) {
                        final booked = vm.bookedSlots.contains(slot);
                        final sel = slot == vm.selectedTime;

                        return InkWell(
                          borderRadius: BorderRadius.circular(chipRadius12),
                          onTap: booked ? null : () => vm.selectTime(slot),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: booked
                                  ? AppColors.backgroundLight
                                  : sel
                                      ? color
                                      : AppColors.surface,
                              borderRadius: BorderRadius.circular(chipRadius12),
                              border: Border.all(
                                color: booked
                                    ? AppColors.border
                                    : sel
                                        ? color
                                        : AppColors.border,
                              ),
                            ),
                            child: Text(
                              slot,
                              style: t.bodyMedium?.copyWith(
                                fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                                color: booked
                                    ? AppColors.textHint
                                    : sel
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                decoration:
                                    booked ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _legend(AppColors.surface, 'Available'),
                      const SizedBox(width: 14),
                      _legend(color, 'Selected'),
                      const SizedBox(width: 14),
                      _legend(AppColors.backgroundLight, 'Booked'),
                    ],
                  ),
                  const SizedBox(height: 18),

                  SectionHeader(
                    title: 'Notes',
                    subtitle: 'Optional instructions for the business',
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: EdgeInsets.all(chipPadding),
                    child: TextField(
                      controller: vm.notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Any special requests...',
                        filled: false,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: color, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              padding: EdgeInsets.fromLTRB(
                bottomBarSidePad,
                bottomBarTopPad,
                bottomBarSidePad,
                bottomBarBottomPad,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (vm.selectedTime != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: (10 * scale).clamp(6.0, 14.0)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${vm.formatDate(vm.selectedDate)}  ·  ${vm.selectedTime}',
                            style: t.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Rs. ${vm.computedPrice.toStringAsFixed(0)}',
                            style: t.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: confirm,
                    
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: bottomBtnVerticalPad),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Confirm ${business.actionLabel}',
                        style: TextStyle(
                          fontSize: (16 * scale).clamp(14.0, 18.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
                color: color,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      );
}
