import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../database/events_notifier.dart';
import '../models/user_model.dart';
import '../services/export_service.dart';
import '../services/session_service.dart';
import '../utils/hours_format.dart';
import 'employee_detail_screen.dart';
import 'settings_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  static const double _annualTarget = 40.0;
  late Future<List<Map<String, dynamic>>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
    EventsNotifier.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    EventsNotifier.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _summaryFuture = DbHelper().getTeamComplianceSummary(
          SessionService.instance.currentUserId!);
    });
  }

  Future<void> _exportTeam() async {
    final rows = await DbHelper().getAggregatedEventsForManager(
        SessionService.instance.currentUserId!);
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun dato da esportare per il team')),
      );
      return;
    }
    try {
      await ExportService.exportAggregatedAndShare(rows);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'esportazione: $e')),
      );
    }
  }

  Color _parseColor(String hex) {
    final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Team - ${SessionService.instance.currentUser?.name ?? ""}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Esporta report team',
            onPressed: _exportTeam,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Impostazioni',
            onPressed: () =>
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final summary = snapshot.data ?? [];
          if (summary.isEmpty) {
            return const Center(child: Text('Nessun dipendente associato'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: summary.length,
            itemBuilder: (context, index) {
              final item = summary[index];
              final AppUser user = item['user'];
              final double annual = item['annualHours'];
              final int pending = item['pendingCount'];
              final bool compliant = annual >= _annualTarget;
              final progress = (annual / _annualTarget).clamp(0.0, 1.0);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: _parseColor(user.avatarColor),
                    child: Text(user.name.substring(0, 1)),
                  ),
                  title: Text(user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        color: compliant ? Colors.green : Colors.orange,
                        backgroundColor: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${HoursFormatter.format(annual)} / ${HoursFormatter
                            .format(_annualTarget)} annue'
                            '${pending > 0
                            ? " · $pending corsi in attesa"
                            : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: compliant ? Colors.green.shade700 : Colors.grey
                              .shade700,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            EmployeeDetailScreen(employee: user)),
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}