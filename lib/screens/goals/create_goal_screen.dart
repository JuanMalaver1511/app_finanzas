import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/goal_model.dart';
import '../../services/goal_service.dart';
import '../../utils/goal_calculator.dart';

// ─── COLORES ────────────────────────────────────────────────────────────────
const kAmber = Color(0xFFFFBB4E);
const kBg = Color(0xFFF0F2F5);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF8A8A9A);
const kGreen = Color(0xFF1D7E45);
const kGreenBtn = Color(0xFF27AE60);
const kRed = Color(0xFFE74C3C);
const kAmberLight = Color(0xFFFFF3DC);

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _initialSavedAmountController = TextEditingController();
  final _motivationController = TextEditingController();

  final GoalService _goalService = GoalService();
  final ImagePicker _imagePicker = ImagePicker();

  GoalSavingFrequency _selectedFrequency = GoalSavingFrequency.monthly;
  DateTime? _selectedDeadline;
  bool _isSaving = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _initialSavedAmountController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  double get _targetAmount => _parseAmount(_targetAmountController.text);
  double get _initialSavedAmount =>
      _parseAmount(_initialSavedAmountController.text);

  GoalCalculationResult? get _previewCalculation {
    if (_targetAmount <= 0 || _selectedDeadline == null) return null;

    return GoalCalculator.calculate(
      targetAmount: _targetAmount,
      savedAmount: _initialSavedAmount,
      deadline: _selectedDeadline!,
      frequency: _selectedFrequency,
      now: DateTime.now(),
    );
  }

  double _parseAmount(String value) {
    final clean = value.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(clean) ?? 0;
  }

  String _formatCurrency(double value) {
    final intValue = value.round();
    final text = intValue.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final indexFromEnd = text.length - i;
      buffer.write(text[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return '\$${buffer.toString()}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initialDate = _selectedDeadline ?? now.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kAmber,
              onPrimary: kDark,
              onSurface: kDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        );
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = file.name;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kRed,
          content: Text('No se pudo seleccionar la imagen: $e'),
        ),
      );
    }
  }

  Future<String?> _uploadGoalImage() async {
    if (_selectedImageBytes == null) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${_selectedImageName ?? 'goal.jpg'}';

    final ref = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(user.uid)
        .child('goals')
        .child(fileName);

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
    );

    await ref.putData(_selectedImageBytes!, metadata);
    return await ref.getDownloadURL();
  }

  Future<void> _saveGoal() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una fecha límite para tu meta.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final imageUrl = await _uploadGoalImage();

      await _goalService.createGoal(
        title: _titleController.text.trim(),
        targetAmount: _targetAmount,
        deadline: _selectedDeadline!,
        savingFrequency: _selectedFrequency,
        imageUrl: imageUrl,
        motivation: _motivationController.text.trim(),
        initialSavedAmount: _initialSavedAmount,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: kGreenBtn,
          content: Text('Meta creada correctamente.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kRed,
          content: Text('No se pudo crear la meta: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      color: kBg,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 28,
        16,
        isMobile ? 16 : 28,
        12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kDark.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: kDark,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 7,
            height: 24,
            decoration: BoxDecoration(
              color: kAmber,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Crear Meta',
              style: TextStyle(
                color: kDark,
                fontWeight: FontWeight.w800,
                fontSize: isMobile ? 22 : 26,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF6E7), Color(0xFFFFF1D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kAmber.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kAmber.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: kDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Define una meta clara y deja que Kybo te diga cuánto debes ahorrar.',
                  style: TextStyle(
                    color: kDark,
                    fontSize: isMobile ? 13.5 : 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Ahora puedes subir una imagen para hacer la meta más visual y motivadora.',
            style: TextStyle(
              color: kGrey,
              fontSize: isMobile ? 12.5 : 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(bool isMobile) {
    final hasImage = _selectedImageBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagen de la meta (opcional)',
          style: TextStyle(
            color: kDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            width: double.infinity,
            height: hasImage ? (isMobile ? 220 : 260) : 170,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color:
                    hasImage ? kAmber.withOpacity(0.45) : Colors.grey.shade200,
                width: hasImage ? 1.3 : 1,
              ),
            ),
            child: hasImage
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.memory(
                          _selectedImageBytes!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImageBytes = null;
                              _selectedImageName = null;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: kAmberLight,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          color: kDark,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Sube una imagen que te motive',
                        style: TextStyle(
                          color: kDark,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ej: la moto, el viaje, la bici o el objetivo que quieres lograr',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kGrey,
                          fontSize: isMobile ? 12.5 : 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(
            color: kDark,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: kGrey,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: kAmber, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: kRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: kRed, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencySelector(bool isMobile) {
    final options = GoalSavingFrequency.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Cada cuánto te gustaría ahorrar?',
          style: TextStyle(
            color: kDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((frequency) {
            final isSelected = frequency == _selectedFrequency;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFrequency = frequency;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? kDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? kDark : Colors.grey.shade200,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: kDark.withOpacity(0.10),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  GoalCalculator.frequencyLabel(frequency),
                  style: TextStyle(
                    color: isSelected ? Colors.white : kDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDeadlineSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fecha límite',
          style: TextStyle(
            color: kDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDeadline,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: kDark,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDeadline == null
                        ? 'Selecciona la fecha límite'
                        : _formatDate(_selectedDeadline!),
                    style: TextStyle(
                      color: _selectedDeadline == null ? kGrey : kDark,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: kGrey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectionCard(bool isMobile) {
    final calculation = _previewCalculation;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: calculation == null
          ? Container(
              key: const ValueKey('empty_projection'),
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 16 : 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                'Completa el monto objetivo y la fecha límite para ver cuánto deberías ahorrar.',
                style: TextStyle(
                  color: kGrey,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            )
          : Container(
              key: const ValueKey('filled_projection'),
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 18 : 20),
              decoration: BoxDecoration(
                color: kDark,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: kDark.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Proyección de ahorro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para cumplir esta meta, deberías ahorrar aproximadamente:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _formatCurrency(calculation.suggestedAmountPerPeriod),
                    style: TextStyle(
                      color: kAmber,
                      fontSize: isMobile ? 28 : 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ' ${GoalCalculator.frequencyLabel(_selectedFrequency).toLowerCase()}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildMiniInfo(
                        icon: Icons.savings_rounded,
                        label: 'Te faltan',
                        value: _formatCurrency(calculation.remainingAmount),
                      ),
                      _buildMiniInfo(
                        icon: Icons.schedule_rounded,
                        label: 'Tiempo restante',
                        value: '${calculation.daysLeft} días',
                      ),
                      _buildMiniInfo(
                        icon: Icons.flag_circle_rounded,
                        label: 'Estado actual',
                        value: GoalCalculator.statusLabel(calculation.status),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMiniInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kAmber),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: kGreenBtn,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kGreenBtn.withOpacity(0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Guardar meta',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isMobile),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 28,
                  8,
                  isMobile ? 16 : 28,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildInfoCard(isMobile),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isMobile ? 16 : 22),
                            decoration: BoxDecoration(
                              color: kCard,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: kDark.withOpacity(0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildImageSection(isMobile),
                                const SizedBox(height: 18),
                                _buildTextField(
                                  controller: _titleController,
                                  label: 'Nombre de la meta',
                                  hint:
                                      'Ej: Viaje a Cartagena, mi moto, fondo de emergencia',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Ingresa un nombre para tu meta.';
                                    }
                                    if (value.trim().length < 3) {
                                      return 'El nombre debe tener al menos 3 caracteres.';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                  prefixIcon: const Icon(
                                    Icons.flag_rounded,
                                    color: kDark,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildTextField(
                                  controller: _targetAmountController,
                                  label: 'Monto objetivo',
                                  hint: 'Ej: 1500000',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  validator: (value) {
                                    final amount = _parseAmount(value ?? '');
                                    if (amount <= 0) {
                                      return 'Ingresa un monto objetivo válido.';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                  prefixIcon: const Icon(
                                    Icons.attach_money_rounded,
                                    color: kDark,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildTextField(
                                  controller: _initialSavedAmountController,
                                  label: '¿Ya llevas algo ahorrado? (opcional)',
                                  hint: 'Ej: 200000',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  validator: (value) {
                                    final amount = _parseAmount(value ?? '');
                                    if (amount < 0) {
                                      return 'El valor no puede ser negativo.';
                                    }
                                    if (_targetAmount > 0 &&
                                        amount > _targetAmount) {
                                      return 'No puede ser mayor al monto objetivo.';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                  prefixIcon: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: kDark,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildDeadlineSelector(),
                                const SizedBox(height: 18),
                                _buildFrequencySelector(isMobile),
                                const SizedBox(height: 18),
                                _buildTextField(
                                  controller: _motivationController,
                                  label: 'Motivación (opcional)',
                                  hint:
                                      'Ej: Quiero lograrlo antes de finalizar el año',
                                  maxLines: 3,
                                  onChanged: (_) => setState(() {}),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(bottom: 44),
                                    child: Icon(
                                      Icons.auto_awesome_rounded,
                                      color: kDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildProjectionCard(isMobile),
                          const SizedBox(height: 20),
                          _buildSaveButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
