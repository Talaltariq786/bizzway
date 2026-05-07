import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/business.dart';

class BookSlotViewModel extends ChangeNotifier {
  final Business business;
  final BusinessItem item;

  BookSlotViewModel({
    required this.business,
    required this.item,
    DateTime? initialDate,
  }) : selectedDate = (initialDate ?? DateTime.now()) {
    // Default hours for with-driver flows to 1.
    selectedHours = 1;
  }

  DateTime selectedDate;
  String? selectedTime;
  int selectedHours = 1;
  final TextEditingController notesController = TextEditingController();

  bool get isRentacar => business.businessTypeId == 'rentacar';

  bool get isWithDriver =>
      isRentacar &&
      (item.unit?.toLowerCase().contains('hour') == true ||
          item.category.toLowerCase().contains('with driver'));

  double get computedPrice => isWithDriver ? item.price * selectedHours : item.price;

  int? get computedDurationMinutes =>
      isWithDriver ? selectedHours * 60 : item.durationMinutes;

  List<int> get hourOptions => const [1, 2, 3, 4, 5, 6, 7, 8];

  final List<String> timeSlots = const [
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

  /// Busy slots (UI only). When backend exposes per-day availability, load here.
  final List<String> bookedSlots = const [];

  List<DateTime> get nextSevenDays =>
      List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

  void selectDate(DateTime date) {
    selectedDate = date;
    selectedTime = null;
    notifyListeners();
  }

  void selectTime(String time) {
    selectedTime = time;
    notifyListeners();
  }

  void selectHours(int hours) {
    selectedHours = hours;
    notifyListeners();
  }

  String formatDate(DateTime d) {
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
      'Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  String dayName(DateTime d) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[d.weekday % 7];
  }

  DateTime? selectedDateTimeOrNull() {
    if (selectedTime == null) return null;
    final parts = selectedTime!.split(' ');
    final hm = parts[0].split(':');
    var h = int.parse(hm[0]);
    final min = int.parse(hm[1]);
    if (parts[1] == 'PM' && h != 12) h += 12;
    if (parts[1] == 'AM' && h == 12) h = 0;
    return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, h, min);
  }

  String? validate() {
    if (selectedTime == null) return 'Please select a time slot';
    return null;
  }

  CustomerBooking buildBooking() {
    final dt = selectedDateTimeOrNull();
    if (dt == null) {
      throw StateError('Cannot build booking without a selected time.');
    }

    return CustomerBooking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      businessId: business.id,
      businessName: business.name,
      businessTypeId: business.businessTypeId,
      itemId: item.id,
      itemName: item.name,
      price: computedPrice,
      durationMinutes: computedDurationMinutes,
      dateTime: dt,
      notes: notesController.text.isEmpty ? null : notesController.text,
    );
  }

  SnackBar validationSnackBar(String message) => SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
      );

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
}

