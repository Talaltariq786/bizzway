import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/constants/gym_pakistan_schema.dart';
import '../models/gym_models.dart';

/// In-app gym admissions + supplement stock (demo; replace with API later).
class GymManagementProvider extends ChangeNotifier {
  final _rand = Random();

  final List<GymMemberAdmission> _admissions = [];
  late List<GymSupplementProduct> _supplements;

  GymManagementProvider() {
    _supplements = GymPakistanSchema.defaultSupplementProducts
        .asMap()
        .entries
        .map(
          (e) => GymSupplementProduct(
            id: 'sup_${e.key}',
            categoryId: e.value['categoryId']! as String,
            name: e.value['name']! as String,
            brand: e.value['brand']! as String,
            pricePkr: (e.value['pricePkr'] as num).toDouble(),
            stockQuantity: e.value['stock'] as int,
          ),
        )
        .toList();
  }

  List<GymMemberAdmission> get allAdmissions => List.unmodifiable(_admissions);

  List<GymMemberAdmission> admissionsForBusiness(String businessId) =>
      _admissions.where((a) => a.businessId == businessId).toList();

  List<GymMemberAdmission> pendingForBusiness(String businessId) =>
      _admissions
          .where((a) =>
              a.businessId == businessId && a.status == GymAdmissionStatus.pendingPayment)
          .toList();

  List<GymMemberAdmission> activeForBusiness(String businessId) =>
      _admissions
          .where((a) =>
              a.businessId == businessId && a.status == GymAdmissionStatus.active)
          .toList();

  List<GymSupplementProduct> supplementsForBusiness(String businessId) {
    // Demo: same stock for every gym id; later scope by businessId.
    return List.unmodifiable(_supplements);
  }

  /// Customer: online admission — generates ticket; payment pending until gym accepts cash.
  GymMemberAdmission requestAdmission({
    required String businessId,
    required String businessName,
    required String packageId,
    required String memberName,
    required String phone,
    String? trainerPreference,
  }) {
    final pkg = GymPakistanSchema.defaultPackages
        .firstWhere((p) => p['id'] == packageId, orElse: () => {});
    if (pkg.isEmpty) throw StateError('Unknown package');
    final name = pkg['name']! as String;
    final fee = (pkg['feePkr'] as num).toDouble();
    final ticket = _nextTicketCode(businessId);
    final adm = GymMemberAdmission(
      id: 'adm_${DateTime.now().millisecondsSinceEpoch}_${_rand.nextInt(9999)}',
      businessId: businessId,
      businessName: businessName,
      packageId: packageId,
      packageName: name,
      memberName: memberName.trim(),
      phone: phone.trim(),
      requestedAt: DateTime.now(),
      feePkr: fee,
      trainerPreference: trainerPreference?.trim().isEmpty == true
          ? null
          : trainerPreference?.trim(),
      ticketCode: ticket,
    );
    _admissions.insert(0, adm);
    notifyListeners();
    return adm;
  }

  /// Owner: mark cash received & start membership window.
  void acceptCashPayment(String admissionId) {
    final i = _admissions.indexWhere((a) => a.id == admissionId);
    if (i == -1) return;
    final a = _admissions[i];
    if (a.status != GymAdmissionStatus.pendingPayment) return;

    final pkg = GymPakistanSchema.defaultPackages
        .firstWhere((p) => p['id'] == a.packageId, orElse: () => {});
    final days = (pkg['durationDays'] as num?)?.toInt() ?? 30;
    final sessionCount = (pkg['sessionCount'] as num?)?.toInt();
    final start = DateTime.now();
    DateTime? end;
    if (days > 0) {
      end = start.add(Duration(days: days));
    } else if (sessionCount != null && sessionCount > 0) {
      // Session packs: validity window to finish sessions (demo rule).
      end = start.add(const Duration(days: 180));
    } else {
      end = start.add(const Duration(days: 1));
    }

    a.paymentMethod = GymPaymentMethod.cash;
    a.status = GymAdmissionStatus.active;
    a.membershipStart = start;
    a.membershipEnd = end;
    notifyListeners();
  }

  void markAttendance(String admissionId) {
    final i = _admissions.indexWhere((a) => a.id == admissionId);
    if (i == -1) return;
    if (_admissions[i].status != GymAdmissionStatus.active) return;
    _admissions[i].attendanceCount += 1;
    notifyListeners();
  }

  String _nextTicketCode(String businessId) {
    final suffix = _rand.nextInt(999999).toString().padLeft(6, '0');
    return 'BW-${businessId.toUpperCase()}-$suffix';
  }
}
