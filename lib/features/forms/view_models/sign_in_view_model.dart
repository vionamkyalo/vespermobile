import 'package:flutter/material.dart';
import '../../auth/auth_repository.dart';

class SignInViewModel extends ChangeNotifier {
  final AuthRepository _auth;
  
  bool _busy = false;
  String? _error;
  bool _passwordHidden = true;

  SignInViewModel(this._auth);


  bool get busy => _busy;
  String? get error => _error;
  bool get passwordHidden => _passwordHidden;

 
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  void togglePasswordVisibility() {
    _passwordHidden = !_passwordHidden;
    notifyListeners();
  }

 
  Future<bool> signIn(String email, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.signIn(email, password);
      _busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      _busy = false;
      _error = 'Sign in failed. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
