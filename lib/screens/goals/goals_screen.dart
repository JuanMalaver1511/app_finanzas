import 'package:flutter/material.dart';

import '../../models/goal_model.dart';
import '../../services/goal_service.dart';
import 'create_goal_screen.dart';
import '../../widgets/goals/goal_card.dart';
import 'goal_detail_screen.dart';

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

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final GoalService _goalService = GoalService();

  String _formatCurrency(double value) {
    final intValue = value.round();
    final text = intValue.toString();
    final reversed = text.split('').reversed.join();
    final chunks = <String>[];

    for (int i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }

    return '\$${chunks.join('.').split('').reversed.join()}';
  }

  Route<T> _buildAnimatedRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, animation, secondaryAnimation) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _openCreateGoal() async {
    final created = await Navigator.push<bool>(
      context,
      _buildAnimatedRoute<bool>(const CreateGoalScreen()),
    );

    if (!mounted) return;

    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: kGreenBtn,
          content: Text('Tu meta fue creada con éxito.'),
        ),
      );
    }
  }

  void _openGoalDetail(GoalModel goal) {
    Navigator.push(
      context,
      _buildAnimatedRoute(GoalDetailScreen(goalId: goal.id)),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: kDark.withOpacity(0.12),
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kAmberLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      color: kDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '¿Cómo funciona esta sección?',
                      style: TextStyle(
                        color: kDark,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'En Metas puedes definir objetivos de ahorro como un viaje, una moto, una bici o un fondo de emergencia.',
                style: TextStyle(
                  color: kDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              const _HelpPoint(
                text:
                    'Crea una meta con nombre, monto objetivo y fecha límite.',
              ),
              const _HelpPoint(
                text:
                    'Elige cada cuánto quieres ahorrar: diario, semanal, quincenal o mensual.',
              ),
              const _HelpPoint(
                text: 'Kybo calcula cuánto deberías aportar para cumplirla.',
              ),
              const _HelpPoint(
                text: 'Puedes subir una imagen para motivarte más visualmente.',
              ),
              const _HelpPoint(
                text:
                    'Cada aporte que registres actualiza tu progreso automáticamente.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(bool isMobile) {
    return Container(
      color: kBg,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 32,
        16,
        isMobile ? 16 : 32,
        12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (widget.onBack != null) {
                widget.onBack!();
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
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
          const SizedBox(width: 16),
          Container(
            width: 7,
            height: 22,
            decoration: BoxDecoration(
              color: kAmber,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mis Metas',
              style: TextStyle(
                color: kDark,
                fontWeight: FontWeight.w800,
                fontSize: isMobile ? 22 : 24,
                letterSpacing: -0.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: _showHelpDialog,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kDark.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: kDark,
                size: 20,
              ),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 12),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _openCreateGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAmber,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Nueva meta',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopSummary(List<GoalModel> goals, bool isMobile) {
    final activeGoals =
        goals.where((g) => g.status == GoalStatus.active).length;
    final completedGoals = goals
        .where((g) =>
            g.status == GoalStatus.completed || g.savedAmount >= g.targetAmount)
        .length;
    final totalSaved =
        goals.fold<double>(0, (sum, item) => sum + item.savedAmount);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.98, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: value,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color.fromARGB(255, 48, 48, 80)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
              'Tus metas financieras',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Convierte tus objetivos en progreso real. Entre más visibles sean, más fácil será cumplirlos.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            if (isMobile) ...[
              Row(
                children: [
                  Expanded(
                    child: _SummaryCapsule(
                      title: 'Metas activas',
                      value: '$activeGoals',
                      icon: Icons.flag_rounded,
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCapsule(
                      title: 'Cumplidas',
                      value: '$completedGoals',
                      icon: Icons.verified_rounded,
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SummaryCapsule(
                title: 'Ahorrado total',
                value: _formatCurrency(totalSaved),
                icon: Icons.savings_rounded,
                fullWidth: true,
              ),
            ] else ...[
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: 220,
                    child: _SummaryCapsule(
                      title: 'Metas activas',
                      value: '$activeGoals',
                      icon: Icons.flag_rounded,
                      fullWidth: true,
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: _SummaryCapsule(
                      title: 'Cumplidas',
                      value: '$completedGoals',
                      icon: Icons.verified_rounded,
                      fullWidth: true,
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: _SummaryCapsule(
                      title: 'Ahorrado total',
                      value: _formatCurrency(totalSaved),
                      icon: Icons.savings_rounded,
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBanner(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 18),
      decoration: BoxDecoration(
        color: kAmberLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kAmber.withOpacity(0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: kAmber.withOpacity(0.20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: kDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Haz tus metas visibles',
                  style: TextStyle(
                    color: kDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Agrega metas con fecha, monto y frecuencia de ahorro. Así la app podrá decirte cuánto necesitas aportar para sí cumplirlas.',
                  style: TextStyle(
                    color: kDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _openCreateGoal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Crear mi primera meta',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
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
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: kAmberLight,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: kDark,
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Aún no has creado metas',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Empieza con una meta clara. Ponle monto, fecha y una frecuencia de ahorro para que Kybo te ayude a cumplirla.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kGrey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _openCreateGoal,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreenBtn,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Crear nueva meta',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsGrid(List<GoalModel> goals, bool isMobile) {
    if (goals.isEmpty) {
      return _buildEmptyState(isMobile);
    }

    final crossAxisCount =
        isMobile ? 1 : (MediaQuery.of(context).size.width < 1200 ? 2 : 3);

    return GridView.builder(
      itemCount: goals.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        mainAxisExtent: isMobile ? 560 : 690,
      ),
      itemBuilder: (context, index) {
        final goal = goals[index];

        return GoalCard(
          goal: goal,
          onTap: () => _openGoalDetail(goal),
        );
      },
    );
  }

  Widget _buildBody(bool isMobile) {
    return StreamBuilder<List<GoalModel>>(
      stream: _goalService.streamGoals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kDark),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: kRed,
                    size: 34,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No pudimos cargar tus metas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Revisa la conexión o la configuración de Firestore.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kGrey,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final goals = snapshot.data ?? [];

        return Scrollbar(
          thumbVisibility: !isMobile,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 28,
              8,
              isMobile ? 16 : 28,
              isMobile ? 100 : 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1380),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopSummary(goals, isMobile),
                    const SizedBox(height: 18),
                    if (goals.isEmpty) ...[
                      _buildQuickActionBanner(isMobile),
                      const SizedBox(height: 18),
                    ],
                    _buildGoalsGrid(goals, isMobile),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: _openCreateGoal,
              backgroundColor: kDark,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Nueva meta',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildDesktopHeader(isMobile),
            Expanded(
              child: _buildBody(isMobile),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCapsule extends StatelessWidget {
  const _SummaryCapsule({
    required this.title,
    required this.value,
    required this.icon,
    this.fullWidth = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      constraints: fullWidth ? null : const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: kAmber,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpPoint extends StatelessWidget {
  const _HelpPoint({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(
              Icons.check_circle_rounded,
              color: kGreenBtn,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: kDark,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
