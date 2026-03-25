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

  List<int> chartData = [];
  List<Map<String, dynamic>> recentUsers = [];

  bool isLoading = true;

  int daysFilter = 7;
  DateTime selectedDate = DateTime.now();

  /// NUEVO (rango)
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

    final now = selectedDate;
    final start = startDate ?? now.subtract(Duration(days: daysFilter));

    int active = 0;
    int inactive = 0;
    int blocked = 0;

    List<int> tempChart = List.filled(daysFilter, 0);
    List<Map<String, dynamic>> tempRecent = [];

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

      /// FILTRO CON RANGO
      if (createdAt != null &&
          createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          createdAt.isBefore(now.add(const Duration(seconds: 1)))) {
        final diff = now.difference(createdAt).inDays;

        if (diff >= 0 && diff < daysFilter) {
          int index = (daysFilter - 1) - diff;

          if (index >= 0 && index < tempChart.length) {
            tempChart[index]++;
          }
        }
      }

      /// ACTIVIDAD FILTRADA
      if (lastLogin != null &&
          lastLogin.isAfter(start) &&
          lastLogin.isBefore(now)) {
        tempRecent.add({
          "name": data['name'] ?? "Usuario",
          "lastLogin": lastLogin,
        });
      }
    }

    tempRecent
        .sort((a, b) => (b['lastLogin'] as DateTime).compareTo(a['lastLogin']));

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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                /// 🔥 BOTÓN MINIMALISTA
                                IconButton(
                                  icon: const Icon(Icons.date_range),
                                  tooltip: "Filtrar por rango",
                                  onPressed: () async {
                                    final range = await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),

                                      /// 🔥 ESPAÑOL
                                      locale: const Locale('es', 'ES'),
                                    );

                                    if (range != null) {
                                      setState(() {
                                        startDate = range.start;
                                        endDate = range.end;
                                        selectedDate = range.end;
                                        daysFilter = range.end
                                                .difference(range.start)
                                                .inDays +
                                            1;
                                      });

                                      _loadData();
                                    }
                                  },
                                ),

                                DropdownButton<int>(
                                  value: daysFilter,
                                  items: const [
                                    DropdownMenuItem(
                                        value: 7, child: Text("7 días")),
                                    DropdownMenuItem(
                                        value: 30, child: Text("30 días")),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      daysFilter = value!;
                                      startDate = null;
                                      endDate = null;
                                    });
                                    _loadData();
                                  },
                                ),
                              ],
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

                        /// GRÁFICAS
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

                        /// CALENDARIO + LISTA
                        isMobile
                            ? Column(
                                children: [
                                  _calendar(isMobile),
                                  const SizedBox(height: 20),
                                  _recentUsers(),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: _calendar(isMobile)),
                                  const SizedBox(width: 20),
                                  Expanded(child: _recentUsers()),
                                ],
                              ),
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
      child: SizedBox(
        height: isMobile ? 180 : 220,
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  chartData.length,
                  (i) => FlSpot(i.toDouble(), chartData[i].toDouble()),
                ),
                isCurved: true,
                color: Colors.blue,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _donut(bool isMobile) {
    final total = totalUsers == 0 ? 1 : totalUsers;

    return _card(
      child: Column(
        children: [
          const Text("Distribución de usuarios",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: isMobile ? 180 : 200,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sections: [
                  _section(activeUsers, Colors.green),
                  _section(inactiveUsers, Colors.orange),
                  _section(blockedUsers, Colors.red),
                ],
              ),
            ),
          ),
          _legend("Activos", activeUsers, total, Colors.green),
          _legend("Inactivos", inactiveUsers, total, Colors.orange),
          _legend("Bloqueados", blockedUsers, total, Colors.red),
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

  Widget _legend(String title, int value, int total, Color color) {
    final percent = (value / total) * 100;
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 6),
        Text("$title (${percent.toStringAsFixed(1)}%)"),
      ],
    );
  }

  Widget _recentUsers() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Actividad reciente",
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...recentUsers.map((u) {
            final d = u['lastLogin'] as DateTime;
            return ListTile(
              dense: true,
              title: Text(u['name']),
              subtitle: Text(
                  "${d.day}/${d.month} ${d.hour}:${d.minute.toString().padLeft(2, '0')}"),
            );
          })
        ],
      ),
    );
  }

  Widget _calendar(bool isMobile) {
    return _card(
      child: SizedBox(
        height: isMobile ? 280 : 300,
        child: CalendarDatePicker(
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          onDateChanged: (date) {
            setState(() {
              selectedDate = date;
              startDate = null;
              endDate = null;
            });
            _loadData();
          },
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
