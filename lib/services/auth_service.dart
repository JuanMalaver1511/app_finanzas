import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ==============================
  /// REGISTRO CON EMAIL
  /// ==============================
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception("Error inesperado en registro");
    }
  }

  /// ==============================
  /// LOGIN CON EMAIL
  /// ==============================
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception("Error inesperado en login");
    }
  }

  /// ==============================
  /// LOGIN CON GOOGLE (WEB + MOVIL)
  /// ==============================
  Future<User?> loginWithGoogle() async {
    try {
      if (kIsWeb) {
        /// 🔥 WEB
        final googleProvider = GoogleAuthProvider();

        final userCredential = await _auth.signInWithPopup(googleProvider);

        return userCredential.user;
      } else {
        /// 📱 MÓVIL
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);

        return userCredential.user;
      }
    } catch (e) {
      print("🔥 ERROR GOOGLE: $e");
      throw e;
    }
  }

  /// ==============================
  /// LOGOUT
  /// ==============================
  Future<void> logout() async {
    await _auth.signOut();

    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
  }

  /// ==============================
  /// RECUPERAR CONTRASEÑA
  /// ==============================
  /// ==============================
  /// RECUPERAR CONTRASEÑA
  /// ==============================
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception("Error al enviar correo de recuperación");
    }
  }
}
