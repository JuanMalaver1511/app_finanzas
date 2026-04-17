import 'package:flutter/material.dart';

import '../../models/goal_model.dart';
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

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onEdit,
  });

  final GoalModel goal;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

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

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    final statusColor = _statusColor(goal.status);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
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
              _GoalCardHeader(
                goalId: goal.id,
                imageUrl: goal.imageUrl,
                title: goal.title,
                statusLabel: GoalCalculator.statusLabel(goal.status),
                statusColor: statusColor,
                statusIcon: _statusIcon(goal.status),
                onEdit: onEdit,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedProgress, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${(animatedProgress * 100).round()}%',
                              style: const TextStyle(
                                color: kDark,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_formatCurrency(goal.savedAmount)} de ${_formatCurrency(goal.targetAmount)}',
                              style: const TextStyle(
                                color: kGrey,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: animatedProgress,
                                minHeight: 10,
                                backgroundColor: const Color(0xFFF1F2F6),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(statusColor),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _GoalInfoChip(
                          icon: Icons.event_rounded,
                          label: _formatDate(goal.deadline),
                        ),
                        _GoalInfoChip(
                          icon: Icons.repeat_rounded,
                          label: GoalCalculator.frequencyLabel(
                            goal.savingFrequency,
                          ),
                        ),
                        _GoalInfoChip(
                          icon: Icons.payments_rounded,
                          label: _formatCurrency(goal.suggestedAmount),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: kAmberLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.savings_rounded,
                              color: kDark,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              goal.status == GoalStatus.completed
                                  ? 'Meta completada. Excelente trabajo.'
                                  : 'Ahorro sugerido: ${_formatCurrency(goal.suggestedAmount)} por ${GoalCalculator.frequencyLabel(goal.savingFrequency).toLowerCase()}.',
                              style: const TextStyle(
                                color: kDark,
                                fontSize: 12.8,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if ((goal.motivation ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
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
                                  fontSize: 12.8,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalCardHeader extends StatelessWidget {
  const _GoalCardHeader({
    required this.goalId,
    required this.imageUrl,
    required this.title,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    this.onEdit,
  });

  final String goalId;
  final String? imageUrl;
  final String title;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Hero(
      tag: 'goal-hero-$goalId',
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: hasImage
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF2B2257), Color(0xFF463A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            image: hasImage
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              gradient: LinearGradient(
                colors: hasImage
                    ? [
                        Colors.black.withOpacity(0.10),
                        Colors.black.withOpacity(0.52),
                      ]
                    : [
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.16),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        GestureDetector(
                          onTap: onEdit,
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: hasImage
                              ? Colors.white.withOpacity(0.16)
                              : Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (!hasImage)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                if (!hasImage) const SizedBox(height: 12),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalInfoChip extends StatelessWidget {
  const _GoalInfoChip({
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
        color: const Color(0xFFF8F9FC),
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