import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../database/events_notifier.dart';
import '../services/session_service.dart';
import '../models/training_course_model.dart';
import 'course_creation_screen.dart';

class ManagerCoursesScreen extends StatefulWidget {
  const ManagerCoursesScreen({super.key});

  @override
  State<ManagerCoursesScreen> createState() => _ManagerCourseScreenState();
}

class _ManagerCourseScreenState extends State<ManagerCoursesScreen>{
  late Future<List<Map<String, dynamic>>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
    EventsNotifier.instance.addListener(_refresh);
  }

  @override
  void dispose(){
    EventsNotifier.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh(){
    setState(() {
      _coursesFuture = DbHelper().getCoursesCreatedBy(SessionService.instance.currentUserId!);
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Corsi Creati')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _coursesFuture,
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? [];
          if(data.isEmpty){
            return const Center(child: Text('Nessun corso creato'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index){
              final TrainingCourse course = data[index]['course'];
              final List<Map<String, dynamic>> assignments = data[index]['assignments'];
              final completed = assignments.where((a) => a['status'] == 'completed').length;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy').format(course.scheduledDate)} · '
                        '${course.durationHours.toStringAsFixed(1)}h · $completed/${assignments.length} completati',
                  ),
                  children: assignments.map((a) {
                    final done = a['status'] == 'completed';
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        done ? Icons.check_circle : Icons.hourglass_empty,
                        color: done ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      title: Text(a['name']),
                      trailing: Text(done ? 'Completato' : 'In attesa'),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CourseCreationScreen()),
          );
          if (result == true) _refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}