import 'package:cer_time/database/events_notifier.dart';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/event_model.dart';
import '../screens/settings_screen.dart';
import '../utils/hours_format.dart';
import '../services/session_service.dart';

class DashboardScreen extends StatefulWidget {
  final ValueNotifier<int>? refreshNotifier;
  const DashboardScreen({super.key, this.refreshNotifier});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const double _monthlyTarget = 8.0;
  static const double _annualTarget = 40.0;
  late Future<List<Event>> _eventsFuture;

  @override
  void initState(){
    super.initState();
    _eventsFuture = DbHelper().getEventsForUser(SessionService.instance.currentUserId!);
    EventsNotifier.instance.addListener(_onEventsChanged);
  }

  void _onEventsChanged(){
    setState(() {
      _eventsFuture = DbHelper().getEventsForUser(SessionService.instance.currentUserId!);
    });
  }

  @override
  void dispose(){
    EventsNotifier.instance.removeListener(_onEventsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CerTime - ${SessionService.instance.currentUser?.name ?? ""}'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Impostazioni',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Event>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];
          final trainingEvents = events.where((e) => e.isTraining).toList();

          final now = DateTime.now();
          final monthlyHours = trainingEvents
              .where((e) => e.startTime.month == now.month && e.startTime.year == now.year)
              .fold(0.0, (sum, e) => sum + e.hours);

          final annualHours = trainingEvents
              .where((e) => e.startTime.year == now.year)
              .fold(0.0, (sum, e) => sum + e.hours);

          final lastTraining = trainingEvents.isNotEmpty ? trainingEvents.first : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Il tuo progresso',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildProgressCircle(
                      context,
                      label: 'Mese Corrente',
                      current: monthlyHours,
                      target: _monthlyTarget,
                      color: Colors.blue,
                    ),
                    _buildProgressCircle(
                      context,
                      label: 'Anno Corrente',
                      current: annualHours,
                      target: _annualTarget,
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  'Ultima Formazione',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (lastTraining != null)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lastTraining.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                '${lastTraining.hours.toStringAsFixed(1)} h',
                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lastTraining.summary ?? 'Nessun sommario disponibile',
                            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('Nessuna formazione registrata'),
                    ),
                  ),
                const SizedBox(height: 32),
                _buildGoalStatus(context, monthlyHours, annualHours),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCircle(
      BuildContext context, {
        required String label,
        required double current,
        required double target,
        required Color color,
      }) {
    final percentage = (current / target).clamp(0.0, 1.0);
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 10,
                backgroundColor: color.withOpacity(0.2),
                color: color,
                strokeCap: StrokeCap.round,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                HoursFormatter.format(current),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        Text('Target: ${HoursFormatter.format(target)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildGoalStatus(BuildContext context, double monthly, double annual) {
    bool monthlyDone = monthly >= _monthlyTarget;
    bool annualDone = annual >= _annualTarget;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _buildStatusRow(
            Icons.check_circle,
            monthlyDone ? Colors.green : colorScheme.onPrimaryContainer.withOpacity(0.5),
            'Stato Mensile: ${monthlyDone ? 'Obiettivo Raggiunto' : 'In corso'}',
            textColor: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            Icons.verified,
            annualDone ? Colors.green : colorScheme.onPrimaryContainer.withOpacity(0.5),
            'Compliance Annuale: ${annualDone ? 'Certificato' : 'In attesa'}',
            textColor: colorScheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, Color color, String text, {Color? textColor}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
        ),
      ],
    );
  }
}
