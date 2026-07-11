class AppUser {
  final String loginId;
  final String role;
  final String name;
  final bool active;

  AppUser({
    required this.loginId,
    required this.role,
    required this.name,
    required this.active,
  });

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      loginId: data['loginId'] ?? '',
      role: data['role'] ?? '',
      name: data['name'] ?? '',
      active: data['active'] ?? false,
    );
  }
}