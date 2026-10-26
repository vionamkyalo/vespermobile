class UserProfile {
  const UserProfile({
    required this.fullName,
    required this.role,
    required this.phone,
    required this.email,
  });

  final String fullName;
  final String role;
  final String phone;
  final String email;

  static const UserProfile placeholder = UserProfile(
    fullName: 'Tendai Phiri',
    role: 'Patrol Officer',
    phone: '+263 795 679 308',
    email: 'tendaiphiri@gmail.com',
  );

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}
