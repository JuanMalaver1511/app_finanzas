import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

const kAmber = Color(0xFFFFBB4E);
const kBg = Color(0xFFF0F2F5);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF8A8A9A);
const kGreen = Color.fromARGB(255, 29, 126, 69);
const kRed = Color(0xFFE74C3C);
const kGreenBtn = Color(0xFF27AE60);

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack; // ✅ declarado
  const ProfileScreen({super.key, this.onBack}); // ✅ pasado al constructor

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  final _nameCtrl = TextEditingController();
  bool _editingName = false;
  bool _uploadingPhoto = false;
  bool _savingName = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _nameCtrl.text = user.displayName ?? user.email?.split('@').first ?? '';
    _photoUrl = user.photoURL;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists && mounted) {
      final data = doc.data()!;
      setState(() {
        _nameCtrl.text = data['displayName'] ?? _nameCtrl.text;
        _photoUrl = data['photoUrl'] ?? _photoUrl;
      });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null) return;
      final bytes = result.files.first.bytes;
      if (bytes == null) return;
      setState(() => _uploadingPhoto = true);
      final ref = _storage.ref().child('users/${user.uid}/avatar.jpg');
      await ref.putData(bytes);
      final url = await ref.getDownloadURL();
      await user.updatePhotoURL(url);
      await _firestore.collection('users').doc(user.uid).set(
        {'photoUrl': url},
        SetOptions(merge: true),
      );
      if (mounted) setState(() => _photoUrl = url);
      _showSnack('Foto actualizada ✓', kGreen);
    } catch (e) {
      _showSnack('Error al subir foto: $e', kRed);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _uploadingPhoto = true);
    try {
      await user.updatePhotoURL(null);
      await _firestore.collection('users').doc(user.uid).set(
        {'photoUrl': null},
        SetOptions(merge: true),
      );
      if (mounted) setState(() => _photoUrl = null);
      _showSnack('Foto eliminada', kGrey);
    } catch (e) {
      _showSnack('Error: $e', kRed);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Foto de perfil',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kDark,
                ),
              ),
              const SizedBox(height: 12),
              _SheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Elegir de galería',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhoto();
                },
              ),
              if (_photoUrl != null)
                _SheetOption(
                  icon: Icons.delete_outline,
                  label: 'Eliminar foto',
                  color: kRed,
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto();
                  },
                ),
              _SheetOption(
                icon: Icons.close,
                label: 'Cancelar',
                color: kGrey,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('El nombre no puede estar vacío', kRed);
      return;
    }
    setState(() => _savingName = true);
    try {
      await user.updateDisplayName(name);
      await _firestore.collection('users').doc(user.uid).set(
        {'displayName': name},
        SetOptions(merge: true),
      );
      setState(() => _editingName = false);
      _showSnack('Nombre actualizado ✓', kGreen);
    } catch (e) {
      _showSnack('Error al guardar: $e', kRed);
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String get _initials {
    final n = _nameCtrl.text.trim();
    final parts = n.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: kDark, size: 20),
          onPressed: () {
            if (widget.onBack != null) {
              // ✅ widget.onBack
              widget.onBack!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Mi perfil',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: kDark,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kAmber, kAmber.withOpacity(0.15)],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _AvatarSection(
              photoUrl: _photoUrl,
              initials: _initials,
              uploading: _uploadingPhoto,
              onTap: _showPhotoOptions,
            ),
            const SizedBox(height: 28),
            _SectionLabel(label: 'Información personal'),
            const SizedBox(height: 10),
            _InfoCard(
              icon: Icons.person_outline_rounded,
              iconColor: kAmber,
              label: 'Nombre',
              child: _editingName
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameCtrl,
                            autofocus: true,
                            style: const TextStyle(fontSize: 14, color: kDark),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: kAmber, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _savingName
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: kAmber, strokeWidth: 2),
                              )
                            : Row(
                                children: [
                                  GestureDetector(
                                    onTap: _saveName,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: kGreenBtn.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: const Icon(Icons.check_rounded,
                                          color: kGreenBtn, size: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _editingName = false;
                                      _loadProfile();
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: kRed.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: const Icon(Icons.close_rounded,
                                          color: kRed, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _nameCtrl.text.isEmpty
                              ? 'Sin nombre'
                              : _nameCtrl.text,
                          style: const TextStyle(fontSize: 14, color: kDark),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _editingName = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: kAmber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Text(
                              'Editar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kAmber,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 10),
            _InfoCard(
              icon: Icons.email_outlined,
              iconColor: const Color(0xFF3B82F6),
              label: 'Correo electrónico',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      user.email ?? 'Sin correo',
                      style: const TextStyle(fontSize: 14, color: kDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Verificado',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _InfoCard(
              icon: Icons.fingerprint_rounded,
              iconColor: kGrey,
              label: 'ID de usuario',
              child: Text(
                user.uid,
                style: const TextStyle(
                    fontSize: 11, color: kGrey, fontFamily: 'monospace'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 28),
            _SectionLabel(label: 'Cuenta'),
            const SizedBox(height: 10),
            _InfoCard(
              icon: Icons.calendar_today_outlined,
              iconColor: kGrey,
              label: 'Miembro desde',
              child: Text(
                _formatDate(user.metadata.creationTime),
                style: const TextStyle(fontSize: 14, color: kDark),
              ),
            ),
            const SizedBox(height: 10),
            _InfoCard(
              icon: Icons.access_time_rounded,
              iconColor: kGrey,
              label: 'Último acceso',
              child: Text(
                _formatDate(user.metadata.lastSignInTime),
                style: const TextStyle(fontSize: 14, color: kDark),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Desconocido';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

// ─── AVATAR SECTION ────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final bool uploading;
  final VoidCallback onTap;

  const _AvatarSection({
    required this.photoUrl,
    required this.initials,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: uploading ? null : onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kAmber, width: 2.5),
                ),
              ),
              ClipOval(
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: uploading
                      ? Container(
                          color: kAmber.withOpacity(0.1),
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: kAmber, strokeWidth: 2.5),
                          ),
                        )
                      : photoUrl != null
                          ? Image.network(
                              photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _AvatarFallback(initials: initials),
                            )
                          : _AvatarFallback(initials: initials),
                ),
              ),
              if (!uploading)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: kAmber,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Toca para cambiar foto',
          style: TextStyle(fontSize: 12, color: kGrey),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;
  const _AvatarFallback({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kAmber.withOpacity(0.15),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: kAmber,
        ),
      ),
    );
  }
}

// ─── INFO CARD ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget child;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: kGrey),
                ),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SECTION LABEL ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: kGrey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ─── SHEET OPTION ──────────────────────────────────────────────────────────────

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = kDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color),
      ),
      onTap: onTap,
    );
  }
}
