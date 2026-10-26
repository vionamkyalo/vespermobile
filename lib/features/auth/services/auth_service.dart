import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';

class VesperUser {
  const VesperUser({
    required this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.isActive,
  });

  final String id;
  final String role;
  final String firstName;
  final String lastName;
  final String fullName;
  final String phoneNumber;
  final String email;
  final bool isActive;

  bool get isOfficer => role == 'patrol_officer';

  factory VesperUser.fromJson(Map<String, dynamic> json) => VesperUser(
    id: json['user_id'] as String,
    role: json['role'] as String,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    fullName: json['full_name'] as String,
    phoneNumber: json['phone_number'] as String,
    email: json['email'] as String,
    isActive: json['is_active'] as bool,
  );
}

abstract class AuthService {
  Future<VesperUser> login({required String email, required String password});
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });
  Future<VesperUser> me();
  Future<bool> hasSession();
  Future<void> logout();
}

class ApiAuthService implements AuthService {
  ApiAuthService(this.api);
  final ApiClient api;

  @override
  Future<VesperUser> login({
    required String email,
    required String password,
  }) async {
    final data = await api.post(
      '/auth/login',
      auth: false,
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );
    await api.saveTokenPair(data as Map<String, dynamic>);
    try {
      // Login only returns tokens, so the user comes from /users/me.
      return await _loadOfficer();
    } catch (_) {
      // Login did not finish (offline, or not an officer): leave no tokens.
      await api.tokens.clear();
      rethrow;
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    await api.post(
      '/auth/forgot-password',
      auth: false,
      body: {'email': email.trim().toLowerCase()},
    );
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await api.post(
      '/auth/reset-password',
      auth: false,
      body: {'token': token.trim(), 'new_password': newPassword},
    );
  }

  @override
  Future<VesperUser> me() => _loadOfficer();

  @override
  Future<bool> hasSession() async => (await api.tokens.readRefresh()) != null;

  /// The backend has no /auth/logout endpoint, so signing out only clears the
  /// tokens stored on the phone.
  @override
  Future<void> logout() => api.tokens.clear();

  /// The mobile app is for patrol officers only. A coordinator who signs in
  /// here is turned away and the tokens are removed.
  Future<VesperUser> _loadOfficer() async {
    final data = await api.get('/users/me');
    final user = VesperUser.fromJson(data as Map<String, dynamic>);
    if (!user.isOfficer) {
      await api.tokens.clear();
      throw const ApiException(
        statusCode: 403,
        code: 'NOT_OFFICER',
        message:
            'This app is for patrol officers. Coordinators should use the dashboard.',
      );
    }
    return user;
  }
}