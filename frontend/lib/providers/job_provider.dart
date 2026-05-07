import 'package:flutter/material.dart';
import '../models/job_request.dart';

class JobProvider extends ChangeNotifier {
  final List<JobRequest> _requests = [];
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

  /// Sample jobs so service-provider UI shows realistic addresses & work types (dev / demo).
  void seedDemoJobsIfEmpty() {
    if (_requests.isNotEmpty) return;
    final base = DateTime.now();
    _requests.addAll([
      JobRequest(
        id: 'demo-sw-1',
        userAddress:
            'Block 5, Clifton, Karachi — near Do Talwar (24.8138, 67.0299)',
        issue:
            'Split AC not cooling; suspect gas leak. Indoor + outdoor unit check.',
        serviceTypeId: 'ac',
        serviceTypeName: 'AC Technician',
        createdAt: base.subtract(const Duration(minutes: 8)),
        status: 'pending',
        destLat: 24.8138,
        destLng: 67.0299,
      ),
      JobRequest(
        id: 'demo-sw-2',
        userAddress: 'DHA Phase 6, Lahore — main boulevard side',
        issue: 'Kitchen sink leak + geyser connection loose; need urgent fix.',
        serviceTypeId: 'plumber',
        serviceTypeName: 'Plumber',
        createdAt: base.subtract(const Duration(minutes: 42)),
        status: 'pending',
        destLat: 31.4697,
        destLng: 74.2728,
      ),
      JobRequest(
        id: 'demo-sw-3',
        userAddress: 'Bahria Town Phase 4, Islamabad',
        issue: 'DB main MCB trips; 2 rooms dead. Need tracing & safe fix.',
        serviceTypeId: 'electrician',
        serviceTypeName: 'Electrician',
        createdAt: base.subtract(const Duration(hours: 1, minutes: 15)),
        status: 'accepted',
        estimatedMins: 35,
        destLat: 33.6844,
        destLng: 73.0479,
      ),
      JobRequest(
        id: 'demo-sw-4',
        userAddress: 'Gulshan-e-Iqbal Block 13A, Karachi',
        issue: '3 ceiling fans install + dimmer switches. Material on site.',
        serviceTypeId: 'electrician',
        serviceTypeName: 'Electrician',
        createdAt: base.subtract(const Duration(days: 1, hours: 3)),
        status: 'completed',
        estimatedMins: 50,
        completedAt: base.subtract(const Duration(hours: 22)),
        destLat: 24.9056,
        destLng: 67.0889,
      ),
      JobRequest(
        id: 'demo-sw-5',
        userAddress: 'Saddar workshop area, Karachi',
        issue: 'Bike puncture + chain noise; general tune-up.',
        serviceTypeId: 'mechanic',
        serviceTypeName: 'Mechanic',
        createdAt: base.subtract(const Duration(minutes: 25)),
        status: 'pending',
        destLat: 24.8607,
        destLng: 67.0011,
      ),
    ]);
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

  /// When a store order is marked completed, close the matching pool rider job (if any).
  void completeRiderJobLinkedToOrder(String orderId) {
    if (orderId.isEmpty) return;
    final i = _requests.indexWhere(
      (r) => r.isRiderJob && (r.linkedOrderId ?? '') == orderId,
    );
    if (i == -1) return;
    complete(_requests[i].id);
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
