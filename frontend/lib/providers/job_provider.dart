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
