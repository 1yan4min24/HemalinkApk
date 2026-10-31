/// Permintaan reset sandi dari pengguna yang lupa sandi (dilihat admin).
class PasswordReset {
  final String id;
  final String userId;
  final String name;
  final String username;
  final String phone;

  /// pending | done | rejected
  final String status;
  final DateTime createdAt;
  final DateTime? handledAt;

  const PasswordReset({
    required this.id,
    required this.userId,
    required this.name,
    required this.username,
    required this.phone,
    required this.status,
    required this.createdAt,
    this.handledAt,
  });

  bool get isPending => status == 'pending';

  factory PasswordReset.fromJson(Map<String, dynamic> j) => PasswordReset(
        id: j['id'] as String,
        userId: j['userId'] as String,
        name: (j['name'] as String?) ?? '',
        username: (j['username'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        status: j['status'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
        handledAt: j['handledAt'] == null
            ? null
            : DateTime.tryParse(j['handledAt'] as String)?.toLocal(),
      );
}
