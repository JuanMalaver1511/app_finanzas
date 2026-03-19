import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// CREAR USUARIO
  Future<void> createUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  /// OBTENER USUARIO
  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    return AppUser.fromMap(doc.data()!);
  }

  /// VERIFICAR SI EMAIL EXISTE
  Future<bool> emailExists(String email) async {
    final result = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }
}