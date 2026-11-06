import '../../auth/services/auth_service.dart';

class UserProfile {
  const UserProfile({
    required this.fullName,
    required this.role,
    required this.phone,
    required this.email,
  });
  factory UserProfile.fromUser(VesperUser user) {
    final name = user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : '${user.firstName} ${user.lastName}'.trim();
    return UserProfile(
      fullName: name,
      role: roleLabel(user.role),
      phone: user.phoneNumber,
      email: user.email,
    );
  }

  final String fullName;
  final String role;
  final String phone;
  final String email;
  static String roleLabel(String role) => role
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
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
