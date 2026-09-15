import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../database/events_notifier.dart';
import '../models/pending_course_model.dart';
import '../services/session_service.dart';
import 'course_completion_screen.dart';

class PendingCoursesScreen extends StatefulWidget {
  const PendingCoursesScreen({super.key});

  @override
  State<PendingCoursesScreen> createState() => _PendingCoursesScreenState();
}

class _PendingCoursesScreenState extends State<PendingCoursesScreen> {
  late Future<List<PendingCourse>> _coursesFuture;

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
      _coursesFuture = DbHelper().getPendingCoursesForUser(SessionService.instance.currentUserId!);
    });
  }

  Future<void> _openCompletion(PendingCourse course) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CourseCompletionScreen(course: course)),
    );
    if (result == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Corsi in Programma')),
      body: FutureBuilder<List<PendingCourse>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return const Center(child: Text('Nessun corso da completare'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final isOverdue = course.scheduledDate.isBefore(DateTime.now());
              final isLocked = course.scheduledDate.isAfter(DateTime.now());
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      if (isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'SCADUTO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if(isLocked)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Disponibile dal ${DateFormat('dd/MM/yyyy').format(course.scheduledDate)}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text('Data prevista: ${DateFormat('dd/MM/yyyy').format(course.scheduledDate)}'),
                      Text('Durata: ${course.durationHours.toStringAsFixed(1)} h'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    onPressed: isLocked ? null : () => _openCompletion(course),
                    child: Text(isLocked ? 'Non disponibile' : 'Segna presenza'),
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