class DonorHistory {
  final String id;
  final String userId;
  final String place;
  final String reason;
  final int bags;
  final DateTime date;

  const DonorHistory({
    required this.id,
    required this.userId,
    required this.place,
    required this.reason,
    required this.bags,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'place': place,
        'reason': reason,
        'bags': bags,
        'date': date.toIso8601String(),
      };

  factory DonorHistory.fromJson(Map<String, dynamic> j) => DonorHistory(
        id: j['id'] as String,
        userId: j['userId'] as String,
        place: j['place'] as String,
        reason: j['reason'] as String,
        bags: j['bags'] as int,
        date: DateTime.parse(j['date'] as String).toLocal(),
      );
}
