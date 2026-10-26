import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../services/auth_service.dart';

class SignInViewModel extends ChangeNotifier {
  SignInViewModel(this._service);

  final AuthService _service;

  bool _busy = false;
  String? _error;
  String? _errorCode;
  bool _passwordHidden = true;
  VesperUser? _user;

  bool get busy => _busy;
  String? get error => _error;
  String? get errorCode => _errorCode;
  bool get passwordHidden => _passwordHidden;
  VesperUser? get user => _user;

  String? validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  String? validateResetToken(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Paste the reset code from your email';
    return null;
  }

  /// Same rules as the backend (validate_password_strength in core/security).
  String? validateNewPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Enter a new password';
    if (text.length < 12) return 'Use at least 12 characters';
    if (text.length > 128) return 'Use at most 128 characters';
    if (!RegExp(r'[a-z]').hasMatch(text)) return 'Add a lowercase letter';
    if (!RegExp(r'[A-Z]').hasMatch(text)) return 'Add a capital letter';
    if (!RegExp(r'\d').hasMatch(text)) return 'Add a number';
    return null;
  }

  void togglePasswordVisibility() {
    _passwordHidden = !_passwordHidden;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) => _run(() async {
    _user = await _service.login(email: email, password: password);
  });

  Future<bool> forgotPassword(String email) => _run(() async {
    await _service.forgotPassword(email);
  });

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) => _run(() async {
    await _service.resetPassword(token: token, newPassword: newPassword);
  });

  /// Called when the app opens. True means the officer is still signed in.
  /// If the phone is offline the officer stays signed in too, and [user]
  /// stays null until the next successful request.
  Future<bool> restoreSession() async {
    if (!await _service.hasSession()) return false;
    try {
      _user = await _service.me();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      return e.isNetwork;
    } catch (e) {
      debugPrint('restoreSession failed: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    notifyListeners();
  }

  /// Pass notify: false from initState, before the first build.
  void clearError({bool notify = true}) {
    if (_error == null) return;
    _error = null;
    _errorCode = null;
    if (notify) notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    _errorCode = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _errorCode = e.code;
      return false;
    } catch (e) {
      debugPrint('Unexpected auth error: $e');
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}