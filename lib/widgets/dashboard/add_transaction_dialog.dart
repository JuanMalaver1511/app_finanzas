import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';

const kAmber = Color(0xFFFFBB4E);
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF8A8A9A);
const kGreen = Color(0xFF1D7E45);
const kGreenBtn = Color(0xFF27AE60);
const kRed = Color(0xFFE74C3C);

class AddTransactionDialog extends StatefulWidget {
  final Future<void> Function(AppTransaction) onAdd;
  const AddTransactionDialog({required this.onAdd});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  bool _isIncome = false;
  bool _loading = false;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  final List<String> _expenseCategories = [
    'Alimentación',
    'Transporte',
    'Entretenimiento',
    'Salud',
    'Educación',
    'Hogar',
    'Ropa',
    'Servicios',
    'Otros',
  ];
  final List<String> _incomeCategories = ['Ingreso', 'Trabajo', 'Otros'];

  List<String> get _categories =>
      _isIncome ? _incomeCategories : _expenseCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: kAmber),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (_titleCtrl.text.trim().isEmpty) {
      _showError('Ingresa una descripción');
      return;
    }
    if (amount == null || amount <= 0) {
      _showError('Ingresa un monto válido');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Selecciona una categoría');
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.onAdd(AppTransaction(
        id: '',
        title: _titleCtrl.text.trim(),
        category: _selectedCategory!,
        amount: amount,
        isIncome: _isIncome,
        date: _selectedDate,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showError('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: kRed),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      // ✅ En móvil ocupa casi toda la pantalla
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 40,
        vertical: isMobile ? 20 : 40,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Agregar transacción',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: kDark)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: kGrey),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Toggle Gasto / Ingreso
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isIncome = false;
                        _selectedCategory = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 44,
                        decoration: BoxDecoration(
                          color: !_isIncome ? kRed : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: !_isIncome ? kRed : Colors.grey[300]!),
                        ),
                        alignment: Alignment.center,
                        child: Text('Gasto',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: !_isIncome ? Colors.white : kGrey,
                            )),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isIncome = true;
                        _selectedCategory = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isIncome ? kGreen : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _isIncome ? kGreen : Colors.grey[300]!),
                        ),
                        alignment: Alignment.center,
                        child: Text('Ingreso',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isIncome ? Colors.white : kGrey,
                            )),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('Descripción',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: kDark)),
              const SizedBox(height: 8),
              _Field(
                  controller: _titleCtrl,
                  hint: 'Ej: Compra de comida o Venta freelance'),
              const SizedBox(height: 14),

              const Text('Monto',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: kDark)),
              const SizedBox(height: 8),
              _Field(
                controller: _amountCtrl,
                hint: '0.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 14),

              const Text('Categoría',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: kDark)),
              const SizedBox(height: 8),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    hint: const Text('Seleccione una categoría',
                        style: TextStyle(color: kGrey, fontSize: 14)),
                    icon: const Icon(Icons.keyboard_arrow_down, color: kGrey),
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        color: _catColor(cat),
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(cat,
                                      style: const TextStyle(
                                          fontSize: 14, color: kDark)),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text('Fecha',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: kDark)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDate(_selectedDate),
                          style: const TextStyle(fontSize: 14, color: kDark)),
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: kGrey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreenBtn,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Agregar',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── INPUT REUTILIZABLE ─────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: kDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kGrey),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

Color _catColor(String cat) {
  switch (cat) {
    case 'Alimentación':
      return Colors.green;
    case 'Transporte':
      return Colors.blue;
    case 'Entretenimiento':
      return Colors.purple;
    case 'Salud':
      return Colors.red;
    case 'Educación':
      return Colors.orange;
    case 'Hogar':
      return Colors.teal;
    case 'Ropa':
      return Colors.pink;
    case 'Servicios':
      return Colors.indigo;
    default:
      return Colors.grey;
  }
}