import 'user.dart';

class AuthRepository {
  AuthRepository();

  Future<User> signIn(String email, String password) async {
   
    return User(
      email: email,
      password: password,
    ); 
  }
}
