import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Registro con correo
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Login con correo
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Login con Google
  Future<User?> loginWithGoogle() async {
    try {

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential result =
          await _auth.signInWithCredential(credential);

      return result.user;

    } catch (e) {
      print(e);
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Recuperar contraseña
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}