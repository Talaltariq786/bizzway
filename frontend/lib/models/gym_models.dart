/// Pakistan gym management — admissions, payments, in-gym store.
library;

enum GymAdmissionStatus {
  pendingPayment,
  active,
  expired,
}

enum GymPaymentMethod {
  pending,
  cash,
}

class GymMemberAdmission {
  final String id;
  final String businessId;
  final String businessName;
  final String packageId;
  final String packageName;
  final String memberName;
  final String phone;
  final DateTime requestedAt;
  final double feePkr;
  final String? trainerPreference;
  DateTime? membershipStart;
  DateTime? membershipEnd;
  int attendanceCount;
  GymAdmissionStatus status;
  final String ticketCode;
  GymPaymentMethod paymentMethod;

  GymMemberAdmission({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.packageId,
    required this.packageName,
    required this.memberName,
    required this.phone,
    required this.requestedAt,
    required this.feePkr,
    this.trainerPreference,
    this.membershipStart,
    this.membershipEnd,
    this.attendanceCount = 0,
    this.status = GymAdmissionStatus.pendingPayment,
    required this.ticketCode,
    this.paymentMethod = GymPaymentMethod.pending,
  });

  bool get isPending => status == GymAdmissionStatus.pendingPayment;
  bool get isActive => status == GymAdmissionStatus.active;
}

class GymSupplementProduct {
  final String id;
  final String categoryId;
  final String name;
  final String brand;
  final double pricePkr;
  int stockQuantity;

  GymSupplementProduct({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.brand,
    required this.pricePkr,
    required this.stockQuantity,
  });
}
