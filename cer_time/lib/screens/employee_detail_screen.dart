import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/session_service.dart';
import '../utils/hours_format.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final AppUser employee;
  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = DbHelper().getEventsForManagedUser(
      SessionService.instance.currentUserId!,
      widget.employee.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Storico - ${widget.employee.name}')),
      body: FutureBuilder<List<Event>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('Nessun evento registrato per questo dipendente'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(DateFormat('dd MMM yyyy').format(event.startTime)),
                      Text('Durata: ${HoursFormatter.format(event.hours)}'),
                      if (event.isTraining && event.summary != null) ...[
                        const Divider(),
                        Text(event.summary!, style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: event.isTraining ? Colors.green.shade100 : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.isTraining ? 'FORMAZIONE' : 'MEETING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: event.isTraining ? Colors.green.shade800 : Colors.blue.shade800,
                      ),
                    ),
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