class JobRequest {
  final String id;
  final String userAddress;
  final String issue;
  final String serviceTypeId;
  final String serviceTypeName;
  final DateTime createdAt;
  String status; // 'pending' | 'accepted' | 'rejected' | 'completed'
  int? estimatedMins;
  DateTime? completedAt;

  /// Restaurant / grocery / pharmacy — rider only sees job after this is [readyForRider].
  /// `awaiting_acceptance` → Accept → `preparing` → "Ready for rider" → `ready_for_rider`
  String? merchantFulfillmentStatus;

  /// Rider / delivery jobs — customer & order line items.
  final String? customerName;
  /// Customer contact (shown to rider for call / WhatsApp).
  final String? customerPhone;
  final List<String> orderItems;

  /// Map route (WGS84). When set, detail screen can show polyline.
  final double? destLat;
  final double? destLng;
  final double? originLat;
  final double? originLng;

  /// Rider delivery — bill breakdown (PKR).
  final double? itemsTotal;
  final double? deliveryFee;
  final double? serviceFee;

  /// What is being delivered — matches [BusinessType.id] (`restaurant`, `grocery`, `pharmacy`, …).
  final String? deliveryCategory;

  /// Store order id (`ORD-…`) when this rider job mirrors that order; used to sync completion.
  final String? linkedOrderId;

  JobRequest({
    required this.id,
    required this.userAddress,
    required this.issue,
    required this.serviceTypeId,
    required this.serviceTypeName,
    required this.createdAt,
    this.status = 'pending',
    this.estimatedMins,
    this.customerName,
    this.customerPhone,
    this.orderItems = const [],
    this.destLat,
    this.destLng,
    this.originLat,
    this.originLng,
    this.itemsTotal,
    this.deliveryFee,
    this.serviceFee,
    this.completedAt,
    this.deliveryCategory,
    this.merchantFulfillmentStatus,
    this.linkedOrderId,
  });

  /// Human label for chips (Urdu-friendly).
  String get deliveryCategoryLabel {
    switch (deliveryCategory) {
      case 'restaurant':
        return 'Restaurant';
      case 'grocery':
        return 'Grocery';
      case 'pharmacy':
        return 'Pharmacy';
      case 'general':
        return 'Delivery';
      default:
        return 'Delivery';
    }
  }

  bool get isCompleted => status == 'completed';

  /// Items + delivery + optional platform fee (when amounts present).
  double? get grandTotal {
    if (itemsTotal == null && deliveryFee == null && serviceFee == null) {
      return null;
    }
    return (itemsTotal ?? 0) + (deliveryFee ?? 0) + (serviceFee ?? 0);
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isRiderJob => serviceTypeId == 'rider';

  static const String merchantAwaiting = 'awaiting_acceptance';
  static const String merchantPreparing = 'preparing';
  static const String merchantReadyForRider = 'ready_for_rider';

  /// Shown on rider home only after store marked ready (or rider already picked up the job).
  bool get isVisibleToRider {
    if (!isRiderJob) return false;
    if (status == 'accepted' || status == 'completed') return true;
    if (status == 'pending' &&
        merchantFulfillmentStatus == merchantReadyForRider) {
      return true;
    }
    return false;
  }

  String get merchantStatusLabel {
    switch (merchantFulfillmentStatus) {
      case merchantAwaiting:
        return 'Awaiting accept';
      case merchantPreparing:
        return 'Preparing';
      case merchantReadyForRider:
        return 'Ready for rider';
      default:
        return '—';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
