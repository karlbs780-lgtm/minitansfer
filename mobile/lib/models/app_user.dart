/// The authenticated user and their current wallet balance (FCFA).
class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int balance;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.balance,
  });

  AppUser copyWith({int? balance}) {
    return AppUser(
      id: id,
      name: name,
      email: email,
      phone: phone,
      balance: balance ?? this.balance,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      balance: (json['balance'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'balance': balance,
      };
}
