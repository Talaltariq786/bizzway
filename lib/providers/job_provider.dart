import 'package:flutter/material.dart';
import '../models/job_request.dart';

class JobProvider extends ChangeNotifier {
  final List<JobRequest> _requests = [
    // ── MECHANIC JOBS ─────────────────────────────────────────────────────────
    JobRequest(
      id: 'j1',
      userAddress: 'Block 6, PECHS, Karachi',
      issue: 'Car tyre puncture — need urgent help',
      serviceTypeId: 'mechanic',
      serviceTypeName: 'Puncture',
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    JobRequest(
      id: 'j1b',
      userAddress: 'DHA Phase 2, Karachi',
      issue: 'Oil change and filter replacement for Toyota Corolla',
      serviceTypeId: 'mechanic',
      serviceTypeName: 'Oil Change',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    JobRequest(
      id: 'j1c',
      userAddress: 'Gulshan-e-Iqbal, Karachi',
      issue: 'Car AC not cooling properly — needs gas refill',
      serviceTypeId: 'mechanic',
      serviceTypeName: 'AC Gas',
      createdAt: DateTime.now().subtract(const Duration(minutes: 22)),
    ),
    JobRequest(
      id: 'j1d',
      userAddress: 'Clifton, Karachi',
      issue: 'Bike brake pads worn out — needing replacement',
      serviceTypeId: 'mechanic',
      serviceTypeName: 'Bike Repair',
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
    ),

    // ── RIDER / DELIVERY (destinations within ~5 km of default hub 24.8607, 67.0011) ──
    JobRequest(
      id: 'rd1',
      userAddress: 'Plot 12, Street 5, DHA Phase 6, Karachi',
      issue: 'Food delivery — restaurant order',
      serviceTypeId: 'rider',
      serviceTypeName: 'Delivery',
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
      customerName: 'Hassan Ali',
      customerPhone: '0300-2847193',
      orderItems: const ['Chicken Biryani × 2', 'Raita', '500ml drink'],
      originLat: 24.8607,
      originLng: 67.0011,
      destLat: 24.875,
      destLng: 67.012,
      itemsTotal: 1180,
      deliveryFee: 150,
      serviceFee: 49,
      deliveryCategory: 'restaurant',
      merchantFulfillmentStatus: JobRequest.merchantAwaiting,
    ),
    JobRequest(
      id: 'rd2',
      userAddress: 'Flat 4B, Gulistan-e-Jauhar Block 15, Karachi',
      issue: 'Grocery run — express',
      serviceTypeId: 'rider',
      serviceTypeName: 'Delivery',
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      customerName: 'Ayesha Malik',
      customerPhone: '0321-5568890',
      orderItems: const ['Milk 1L', 'Bread', 'Eggs dozen', 'Oil 1L'],
      originLat: 24.8607,
      originLng: 67.0011,
      destLat: 24.848,
      destLng: 67.018,
      itemsTotal: 2450,
      deliveryFee: 120,
      serviceFee: 49,
      deliveryCategory: 'grocery',
      merchantFulfillmentStatus: JobRequest.merchantReadyForRider,
    ),
    JobRequest(
      id: 'rd3',
      userAddress: 'Shop 3, Tariq Road, PECHS, Karachi',
      issue: 'Pharmacy — medicines delivery',
      serviceTypeId: 'rider',
      serviceTypeName: 'Delivery',
      createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
      customerName: 'Bilal Ahmed',
      customerPhone: '0333-9012448',
      orderItems: const ['Panadol × 2', 'Vitamin C', 'ORS'],
      originLat: 24.8607,
      originLng: 67.0011,
      destLat: 24.868,
      destLng: 66.985,
      itemsTotal: 890,
      deliveryFee: 120,
      serviceFee: 39,
      deliveryCategory: 'pharmacy',
      merchantFulfillmentStatus: JobRequest.merchantPreparing,
    ),
  ];

  List<JobRequest> get all      => List.unmodifiable(_requests);
  List<JobRequest> get pending  => _requests.where((r) => r.isPending).toList();

  /// Jobs for the logged-in business type (e.g. mechanic only sees mechanic jobs).
  List<JobRequest> requestsForBusiness(String businessTypeId) {
    if (businessTypeId.isEmpty) return const [];
    return _requests.where((r) => r.serviceTypeId == businessTypeId).toList();
  }
  List<JobRequest> get active   => _requests.where((r) => r.isAccepted).toList();
  int get pendingCount          => pending.length;

  void addRequest(JobRequest req) {
    _requests.insert(0, req);
    notifyListeners();
  }

  void accept(String id, {int estimatedMins = 15}) {
    final i = _requests.indexWhere((r) => r.id == id);
    if (i != -1) {
      _requests[i].status = 'accepted';
      _requests[i].estimatedMins = estimatedMins;
      notifyListeners();
    }
  }

  void reject(String id) {
    final i = _requests.indexWhere((r) => r.id == id);
    if (i != -1) {
      _requests[i].status = 'rejected';
      notifyListeners();
    }
  }

  void complete(String id) {
    final i = _requests.indexWhere((r) => r.id == id);
    if (i != -1) {
      _requests[i].status = 'completed';
      _requests[i].completedAt = DateTime.now();
      notifyListeners();
    }
  }

  /// Store accepted the order → kitchen/preparing.
  void merchantAcceptDeliveryJob(String id) {
    final i = _requests.indexWhere((r) => r.id == id);
    if (i == -1) return;
    final r = _requests[i];
    if (!r.isRiderJob) return;
    if (r.merchantFulfillmentStatus == JobRequest.merchantAwaiting) {
      r.merchantFulfillmentStatus = JobRequest.merchantPreparing;
      notifyListeners();
    }
  }

  /// Store finished prep → nearby riders see this job.
  void merchantMarkReadyForRider(String id) {
    final i = _requests.indexWhere((r) => r.id == id);
    if (i == -1) return;
    final r = _requests[i];
    if (!r.isRiderJob) return;
    if (r.merchantFulfillmentStatus == JobRequest.merchantPreparing ||
        r.merchantFulfillmentStatus == JobRequest.merchantAwaiting) {
      r.merchantFulfillmentStatus = JobRequest.merchantReadyForRider;
      notifyListeners();
    }
  }
}
