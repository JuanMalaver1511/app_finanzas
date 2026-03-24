import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;

  /// SEGURIDAD
  final bool isActive;
  final int failedAttempts;

  final DateTime? lastLogin;
  final DateTime? createdAt; 
  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'user',

    /// VALORES POR DEFECTO
    this.isActive = true,
    this.failedAttempts = 0,

    this.lastLogin,
    this.createdAt, 
  });

  /// ==============================
  /// TO MAP (GUARDAR EN FIRESTORE)
  /// ==============================
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,

      /// SEGURIDAD
      'isActive': isActive,
      'failedAttempts': failedAttempts,

      'lastLogin': lastLogin,
      'createdAt': createdAt, 
    };
  }

  /// ==============================
  /// FROM MAP (LEER DE FIRESTORE)
  /// ==============================
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',

      /// SEGURIDAD
      isActive: map['isActive'] ?? true,
      failedAttempts: map['failedAttempts'] ?? 0,

      lastLogin: map['lastLogin'] != null
          ? (map['lastLogin'] as Timestamp).toDate()
          : null,

      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null, 
    );
  }
}