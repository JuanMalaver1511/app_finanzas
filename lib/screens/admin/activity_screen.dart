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
  int totalUsers = 0;
  int activeUsers = 0;
  int inactiveUsers = 0;
  int blockedUsers = 0;

  String groupBy = "Día";

  String selectedPeriod = "Últimos 7 días";

  final List<String> periods = [
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
  List<Map<String, dynamic>> recentUsers = [];

  bool isLoading = true;

  int daysFilter = 7;
  DateTime selectedDate = DateTime.now();

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
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide =
        Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(_fade);

    _loadData();
    _controller.forward();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    final now = endDate ?? DateTime.now();
    final start = startDate ?? now.subtract(Duration(days: daysFilter));
    int active = 0;
    int inactive = 0;
    int blocked = 0;
    List<Map<String, dynamic>> tempRecent = [];
    int diffDays = now.difference(start).inDays + 1;
    List<int> tempChart = List.filled(diffDays, 0);

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final lastLogin = (data['lastLogin'] as Timestamp?)?.toDate();

      bool isActive = data['isActive'] == true;
      bool isBlocked = data['isBlocked'] == true;

      if (isBlocked) {
        blocked++;
      } else if (isActive) {
        active++;
      } else {
        inactive++;
      }

      if (createdAt != null &&
          createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          createdAt.isBefore(now.add(const Duration(seconds: 1)))) {
        final diff = now.difference(createdAt).inDays;

        if (diff >= 0 && diff < tempChart.length) {
          int index = (tempChart.length - 1) - diff;

          if (index >= 0 && index < tempChart.length) {
            tempChart[index]++;
          }
        }
      }

      if (lastLogin != null &&
          lastLogin.isAfter(start) &&
          lastLogin.isBefore(now)) {
        tempRecent.add({
          "name": data['name'] ?? "Usuario",
          "lastLogin": lastLogin,
        });
      }
    }

    tempRecent.sort((a, b) =>
        (b['lastLogin'] as DateTime).compareTo(a['lastLogin'] as DateTime));

    if (!mounted) return;

    setState(() {
      totalUsers = snapshot.docs.length;
      activeUsers = active;
      inactiveUsers = inactive;
      blockedUsers = blocked;
      chartData = tempChart;
      recentUsers = tempRecent.take(5).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// HEADER
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Expanded(
                              child: Text(
                                "Dashboard de usuarios",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        /// FILTROS PRO
                        Row(
                          children: [
                            /// 🔥 FILTRO PERIODO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Periodo",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _filterBox(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedPeriod,
                                        isExpanded: true,
                                        items: periods.map((p) {
                                          return DropdownMenuItem(
                                            value: p,
                                            child: Text(p),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(
                                              () => selectedPeriod = value!);

                                          final now = DateTime.now();

                                          switch (value) {
                                            case "Hoy":
                                              startDate = DateTime(
                                                  now.year, now.month, now.day);
                                              endDate = now;
                                              break;

                                            case "Ayer":
                                              final ayer = now.subtract(
                                                  const Duration(days: 1));
                                              startDate = DateTime(ayer.year,
                                                  ayer.month, ayer.day);
                                              endDate = ayer;
                                              break;

                                            case "Semana actual":
                                              final startWeek = now.subtract(
                                                  Duration(
                                                      days: now.weekday - 1));
                                              startDate = DateTime(
                                                  startWeek.year,
                                                  startWeek.month,
                                                  startWeek.day);
                                              endDate = now;
                                              break;

                                            case "Últimos 7 días":
                                              startDate = now.subtract(
                                                  const Duration(days: 7));
                                              endDate = now;
                                              break;

                                            case "Últimos 30 días":
                                              startDate = now.subtract(
                                                  const Duration(days: 30));
                                              endDate = now;
                                              break;

                                            case "Mes actual":
                                              startDate = DateTime(
                                                  now.year, now.month, 1);
                                              endDate = now;
                                              break;

                                            case "Mes anterior":
                                              final prevMonth = DateTime(
                                                  now.year, now.month - 1, 1);
                                              startDate = prevMonth;
                                              endDate = DateTime(
                                                  now.year, now.month, 0);
                                              break;

                                            case "Año actual":
                                              startDate =
                                                  DateTime(now.year, 1, 1);
                                              endDate = now;
                                              break;

                                            case "Personalizado":
                                              return;
                                          }

                                          _loadData();
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            /// 🔥 FILTRO FECHA
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Rango de fechas",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () async {
                                      final picked = await showDateRangePicker(
                                        context: context,
                                        initialDateRange:
                                            startDate != null && endDate != null
                                                ? DateTimeRange(
                                                    start: startDate!,
                                                    end: endDate!)
                                                : null,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                        locale: const Locale('es'),
                                      );

                                      if (picked != null) {
                                        setState(() {
                                          startDate = picked.start;
                                          endDate = picked.end;
                                          selectedPeriod = "Personalizado";
                                        });

                                        _loadData();
                                      }
                                    },
                                    child: _filterBox(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.date_range,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              startDate != null &&
                                                      endDate != null
                                                  ? "${startDate!.day}/${startDate!.month} - ${endDate!.day}/${endDate!.month}"
                                                  : "Seleccionar",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Icon(Icons.arrow_drop_down),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// KPIs
                        GridView.count(
                          crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 4),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isMobile ? 2.8 : 2.5,
                          children: [
                            _kpi("Total", "$totalUsers", Colors.blue),
                            _kpi("Activos", "$activeUsers", Colors.green),
                            _kpi("Inactivos", "$inactiveUsers", Colors.orange),
                            _kpi("Bloqueados", "$blockedUsers", Colors.red),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// GRAFICAS
                        isMobile
                            ? Column(
                                children: [
                                  _growthChart(isMobile),
                                  const SizedBox(height: 20),
                                  _donut(isMobile),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: _growthChart(isMobile)),
                                  const SizedBox(width: 20),
                                  Expanded(child: _donut(isMobile)),
                                ],
                              ),

                        const SizedBox(height: 20),

                        _recentUsers(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _kpi(String title, String value, Color color) {
    IconData icon;

    switch (title) {
      case "Total":
        icon = Icons.people;
        break;
      case "Activos":
        icon = Icons.check_circle;
        break;
      case "Inactivos":
        icon = Icons.pause_circle;
        break;
      case "Bloqueados":
        icon = Icons.block;
        break;
      default:
        icon = Icons.info;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.85), color],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _growthChart(bool isMobile) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔥 TÍTULO
          const Text(
            "Usuarios registrados",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: isMobile ? 180 : 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            "D${value.toInt() + 1}",
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      chartData.length,
                      (i) => FlSpot(i.toDouble(), chartData[i].toDouble()),
                    ),
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF3B82F6).withOpacity(0.15),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          "${spot.y.toInt()} usuarios",
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _donut(bool isMobile) {
    final total = totalUsers == 0 ? 1 : totalUsers;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔥 TÍTULO
          const Text(
            "Distribución de usuarios",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          /// 🔥 DONUT + TOTAL CENTRO
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: isMobile ? 180 : 200,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    sections: [
                      _section(activeUsers, Colors.green),
                      _section(inactiveUsers, Colors.orange),
                      _section(blockedUsers, Colors.red),
                    ],
                  ),
                ),
              ),

              /// 🔥 TOTAL EN EL CENTRO
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Total",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    "$totalUsers",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// 🔥 LEYENDA PRO
          _legendItem("Activos", activeUsers, total, Colors.green),
          _legendItem("Inactivos", inactiveUsers, total, Colors.orange),
          _legendItem("Bloqueados", blockedUsers, total, Colors.red),
        ],
      ),
    );
  }

  PieChartSectionData _section(int value, Color color) {
    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      showTitle: false,
    );
  }

  Widget _legendItem(String title, int value, int total, Color color) {
    final percent = ((value / total) * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          /// COLOR
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(width: 8),

          /// TEXTO
          Expanded(
            child: Text(title),
          ),

          /// VALOR + %
          Text(
            "$value ($percent%)",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _recentUsers() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔥 TÍTULO
          const Text(
            "Actividad reciente",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          /// 🔥 LISTA
          if (recentUsers.isEmpty) const Text("No hay actividad reciente"),

          ...recentUsers.map((u) {
            final d = u['lastLogin'] as DateTime?;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFB84E),
                child: Icon(Icons.person, color: Colors.black),
              ),
              title: Text(
                u['name'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: d != null
                  ? Text(
                      "${d.day}/${d.month} - ${d.hour}:${d.minute.toString().padLeft(2, '0')}",
                    )
                  : const Text("Sin fecha"),
            );
          }),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _filterBox({required Widget child}) {
    return Container(
      height: 48, // 🔥 MISMA ALTURA PARA TODO
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(child: child),
    );
  }
}
