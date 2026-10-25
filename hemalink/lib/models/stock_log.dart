/// Catatan perubahan stok darah (untuk audit).
class StockLog {
  final String id;
  final DateTime at;
  final String actor;
  final String reason;
  final String bloodType;
  final int before;
  final int after;

  StockLog({
    required this.id,
    required this.at,
    required this.actor,
    required this.reason,
    required this.bloodType,
    required this.before,
    required this.after,
  });

  int get delta => after - before;

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'actor': actor,
        'reason': reason,
        'bloodType': bloodType,
        'before': before,
        'after': after,
      };

  factory StockLog.fromJson(Map<String, dynamic> j) => StockLog(
        id: j['id'] as String,
        at: DateTime.parse(j['at'] as String),
        actor: j['actor'] as String,
        reason: j['reason'] as String,
        bloodType: j['bloodType'] as String,
        before: j['before'] as int,
        after: j['after'] as int,
      );
}
