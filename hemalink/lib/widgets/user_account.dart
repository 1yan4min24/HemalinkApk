class UserAccount {
  final String id;
  final String name;
  final String username;
  final String passwordHash;
  final String phone;
  final String bloodType;
  final String city;
  final int weight;
  final int height;

  const UserAccount({
    required this.id,
    required this.name,
    required this.username,
    required this.passwordHash,
    required this.phone,
    required this.bloodType,
    required this.city,
    required this.weight,
    required this.height,
  });

  UserAccount copyWith({
    String? name,
    String? phone,
    String? bloodType,
    String? city,
    int? weight,
    int? height,
  }) =>
      UserAccount(
        id: id,
        name: name ?? this.name,
        username: username,
        passwordHash: passwordHash,
        phone: phone ?? this.phone,
        bloodType: bloodType ?? this.bloodType,
        city: city ?? this.city,
        weight: weight ?? this.weight,
        height: height ?? this.height,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'passwordHash': passwordHash,
        'phone': phone,
        'bloodType': bloodType,
        'city': city,
        'weight': weight,
        'height': height,
      };

  factory UserAccount.fromJson(Map<String, dynamic> j) => UserAccount(
        id: j['id'] as String,
        name: j['name'] as String,
        username: j['username'] as String,
        passwordHash: j['passwordHash'] as String,
        phone: j['phone'] as String,
        bloodType: j['bloodType'] as String,
        city: j['city'] as String,
        weight: j['weight'] as int,
        height: j['height'] as int,
      );
}
