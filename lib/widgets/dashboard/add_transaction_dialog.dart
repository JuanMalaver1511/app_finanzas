import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/transaction_model.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/services.dart';

const kPrimary = Color(0xFF6C63FF);
const kBackground = Color(0xFFF5F6FA);
const kCard = Colors.white;

const kIncome = Color(0xFF00C897);
const kExpense = Color(0xFFFF5C5C);

class AddTransactionDialog extends StatefulWidget {
  final Future<void> Function(AppTransaction) onAdd;
  final AppTransaction? initial;

  const AddTransactionDialog({
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
  }

  // ================= FIRESTORE =================
  Stream<List<Map<String, dynamic>>> _categoriesStream() {
    return FirebaseFirestore.instance
        .collection('categories')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  // ================= EMOJI INTELIGENTE =================
  final Map<String, String> keywordEmoji = {
    // comida
    'pizza': '🍕',
    'hamburguesa': '🍔',
    'comida': '🍔',
    'restaurante': '🍽️',
    'cafe': '☕',
    'desayuno': '🥐',

    // transporte
    'uber': '🚗',
    'taxi': '🚗',
    'bus': '🚌',
    'gasolina': '⛽',

    // entretenimiento
    'netflix': '🎬',
    'cine': '🎬',
    'spotify': '🎧',
    'musica': '🎧',

    // salud
    'medico': '💊',
    'farmacia': '💊',
    'hospital': '🏥',

    // compras
    'ropa': '🛍️',
    'zapatos': '👟',

    // hogar
    'arriendo': '🏠',
    'casa': '🏠',
    'luz': '💡',
    'agua': '🚿',

    // ingresos
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

  bool _emojiManual = false;

  void _suggestEmoji(String text) {
    if (_emojiManual) return;

    final t = text.toLowerCase();

    // 🔥 1. buscar por palabras clave
    for (var key in keywordEmoji.keys) {
      if (t.contains(key)) {
        setState(() {
          _selectedEmoji = keywordEmoji[key]!;
        });
        return;
      }
    }

    // 🔥 2. usar categoría como fallback
    if (_selectedCategory != null &&
        categoryEmoji.containsKey(_selectedCategory)) {
      setState(() {
        _selectedEmoji = categoryEmoji[_selectedCategory]!;
      });
      return;
    }

    // 🔥 3. fallback final
    setState(() {
      _selectedEmoji = '💸';
    });
  }

  // ================= EMOJI PICKER =================
  void _pickEmoji() {
    if (kIsWeb) {
      _openEmojiGrid();
    } else {
      showModalBottomSheet(
        context: context,
        builder: (_) => SizedBox(
          height: 320,
          child: EmojiPicker(
            onEmojiSelected: (_, emoji) {
              setState(() => _selectedEmoji = emoji.emoji);
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  void _openEmojiGrid() {
    final emojis = ['🍔', '🍕', '🚗', '🎬', '💊', '🛍️', '🏠', '💼', '💰'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Selecciona un emoji"),
        content: Wrap(
          children: emojis.map((e) {
            return GestureDetector(
              onTap: () {
                setState(() => _selectedEmoji = e);
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(e, style: TextStyle(fontSize: 24)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ================= VALIDACIÓN =================
  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);

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

    await widget.onAdd(AppTransaction(
      id: '',
      title: _titleCtrl.text.trim(),
      category: _selectedCategory!,
      amount: amount,
      isIncome: _isIncome,
      date: _selectedDate,
      emoji: _selectedEmoji,
    ));

    if (mounted) Navigator.pop(context);
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _step == 1 ? _step1() : _step2(),
      ),
    );
  }

  // STEP 1
  Widget _step1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("¿Qué deseas agregar?"),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _card(false, "Gasto", kExpense)),
            const SizedBox(width: 10),
            Expanded(child: _card(true, "Ingreso", kIncome)),
          ],
        ),
      ],
    );
  }

  Widget _card(bool income, String text, Color color) {
    final active = _isIncome == income;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isIncome = income;
          _selectedCategory = null;
          _step = 2;
        });
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
          color: active ? color.withOpacity(0.1) : null,
        ),
        child: Center(child: Text(text)),
      ),
    );
  }

  // STEP 2
  Widget _step2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _pickEmoji,
          child: Text(_selectedEmoji, style: TextStyle(fontSize: 40)),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _titleCtrl,
          decoration: InputDecoration(
            labelText: "Descripción",
          ),
          onChanged: _suggestEmoji,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: "Monto",
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<Map<String, dynamic>>>(
          key: ValueKey(_isIncome),
          stream: _categoriesStream(),
          builder: (_, snapshot) {
            final categories = (snapshot.data ?? [])
                .where((c) => c['type'] == (_isIncome ? 'income' : 'expense'))
                .toList();

            return DropdownButtonFormField<String>(
              value: categories.any((c) => c['name'] == _selectedCategory)
                  ? _selectedCategory
                  : null,
              hint: Text("Categoría"),
              items: categories.map<DropdownMenuItem<String>>((c) {
                return DropdownMenuItem(
                  value: c['name'],
                  child: Text(c['name']),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            );
          },
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: Text("Guardar"),
        ),
      ],
    );
  }
}
