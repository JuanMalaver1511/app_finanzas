import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/transaction_model.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

const kPrimary = Color(0xFFFFBB4E);
const kBackground = Color(0xFFF5F6FA);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF8A8A9A);

const kIncome = Color(0xFF00C897);
const kExpense = Color(0xFFFF5C5C);

class AddTransactionDialog extends StatefulWidget {
  final Future<void> Function(AppTransaction) onAdd;
  final AppTransaction? initial;

  const AddTransactionDialog({
    super.key,
    required this.onAdd,
    this.initial,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  late bool _isIncome;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String _selectedEmoji = '❓';

  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  bool _loading = false;
  int _step = 1;
  bool _emojiManual = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.initial;

    _isIncome = tx?.isIncome ?? false;
    _selectedCategory = tx?.category;
    _selectedDate = tx?.date ?? DateTime.now();
    _selectedEmoji = tx?.emoji ?? '❓';

    _titleCtrl.text = tx?.title ?? '';
    _amountCtrl.text = tx != null ? tx.amount.toStringAsFixed(0) : '';

    if (widget.initial != null) {
      _step = 2;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _categoriesStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final globalStream =
        FirebaseFirestore.instance.collection('categories').snapshots();

    return globalStream.asyncMap((globalSnap) async {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('categories')
          .get();

      final globalCats = globalSnap.docs.map((d) => d.data()).toList();
      final userCats = userSnap.docs.map((d) => d.data()).toList();

      final merged = [...globalCats, ...userCats];

      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];

      for (final cat in merged) {
        final key =
            '${cat['name']?.toString().trim().toLowerCase()}_${cat['type']}';
        if (!seen.contains(key)) {
          seen.add(key);
          unique.add(cat);
        }
      }

      return unique;
    });
  }

  final Map<String, String> keywordEmoji = {
    'pizza': '🍕',
    'hamburguesa': '🍔',
    'comida': '🍔',
    'restaurante': '🍽️',
    'cafe': '☕',
    'desayuno': '🥐',
    'uber': '🚗',
    'taxi': '🚗',
    'bus': '🚌',
    'gasolina': '⛽',
    'netflix': '🎬',
    'cine': '🎬',
    'spotify': '🎧',
    'musica': '🎧',
    'medico': '💊',
    'farmacia': '💊',
    'hospital': '🏥',
    'ropa': '🛍️',
    'zapatos': '👟',
    'arriendo': '🏠',
    'casa': '🏠',
    'luz': '💡',
    'agua': '🚿',
    'salario': '💰',
    'trabajo': '💼',
    'pago': '💰',
  };

  final Map<String, String> categoryEmoji = {
    'Alimentación': '🍔',
    'Transporte': '🚗',
    'Entretenimiento': '🎬',
    'Salud': '💊',
    'Hogar': '🏠',
    'Trabajo': '💼',
    'Ingreso': '💰',
  };

  void _suggestEmoji(String text) {
    if (_emojiManual) return;

    final t = text.toLowerCase();

    for (final key in keywordEmoji.keys) {
      if (t.contains(key)) {
        setState(() {
          _selectedEmoji = keywordEmoji[key]!;
        });
        return;
      }
    }

    if (_selectedCategory != null &&
        categoryEmoji.containsKey(_selectedCategory)) {
      setState(() {
        _selectedEmoji = categoryEmoji[_selectedCategory]!;
      });
      return;
    }

    setState(() {
      _selectedEmoji = _isIncome ? '💰' : '💸';
    });
  }

  void _pickEmoji() {
    if (kIsWeb) {
      _openEmojiGrid();
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        showDragHandle: true,
        builder: (_) => SizedBox(
          height: 340,
          child: EmojiPicker(
            onEmojiSelected: (_, emoji) {
              setState(() {
                _selectedEmoji = emoji.emoji;
                _emojiManual = true;
              });
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  void _openEmojiGrid() {
    final emojis = [
      '🍔',
      '🍕',
      '🚗',
      '🎬',
      '💊',
      '🛍️',
      '🏠',
      '💼',
      '💰',
      '📚',
      '🎁',
      '🧾',
      '✈️',
      '🚌',
      '☕',
      '💳',
      '🛒',
      '⚽',
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          "Selecciona un emoji",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: emojis.map((e) {
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  _selectedEmoji = e;
                  _emojiManual = true;
                });
                Navigator.pop(context);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    e,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Seleccionar fecha',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kPrimary,
            onPrimary: Colors.white,
            onSurface: kDark,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));

    if (_titleCtrl.text.trim().isEmpty) {
      _error("Escribe una descripción");
      return;
    }

    if (amount == null || amount <= 0) {
      _error("Monto inválido");
      return;
    }

    if (_selectedCategory == null) {
      _error("Selecciona una categoría");
      return;
    }

    setState(() => _loading = true);

    try {
      await widget.onAdd(
        AppTransaction(
          id: widget.initial?.id ?? '',
          title: _titleCtrl.text.trim(),
          category: _selectedCategory!,
          amount: amount,
          isIncome: _isIncome,
          date: _selectedDate,
          emoji: _selectedEmoji,
        ),
      );

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _error(String msg) {
    _showToast(msg);
  }

  void _showToast(String message, {bool success = false}) {
    final overlay = Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, -20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    success ? const Color(0xFF1E8E3E) : const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    success
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  String _formatPreviewAmount() {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: 'COP ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _openCreateCategoryDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.add_box_rounded,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nueva categoría',
                          style: TextStyle(
                            color: kDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Crea una categoría personalizada para tus movimientos',
                          style: TextStyle(
                            color: kGrey,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Mascotas',
                    labelText: 'Nombre de la categoría',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.edit_rounded),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kDark,
                        side: BorderSide(color: Colors.black.withOpacity(0.08)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = controller.text.trim();
                        if (name.isEmpty) {
                          _error("Escribe un nombre para la categoría");
                          return;
                        }

                        final uid = FirebaseAuth.instance.currentUser!.uid;
                        final nameLower = name.toLowerCase().trim();

                        final existingGlobal = await FirebaseFirestore.instance
                            .collection('categories')
                            .where('nameLower', isEqualTo: nameLower)
                            .get();

                        final existingUser = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('categories')
                            .where('nameLower', isEqualTo: nameLower)
                            .get();

                        if (existingGlobal.docs.isNotEmpty ||
                            existingUser.docs.isNotEmpty) {
                          _error("Ya existe una categoría con ese nombre");
                          return;
                        }

                        const categoryPalette = [
                          '#6366F1',
                          '#E11D48',
                          '#84CC16',
                          '#06B6D4',
                          '#1F2937',
                          '#374151',
                          '#9CA3AF',
                          '#F43F5E',
                          '#22C55E',
                          '#EAB308',
                          '#FB7185',
                          '#C084FC',
                          '#67E8F9',
                          '#A3E635'
                        ];

                        final color = categoryPalette[
                            DateTime.now().millisecondsSinceEpoch %
                                categoryPalette.length];

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('categories')
                            .add({
                          'name': name,
                          'nameLower': nameLower,
                          'type': _isIncome ? 'income' : 'expense',
                          'isDefault': false,
                          'color': color,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        if (!mounted) return;

                        setState(() {
                          _selectedCategory = name;
                        });

                        _suggestEmoji(name);

                        Navigator.pop(context);
                        _showToast("Categoría creada correctamente",
                            success: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Guardar',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: kBackground,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _step == 1 ? _step1(isEdit) : _step2(isEdit),
          ),
        ),
      ),
    );
  }

  Widget _step1(bool isEdit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _topBar(
          title: isEdit ? "Editar movimiento" : "Nuevo movimiento",
          subtitle: "Selecciona el tipo de transacción",
          showClose: true,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nuevo movimiento",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Selecciona si deseas registrar un ingreso o un gasto",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _typeCard(
                income: false,
                title: "Gasto",
                subtitle: "Salidas de dinero",
                color: kExpense,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _typeCard(
                income: true,
                title: "Ingreso",
                subtitle: "Entradas de dinero",
                color: kIncome,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _typeCard({
    required bool income,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    final active = _isIncome == income;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        setState(() {
          _isIncome = income;
          _selectedCategory = null;
          _step = 2;
          if (!_emojiManual) {
            _selectedEmoji = income ? '💰' : '💸';
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 145,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : kCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? color : Colors.black.withOpacity(0.05),
            width: active ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(active ? 0.16 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: active ? color.withOpacity(0.18) : kBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: kDark,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: kGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step2(bool isEdit) {
    final actionColor = _isIncome ? kIncome : kExpense;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _topBar(
            title: isEdit ? "Editar movimiento" : "Nuevo movimiento",
            subtitle: _isIncome ? "Registrar ingreso" : "Registrar gasto",
            showBack: true,
            onBack: () {
              setState(() => _step = 1);
            },
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _pickEmoji,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: actionColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            _selectedEmoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleCtrl.text.trim().isEmpty
                                ? "Sin descripción"
                                : _titleCtrl.text.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kDark,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: actionColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              _isIncome ? "Ingreso" : "Gasto",
                              style: TextStyle(
                                color: actionColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (_amountCtrl.text.trim().isEmpty
                                    ? (_isIncome ? "+ " : "- ")
                                    : '${_isIncome ? "+ " : "- "}${_formatPreviewAmount()}')
                                .trim(),
                            style: TextStyle(
                              color: actionColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                _sectionTitle("Información del movimiento"),
                const SizedBox(height: 14),
                _modernField(
                  child: TextField(
                    controller: _titleCtrl,
                    onChanged: (value) {
                      _suggestEmoji(value);
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Ej: Pago del arriendo",
                      labelText: "Descripción",
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _modernField(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Ej: 120000",
                      labelText: "Monto",
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<Map<String, dynamic>>>(
                  key: ValueKey(_isIncome),
                  stream: _categoriesStream(),
                  builder: (_, snapshot) {
                    final categories = (snapshot.data ?? [])
                        .where((c) =>
                            c['type'] == (_isIncome ? 'income' : 'expense'))
                        .toList();

                    final normalizedSelected = _selectedCategory?.trim();

                    final selectedValue = categories.any(
                      (c) =>
                          (c['name'] ?? '').toString().trim() ==
                          normalizedSelected,
                    )
                        ? normalizedSelected
                        : null;

                    return _modernField(
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: selectedValue,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              labelText: "Categoría",
                              prefixIcon: Icon(Icons.grid_view_rounded),
                            ),
                            hint: const Text("Selecciona una categoría"),
                            items:
                                categories.map<DropdownMenuItem<String>>((c) {
                              final name = (c['name'] ?? '').toString().trim();
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedCategory = v?.trim();
                              });
                              _suggestEmoji(_titleCtrl.text);
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _openCreateCategoryDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Crear nueva categoría'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: kBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: kGrey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Fecha",
                                style: TextStyle(
                                  color: kGrey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                                style: const TextStyle(
                                  color: kDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: kGrey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kDark,
                    side: BorderSide(color: Colors.black.withOpacity(0.08)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : Text(
                          isEdit
                              ? "Actualizar movimiento"
                              : "Guardar movimiento",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topBar({
    required String title,
    required String subtitle,
    bool showBack = false,
    bool showClose = false,
    VoidCallback? onBack,
  }) {
    return Row(
      children: [
        if (showBack)
          _circleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack ?? () {},
          ),
        if (showBack) const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: kGrey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (showClose)
          _circleIconButton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.pop(context),
          ),
      ],
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Icon(icon, color: kDark, size: 18),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: kDark,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _modernField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: child,
    );
  }
}
