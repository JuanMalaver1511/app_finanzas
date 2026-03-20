import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ==============================
  /// CREAR USUARIO
  /// ==============================
  Future<void> createUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  /// ==============================
  /// OBTENER USUARIO
  /// ==============================
  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    return AppUser.fromMap(doc.data()!);
  }

  /// ==============================
  /// VERIFICAR SI EMAIL EXISTE
  /// ==============================
  Future<bool> emailExists(String email) async {
    final result = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  /// ==============================
  /// OBTENER ROL DEL USUARIO
  /// ==============================
  Future<String> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) return 'user';

    return doc.data()?['role'] ?? 'user';
  }

  /// ==============================
  /// OBTENER TODOS LOS USUARIOS (ADMIN)
  /// ==============================
  Future<List<AppUser>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();

    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.data()))
        .toList();
  }

  /// ==============================
  /// ACTUALIZAR ROL (ADMIN)
  /// ==============================
  Future<void> updateUserRole(String uid, String newRole) async {
    await _db.collection('users').doc(uid).update({
      'role': newRole,
    });
  }

  /// ==============================
  /// ELIMINAR USUARIO (ADMIN)
  /// ==============================
  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  /// ==============================
  /// ACTUALIZAR LOGIN (PRO)
  /// ==============================
  Future<void> updateUserLoginData(String uid) async {
    await _db.collection('users').doc(uid).update({
      'lastLogin': DateTime.now(),
      'failedAttempts': 0,
    });
  }

  /// ==============================
  /// SUMAR INTENTOS FALLIDOS
  /// ==============================
  Future<void> incrementFailedAttemptsByEmail(String email) async {
    final result = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (result.docs.isNotEmpty) {
      final doc = result.docs.first;

      await doc.reference.update({
        'failedAttempts': FieldValue.increment(1),
      });
    }
  }

  /// ==============================
  /// ACTIVAR / DESACTIVAR USUARIO
  /// ==============================
  Future<void> updateUserStatus(String uid, bool status) async {
    await _db.collection('users').doc(uid).update({
      'isActive': status,
    });
  }

  /// ==============================
  /// BLOQUEO AUTOMÁTICO (PRO)
  /// ==============================
  Future<void> checkAndBlockUser(String email) async {
    final result = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (result.docs.isNotEmpty) {
      final doc = result.docs.first;
      final data = doc.data();

      final attempts = data['failedAttempts'] ?? 0;

      if (attempts >= 5) {
        await doc.reference.update({
          'isActive': false,
        });
      }
    }
  }
}