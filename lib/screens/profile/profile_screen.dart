import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

const kAmber = Color(0xFFFFB84E);
const kBg = Color(0xFFF6F7FB);
const kCard = Colors.white;
const kPrimary = Color(0xFF1A1A2E);
const kPrimarySoft = Color.fromARGB(255, 42, 36, 76);
const kGrey = Color(0xFF8A8A9A);
const kGreen = Color(0xFF16A34A);
const kRed = Color(0xFFEF4444);
const kBlue = Color(0xFF3B82F6);

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ProfileScreen({super.key, this.onBack});

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
        _nameCtrl.text = (data['displayName'] ?? _nameCtrl.text).toString();
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

      if (mounted) {
        setState(() => _photoUrl = url);
      }

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
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
                  fontWeight: FontWeight.w800,
                  color: kPrimary,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String get _initials {
    final n = _nameCtrl.text.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return n[0].toUpperCase();
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Desconocido';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String get _displayName =>
      _nameCtrl.text.trim().isEmpty ? 'Sin nombre' : _nameCtrl.text.trim();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 24,
            isMobile ? 16 : 20,
            isMobile ? 16 : 24,
            24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context, isMobile),
                  const SizedBox(height: 18),
                  _buildHeroBanner(isMobile),
                  const SizedBox(height: 18),
                  _buildProfileCard(isMobile),
                  const SizedBox(height: 18),
                  _buildAccountCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEBEEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: kPrimary,
                size: 18,
              ),
              onPressed: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi perfil',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w800,
                    color: kPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestiona tu información personal y acceso',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimary, kPrimarySoft],
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroUserBlock(),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroChip(
                      title: 'Correo',
                      value: user.email != null ? 'Registrado' : 'Sin correo',
                      color: kBlue,
                    ),
                    const _HeroChip(
                      title: 'Perfil',
                      value: 'Activo',
                      color: kGreen,
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 4, child: _heroUserBlock()),
                const SizedBox(width: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroChip(
                      title: 'Correo',
                      value: user.email != null ? 'Registrado' : 'Sin correo',
                      color: kBlue,
                    ),
                    const _HeroChip(
                      title: 'Perfil',
                      value: 'Activo',
                      color: kGreen,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _heroUserBlock() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AvatarSection(
          photoUrl: _photoUrl,
          initials: _initials,
          uploading: _uploadingPhoto,
          onTap: _showPhotoOptions,
          compact: true,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Perfil Kybo',
                style: TextStyle(
                  color: Color(0xFFFFD89A),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user.email ?? 'Sin correo',
                style: TextStyle(
                  color: Colors.white.withOpacity(.84),
                  fontSize: 13.2,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatusPill(
                    text:
                        'Miembro desde ${_formatDate(user.metadata.creationTime)}',
                    light: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEBEEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            title: 'Información personal',
            subtitle: 'Datos principales de tu perfil',
          ),
          const SizedBox(height: 18),
          if (!isMobile) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildNameCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildEmailCard()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildUidCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildPhotoCard()),
              ],
            ),
          ] else ...[
            _buildNameCard(),
            const SizedBox(height: 12),
            _buildEmailCard(),
            const SizedBox(height: 12),
            _buildUidCard(),
            const SizedBox(height: 12),
            _buildPhotoCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEBEEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            title: 'Cuenta',
            subtitle: 'Información de acceso y trazabilidad',
          ),
          const SizedBox(height: 18),
          _InfoCard(
            icon: Icons.calendar_today_outlined,
            iconColor: kGrey,
            label: 'Miembro desde',
            child: Text(
              _formatDate(user.metadata.creationTime),
              style: const TextStyle(fontSize: 14, color: kPrimary),
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.access_time_rounded,
            iconColor: kGrey,
            label: 'Último acceso',
            child: Text(
              _formatDate(user.metadata.lastSignInTime),
              style: const TextStyle(fontSize: 14, color: kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameCard() {
    return _InfoCard(
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
                    style: const TextStyle(fontSize: 14, color: kPrimary),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kAmber, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
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
                          color: kAmber,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        children: [
                          GestureDetector(
                            onTap: _saveName,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: kGreen.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: kGreen,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() {
                              _editingName = false;
                              _loadProfile();
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: kRed.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: kRed,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _displayName,
                    style: const TextStyle(fontSize: 14, color: kPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _editingName = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kAmber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Editar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kAmber,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmailCard() {
    return _InfoCard(
      icon: Icons.email_outlined,
      iconColor: kBlue,
      label: 'Correo electrónico',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              user.email ?? 'Sin correo',
              style: const TextStyle(fontSize: 14, color: kPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Verificado',
              style: TextStyle(
                fontSize: 11,
                color: kBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUidCard() {
    return _InfoCard(
      icon: Icons.fingerprint_rounded,
      iconColor: kGrey,
      label: 'ID de usuario',
      child: Text(
        user.uid,
        style: const TextStyle(
          fontSize: 11.5,
          color: kGrey,
          fontFamily: 'monospace',
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPhotoCard() {
    return _InfoCard(
      icon: Icons.photo_camera_back_outlined,
      iconColor: kAmber,
      label: 'Foto de perfil',
      child: Row(
        children: [
          Expanded(
            child: Text(
              _photoUrl != null ? 'Configurada' : 'Sin foto',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: kPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _uploadingPhoto ? null : _showPhotoOptions,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: kAmber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _photoUrl != null ? 'Cambiar' : 'Agregar',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kAmber,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12.8,
          ),
        ),
      ],
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final bool uploading;
  final VoidCallback onTap;
  final bool compact;

  const _AvatarSection({
    required this.photoUrl,
    required this.initials,
    required this.uploading,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final outer = compact ? 76.0 : 108.0;
    final inner = compact ? 68.0 : 96.0;
    final camera = compact ? 24.0 : 30.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: uploading ? null : onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: outer,
                height: outer,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kAmber, width: 2.5),
                ),
              ),
              ClipOval(
                child: SizedBox(
                  width: inner,
                  height: inner,
                  child: uploading
                      ? Container(
                          color: kAmber.withOpacity(0.1),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: kAmber,
                              strokeWidth: 2.5,
                            ),
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
                    width: camera,
                    height: camera,
                    decoration: BoxDecoration(
                      color: kAmber,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: compact ? 12 : 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 10),
          const Text(
            'Toca para cambiar foto',
            style: TextStyle(fontSize: 12, color: kGrey),
          ),
        ],
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBEEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
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
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: kGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _HeroChip({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(.88),
              fontWeight: FontWeight.w600,
              fontSize: 12.3,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final bool light;

  const _StatusPill({
    required this.text,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: light ? Colors.white.withOpacity(.10) : kAmber.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              light ? Colors.white.withOpacity(.12) : kAmber.withOpacity(.18),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: light ? Colors.white : kAmber,
          fontSize: 12.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = kPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }
}
