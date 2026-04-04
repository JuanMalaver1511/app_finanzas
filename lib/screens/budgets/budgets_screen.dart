import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

const kPrimary = Color(0xFFFFBB4E);
const kBackground = Color(0xFFF5F6FA);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF8A8A9A);
const kSuccess = Color(0xFF00C897);
const kDanger = Color(0xFFFF5C5C);
const kWarning = Color(0xFFF59E0B);
const kInfo = Color(0xFF3B82F6);

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  late final NotificationService _notificationService;

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'es_CO',
    symbol: 'COP ',
    decimalDigits: 0,
  );

  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _savingKeys = {};

  bool _loading = true;
  bool _financeDialogShown = false;
  bool _missingBudgetDialogShown = false;
  bool _categoryNotificationSyncRunning = false;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  List<Map<String, dynamic>> _categories = [];
  Map<String, Map<String, dynamic>> _budgetsMap = {};
  Map<String, double> _spentMap = {};
  Map<String, dynamic>? _financeProfile;

  String? _expandedCategoryKey;

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  final List<String> _categoryPalette = const [
    '#6366F1',
    '#E11D48',
    '#84CC16',
    '#06B6D4',
    '#F59E0B',
    '#8B5CF6',
    '#14B8A6',
    '#F97316',
  ];

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(uid);
    _loadData();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _monthKey => DateFormat('yyyy-MM').format(_selectedMonth);

  DateTime get _monthStart =>
      DateTime(_selectedMonth.year, _selectedMonth.month);

  DateTime get _monthEnd =>
      DateTime(_selectedMonth.year, _selectedMonth.month + 1);

  bool get _hasFinancialProfile {
    if (_financeProfile == null) return false;
    return _financeProfile!['financialProfileCompleted'] == true &&
        ((_financeProfile!['monthlyIncome'] as num?)?.toDouble() ?? 0) > 0;
  }

  double get _monthlyIncome {
    return (_financeProfile?['monthlyIncome'] as num?)?.toDouble() ?? 0;
  }

  String get _incomeType {
    return (_financeProfile?['incomeType'] ?? 'fixed').toString();
  }

  int? get _payday {
    final value = _financeProfile?['payday'];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String _normalizeCategory(String value) {
    return value.trim().toLowerCase();
  }

  DateTime _previousMonth(DateTime date) {
    return DateTime(date.year, date.month - 1);
  }

  String _monthKeyFromDate(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  Future<bool> _ensureMonthBudgetExists() async {
    final currentMonthRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(_monthKey)
        .collection('items');

    final currentSnap = await currentMonthRef.get();

    /// Si ya existe presupuesto para el mes actual, no hacer nada
    if (currentSnap.docs.isNotEmpty) {
      return false;
    }

    final previousMonth = _previousMonth(_selectedMonth);
    final previousMonthKey = _monthKeyFromDate(previousMonth);

    final previousSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(previousMonthKey)
        .collection('items')
        .get();

    /// Si el mes anterior tampoco tiene datos, no clonamos nada
    if (previousSnap.docs.isEmpty) {
      return false;
    }

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in previousSnap.docs) {
      final data = doc.data();

      final newDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(_monthKey)
          .collection('items')
          .doc(doc.id);

      batch.set(newDocRef, {
        ...data,
        'monthKey': _monthKey,
        'copiedFromMonth': previousMonthKey,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return true;
  }

  Future<void> _showMissingBudgetDialog() async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: kWarning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: kWarning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Aún no has creado tus presupuestos',
                      style: TextStyle(
                        color: kDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Todavía no has definido presupuestos para ${_monthName(_selectedMonth.month)}. Configúralos ahora para llevar mejor control de tus gastos.',
                style: const TextStyle(
                  color: kGrey,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Después',
                      style: TextStyle(color: kGrey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: kDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(fontWeight: FontWeight.w800),
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

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    final selectedMonth = _selectedMonth;
    final monthKey = DateFormat('yyyy-MM').format(selectedMonth);
    final monthStart = DateTime(selectedMonth.year, selectedMonth.month);
    final monthEnd = DateTime(selectedMonth.year, selectedMonth.month + 1);

    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('settings')
            .doc('finance')
            .get(),
        FirebaseFirestore.instance.collection('categories').get(),
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('categories')
            .get(),
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
            .where('date', isLessThan: Timestamp.fromDate(monthEnd))
            .get(),
      ]);

      final financeSnap = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final globalSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final userSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;
      bool copiedFromPreviousMonth = false;
      final transactionsSnap =
          results[3] as QuerySnapshot<Map<String, dynamic>>;

      final budgetsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(monthKey)
          .collection('items')
          .get();

      final global = globalSnap.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
          'source': 'global',
        };
      }).toList();

      final user = userSnap.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
          'source': 'user',
        };
      }).toList();

      final merged = [...global, ...user]
          .where((c) => (c['type'] ?? '').toString().trim() == 'expense')
          .toList();

      final uniqueByName = <String, Map<String, dynamic>>{};

      for (final cat in merged) {
        final rawName = (cat['name'] ?? '').toString().trim();
        if (rawName.isEmpty) continue;

        final key = _normalizeCategory(rawName);

        if (!uniqueByName.containsKey(key)) {
          uniqueByName[key] = {
            ...cat,
            'budgetKey': key,
            'displayName': rawName,
          };
        } else {
          final existing = uniqueByName[key]!;
          final bool currentIsUser = cat['source'] == 'user';
          final bool existingIsGlobal = existing['source'] == 'global';

          if (currentIsUser && existingIsGlobal) {
            uniqueByName[key] = {
              ...cat,
              'budgetKey': key,
              'displayName': rawName,
            };
          }
        }
      }

      final budgets = <String, Map<String, dynamic>>{};
      for (final doc in budgetsSnap.docs) {
        final data = doc.data();
        final key = (data['categoryKey'] ?? '').toString().trim();
        if (key.isNotEmpty) {
          budgets[key] = data;
        }
      }

      final spent = <String, double>{};

      for (final doc in transactionsSnap.docs) {
        final data = doc.data();

        final bool isIncome =
            data['isIncome'] == true || data['type'] == 'income';

        if (isIncome) continue;

        final rawCategory =
            (data['categoryName'] ?? data['category'] ?? '').toString().trim();

        if (rawCategory.isEmpty) continue;

        final key = _normalizeCategory(rawCategory);
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;

        spent[key] = (spent[key] ?? 0) + amount;
      }

      final categories = uniqueByName.values.toList()
        ..sort((a, b) {
          final aKey = (a['budgetKey'] ?? '').toString();
          final bKey = (b['budgetKey'] ?? '').toString();

          final aPriority = _priorityForCategory(
            planned: (budgets[aKey]?['planned'] as num?)?.toDouble() ?? 0,
            spent: spent[aKey] ?? 0,
          );

          final bPriority = _priorityForCategory(
            planned: (budgets[bKey]?['planned'] as num?)?.toDouble() ?? 0,
            spent: spent[bKey] ?? 0,
          );

          if (aPriority != bPriority) {
            return aPriority.compareTo(bPriority);
          }

          final aName = (a['displayName'] ?? '').toString().toLowerCase();
          final bName = (b['displayName'] ?? '').toString().toLowerCase();
          return aName.compareTo(bName);
        });

      final validKeys = categories
          .map((cat) => (cat['budgetKey'] ?? '').toString())
          .where((key) => key.isNotEmpty)
          .toSet();

      final keysToRemove =
          _controllers.keys.where((key) => !validKeys.contains(key)).toList();

      for (final key in keysToRemove) {
        _controllers[key]?.dispose();
        _controllers.remove(key);
      }

      for (final cat in categories) {
        final key = (cat['budgetKey'] ?? '').toString();
        if (key.isEmpty) continue;

        final planned = (budgets[key]?['planned'] as num?)?.toDouble();

        _controllers.putIfAbsent(key, () => TextEditingController());

        if (planned != null && planned > 0) {
          _controllers[key]!.text = planned.toStringAsFixed(0);
        } else {
          _controllers[key]!.text = '';
        }
      }

      if (!mounted) return;

      setState(() {
        _financeProfile = financeSnap.data();
        _categories = categories;
        _budgetsMap = budgets;
        _spentMap = spent;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final copied = await _ensureMonthBudgetExists();

        if (!mounted || !copied) return;

        _showToast(
          'Presupuestos de ${_monthName(_selectedMonth.month)} creados automáticamente',
          success: true,
        );

        final previousMonthKey =
            _monthKeyFromDate(_previousMonth(_selectedMonth));

        await _notificationService.createUnique(
          dedupeKey: 'budget_auto_created_${_monthKey}_from_$previousMonthKey',
          title: 'Presupuesto creado automáticamente',
          message:
              'Tus presupuestos fueron copiados del mes anterior automáticamente.',
          type: 'budget_auto_created',
          priority: 'low',
          source: 'system',
        );

        if (mounted) {
          _loadData();
        }
      });

      _queueCategoryNotificationSync(
        categories: categories,
        budgets: budgets,
        spent: spent,
        monthKey: monthKey,
      );

      if (_isCurrentMonth &&
          !copiedFromPreviousMonth &&
          budgetsSnap.docs.isEmpty &&
          mounted) {
        final dedupeKey = 'month_without_budget_$monthKey';

        await _notificationService.createUnique(
          dedupeKey: dedupeKey,
          title: 'Aún no has creado tus presupuestos',
          message:
              'Todavía no has definido presupuestos para ${_monthName(selectedMonth.month)}. Configúralos para tener mejor control de tus gastos.',
          type: 'month_without_budget',
          priority: 'medium',
          source: 'system',
        );

        if (!_missingBudgetDialogShown) {
          _missingBudgetDialogShown = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showMissingBudgetDialog();
            }
          });
        }
      }

      if (!_hasFinancialProfile && !_financeDialogShown) {
        _financeDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showFinancialProfileDialog(forceOpen: true);
          }
        });
      }
    } catch (e, st) {
      debugPrint('Error al cargar presupuestos: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _queueCategoryNotificationSync({
    required List<Map<String, dynamic>> categories,
    required Map<String, Map<String, dynamic>> budgets,
    required Map<String, double> spent,
    required String monthKey,
  }) {
    if (_categoryNotificationSyncRunning) return;

    _categoryNotificationSyncRunning = true;

    Future.microtask(() async {
      try {
        await _syncCategoryNotifications(
          categories: categories,
          budgets: budgets,
          spent: spent,
          monthKey: monthKey,
        );
      } catch (e) {
        debugPrint('Error sincronizando notificaciones por categoría: $e');
      } finally {
        _categoryNotificationSyncRunning = false;
      }
    });
  }

  Future<void> _syncCategoryNotifications({
    required List<Map<String, dynamic>> categories,
    required Map<String, Map<String, dynamic>> budgets,
    required Map<String, double> spent,
    required String monthKey,
  }) async {
    for (final cat in categories) {
      final categoryKey = (cat['budgetKey'] ?? '').toString().trim();
      final categoryName = (cat['displayName'] ?? '').toString().trim();

      if (categoryKey.isEmpty || categoryName.isEmpty) continue;

      final planned =
          (budgets[categoryKey]?['planned'] as num?)?.toDouble() ?? 0;
      final spentAmount = spent[categoryKey] ?? 0;

      await _syncSingleCategoryNotification(
        monthKey: monthKey,
        categoryKey: categoryKey,
        categoryName: categoryName,
        planned: planned,
        spentAmount: spentAmount,
      );
    }
  }

  Future<void> _syncSingleCategoryNotification({
    required String monthKey,
    required String categoryKey,
    required String categoryName,
    required double planned,
    required double spentAmount,
  }) async {
    final missingKey = 'budget_missing_with_spend_${monthKey}_$categoryKey';
    final exceededKey = 'budget_exceeded_${monthKey}_$categoryKey';
    final warningKey = 'budget_warning_${monthKey}_$categoryKey';

    if (spentAmount <= 0) {
      await _removeNotificationsByDedupeKeys([
        missingKey,
        exceededKey,
        warningKey,
      ]);
      return;
    }

    if (planned <= 0) {
      await _removeNotificationsByDedupeKeys([exceededKey, warningKey]);

      await _notificationService.createUnique(
        dedupeKey: missingKey,
        title: 'Gastaste sin presupuesto',
        message:
            'Ya registraste gastos en $categoryName pero no tienes presupuesto definido.',
        type: 'budget_missing_with_spend',
        priority: 'medium',
        source: 'system',
      );
      return;
    }

    if (spentAmount >= planned) {
      await _removeNotificationsByDedupeKeys([missingKey, warningKey]);

      await _notificationService.createUnique(
        dedupeKey: exceededKey,
        title: 'Presupuesto excedido',
        message: 'Superaste el presupuesto en $categoryName.',
        type: 'budget_exceeded',
        priority: 'high',
        source: 'system',
      );
      return;
    }

    if (spentAmount >= planned * 0.8) {
      await _removeNotificationsByDedupeKeys([missingKey, exceededKey]);

      await _notificationService.createUnique(
        dedupeKey: warningKey,
        title: 'Estás cerca del límite',
        message: 'Ya casi alcanzas el presupuesto en $categoryName.',
        type: 'budget_warning',
        priority: 'medium',
        source: 'system',
      );
      return;
    }

    await _removeNotificationsByDedupeKeys([
      missingKey,
      exceededKey,
      warningKey,
    ]);
  }

  Future<void> _removeNotificationsByDedupeKeys(List<String> dedupeKeys) async {
    for (final dedupeKey in dedupeKeys) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('dedupeKey', isEqualTo: dedupeKey)
          .get();

      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }
  }

  int _priorityForCategory({
    required double planned,
    required double spent,
  }) {
    if (planned <= 0) return 0; // sin definir
    final progress = spent / planned;
    if (progress >= 1) return 1; // excedido
    if (progress >= 0.8) return 2; // alerta
    return 3; // normal
  }

  Future<void> _saveFinancialProfile({
    required double monthlyIncome,
    required String incomeType,
    int? payday,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('finance')
        .set({
      'monthlyIncome': monthlyIncome,
      'incomeType': incomeType,
      'payday': payday,
      'financialProfileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _financeProfile = {
      'monthlyIncome': monthlyIncome,
      'incomeType': incomeType,
      'payday': payday,
      'financialProfileCompleted': true,
    };

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showFinancialProfileDialog({bool forceOpen = false}) async {
    final incomeController = TextEditingController(
      text: _monthlyIncome > 0 ? _monthlyIncome.toStringAsFixed(0) : '',
    );
    final paydayController = TextEditingController(
      text: _payday != null ? _payday.toString() : '',
    );

    String selectedIncomeType = _incomeType;
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: !forceOpen,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return WillPopScope(
              onWillPop: () async => !forceOpen,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuremos tu base mensual',
                      style: TextStyle(
                        color: kDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      forceOpen
                          ? 'Antes de usar presupuestos, necesitamos conocer tu ingreso mensual base.'
                          : 'Actualiza tu ingreso mensual para que los presupuestos sean más claros y útiles.',
                      style: const TextStyle(
                        color: kGrey,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      _dialogSectionTitle('1. ¿Cómo recibes tus ingresos?'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _incomeTypeCard(
                              title: 'Ingreso fijo',
                              subtitle: 'Recibo casi el mismo valor cada mes',
                              icon: Icons.payments_outlined,
                              selected: selectedIncomeType == 'fixed',
                              onTap: () {
                                setLocalState(() {
                                  selectedIncomeType = 'fixed';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _incomeTypeCard(
                              title: 'Ingreso variable',
                              subtitle: 'No siempre recibo el mismo valor',
                              icon: Icons.show_chart_rounded,
                              selected: selectedIncomeType == 'variable',
                              onTap: () {
                                setLocalState(() {
                                  selectedIncomeType = 'variable';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _dialogSectionTitle(
                          '2. ¿Cuál es tu ingreso mensual actual?'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: incomeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: kBackground,
                          hintText: 'Ej: 2500000',
                          labelText: 'Ingreso mensual',
                          prefixIcon: const Icon(Icons.attach_money_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Este valor será la base para organizar mejor tus presupuestos.',
                          style: TextStyle(
                            color: kGrey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _dialogSectionTitle(
                          '3. ¿Qué día sueles recibirlo? (opcional)'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: paydayController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          LengthLimitingTextInputFormatter(2),
                        ],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: kBackground,
                          hintText: 'Ej: 30',
                          labelText: 'Día de pago',
                          prefixIcon: const Icon(Icons.calendar_today_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Esto nos puede servir después para recordatorios y proyecciones.',
                          style: TextStyle(
                            color: kGrey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (!forceOpen)
                    TextButton(
                      onPressed:
                          saving ? null : () => Navigator.pop(dialogContext),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: kGrey),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final monthlyIncome = double.tryParse(
                              incomeController.text.trim().replaceAll(
                                    RegExp(r'[^0-9]'),
                                    '',
                                  ),
                            );

                            final paydayRaw = paydayController.text.trim();
                            final payday = paydayRaw.isEmpty
                                ? null
                                : int.tryParse(paydayRaw);

                            if (monthlyIncome == null || monthlyIncome <= 0) {
                              _showToast('Ingresa un valor mensual válido');
                              return;
                            }

                            if (payday != null && (payday < 1 || payday > 31)) {
                              _showToast(
                                  'El día de pago debe estar entre 1 y 31');
                              return;
                            }

                            setLocalState(() => saving = true);

                            try {
                              await _saveFinancialProfile(
                                monthlyIncome: monthlyIncome,
                                incomeType: selectedIncomeType,
                                payday: payday,
                              );

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }

                              if (mounted) {
                                _showToast(
                                  'Base financiera guardada',
                                  success: true,
                                );
                              }
                            } catch (e) {
                              _showToast('No se pudo guardar la información');
                            } finally {
                              if (dialogContext.mounted) {
                                setLocalState(() => saving = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: kDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kDark,
                              ),
                            )
                          : const Text(
                              'Guardar y continuar',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _dialogSectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: kDark,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _incomeTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? kPrimary.withOpacity(0.12) : kBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? kPrimary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? kDark : kGrey,
              size: 24,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? kDark : kGrey,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kGrey,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBudget({
    required Map<String, dynamic> category,
  }) async {
    final categoryId = (category['id'] ?? '').toString().trim();
    final categoryName = (category['displayName'] ?? '').toString().trim();
    final categoryKey = (category['budgetKey'] ?? '').toString().trim();
    final colorHex = (category['color'] ?? '#CBD5E1').toString().trim();
    final controller = _controllers[categoryKey];

    if (categoryId.isEmpty || categoryName.isEmpty || categoryKey.isEmpty) {
      _showToast('Categoría inválida');
      return;
    }

    if (controller == null) return;

    final raw = controller.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(raw);

    if (amount == null || amount <= 0) {
      _showToast('Ingresa un monto válido');
      return;
    }

    setState(() => _savingKeys.add(categoryKey));

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(_monthKey)
          .collection('items')
          .doc(categoryId)
          .set({
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryKey': categoryKey,
        'planned': amount,
        'color': colorHex,
        'type': 'expense',
        'isActive': true,
        'period': 'monthly',
        'monthKey': _monthKey,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final missingBudgetSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('dedupeKey', isEqualTo: 'month_without_budget_$_monthKey')
          .limit(1)
          .get();

      for (final doc in missingBudgetSnap.docs) {
        await doc.reference.delete();
      }

      _budgetsMap[categoryKey] = {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryKey': categoryKey,
        'planned': amount,
        'color': colorHex,
        'type': 'expense',
        'isActive': true,
        'period': 'monthly',
        'monthKey': _monthKey,
      };

      _queueCategoryNotificationSync(
        categories: _categories,
        budgets: _budgetsMap,
        spent: _spentMap,
        monthKey: _monthKey,
      );

      if (!mounted) return;
      _showToast('Presupuesto guardado', success: true);
      setState(() {
        _expandedCategoryKey = null;
      });
    } catch (e) {
      _showToast('No se pudo guardar el presupuesto');
    } finally {
      if (mounted) {
        setState(() => _savingKeys.remove(categoryKey));
      }
    }
  }

  Future<void> _deleteBudget({
    required Map<String, dynamic> category,
  }) async {
    final categoryId = (category['id'] ?? '').toString().trim();
    final categoryKey = (category['budgetKey'] ?? '').toString().trim();
    final categoryName = (category['displayName'] ?? '').toString().trim();

    if (categoryId.isEmpty || categoryKey.isEmpty) return;

    setState(() => _savingKeys.add(categoryKey));

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(_monthKey)
          .collection('items')
          .doc(categoryId)
          .delete();

      _budgetsMap.remove(categoryKey);
      _controllers[categoryKey]?.clear();

      await _syncSingleCategoryNotification(
        monthKey: _monthKey,
        categoryKey: categoryKey,
        categoryName: categoryName,
        planned: 0,
        spentAmount: _spentMap[categoryKey] ?? 0,
      );

      if (!mounted) return;
      _showToast('Presupuesto eliminado', success: true);
      setState(() {
        if (_expandedCategoryKey == categoryKey) {
          _expandedCategoryKey = null;
        }
      });
    } catch (e) {
      _showToast('No se pudo eliminar el presupuesto');
    } finally {
      if (mounted) {
        setState(() => _savingKeys.remove(categoryKey));
      }
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) return const Color(0xFFCBD5E1);

    final clean = hex.replaceAll('#', '').trim();

    if (clean.length != 6) return const Color(0xFFCBD5E1);

    try {
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFFCBD5E1);
    }
  }

  String _formatMoney(num value) => _currency.format(value);

  double _plannedFor(String key) {
    return (_budgetsMap[key]?['planned'] as num?)?.toDouble() ?? 0;
  }

  double _spentFor(String key) {
    return _spentMap[key] ?? 0;
  }

  double _remainingFor(String key) {
    return _plannedFor(key) - _spentFor(key);
  }

  double _progressFor(String key) {
    final planned = _plannedFor(key);
    final spent = _spentFor(key);

    if (planned <= 0) return 0;
    return spent / planned;
  }

  String _statusFor(String key) {
    final progress = _progressFor(key);

    if (_plannedFor(key) <= 0) return 'Sin definir';
    if (progress >= 1) return 'Excedido';
    if (progress >= 0.8) return 'Alerta';
    return 'Normal';
  }

  Color _statusColor(String key) {
    final progress = _progressFor(key);

    if (_plannedFor(key) <= 0) return kGrey;
    if (progress >= 1) return kDanger;
    if (progress >= 0.8) return kWarning;
    return kSuccess;
  }

  String _monthName(int month) {
    return const [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ][month - 1];
  }

  String _monthShort(int month) {
    return const [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ][month - 1];
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta);
      _expandedCategoryKey = null;
      _missingBudgetDialogShown = false;
    });
    _loadData();
  }

  void _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Seleccionar mes',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kPrimary,
            onPrimary: kDark,
            onSurface: kDark,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _expandedCategoryKey = null;
        _missingBudgetDialogShown = false;
      });
      _loadData();
    }
  }

  void _showToast(String message, {bool success = false}) {
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 250),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, -16 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: success ? kSuccess : kDark,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
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

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  Widget _topHeader() {
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _handleBack,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kDark.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
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
              const SizedBox(width: 12),
              Container(
                width: 6,
                height: 22,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Presupuestos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: kDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _headerIconButton(
                icon: Icons.help_outline_rounded,
                onTap: _showHelpDialog,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCreateBudgetCategoryDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Crear categoría'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: kDark,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        GestureDetector(
          onTap: _handleBack,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: kDark.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
            color: kPrimary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Presupuestos',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: kDark,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _headerIconButton(
          icon: Icons.help_outline_rounded,
          onTap: _showHelpDialog,
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _showCreateBudgetCategoryDialog,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Crear categoría'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: kDark,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: kDark.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: kDark,
          size: 20,
        ),
      ),
    );
  }

  Future<void> _showHelpDialog() async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Cómo usar tus presupuestos',
                        style: TextStyle(
                          color: kDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                /// BLOQUE 1
                _helpItem(
                  icon: Icons.edit_rounded,
                  title: '1. Define cuánto quieres gastar',
                  description:
                      'Asigna un valor a cada categoría según lo que planeas gastar este mes.',
                ),

                /// BLOQUE 2
                _helpItem(
                  icon: Icons.compare_arrows_rounded,
                  title: '2. Compara con tus gastos reales',
                  description:
                      'La app automáticamente compara lo que planeaste con lo que ya gastaste.',
                ),

                /// BLOQUE 3
                _helpItem(
                  icon: Icons.visibility_rounded,
                  title: '3. Interpreta los estados',
                  description:
                      'Cada categoría cambia de color según tu comportamiento.',
                ),

                const SizedBox(height: 12),

                /// ESTADOS
                _statusLegend(),

                const SizedBox(height: 18),

                /// BLOQUE FINAL
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '💡 Tip: No se trata de gastar menos, sino de tener claridad y control sobre tu dinero.',
                    style: TextStyle(
                      color: kDark,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// BOTÓN
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: kDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPlanned = _budgetsMap.values.fold<double>(
      0,
      (sum, item) => sum + (((item['planned'] ?? 0) as num).toDouble()),
    );

    final totalSpent = _spentMap.values.fold<double>(
      0,
      (sum, item) => sum + item,
    );

    final totalRemaining = totalPlanned - totalSpent;
    final totalProgress = totalPlanned > 0 ? (totalSpent / totalPlanned) : 0.0;
    final overBudget = _hasFinancialProfile && totalPlanned > _monthlyIncome;

    return Scaffold(
      backgroundColor: kBackground,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimary),
            )
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: _loadData,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 10,
                  20,
                  20,
                ),
                children: [
                  _topHeader(),
                  const SizedBox(height: 24),
                  _headerCard(
                    totalPlanned: totalPlanned,
                    totalSpent: totalSpent,
                    totalRemaining: totalRemaining,
                    totalProgress: totalProgress,
                  ),
                  const SizedBox(height: 16),
                  if (!_hasFinancialProfile) _financialProfileWarningCard(),
                  const SizedBox(height: 16),
                  _financialProfileCard(),
                  const SizedBox(height: 16),
                  if (overBudget) _overBudgetAlertCard(),
                  if (overBudget) const SizedBox(height: 16),
                  _insightCard(
                    totalPlanned: totalPlanned,
                    totalSpent: totalSpent,
                    totalRemaining: totalRemaining,
                  ),
                  const SizedBox(height: 18),
                  _monthSelector(),
                  const SizedBox(height: 18),
                  _sectionTitle(),
                  const SizedBox(height: 8),
                  const Text(
                    'Define cuánto quieres gastar por categoría durante este mes y revisa cuánto llevas consumido.',
                    style: TextStyle(
                      color: kGrey,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_categories.isEmpty)
                    _emptyState()
                  else
                    ..._categories.map((cat) {
                      final key = (cat['budgetKey'] ?? '').toString();
                      final isSaving = _savingKeys.contains(key);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _budgetCard(
                          category: cat,
                          isSaving: isSaving,
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _headerCard({
    required double totalPlanned,
    required double totalSpent,
    required double totalRemaining,
    required double totalProgress,
  }) {
    final remainingColor =
        totalRemaining >= 0 ? Colors.white : const Color(0xFFFFCACA);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF242A52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: kDark.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.pie_chart_outline_rounded,
                  color: kPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Presupuestos',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Control de ${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _monthShort(_selectedMonth.month),
                  style: const TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Disponible del presupuesto',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatMoney(totalRemaining),
            style: TextStyle(
              color: remainingColor,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: totalPlanned > 0 ? totalProgress.clamp(0.0, 1.0) : 0,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                totalProgress >= 1
                    ? kDanger
                    : totalProgress >= 0.8
                        ? kWarning
                        : kSuccess,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  label: 'Planeado',
                  value: _formatMoney(totalPlanned),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryItem(
                  label: 'Gastado',
                  value: _formatMoney(totalSpent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _financialProfileWarningCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kWarning.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
                  color: kWarning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: kWarning,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Falta tu base mensual',
                  style: TextStyle(
                    color: kDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Para que esta pantalla sea más clara y útil, primero configura tu ingreso mensual. Así podremos validar mejor tus presupuestos.',
            style: TextStyle(
              color: kGrey,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _showFinancialProfileDialog(),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Configurar ingreso mensual'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: kDark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _financialProfileCard() {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kInfo.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  color: kInfo,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tu base financiera',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: kDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showFinancialProfileDialog(),
                child: const Text('Editar'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isMobile) ...[
            _miniInfoBox(
              label: 'Ingreso mensual',
              value: _formatMoney(_monthlyIncome),
              color: kInfo,
            ),
            const SizedBox(height: 10),
            _miniInfoBox(
              label: 'Tipo',
              value: _incomeType == 'fixed' ? 'Fijo' : 'Variable',
              color: kPrimary,
            ),
            const SizedBox(height: 10),
            _miniInfoBox(
              label: 'Día de pago',
              value: _payday?.toString() ?? 'No definido',
              color: kSuccess,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _miniInfoBox(
                    label: 'Ingreso mensual',
                    value: _formatMoney(_monthlyIncome),
                    color: kInfo,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _miniInfoBox(
                    label: 'Tipo',
                    value: _incomeType == 'fixed' ? 'Fijo' : 'Variable',
                    color: kPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _miniInfoBox(
                    label: 'Día de pago',
                    value: _payday?.toString() ?? 'No definido',
                    color: kSuccess,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniInfoBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kGrey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overBudgetAlertCard() {
    final difference = _budgetsMap.values.fold<double>(
          0,
          (sum, item) => sum + (((item['planned'] ?? 0) as num).toDouble()),
        ) -
        _monthlyIncome;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kDanger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kDanger.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: kDanger,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tus presupuestos planeados superan tu ingreso mensual por ${_formatMoney(difference)}. Te recomiendo ajustar algunas categorías.',
              style: const TextStyle(
                color: kDark,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightCard({
    required double totalPlanned,
    required double totalSpent,
    required double totalRemaining,
  }) {
    String title;
    String subtitle;
    Color color;
    IconData icon;

    if (totalPlanned <= 0) {
      title = 'Empieza definiendo tus límites';
      subtitle =
          'Asigna un valor a cada categoría importante para que puedas comparar lo que planeaste con lo que realmente gastas.';
      color = kInfo;
      icon = Icons.lightbulb_outline_rounded;
    } else if (totalSpent >= totalPlanned) {
      title = 'Ya superaste tu presupuesto general';
      subtitle =
          'Este mes ya gastaste más de lo planeado. Revisa primero las categorías en rojo.';
      color = kDanger;
      icon = Icons.error_outline_rounded;
    } else if (totalSpent >= totalPlanned * 0.8) {
      title = 'Vas cerca del límite';
      subtitle =
          'Ya consumiste una parte alta de tu presupuesto mensual. Mira las categorías en alerta.';
      color = kWarning;
      icon = Icons.track_changes_rounded;
    } else {
      title = 'Vas bien este mes';
      subtitle =
          'Todavía tienes margen disponible. Mantén controladas las categorías que más gasto te generan.';
      color = kSuccess;
      icon = Icons.verified_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: kGrey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (totalPlanned > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Disponible actual: ${_formatMoney(totalRemaining)}',
                    style: const TextStyle(
                      color: kDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthSelector() {
    final now = DateTime.now();
    final canGoNext = _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kDark.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _navBtn(Icons.chevron_left_rounded, () => _changeMonth(-1)),
          Expanded(
            child: GestureDetector(
              onTap: _pickMonth,
              child: Column(
                children: [
                  Text(
                    _monthName(_selectedMonth.month),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '${_selectedMonth.year}',
                    style: const TextStyle(fontSize: 12, color: kGrey),
                  ),
                ],
              ),
            ),
          ),
          _navBtn(
            Icons.chevron_right_rounded,
            canGoNext ? () => _changeMonth(1) : null,
          ),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: onTap == null ? kBackground.withOpacity(0.5) : kBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: onTap == null ? kGrey.withOpacity(0.4) : kDark,
          size: 22,
        ),
      ),
    );
  }

  Widget _sectionTitle() {
    return const Row(
      children: [
        Text(
          'Categorías de gasto',
          style: TextStyle(
            color: kDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: kGrey,
            size: 34,
          ),
          SizedBox(height: 10),
          Text(
            'No hay categorías de gasto disponibles',
            style: TextStyle(
              color: kDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Crea o carga categorías tipo expense para empezar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kGrey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetCard({
    required Map<String, dynamic> category,
    required bool isSaving,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    final categoryName = (category['displayName'] ?? '').toString().trim();
    final categoryKey = (category['budgetKey'] ?? '').toString().trim();
    final colorHex = (category['color'] ?? '#CBD5E1').toString().trim();
    final color = _parseColor(colorHex);

    final planned = _plannedFor(categoryKey);
    final spent = _spentFor(categoryKey);
    final remaining = _remainingFor(categoryKey);
    final progress = _progressFor(categoryKey);
    final status = _statusFor(categoryKey);
    final statusColor = _statusColor(categoryKey);
    final hasBudget = planned > 0;
    final isExpanded = _expandedCategoryKey == categoryKey;
    final isGlobal = (category['source'] ?? 'global') == 'global';

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      color: kDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isMobile) ...[
              Row(
                children: [
                  Expanded(
                    child: _infoChip(
                      label: 'Planeado',
                      value: hasBudget ? _formatMoney(planned) : 'Sin definir',
                      valueColor: hasBudget ? kDark : kGrey,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _infoChip(
                      label: 'Gastado',
                      value: _formatMoney(spent),
                      valueColor: spent > 0 ? kDanger : kGrey,
                      compact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _infoChip(
                      label: 'Disponible',
                      value: _formatMoney(remaining),
                      valueColor: remaining >= 0 ? kSuccess : kDanger,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _infoChip(
                      label: 'Planeado',
                      value: hasBudget ? _formatMoney(planned) : 'Sin definir',
                      valueColor: hasBudget ? kDark : kGrey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _infoChip(
                      label: 'Gastado',
                      value: _formatMoney(spent),
                      valueColor: spent > 0 ? kDanger : kGrey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _infoChip(
                      label: 'Disponible',
                      value: _formatMoney(remaining),
                      valueColor: remaining >= 0 ? kSuccess : kDanger,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: hasBudget ? progress.clamp(0.0, 1.0) : 0,
                minHeight: 9,
                backgroundColor: kBackground,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                hasBudget
                    ? '${(progress * 100).toStringAsFixed(0)}% usado'
                    : 'Aún no has definido un presupuesto para esta categoría',
                style: const TextStyle(
                  color: kGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _expandedCategoryKey = isExpanded ? null : categoryKey;
                    });
                  },
                  icon: Icon(
                    isExpanded ? Icons.expand_less_rounded : Icons.edit_rounded,
                    size: 18,
                  ),
                  label: Text(isExpanded ? 'Cerrar edición' : 'Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kDark,
                    side: BorderSide(color: kDark.withOpacity(0.08)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                if (hasBudget || !isGlobal) ...[
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (isGlobal) {
                              final confirm = await _confirmDeleteDialog(
                                title: '¿Eliminar presupuesto?',
                                message:
                                    'Se eliminará el presupuesto de esta categoría para el mes actual.',
                              );

                              if (confirm) {
                                await _deleteBudget(category: category);
                              }
                            } else {
                              await _deleteCategoryAndBudget(
                                  category: category);
                            }
                          },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(isGlobal
                        ? 'Eliminar presupuesto'
                        : 'Eliminar categoría'),
                    style: TextButton.styleFrom(
                      foregroundColor: kDanger,
                    ),
                  ),
                ],
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kBackground,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Define cuánto quieres asignar este mes a esta categoría.',
                            style: TextStyle(
                              color: kGrey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controllers[categoryKey],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9]'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: 'Ej: 300000',
                                  labelText: 'Presupuesto mensual',
                                  prefixIcon:
                                      const Icon(Icons.attach_money_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () => _saveBudget(category: category),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.2,
                                        ),
                                      )
                                    : const Icon(Icons.save_rounded),
                                label: Text(
                                  isSaving ? 'Guardando' : 'Guardar',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!isGlobal) ...[
                          const SizedBox(height: 16),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Color de la categoría',
                              style: TextStyle(
                                color: kDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _categoryPalette.map((hex) {
                              final paletteColor = _parseColor(hex);
                              final selected =
                                  colorHex.toLowerCase() == hex.toLowerCase();

                              return InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: isSaving
                                    ? null
                                    : () => _updateCategoryColor(
                                          category: category,
                                          colorHex: hex,
                                        ),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: paletteColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          selected ? kDark : Colors.transparent,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: selected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text(
                                'Color predeterminado',
                                style: TextStyle(
                                  color: kGrey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip({
    required String label,
    required String value,
    required Color valueColor,
    bool compact = false,
  }) {
    return Container(
      height: compact ? 64 : 72, // 🔥 clave para que todos midan igual
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, // centra vertical
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: kGrey,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1, // 🔥 evita que rompa a dos líneas
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteDialog({
    required String title,
    required String message,
    bool danger = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: (danger ? kDanger : kWarning).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  danger
                      ? Icons.delete_outline_rounded
                      : Icons.warning_amber_rounded,
                  color: danger ? kDanger : kWarning,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kGrey,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
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
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: danger ? kDanger : kWarning,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Sí, eliminar',
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

    return result ?? false;
  }

  Future<void> _deleteCategoryAndBudget({
    required Map<String, dynamic> category,
  }) async {
    final categoryId = (category['id'] ?? '').toString().trim();
    final categoryKey = (category['budgetKey'] ?? '').toString().trim();
    final categoryName = (category['displayName'] ?? '').toString().trim();
    final isGlobal = (category['source'] ?? 'global') == 'global';

    if (categoryId.isEmpty || categoryKey.isEmpty) return;

    if (isGlobal) {
      _showToast('Las categorías globales no se pueden eliminar');
      return;
    }

    final confirm = await _confirmDeleteDialog(
      title: '¿Eliminar categoría?',
      message:
          'Se eliminará la categoría "$categoryName" de tu perfil y también su presupuesto del mes actual. Esta acción no se puede deshacer.',
    );

    if (!confirm) return;

    setState(() => _savingKeys.add(categoryKey));

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      await userRef
          .collection('budgets')
          .doc(_monthKey)
          .collection('items')
          .doc(categoryId)
          .delete()
          .catchError((_) {});

      await userRef.collection('categories').doc(categoryId).delete();

      await _removeNotificationsByDedupeKeys([
        'budget_missing_with_spend_${_monthKey}_$categoryKey',
        'budget_exceeded_${_monthKey}_$categoryKey',
        'budget_warning_${_monthKey}_$categoryKey',
      ]);

      _budgetsMap.remove(categoryKey);
      _controllers[categoryKey]?.dispose();
      _controllers.remove(categoryKey);
      _categories.removeWhere(
        (cat) => (cat['id'] ?? '').toString().trim() == categoryId,
      );

      if (!mounted) return;
      _showToast('Categoría eliminada', success: true);
      setState(() {
        if (_expandedCategoryKey == categoryKey) {
          _expandedCategoryKey = null;
        }
      });
    } catch (e) {
      _showToast('No se pudo eliminar la categoría');
    } finally {
      if (mounted) {
        setState(() => _savingKeys.remove(categoryKey));
      }
    }
  }

  Future<void> _updateCategoryColor({
    required Map<String, dynamic> category,
    required String colorHex,
  }) async {
    final categoryId = (category['id'] ?? '').toString().trim();
    final categoryKey = (category['budgetKey'] ?? '').toString().trim();
    final isGlobal = (category['source'] ?? 'global') == 'global';

    if (categoryId.isEmpty || categoryKey.isEmpty) return;

    if (isGlobal) {
      _showToast('Las categorías globales no se pueden personalizar');
      return;
    }

    setState(() => _savingKeys.add(categoryKey));

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      await userRef.collection('categories').doc(categoryId).set({
        'color': colorHex,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await userRef
          .collection('budgets')
          .doc(_monthKey)
          .collection('items')
          .doc(categoryId)
          .set({
        'color': colorHex,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final categoryIndex = _categories.indexWhere(
        (cat) => (cat['id'] ?? '').toString().trim() == categoryId,
      );

      if (categoryIndex != -1) {
        _categories[categoryIndex] = {
          ..._categories[categoryIndex],
          'color': colorHex,
        };
      }

      if (_budgetsMap.containsKey(categoryKey)) {
        _budgetsMap[categoryKey] = {
          ..._budgetsMap[categoryKey]!,
          'color': colorHex,
        };
      }

      if (!mounted) return;
      _showToast('Color actualizado', success: true);
      setState(() {});
    } catch (e) {
      _showToast('No se pudo actualizar el color');
    } finally {
      if (mounted) {
        setState(() => _savingKeys.remove(categoryKey));
      }
    }
  }

  Future<void> _showCreateBudgetCategoryDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.add_box_rounded, color: kPrimary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nueva categoría de gasto',
                      style: TextStyle(
                        color: kDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: kBackground,
                  hintText: 'Ej: Mascotas',
                  labelText: 'Nombre de la categoría',
                  prefixIcon: const Icon(Icons.edit_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
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
                          _showToast('Escribe un nombre para la categoría');
                          return;
                        }

                        final nameLower = name.toLowerCase().trim();

                        final globalExists = await FirebaseFirestore.instance
                            .collection('categories')
                            .where('nameLower', isEqualTo: nameLower)
                            .get();

                        final userExists = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('categories')
                            .where('nameLower', isEqualTo: nameLower)
                            .get();

                        if (globalExists.docs.isNotEmpty ||
                            userExists.docs.isNotEmpty) {
                          _showToast('Ya existe una categoría con ese nombre');
                          return;
                        }

                        final color = _categoryPalette[
                            DateTime.now().millisecondsSinceEpoch %
                                _categoryPalette.length];

                        final newDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('categories')
                            .add({
                          'name': name,
                          'nameLower': nameLower,
                          'type': 'expense',
                          'isDefault': false,
                          'color': color,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        final newCategory = {
                          'id': newDoc.id,
                          'name': name,
                          'nameLower': nameLower,
                          'type': 'expense',
                          'isDefault': false,
                          'color': color,
                          'source': 'user',
                          'budgetKey': nameLower,
                          'displayName': name,
                        };

                        _controllers.putIfAbsent(
                          nameLower,
                          () => TextEditingController(),
                        );

                        if (!mounted) return;

                        Navigator.pop(context);

                        setState(() {
                          _categories = [..._categories, newCategory]
                            ..sort((a, b) {
                              final aKey = (a['budgetKey'] ?? '').toString();
                              final bKey = (b['budgetKey'] ?? '').toString();

                              final aPriority = _priorityForCategory(
                                planned: (_budgetsMap[aKey]?['planned'] as num?)
                                        ?.toDouble() ??
                                    0,
                                spent: _spentMap[aKey] ?? 0,
                              );

                              final bPriority = _priorityForCategory(
                                planned: (_budgetsMap[bKey]?['planned'] as num?)
                                        ?.toDouble() ??
                                    0,
                                spent: _spentMap[bKey] ?? 0,
                              );

                              if (aPriority != bPriority) {
                                return aPriority.compareTo(bPriority);
                              }

                              final aName = (a['displayName'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              final bName = (b['displayName'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              return aName.compareTo(bName);
                            });
                          _expandedCategoryKey = nameLower;
                        });

                        _showToast('Categoría creada', success: true);
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

  Widget _helpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kPrimary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: kGrey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusLegend() {
    return Column(
      children: [
        _statusItem(
          kSuccess,
          'Normal',
          'Vas bien, estás dentro del presupuesto',
        ),
        _statusItem(
          kWarning,
          'Alerta',
          'Estás cerca del límite de gasto',
        ),
        _statusItem(
          kDanger,
          'Excedido',
          'Ya superaste el valor planeado',
        ),
        _statusItem(
          kGrey,
          'Sin definir',
          'Aún no has asignado presupuesto a esta categoría',
        ),
      ],
    );
  }

  Widget _statusItem(Color color, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: kDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: kGrey,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
