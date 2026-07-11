import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signIn({
    required String loginId,
    required String password,
  }) async {
    final normalizedLoginId = loginId.trim().toLowerCase();

    final email = '$normalizedLoginId@study-support.app';

    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}