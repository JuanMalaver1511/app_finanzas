import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fl_chart/fl_chart.dart';

class NotificationsAdminScreen extends StatefulWidget {
  const NotificationsAdminScreen({super.key});

  @override
  State<NotificationsAdminScreen> createState() =>
      _NotificationsAdminScreenState();
}

class _NotificationsAdminScreenState extends State<NotificationsAdminScreen> {
  static const Color _primary = Color(0xFF2B2257);
  static const Color _accent = Color(0xFFFFB84E);
  static const Color _bg = Color(0xFFF6F7FB);
  static const Color _card = Colors.white;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController userSearchController = TextEditingController();
  final TextEditingController historySearchController = TextEditingController();

  String selectedCategory = 'motivational';
  String selectedTarget = 'all';
  String selectedUserId = '';
  String selectedUserName = '';
  String selectedUserEmail = '';
  String priority = 'normal';

  String historyCategory = 'all';
  String historyChannel = 'all';
  String historyPeriod = 'all';

  String dashboardPeriod = '30';

  bool sendApp = true;
  bool sendEmail = false;
  bool isSending = false;
  bool scheduleMessage = false;
  DateTime? scheduledDateTime;

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    userSearchController.dispose();
    historySearchController.dispose();
    super.dispose();
  }

  Future<void> _pickScheduleDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: scheduledDateTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(scheduledDateTime ?? now),
    );

    if (time == null) return;

    setState(() {
      scheduledDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _sendNotification() async {
    final title = titleController.text.trim();
    final message = messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      _showMessage("Completa el título y el mensaje.");
      return;
    }

    if (!sendApp && !sendEmail) {
      _showMessage("Selecciona al menos un canal de envío.");
      return;
    }

    if (selectedTarget == 'specific_user' && selectedUserId.isEmpty) {
      _showMessage("Selecciona un usuario específico.");
      return;
    }

    setState(() => isSending = true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('sendCustomNotification');

      final result = await callable.call({
        'category': selectedCategory,
        'target': selectedTarget,
        'userId': selectedTarget == 'specific_user' ? selectedUserId : null,
        'title': title,
        'message': message,
        'sendApp': sendApp,
        'sendEmail': sendEmail,
        'priority': priority,
      });

      final data = Map<String, dynamic>.from(result.data as Map);

      if (!mounted) return;

      titleController.clear();
      messageController.clear();
      userSearchController.clear();

      setState(() {
        selectedCategory = 'motivational';
        selectedTarget = 'all';
        selectedUserId = '';
        selectedUserName = '';
        selectedUserEmail = '';
        priority = 'normal';
        sendApp = true;
        sendEmail = false;
      });

      _showMessage(
        "Mensaje enviado. Usuarios: ${data['totalRecipients'] ?? 0}.",
      );
    } on FirebaseFunctionsException catch (e) {
      _showMessage(e.message ?? "No se pudo enviar el mensaje.");
    } catch (e) {
      _showMessage("Error inesperado: $e");
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  Future<void> _scheduleNotification() async {
    final title = titleController.text.trim();
    final message = messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      _showMessage("Completa el título y el mensaje.");
      return;
    }

    if (!sendApp && !sendEmail) {
      _showMessage("Selecciona al menos un canal de envío.");
      return;
    }

    if (selectedTarget == 'specific_user' && selectedUserId.isEmpty) {
      _showMessage("Selecciona un usuario específico.");
      return;
    }

    if (scheduledDateTime == null) {
      _showMessage("Selecciona la fecha y hora de programación.");
      return;
    }

    if (scheduledDateTime!.isBefore(DateTime.now())) {
      _showMessage("La fecha programada debe ser futura.");
      return;
    }

    setState(() => isSending = true);

    try {
      await FirebaseFirestore.instance
          .collection('notification_campaigns')
          .add({
        'category': selectedCategory,
        'target': selectedTarget,
        'userId': selectedTarget == 'specific_user' ? selectedUserId : null,
        'title': title,
        'message': message,
        'sendApp': sendApp,
        'sendEmail': sendEmail,
        'priority': priority,
        'status': 'scheduled',
        'scheduledAt': Timestamp.fromDate(scheduledDateTime!),
        'createdAt': FieldValue.serverTimestamp(),
        'sentAt': null,
        'totalRecipients': 0,
        'appSent': 0,
        'emailSent': 0,
        'readCount': 0,
      });

      if (!mounted) return;

      titleController.clear();
      messageController.clear();
      userSearchController.clear();

      setState(() {
        selectedCategory = 'motivational';
        selectedTarget = 'all';
        selectedUserId = '';
        selectedUserName = '';
        selectedUserEmail = '';
        priority = 'normal';
        sendApp = true;
        sendEmail = false;
        scheduleMessage = false;
        scheduledDateTime = null;
      });

      _showMessage("Campaña programada correctamente.");
    } catch (e) {
      _showMessage("No se pudo programar la campaña: $e");
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  Future<void> _deleteCampaign(String campaignId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Eliminar historial"),
        content: const Text(
          "Esto eliminará esta campaña del historial administrativo. Las notificaciones ya recibidas por los usuarios no se eliminarán.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('notification_campaigns')
        .doc(campaignId)
        .delete();

    if (!mounted) return;
    _showMessage("Campaña eliminada del historial.");
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "Centro de mensajes",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          bottom: const TabBar(
            labelColor: _accent,
            unselectedLabelColor: Colors.white70,
            indicatorColor: _accent,
            tabs: [
              Tab(
                icon: Icon(Icons.dashboard_rounded),
                text: "Dashboard",
              ),
              Tab(
                icon: Icon(Icons.edit_notifications_rounded),
                text: "Nuevo mensaje",
              ),
              Tab(
                icon: Icon(Icons.history_rounded),
                text: "Historial",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _dashboardTab(),
            _newMessageTab(),
            _historyTab(),
          ],
        ),
      ),
    );
  }

  Widget _newMessageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerCard(),
              const SizedBox(height: 18),
              _formCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notification_campaigns')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data!.docs;
        final docs = _filterDashboardDocs(allDocs);

        int totalCampaigns = docs.length;
        int totalRecipients = 0;
        int appSent = 0;
        int emailSent = 0;
        int readCount = 0;

        final Map<String, int> campaignsByDay = {};
        final List<Map<String, dynamic>> campaignRanking = [];

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;

          final recipients = _asInt(data['totalRecipients']);
          final app = _asInt(data['appSent']);
          final email = _asInt(data['emailSent']);
          final reads = _asInt(data['readCount']);
          final createdAt = data['createdAt'];

          totalRecipients += recipients;
          appSent += app;
          emailSent += email;
          readCount += reads;

          if (createdAt is Timestamp) {
            final date = createdAt.toDate();
            final key =
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
            campaignsByDay[key] = (campaignsByDay[key] ?? 0) + 1;
          }

          final rate = app > 0 ? ((reads / app) * 100).round() : 0;

          campaignRanking.add({
            'title': (data['title'] ?? 'Sin título').toString(),
            'category': (data['category'] ?? 'general').toString(),
            'readCount': reads,
            'appSent': app,
            'rate': rate,
          });
        }

        campaignRanking
            .sort((a, b) => (b['rate'] as int).compareTo(a['rate'] as int));

        final notRead = (appSent - readCount).clamp(0, appSent);
        final impact = appSent > 0 ? ((readCount / appSent) * 100).round() : 0;

        final isWide = MediaQuery.of(context).size.width >= 950;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dashboardHeader(),
              const SizedBox(height: 16),
              _dashboardFilter(),
              const SizedBox(height: 16),
              _dashboardKpis(
                totalCampaigns: totalCampaigns,
                totalRecipients: totalRecipients,
                appSent: appSent,
                emailSent: emailSent,
                readCount: readCount,
                notRead: notRead,
                impact: impact,
              ),
              const SizedBox(height: 18),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _impactDonutChart(readCount, notRead),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _channelsBarChart(appSent, emailSent),
                    ),
                  ],
                )
              else ...[
                _impactDonutChart(readCount, notRead),
                const SizedBox(height: 16),
                _channelsBarChart(appSent, emailSent),
              ],
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _campaignsByDayChart(campaignsByDay),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _topCampaignsCard(campaignRanking),
                    ),
                  ],
                )
              else ...[
                _campaignsByDayChart(campaignsByDay),
                const SizedBox(height: 16),
                _topCampaignsCard(campaignRanking),
              ],
            ],
          ),
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filterDashboardDocs(
    List<QueryDocumentSnapshot> docs,
  ) {
    final now = DateTime.now();

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = data['createdAt'];

      if (dashboardPeriod == 'all') return true;
      if (createdAt is! Timestamp) return false;

      final date = createdAt.toDate();

      if (dashboardPeriod == 'today') {
        final start = DateTime(now.year, now.month, now.day);
        return !date.isBefore(start);
      }

      if (dashboardPeriod == '7') {
        final start = now.subtract(const Duration(days: 7));
        return !date.isBefore(start);
      }

      if (dashboardPeriod == '30') {
        final start = now.subtract(const Duration(days: 30));
        return !date.isBefore(start);
      }

      return true;
    }).toList();
  }

  Widget _dashboardHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.analytics_rounded, color: _accent, size: 34),
          SizedBox(height: 14),
          Text(
            "Dashboard de mensajes",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Analiza campañas, lectura en app, canales usados y rendimiento de los mensajes enviados.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonFormField<String>(
        value: dashboardPeriod,
        decoration: _inputDecoration("Periodo del dashboard"),
        items: const [
          DropdownMenuItem(value: 'today', child: Text('Hoy')),
          DropdownMenuItem(value: '7', child: Text('Últimos 7 días')),
          DropdownMenuItem(value: '30', child: Text('Últimos 30 días')),
          DropdownMenuItem(value: 'all', child: Text('Todo el historial')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => dashboardPeriod = value);
        },
      ),
    );
  }

  Widget _dashboardKpis({
    required int totalCampaigns,
    required int totalRecipients,
    required int appSent,
    required int emailSent,
    required int readCount,
    required int notRead,
    required int impact,
  }) {
    final cards = [
      _summaryMiniCard(
        icon: Icons.campaign_rounded,
        label: "Campañas",
        value: "$totalCampaigns",
        subtitle: "en el periodo",
      ),
      _summaryMiniCard(
        icon: Icons.group_rounded,
        label: "Alcance",
        value: "$totalRecipients",
        subtitle: "destinatarios",
      ),
      _summaryMiniCard(
        icon: Icons.notifications_active_rounded,
        label: "App",
        value: "$appSent",
        subtitle: "guardadas",
      ),
      _summaryMiniCard(
        icon: Icons.email_rounded,
        label: "Correo",
        value: "$emailSent",
        subtitle: "enviados",
      ),
      _summaryMiniCard(
        icon: Icons.visibility_rounded,
        label: "Vistos",
        value: "$readCount",
        subtitle: "$impact% lectura",
      ),
      _summaryMiniCard(
        icon: Icons.visibility_off_rounded,
        label: "No vistos",
        value: "$notRead",
        subtitle: "pendientes",
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        if (isMobile) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: constraints.maxWidth >= 1200 ? 6 : 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: cards,
        );
      },
    );
  }

  Widget _chartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _impactDonutChart(int readCount, int notRead) {
    final total = readCount + notRead;

    return _chartCard(
      title: "Lectura en app",
      subtitle: "Comparación entre vistos y no vistos.",
      child: total == 0
          ? _emptyChart("Aún no hay datos de lectura.")
          : SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 54,
                  sections: [
                    PieChartSectionData(
                      value: readCount.toDouble(),
                      color: Colors.green,
                      title: "Vistos\n$readCount",
                      radius: 68,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: notRead.toDouble(),
                      color: Colors.red,
                      title: "No vistos\n$notRead",
                      radius: 68,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _channelsBarChart(int appSent, int emailSent) {
    final maxValue = [appSent, emailSent, 1].reduce((a, b) => a > b ? a : b);

    return _chartCard(
      title: "Canales de envío",
      subtitle: "Comparación entre app y correo.",
      child: SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            maxY: maxValue.toDouble() + 2,
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    switch (value.toInt()) {
                      case 0:
                        return const Text("App");
                      case 1:
                        return const Text("Correo");
                      default:
                        return const Text("");
                    }
                  },
                ),
              ),
            ),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: appSent.toDouble(),
                    color: _primary,
                    width: 34,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: emailSent.toDouble(),
                    color: _accent,
                    width: 34,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campaignsByDayChart(Map<String, int> campaignsByDay) {
    final entries = campaignsByDay.entries.toList();

    if (entries.isEmpty) {
      return _chartCard(
        title: "Campañas por día",
        subtitle: "Última actividad registrada.",
        child: _emptyChart("No hay campañas en este periodo."),
      );
    }

    entries.sort((a, b) => a.key.compareTo(b.key));
    final maxValue =
        entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return _chartCard(
      title: "Campañas por día",
      subtitle: "Evolución de envíos en el periodo seleccionado.",
      child: SizedBox(
        height: 260,
        child: LineChart(
          LineChartData(
            maxY: maxValue.toDouble() + 1,
            minY: 0,
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= entries.length) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        entries[index].key,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: _primary,
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: _primary.withOpacity(.10),
                ),
                spots: List.generate(
                  entries.length,
                  (index) => FlSpot(
                    index.toDouble(),
                    entries[index].value.toDouble(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topCampaignsCard(List<Map<String, dynamic>> campaigns) {
    final top = campaigns.take(5).toList();

    return _chartCard(
      title: "Top campañas",
      subtitle: "Mejor tasa de lectura en app.",
      child: top.isEmpty
          ? _emptyChart("No hay campañas para rankear.")
          : Column(
              children: top.map((item) {
                final title = item['title'].toString();
                final rate = item['rate'] as int;
                final reads = item['readCount'] as int;
                final app = item['appSent'] as int;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: rate / 100,
                          minHeight: 9,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _impactColor(rate),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "$rate% lectura · $reads vistos de $app enviados",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _emptyChart(String text) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.campaign_rounded, color: _accent, size: 34),
          SizedBox(height: 14),
          Text(
            "Crear campaña",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Configura el destinatario, el canal y el contenido del mensaje antes de enviarlo.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 850;

          final configColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                icon: Icons.tune_rounded,
                title: "Configuración",
                subtitle: "Define a quién se enviará y por qué canal.",
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: _inputDecoration("Categoría del mensaje"),
                items: const [
                  DropdownMenuItem(
                      value: 'motivational', child: Text('Motivacional')),
                  DropdownMenuItem(
                      value: 'reminder', child: Text('Recordatorio')),
                  DropdownMenuItem(
                      value: 'announcement', child: Text('Anuncio')),
                  DropdownMenuItem(
                      value: 'financial_education',
                      child: Text('Educación financiera')),
                  DropdownMenuItem(
                      value: 'alert', child: Text('Alerta manual')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedCategory = value);
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedTarget,
                decoration: _inputDecoration("Destinatarios"),
                items: const [
                  DropdownMenuItem(
                      value: 'all', child: Text('Todos los usuarios')),
                  DropdownMenuItem(
                      value: 'active', child: Text('Usuarios activos')),
                  DropdownMenuItem(
                      value: 'inactive', child: Text('Usuarios inactivos')),
                  DropdownMenuItem(
                      value: 'blocked', child: Text('Usuarios bloqueados')),
                  DropdownMenuItem(
                      value: 'never_logged',
                      child: Text('Usuarios sin primer acceso')),
                  DropdownMenuItem(
                      value: 'specific_user',
                      child: Text('Usuario específico')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedTarget = value;
                    selectedUserId = '';
                    selectedUserName = '';
                    selectedUserEmail = '';
                    userSearchController.clear();
                  });
                },
              ),
              if (selectedTarget == 'specific_user') ...[
                const SizedBox(height: 14),
                _specificUserSelector(),
              ],
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: _inputDecoration("Prioridad"),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Baja')),
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'high', child: Text('Alta')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => priority = value);
                },
              ),
              const SizedBox(height: 18),
              const Text(
                "Canales de envío",
                style: TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _channelChip(
                    label: "Aplicación",
                    icon: Icons.notifications_active_rounded,
                    value: sendApp,
                    onChanged: (value) => setState(() => sendApp = value),
                  ),
                  _channelChip(
                    label: "Correo",
                    icon: Icons.email_rounded,
                    value: sendEmail,
                    onChanged: (value) => setState(() => sendEmail = value),
                  ),
                ],
              ),
            ],
          );

          final contentColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                icon: Icons.edit_note_rounded,
                title: "Contenido del mensaje",
                subtitle: "Redacta el mensaje que verá el usuario.",
              ),
              const SizedBox(height: 18),
              TextField(
                controller: titleController,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration("Título"),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: messageController,
                onChanged: (_) => setState(() {}),
                maxLines: 7,
                decoration: _inputDecoration("Mensaje"),
              ),
              const SizedBox(height: 18),
              _messagePreview(),
              const SizedBox(height: 22),
              _scheduleSection(),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSending
                      ? null
                      : scheduleMessage
                          ? _scheduleNotification
                          : _sendNotification,
                  icon: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _primary,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    isSending
                        ? "Procesando..."
                        : scheduleMessage
                            ? "Programar campaña"
                            : "Enviar campaña",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: configColumn),
                const SizedBox(width: 24),
                Expanded(child: contentColumn),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              configColumn,
              const SizedBox(height: 26),
              contentColumn,
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _primary.withOpacity(.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _messagePreview() {
    final title = titleController.text.trim();
    final message = messageController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Vista previa",
            style: TextStyle(
              color: _primary,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: _accent,
                  child: Icon(Icons.notifications_rounded, color: _primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? "Título del mensaje" : title,
                        style: TextStyle(
                          color: title.isEmpty ? Colors.grey : _primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        message.isEmpty
                            ? "Aquí se mostrará el contenido que recibirá el usuario."
                            : message,
                        style: TextStyle(
                          color: message.isEmpty ? Colors.grey : Colors.black87,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specificUserSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: userSearchController,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration("Buscar usuario por nombre o correo"),
          ),
          const SizedBox(height: 12),
          if (selectedUserId.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primary.withOpacity(.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _primary.withOpacity(.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: _primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "$selectedUserName\n$selectedUserEmail",
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        selectedUserId = '';
                        selectedUserName = '';
                        selectedUserEmail = '';
                      });
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final query = userSearchController.text.trim().toLowerCase();

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();

                if (query.isEmpty) return true;
                return name.contains(query) || email.contains(query);
              }).toList();

              if (docs.isEmpty) {
                return Text(
                  "No hay usuarios con esa búsqueda.",
                  style: TextStyle(color: Colors.grey.shade700),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? 'Sin nombre').toString();
                  final email = (data['email'] ?? '').toString();
                  final role = (data['role'] ?? 'user').toString();

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: _accent.withOpacity(.25),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(email),
                    trailing: Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        color: role == 'admin' ? Colors.red : Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        selectedUserId = doc.id;
                        selectedUserName = name;
                        selectedUserEmail = email;
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _historyTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notification_campaigns')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredDocs = _filterHistoryDocs(snapshot.data!.docs);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _historyFilters(),
                  const SizedBox(height: 14),
                  if (snapshot.data!.docs.isNotEmpty)
                    _historySummary(snapshot.data!.docs, filteredDocs),
                  const SizedBox(height: 14),
                  if (filteredDocs.isEmpty)
                    _emptyHistory()
                  else
                    ...filteredDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _historyCard(doc.id, data);
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filterHistoryDocs(
    List<QueryDocumentSnapshot> docs,
  ) {
    final search = historySearchController.text.trim().toLowerCase();
    final now = DateTime.now();

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final title = (data['title'] ?? '').toString().toLowerCase();
      final message = (data['message'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? 'general').toString();
      final sendAppValue = data['sendApp'] == true;
      final sendEmailValue = data['sendEmail'] == true;
      final createdAt = data['createdAt'];

      if (search.isNotEmpty &&
          !title.contains(search) &&
          !message.contains(search)) {
        return false;
      }

      if (historyCategory != 'all' && category != historyCategory) {
        return false;
      }

      if (historyChannel == 'app' && !sendAppValue) return false;
      if (historyChannel == 'email' && !sendEmailValue) return false;
      if (historyChannel == 'both' && (!sendAppValue || !sendEmailValue)) {
        return false;
      }

      if (historyPeriod != 'all' && createdAt is Timestamp) {
        final date = createdAt.toDate();

        if (historyPeriod == 'today') {
          final start = DateTime(now.year, now.month, now.day);
          if (date.isBefore(start)) return false;
        }

        if (historyPeriod == '7') {
          final start = now.subtract(const Duration(days: 7));
          if (date.isBefore(start)) return false;
        }

        if (historyPeriod == '30') {
          final start = now.subtract(const Duration(days: 30));
          if (date.isBefore(start)) return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _historyFilters() {
    final isMobile = MediaQuery.of(context).size.width < 720;

    final filters = [
      DropdownButtonFormField<String>(
        value: historyPeriod,
        decoration: _inputDecoration("Fecha"),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('Todas')),
          DropdownMenuItem(value: 'today', child: Text('Hoy')),
          DropdownMenuItem(value: '7', child: Text('Últimos 7 días')),
          DropdownMenuItem(value: '30', child: Text('Últimos 30 días')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => historyPeriod = value);
        },
      ),
      DropdownButtonFormField<String>(
        value: historyCategory,
        decoration: _inputDecoration("Categoría"),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('Todas')),
          DropdownMenuItem(value: 'motivational', child: Text('Motivacional')),
          DropdownMenuItem(value: 'reminder', child: Text('Recordatorio')),
          DropdownMenuItem(value: 'announcement', child: Text('Anuncio')),
          DropdownMenuItem(
            value: 'financial_education',
            child: Text('Educación financiera'),
          ),
          DropdownMenuItem(value: 'alert', child: Text('Alerta')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => historyCategory = value);
        },
      ),
      DropdownButtonFormField<String>(
        value: historyChannel,
        decoration: _inputDecoration("Canal"),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('Todos')),
          DropdownMenuItem(value: 'app', child: Text('App')),
          DropdownMenuItem(value: 'email', child: Text('Correo')),
          DropdownMenuItem(value: 'both', child: Text('App + correo')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => historyChannel = value);
        },
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Historial de envíos",
            style: TextStyle(
              color: _primary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Consulta campañas enviadas, filtra por fecha, categoría o canal y revisa los vistos en app.",
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: historySearchController,
            onChanged: (_) => setState(() {}),
            decoration:
                _inputDecoration("Buscar por título o mensaje").copyWith(
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          if (isMobile)
            Column(
              children: filters
                  .map(
                    (filter) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: filter,
                    ),
                  )
                  .toList(),
            )
          else
            Row(
              children: filters
                  .map(
                    (filter) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: filter,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _historySummary(
    List<QueryDocumentSnapshot> allDocs,
    List<QueryDocumentSnapshot> filteredDocs,
  ) {
    int totalRecipients = 0;
    int appSent = 0;
    int emailSent = 0;
    int readCount = 0;

    for (final doc in filteredDocs) {
      final data = doc.data() as Map<String, dynamic>;
      totalRecipients += _asInt(data['totalRecipients']);
      appSent += _asInt(data['appSent']);
      emailSent += _asInt(data['emailSent']);
      readCount += _asInt(data['readCount']);
    }

    final notRead = (appSent - readCount).clamp(0, appSent);
    final impact = appSent > 0 ? ((readCount / appSent) * 100).round() : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        final cards = [
          _summaryMiniCard(
            icon: Icons.campaign_rounded,
            label: "Campañas",
            value: "${filteredDocs.length}",
            subtitle: "de ${allDocs.length} registros",
          ),
          _summaryMiniCard(
            icon: Icons.group_rounded,
            label: "Destinatarios",
            value: "$totalRecipients",
            subtitle: "usuarios alcanzados",
          ),
          _summaryMiniCard(
            icon: Icons.visibility_rounded,
            label: "Vistos app",
            value: "$readCount",
            subtitle: "$impact% de lectura",
          ),
          _summaryMiniCard(
            icon: Icons.visibility_off_rounded,
            label: "No vistos",
            value: "$notRead",
            subtitle: "pendientes en app",
          ),
          _summaryMiniCard(
            icon: Icons.email_rounded,
            label: "Correos",
            value: "$emailSent",
            subtitle: "enviados",
          ),
        ];

        if (isMobile) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (card) => SizedBox(
                  width: 190,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _summaryMiniCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(String campaignId, Map<String, dynamic> data) {
    final title = (data['title'] ?? 'Sin título').toString();
    final message = (data['message'] ?? '').toString();
    final category = (data['category'] ?? 'general').toString();
    final target = (data['target'] ?? 'all').toString();

    final totalRecipients = _asInt(data['totalRecipients']);
    final appSent = _asInt(data['appSent']);
    final emailSent = _asInt(data['emailSent']);
    final readCount = _asInt(data['readCount']);
    final notRead = (appSent - readCount).clamp(0, appSent);
    final impact = appSent > 0 ? ((readCount / appSent) * 100).round() : 0;

    final createdAt = data['createdAt'];

    String dateText = 'Fecha no disponible';
    if (createdAt is Timestamp) {
      final date = createdAt.toDate();
      dateText =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    final impactColor = _impactColor(impact);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: impactColor.withOpacity(.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _badge(_categoryLabel(category), _primary),
                    _badge(_targetLabel(target), Colors.blueGrey),
                    _badge(dateText, Colors.grey),
                    _badge("Lectura $impact%", impactColor),
                  ],
                ),
              ),
              IconButton(
                tooltip: "Eliminar del historial",
                onPressed: () => _deleteCampaign(campaignId),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 21,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _primary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 520;

              final metrics = [
                _metric(
                    Icons.group_rounded, "Destinatarios", "$totalRecipients"),
                _metric(Icons.notifications_rounded, "App", "$appSent"),
                _metric(Icons.email_rounded, "Correo", "$emailSent"),
                _metric(Icons.visibility_rounded, "Vistos", "$readCount"),
                _metric(Icons.visibility_off_rounded, "No vistos", "$notRead"),
              ];

              if (isMobile) {
                return Column(
                  children: metrics
                      .map(
                        (metric) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child:
                              SizedBox(width: double.infinity, child: metric),
                        ),
                      )
                      .toList(),
                );
              }

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: metrics,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyHistory() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_unread_rounded,
                size: 46, color: Colors.grey.shade500),
            const SizedBox(height: 14),
            const Text(
              "No hay mensajes para mostrar",
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Ajusta los filtros o envía una nueva campaña desde el centro de mensajes.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleSection() {
    String dateText = "Sin fecha seleccionada";

    if (scheduledDateTime != null) {
      final d = scheduledDateTime!;
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      final hour = d.hour.toString().padLeft(2, '0');
      final minute = d.minute.toString().padLeft(2, '0');

      dateText = "$day/$month/${d.year} · $hour:$minute";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Programación",
            style: TextStyle(
              color: _primary,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: scheduleMessage,
            activeColor: _primary,
            title: const Text(
              "Programar campaña",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              scheduleMessage
                  ? "El mensaje se enviará en la fecha seleccionada."
                  : "El mensaje se enviará inmediatamente.",
            ),
            onChanged: (value) {
              setState(() {
                scheduleMessage = value;
                if (!value) scheduledDateTime = null;
              });
            },
          ),
          if (scheduleMessage) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickScheduleDateTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded, color: _primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dateText,
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(Icons.edit_calendar_rounded, color: _primary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _channelChip({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value ? _primary.withOpacity(.08) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? _primary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: value ? _primary : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: value ? _primary : Colors.grey.shade700,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              value ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: value ? _primary : Colors.grey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _primary),
          const SizedBox(width: 7),
          Text(
            "$label: ",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 1.4),
      ),
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Color _impactColor(int percent) {
    if (percent >= 70) return Colors.green;
    if (percent >= 35) return Colors.orange;
    return Colors.red;
  }

  String _categoryLabel(String value) {
    switch (value) {
      case 'motivational':
        return 'Motivacional';
      case 'reminder':
        return 'Recordatorio';
      case 'announcement':
        return 'Anuncio';
      case 'financial_education':
        return 'Educación financiera';
      case 'alert':
        return 'Alerta';
      default:
        return 'General';
    }
  }

  String _targetLabel(String value) {
    switch (value) {
      case 'all':
        return 'Todos';
      case 'active':
        return 'Activos';
      case 'inactive':
        return 'Inactivos';
      case 'blocked':
        return 'Bloqueados';
      case 'never_logged':
        return 'Sin primer acceso';
      case 'specific_user':
        return 'Usuario específico';
      default:
        return value;
    }
  }
}
