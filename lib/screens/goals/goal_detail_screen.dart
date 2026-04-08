import 'package:flutter/material.dart';

import '../../models/goal_contribution_model.dart';
import '../../models/goal_model.dart';
import '../../services/goal_service.dart';
import '../../utils/goal_calculator.dart';
import 'dialogs/add_goal_contribution_dialog.dart';

const kAmber = Color(0xFFFFBB4E);
const kBg = Color(0xFFF0F2F5);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF8A8A9A);
const kGreen = Color(0xFF1D7E45);
const kGreenBtn = Color(0xFF27AE60);
const kRed = Color(0xFFE74C3C);
const kAmberLight = Color(0xFFFFF3DC);

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({
    super.key,
    required this.goalId,
  });

  final String goalId;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final GoalService _goalService = GoalService();
  bool _isSavingContribution = false;

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

  String _formatShortDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatContributionDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _statusColor(GoalStatus status) {
    switch (status) {
      case GoalStatus.active:
        return kGreenBtn;
      case GoalStatus.atRisk:
        return kAmber;
      case GoalStatus.delayed:
        return kRed;
      case GoalStatus.completed:
        return const Color(0xFF6C63FF);
    }
  }

  IconData _statusIcon(GoalStatus status) {
    switch (status) {
      case GoalStatus.active:
        return Icons.trending_up_rounded;
      case GoalStatus.atRisk:
        return Icons.warning_amber_rounded;
      case GoalStatus.delayed:
        return Icons.access_time_filled_rounded;
      case GoalStatus.completed:
        return Icons.verified_rounded;
    }
  }

  Future<void> _openAddContribution(GoalModel goal) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AddGoalContributionDialog(),
    );

    if (result == null) return;

    final amount = result['amount'] as double?;
    final note = result['note'] as String?;

    if (amount == null || amount <= 0) return;

    setState(() => _isSavingContribution = true);

    try {
      await _goalService.addContribution(
        goalId: goal.id,
        amount: amount,
        note: note,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kGreenBtn,
          content: Text(
            'Aporte de ${_formatCurrency(amount)} agregado correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kRed,
          content: Text('No se pudo guardar el aporte: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingContribution = false);
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
              'Detalle de meta',
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

  Widget _buildHeroSection(GoalModel goal, bool isMobile) {
    final hasImage = goal.imageUrl != null && goal.imageUrl!.trim().isNotEmpty;
    final statusColor = _statusColor(goal.status);

    return Hero(
      tag: 'goal-hero-${goal.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: isMobile ? 205 : 310,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: hasImage
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF2B2257), Color(0xFF463A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            image: hasImage
                ? DecorationImage(
                    image: NetworkImage(goal.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                colors: hasImage
                    ? [
                        Colors.black.withOpacity(0.16),
                        Colors.black.withOpacity(0.60),
                      ]
                    : [
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.24),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: EdgeInsets.all(isMobile ? 18 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.14),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(goal.status), color: statusColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          GoalCalculator.statusLabel(goal.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (!hasImage)
                  Container(
                    width: isMobile ? 50 : 58,
                    height: isMobile ? 50 : 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                if (!hasImage) const SizedBox(height: 12),
                Text(
                  goal.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 22 : 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Meta objetivo: ${_formatCurrency(goal.targetAmount)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: isMobile ? 12.5 : 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(GoalModel goal, bool isMobile) {
    final items = [
      _MetricCardData(
        title: 'Ahorrado',
        value: _formatCurrency(goal.savedAmount),
        icon: Icons.savings_rounded,
      ),
      _MetricCardData(
        title: 'Faltante',
        value: _formatCurrency(goal.remainingAmount),
        icon: Icons.account_balance_wallet_rounded,
      ),
      _MetricCardData(
        title: 'Fecha límite',
        value: _formatShortDate(goal.deadline),
        icon: Icons.event_rounded,
      ),
      _MetricCardData(
        title: 'Frecuencia',
        value: GoalCalculator.frequencyLabel(goal.savingFrequency),
        icon: Icons.repeat_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile ? 2 : 4;
        final spacing = isMobile ? 12.0 : 14.0;
        final totalSpacing = spacing * (crossAxisCount - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: isMobile ? 108 : 102,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _MetricCard(
              title: item.title,
              value: item.value,
              icon: item.icon,
              isMobile: isMobile,
              forcedWidth: itemWidth,
            );
          },
        );
      },
    );
  }

  Widget _buildProgressBlock(GoalModel goal, bool isMobile) {
    final calculation = GoalCalculator.calculate(
      targetAmount: goal.targetAmount,
      savedAmount: goal.savedAmount,
      deadline: goal.deadline,
      frequency: goal.savingFrequency,
      now: DateTime.now(),
    );

    final statusColor = _statusColor(goal.status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progreso actual',
            style: TextStyle(
              color: kDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 18),
          _buildMetricsGrid(goal, isMobile),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: goal.progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(animatedProgress * 100).round()}%',
                    style: TextStyle(
                      color: kDark,
                      fontSize: isMobile ? 34 : 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatCurrency(goal.savedAmount)} de ${_formatCurrency(goal.targetAmount)}',
                    style: const TextStyle(
                      color: kGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: animatedProgress,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFF1F2F6),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 14 : 16),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proyección de ahorro',
                  style: TextStyle(
                    color: kDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  goal.status == GoalStatus.completed
                      ? 'Ya cumpliste esta meta. Excelente trabajo.'
                      : 'Para cumplirla, deberías ahorrar aproximadamente ${_formatCurrency(calculation.suggestedAmountPerPeriod)} por ${GoalCalculator.frequencyLabel(goal.savingFrequency).toLowerCase()}.',
                  style: const TextStyle(
                    color: kDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _SmallTag(
                      icon: Icons.schedule_rounded,
                      label: '${calculation.daysLeft} días restantes',
                    ),
                    _SmallTag(
                      icon: Icons.flag_circle_rounded,
                      label: GoalCalculator.statusLabel(goal.status),
                    ),
                    _SmallTag(
                      icon: Icons.payments_rounded,
                      label:
                          '${_formatCurrency(calculation.suggestedAmountPerPeriod)} sugeridos',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if ((goal.motivation ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: kAmber,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      goal.motivation!.trim(),
                      style: const TextStyle(
                        color: kDark,
                        fontSize: 13.4,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(GoalModel goal, bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSavingContribution ? null : () => _openAddContribution(goal),
        style: ElevatedButton.styleFrom(
          backgroundColor: kGreenBtn,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kGreenBtn.withOpacity(0.55),
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: _isSavingContribution
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_rounded),
        label: Text(
          _isSavingContribution ? 'Guardando...' : 'Agregar aporte',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }

  Widget _buildContributionsSection(
    GoalModel goal,
    List<GoalContributionModel> contributions,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial de aportes',
            style: TextStyle(
              color: kDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            contributions.isEmpty
                ? 'Aún no has registrado aportes en esta meta.'
                : 'Cada aporte te acerca un poco más a lograr "${goal.title}".',
            style: const TextStyle(
              color: kGrey,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          if (contributions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.savings_outlined,
                    color: kGrey,
                    size: 34,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Todavía no hay movimientos en esta meta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              itemCount: contributions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = contributions[index];

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.96, end: 1),
                  duration: Duration(milliseconds: 220 + (index * 40)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: kAmberLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.payments_rounded,
                            color: kDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatCurrency(item.amount),
                                style: const TextStyle(
                                  color: kDark,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.note?.trim().isNotEmpty == true
                                    ? item.note!.trim()
                                    : 'Aporte registrado',
                                style: const TextStyle(
                                  color: kGrey,
                                  fontSize: 12.8,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatContributionDate(item.createdAt),
                          style: const TextStyle(
                            color: kGrey,
                            fontSize: 12.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isMobile),
            Expanded(
              child: StreamBuilder<GoalModel?>(
                stream: _goalService.streamGoalById(widget.goalId),
                builder: (context, goalSnapshot) {
                  if (goalSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: kDark),
                    );
                  }

                  if (goalSnapshot.hasError) {
                    return const Center(
                      child: Text(
                        'No se pudo cargar la meta.',
                        style: TextStyle(
                          color: kDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }

                  final goal = goalSnapshot.data;

                  if (goal == null) {
                    return const Center(
                      child: Text(
                        'La meta no existe o fue eliminada.',
                        style: TextStyle(
                          color: kDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }

                  return StreamBuilder<List<GoalContributionModel>>(
                    stream: _goalService.streamContributions(goal.id),
                    builder: (context, contributionsSnapshot) {
                      final contributions = contributionsSnapshot.data ?? [];

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          isMobile ? 16 : 28,
                          8,
                          isMobile ? 16 : 28,
                          28,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeroSection(goal, isMobile),
                                const SizedBox(height: 18),
                                _buildActions(goal, isMobile),
                                const SizedBox(height: 18),
                                _buildProgressBlock(goal, isMobile),
                                const SizedBox(height: 18),
                                _buildContributionsSection(
                                  goal,
                                  contributions,
                                  isMobile,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.isMobile,
    required this.forcedWidth,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool isMobile;
  final double forcedWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: forcedWidth,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 11 : 14),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: isMobile ? 38 : 42,
              height: isMobile ? 38 : 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: kDark,
                size: isMobile ? 18 : 20,
              ),
            ),
            SizedBox(width: isMobile ? 10 : 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: kGrey,
                      fontSize: isMobile ? 11.2 : 12.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: kDark,
                      fontSize: isMobile ? 12.4 : 13.4,
                      fontWeight: FontWeight.w800,
                      height: 1.18,
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

class _SmallTag extends StatelessWidget {
  const _SmallTag({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kDark),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: kDark,
              fontSize: 12.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}