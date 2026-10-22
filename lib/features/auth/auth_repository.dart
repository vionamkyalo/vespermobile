abstract class AuthRepository {
  Future<void> signIn(String email, String password);
}

class DemoAuthRepository implements AuthRepository {
  @override
  Future<void> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
