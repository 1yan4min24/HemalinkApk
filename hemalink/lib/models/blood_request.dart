class BloodRequest {
  final String id;
  final String requesterId;
  String requesterName;
  final String bloodType;
  final int bags;
  final String reason;
  final String hospital;
  final DateTime createdAt;

  BloodRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.bloodType,
    required this.bags,
    required this.reason,
    required this.hospital,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'requesterId': requesterId,
        'requesterName': requesterName,
        'bloodType': bloodType,
        'bags': bags,
        'reason': reason,
        'hospital': hospital,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BloodRequest.fromJson(Map<String, dynamic> j) => BloodRequest(
        id: j['id'] as String,
        requesterId: j['requesterId'] as String,
        requesterName: j['requesterName'] as String,
        bloodType: j['bloodType'] as String,
        bags: j['bags'] as int,
        reason: j['reason'] as String,
        hospital: j['hospital'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
