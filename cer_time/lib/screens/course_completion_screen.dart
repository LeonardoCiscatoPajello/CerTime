import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/event_model.dart';
import '../models/pending_course_model.dart';
import '../services/session_service.dart';

class CourseCompletionScreen extends StatefulWidget {
  final PendingCourse course;
  const CourseCompletionScreen({super.key, required this.course});

  @override
  State<CourseCompletionScreen> createState() => _CourseCompletionScreenState();
}

class _CourseCompletionScreenState extends State<CourseCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  late TextEditingController _hoursController;
  DateTime _completionDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(text: widget.course.durationHours.toStringAsFixed(1));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _completionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _completionDate = picked);
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final hours = double.tryParse(_hoursController.text.replaceAll(',', '.'));
    if (hours == null || hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un numero di ore valido')),
      );
      return;
    }

    final start = DateTime(_completionDate.year, _completionDate.month, _completionDate.day, 9, 0);
    final end = start.add(Duration(minutes: (hours * 60).round()));

    final event = Event(
      userId: SessionService.instance.currentUserId!,
      courseId: widget.course.courseId,
      title: widget.course.title,
      startTime: start,
      endTime: end,
      hours: hours,
      isTraining: true,
      summary: _summaryController.text,
    );
    try {
      await DbHelper().completeCourseAssignment(
        assignmentId: widget.course.assignmentId,
        event: event,
      );
    } catch(e){
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('StateError', ''))),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Corso completato con successo')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Segna Presenza'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.course.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (widget.course.description != null && widget.course.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(widget.course.description!, style: const TextStyle(color: Colors.grey)),
              ],
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Data completamento'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_completionDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey, width: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hoursController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Ore di presenza effettive',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Inserisci le ore';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  labelText: 'Sommario Didattico *',
                  helperText: 'Richiesto per audit aziendale',
                  hintText: 'Cosa hai imparato?',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 200,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Il sommario è obbligatorio per la formazione';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}