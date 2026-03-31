class JobRequest {
  final String id;
  final String userAddress;
  final String issue;
  final String serviceTypeId;
  final String serviceTypeName;
  final DateTime createdAt;
  String status; // 'pending' | 'accepted' | 'rejected' | 'completed'
  int? estimatedMins;

  JobRequest({
    required this.id,
    required this.userAddress,
    required this.issue,
    required this.serviceTypeId,
    required this.serviceTypeName,
    required this.createdAt,
    this.status = 'pending',
    this.estimatedMins,
  });

  bool get isPending  => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
