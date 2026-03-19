import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ==============================
  /// USUARIO ACTUAL 
  /// ==============================
  User? get currentUser => _auth.currentUser;

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
      throw Exception(_mapError(e.code));
    } catch (_) {
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
      throw Exception(_mapError(e.code));
    } catch (_) {
      throw Exception("Error inesperado en login");
    }
  }

  /// ==============================
  /// LOGIN CON GOOGLE (WEB + MÓVIL)
  /// ==============================
  Future<User?> loginWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();

        final userCredential =
            await _auth.signInWithPopup(googleProvider);

        return userCredential.user;
      } else {
        final GoogleSignInAccount? googleUser =
            await GoogleSignIn().signIn();

        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential =
            await _auth.signInWithCredential(credential);

        return userCredential.user;
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapError(e.code));
    } catch (_) {
      throw Exception("Error con Google");
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
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapError(e.code));
    } catch (_) {
      throw Exception("Error al enviar correo de recuperación");
    }
  }

  /// ==============================
  /// MAPEO DE ERRORES
  /// ==============================
  String _mapError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return "Este correo ya está registrado";

      case 'weak-password':
        return "La contraseña debe tener al menos 6 caracteres";

      case 'invalid-email':
        return "Correo inválido";

      case 'user-not-found':
        return "El usuario no existe";

      case 'wrong-password':
        return "Contraseña incorrecta";

      case 'invalid-credential':
        return "Credenciales incorrectas";

      case 'popup-closed-by-user':
        return "Inicio cancelado";

      default:
        return "Error de autenticación";
    }
  }
}