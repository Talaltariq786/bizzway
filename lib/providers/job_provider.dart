import 'package:flutter/material.dart';
import '../models/job_request.dart';

class JobProvider extends ChangeNotifier {
  final List<JobRequest> _requests = [
    // Dummy pending requests for demo
    JobRequest(
      id: 'j1',
      userAddress: 'Block 6, PECHS, Karachi',
      issue: 'Car tyre puncture — need urgent help',
      serviceTypeId: 'mechanic',
      serviceTypeName: 'Puncture',
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    JobRequest(
      id: 'j2',
      userAddress: 'Gulshan Block 13, Karachi',
      issue: 'Main circuit breaker tripped, no electricity in house',
      serviceTypeId: 'homeservice',
      serviceTypeName: 'Electrician',
      createdAt: DateTime.now().subtract(const Duration(minutes: 11)),
    ),
    JobRequest(
      id: 'j3',
      userAddress: 'DHA Phase 4, Karachi',
      issue: 'Bathroom pipe leaking — water damage on floor',
      serviceTypeId: 'homeservice',
      serviceTypeName: 'Plumber',
      createdAt: DateTime.now().subtract(const Duration(minutes: 28)),
      status: 'accepted',
      estimatedMins: 20,
    ),
  ];

  List<JobRequest> get all      => List.unmodifiable(_requests);
  List<JobRequest> get pending  => _requests.where((r) => r.isPending).toList();
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
      notifyListeners();
    }
  }
}
