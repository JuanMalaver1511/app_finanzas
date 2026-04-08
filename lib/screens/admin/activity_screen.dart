import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  static const Color _kyboPrimary = Color(0xFF2B2257);
  static const Color _kyboAccent = Color(0xFFFFB84E);
  static const Color _kyboBg = Color(0xFFF6F7FB);
  static const Color _kyboCard = Colors.white;
  static const Color _success = Color(0xFF16A34A);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _info = Color(0xFF4F46E5);

  static const int _inactiveThresholdDays = 8;

  int totalUsers = 0;
  int activeUsers = 0;
  int inactiveUsers = 0;
  int blockedUsers = 0;

  String selectedPeriod = "Últimos 7 días";

  final List<String> periods = const [
    "Hoy",
    "Ayer",
    "Semana actual",
    "Últimos 7 días",
    "Últimos 30 días",
    "Mes actual",
    "Mes anterior",
    "Año actual",
    "Personalizado",
  ];

  List<int> chartData = [];
  List<String> chartLabels = [];
  List<Map<String, dynamic>> recentUsers = [];

  bool isLoading = true;

  int daysFilter = 7;
  DateTime? startDate;
  DateTime? endDate;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, .04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _initializeDefaultRange();
    _loadData();
    _controller.forward();
  }

  void _initializeDefaultRange() {
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    endDate = now;
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final now = DateTime.now();
      final rangeStart =
          _normalizeStart(startDate ?? now.subtract(Duration(days: daysFilter)));
      final rangeEnd = _normalizeEnd(endDate ?? now);

      int active = 0;
      int inactive = 0;
      int blocked = 0;

      final List<Map<String, dynamic>> tempRecent = [];

      final int totalDays = rangeEnd.difference(rangeStart).inDays + 1;
      final List<int> tempChart = List.filled(totalDays, 0);
      final List<String> tempLabels = List.generate(
        totalDays,
        (i) => _shortDateLabel(rangeStart.add(Duration(days: i))),
      );

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final lastLogin = (data['lastLogin'] as Timestamp?)?.toDate();

        final bool isBlocked = data['isBlocked'] == true;
        final bool isEnabled = data['isActive'] != false;

        final DateTime? activityReference = lastLogin ?? createdAt;
        final bool recentlyActive = activityReference != null &&
            now.difference(activityReference).inDays <=
                _inactiveThresholdDays;

        if (isBlocked) {
          blocked++;
        } else if (isEnabled && recentlyActive) {
          active++;
        } else {
          inactive++;
        }

        if (createdAt != null &&
            !createdAt.isBefore(rangeStart) &&
            !createdAt.isAfter(rangeEnd)) {
          final index = createdAt.difference(rangeStart).inDays;
          if (index >= 0 && index < tempChart.length) {
            tempChart[index]++;
          }
        }

        if (activityReference != null) {
          tempRecent.add({
            "name": (data['name'] ?? 'Usuario').toString(),
            "email": (data['email'] ?? '').toString(),
            "lastLogin": lastLogin,
            "createdAt": createdAt,
            "isBlocked": isBlocked,
            "isEnabled": isEnabled,
            "recentlyActive": recentlyActive,
          });
        }
      }

      tempRecent.sort((a, b) {
        final DateTime aDate =
            (a['lastLogin'] as DateTime?) ??
                (a['createdAt'] as DateTime?) ??
                DateTime(2000);
        final DateTime bDate =
            (b['lastLogin'] as DateTime?) ??
                (b['createdAt'] as DateTime?) ??
                DateTime(2000);
        return bDate.compareTo(aDate);
      });

      if (!mounted) return;

      setState(() {
        totalUsers = snapshot.docs.length;
        activeUsers = active;
        inactiveUsers = inactive;
        blockedUsers = blocked;
        chartData = tempChart;
        chartLabels = tempLabels;
        recentUsers = tempRecent.take(6).toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando actividad: $e'),
          backgroundColor: _danger,
        ),
      );
    }
  }

  DateTime _normalizeStart(DateTime date) {
    return DateTime(date.year, date.month, date.day, 0, 0, 0);
  }

  DateTime _normalizeEnd(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  Future<void> _applyPeriod(String value) async {
    setState(() => selectedPeriod = value);

    final now = DateTime.now();

    switch (value) {
      case "Hoy":
        startDate = DateTime(now.year, now.month, now.day);
        endDate = now;
        break;

      case "Ayer":
        final yesterday = now.subtract(const Duration(days: 1));
        startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          23,
          59,
          59,
        );
        break;

      case "Semana actual":
        final startWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        startDate = startWeek;
        endDate = now;
        break;

      case "Últimos 7 días":
        startDate = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        endDate = now;
        break;

      case "Últimos 30 días":
        startDate = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 29));
        endDate = now;
        break;

      case "Mes actual":
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
        break;

      case "Mes anterior":
        final firstDayCurrentMonth = DateTime(now.year, now.month, 1);
        final firstDayPreviousMonth = DateTime(
          firstDayCurrentMonth.year,
          firstDayCurrentMonth.month - 1,
          1,
        );
        final lastDayPreviousMonth = DateTime(
          firstDayCurrentMonth.year,
          firstDayCurrentMonth.month,
          0,
          23,
          59,
          59,
        );
        startDate = firstDayPreviousMonth;
        endDate = lastDayPreviousMonth;
        break;

      case "Año actual":
        startDate = DateTime(now.year, 1, 1);
        endDate = now;
        break;

      case "Personalizado":
        return;
    }

    await _loadData();
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: (startDate != null && endDate != null)
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kyboPrimary,
              secondary: _kyboAccent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        selectedPeriod = "Personalizado";
      });

      await _loadData();
    }
  }

  double get _activePercent =>
      totalUsers == 0 ? 0 : (activeUsers / totalUsers) * 100;

  double get _inactivePercent =>
      totalUsers == 0 ? 0 : (inactiveUsers / totalUsers) * 100;

  double get _blockedPercent =>
      totalUsers == 0 ? 0 : (blockedUsers / totalUsers) * 100;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;
    final isTablet = size.width >= 700 && size.width < 1100;

    return Scaffold(
      backgroundColor: _kyboBg,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: _kyboPrimary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: isMobile ? 16 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(isMobile),
                          const SizedBox(height: 18),
                          _buildTopSummary(isMobile),
                          const SizedBox(height: 18),
                          _buildFilters(isMobile),
                          const SizedBox(height: 20),
                          _buildKpis(isMobile, isTablet),
                          const SizedBox(height: 20),
                          isMobile
                              ? Column(
                                  children: [
                                    _growthChart(isMobile),
                                    const SizedBox(height: 20),
                                    _statusChart(isMobile),
                                  ],
                                )
                              : SizedBox(
                                  height: 430,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: _growthChart(isMobile),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        flex: 2,
                                        child: _statusChart(isMobile),
                                      ),
                                    ],
                                  ),
                                ),
                          const SizedBox(height: 20),
                          _recentUsers(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _kyboCard,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: _kyboPrimary,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Actividad de usuarios",
                style: TextStyle(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.w800,
                  color: _kyboPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Vista general de uso, registros y usuarios sin actividad reciente",
                style: TextStyle(
                  fontSize: isMobile ? 12.5 : 13.5,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopSummary(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2B2257),
            Color(0xFF3B2F79),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _kyboPrimary.withOpacity(.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryTexts(),
                const SizedBox(height: 16),
                _summaryChips(wrap: true),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 4, child: _summaryTexts()),
                const SizedBox(width: 24),
                SizedBox(
                  width: 260,
                  child: _summaryChips(wrap: false),
                ),
              ],
            ),
    );
  }

  Widget _summaryTexts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Panel Kybo",
          style: TextStyle(
            color: Color(0xFFFFD89A),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "$activeUsers usuarios activos y $inactiveUsers inactivos",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Se toma como inactivo quien no registra acceso en más de $_inactiveThresholdDays días.",
          style: TextStyle(
            color: Colors.white.withOpacity(.82),
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _summaryChips({required bool wrap}) {
    final items = [
      _miniStat("Activos", "${_activePercent.toStringAsFixed(1)}%", _success),
      _miniStat("Inactivos", "${_inactivePercent.toStringAsFixed(1)}%", _warning),
      _miniStat("Bloqueados", "${_blockedPercent.toStringAsFixed(1)}%", _danger),
    ];

    if (wrap) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items,
      );
    }

    return Column(
      children: items
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: e,
            ),
          )
          .toList(),
    );
  }

  Widget _miniStat(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              color: Colors.white.withOpacity(.84),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
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

  Widget _buildFilters(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _periodFilter(),
          const SizedBox(height: 12),
          _dateRangeFilter(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 1, child: _periodFilter()),
        const SizedBox(width: 14),
        Expanded(flex: 1, child: _dateRangeFilter()),
      ],
    );
  }

  Widget _periodFilter() {
    return _filterContainer(
      label: "Periodo",
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPeriod,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: BorderRadius.circular(16),
          items: periods.map((p) {
            return DropdownMenuItem<String>(
              value: p,
              child: Text(
                p,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            _applyPeriod(value);
          },
        ),
      ),
    );
  }

  Widget _dateRangeFilter() {
    return _filterContainer(
      label: "Rango de fechas",
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _pickCustomRange,
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: _kyboPrimary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                (startDate != null && endDate != null)
                    ? "${_formatDate(startDate!)} - ${_formatDate(endDate!)}"
                    : "Seleccionar rango",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _kyboPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down_rounded, color: _kyboPrimary),
          ],
        ),
      ),
    );
  }

  Widget _filterContainer({
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: _kyboCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E9F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildKpis(bool isMobile, bool isTablet) {
    return GridView.count(
      crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 2.9 : (isTablet ? 2.2 : 2.55),
      children: [
        _kpiCard(
          title: "Total usuarios",
          value: "$totalUsers",
          subtitle: "Base general registrada",
          color: _info,
          icon: Icons.groups_rounded,
        ),
        _kpiCard(
          title: "Usuarios activos",
          value: "$activeUsers",
          subtitle: "Con acceso en ≤ $_inactiveThresholdDays días",
          color: _success,
          icon: Icons.check_circle_rounded,
        ),
        _kpiCard(
          title: "Usuarios inactivos",
          value: "$inactiveUsers",
          subtitle: "Sin acceso reciente",
          color: _warning,
          icon: Icons.schedule_rounded,
        ),
        _kpiCard(
          title: "Usuarios bloqueados",
          value: "$blockedUsers",
          subtitle: "Acceso restringido",
          color: _danger,
          icon: Icons.block_rounded,
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kyboCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _kyboPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.2,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _growthChart(bool isMobile) {
    final maxY = _calculateMaxY(chartData);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: "Usuarios registrados",
            subtitle: "Registros creados dentro del rango seleccionado",
            icon: Icons.show_chart_rounded,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: isMobile ? 240 : 250,
            child: chartData.isEmpty
                ? _emptyState("No hay registros para este periodo")
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval:
                            maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(.12),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval:
                                maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: _bottomInterval(chartData.length),
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= chartLabels.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  chartLabels[index],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 14,
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          tooltipBgColor: _kyboPrimary,
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              final i = spot.x.toInt();
                              final label = i >= 0 && i < chartLabels.length
                                  ? chartLabels[i]
                                  : '';
                              return LineTooltipItem(
                                "$label\n${spot.y.toInt()} usuarios",
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            chartData.length,
                            (i) =>
                                FlSpot(i.toDouble(), chartData[i].toDouble()),
                          ),
                          isCurved: true,
                          color: _kyboAccent,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: chartData.length <= 12,
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: _kyboAccent.withOpacity(.16),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusChart(bool isMobile) {
    final total = totalUsers == 0 ? 1 : totalUsers;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: "Estado de usuarios",
            subtitle: "Distribución actual del estado",
            icon: Icons.pie_chart_rounded,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: isMobile ? 220 : 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: isMobile ? 48 : 58,
                    sectionsSpace: 3,
                    startDegreeOffset: -90,
                    sections: [
                      _pieSection(activeUsers, _success),
                      _pieSection(inactiveUsers, _warning),
                      _pieSection(blockedUsers, _danger),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "$totalUsers",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _kyboPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _legendItem("Activos", activeUsers, total, _success),
          _legendItem("Inactivos", inactiveUsers, total, _warning),
          _legendItem("Bloqueados", blockedUsers, total, _danger),
        ],
      ),
    );
  }

  Widget _recentUsers() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: "Actividad reciente",
            subtitle: "Últimos usuarios con movimiento o acceso",
            icon: Icons.history_rounded,
          ),
          const SizedBox(height: 10),
          if (recentUsers.isEmpty) _emptyState("No hay actividad reciente"),
          ...recentUsers.map((u) {
            final DateTime? lastLogin = u['lastLogin'] as DateTime?;
            final DateTime? createdAt = u['createdAt'] as DateTime?;
            final bool isBlocked = u['isBlocked'] == true;
            final bool recentlyActive = u['recentlyActive'] == true;
            final String email = (u['email'] ?? '').toString();

            final String statusText = isBlocked
                ? "Bloqueado"
                : recentlyActive
                    ? "Activo"
                    : "Inactivo";

            final Color statusColor = isBlocked
                ? _danger
                : recentlyActive
                    ? _success
                    : _warning;

            return Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFD),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEBEEF5)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _kyboAccent.withOpacity(.20),
                    child: const Icon(
                      Icons.person_rounded,
                      color: _kyboPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (u['name'] ?? 'Usuario').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _kyboPrimary,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.2,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          lastLogin != null
                              ? "Último acceso: ${_formatDateTime(lastLogin)}"
                              : createdAt != null
                                  ? "Registrado: ${_formatDateTime(createdAt)}"
                                  : "Sin fecha disponible",
                          style: TextStyle(
                            fontSize: 12.2,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _kyboPrimary.withOpacity(.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _kyboPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: _kyboPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  PieChartSectionData _pieSection(int value, Color color) {
    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      showTitle: false,
      radius: 22,
    );
  }

  Widget _legendItem(String title, int value, int total, Color color) {
    final percent = total == 0 ? 0.0 : ((value / total) * 100);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _kyboPrimary,
              ),
            ),
          ),
          Text(
            "$value · ${percent.toStringAsFixed(1)}%",
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBEEF5)),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, color: Colors.grey.shade500, size: 30),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kyboCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFEEF0F6)),
      ),
      child: child,
    );
  }

  double _calculateMaxY(List<int> values) {
    if (values.isEmpty) return 4;
    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxValue <= 4) return 4;
    return (maxValue + 1).ceilToDouble();
  }

  double _bottomInterval(int length) {
    if (length <= 7) return 1;
    if (length <= 14) return 2;
    if (length <= 31) return 4;
    if (length <= 90) return 10;
    return (length / 6).ceilToDouble();
  }

  String _shortDateLabel(DateTime date) {
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
      'dic'
    ];
    return "${date.day} ${months[date.month - 1]}";
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatDateTime(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return "${_formatDate(date)} · $hh:$mm";
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}