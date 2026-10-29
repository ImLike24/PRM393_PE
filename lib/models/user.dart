class User {
  final int? userId;
  final String username;
  final String password;
  final String? email;
  final String? avatarUrl;
  final int isActive;

  User({
    this.userId,
    required this.username,
    required this.password,
    this.email,
    this.avatarUrl,
    this.isActive = 1,
  });

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'username': username,
    'password': password,
    'email': email,
    'avatar_url': avatarUrl,
    'isActive': isActive,
  };

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'] is int
          ? map['user_id'] as int
          : int.tryParse('${map['user_id']}'),
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      email: map['email']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      isActive: map['isActive'] is int ? map['isActive'] as int : 1,
    );
  }
}