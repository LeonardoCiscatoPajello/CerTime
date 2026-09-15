import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/event_model.dart';
import '../services/session_service.dart';

class FormScreen extends StatefulWidget {
  final Event? event;
  const FormScreen({super.key, this.event});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  bool _isTraining = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event != null) {
      _titleController.text = event.title;
      _summaryController.text = event.summary ?? '';
      _selectedDate = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
      _startTime = TimeOfDay.fromDateTime(event.startTime);
      _endTime = TimeOfDay.fromDateTime(event.endTime);
      _isTraining = event.isTraining;
    } else {
      final now = TimeOfDay.now();
      _startTime = now;
      _endTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: now.minute);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  double _calculateHours() {
    final start = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _startTime.hour, _startTime.minute,
    );
    final end = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _endTime.hour, _endTime.minute,
    );
    return end.difference(start).inMinutes / 60.0;
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final hours = _calculateHours();

      if (hours <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('L\'orario di fine deve essere successivo a quello di inizio')),
        );
        return;
      }

      final startDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _startTime.hour, _startTime.minute,
      );
      final endDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _endTime.hour, _endTime.minute,
      );

      final event = Event(
        id: widget.event?.id,
        userId: widget.event?.userId ?? SessionService.instance.currentUserId!,
        courseId: widget.event?.courseId,
        title: _titleController.text,
        startTime: startDateTime,
        endTime: endDateTime,
        hours: hours,
        isTraining: _isTraining,
        summary: _isTraining ? _summaryController.text : null,
      );

      if (_isEditing) {
        await DbHelper().updateEvent(event);
      } else {
        await DbHelper().insertEvent(event);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Evento aggiornato con successo' : 'Evento salvato con successo')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica Evento': 'Nuovo Evento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titolo Evento',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci un titolo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('Data'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey, width: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Inizio'),
                      subtitle: Text(_startTime.format(context)),
                      onTap: _pickStartTime,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.grey, width: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ListTile(
                      title: const Text('Fine'),
                      subtitle: Text(_endTime.format(context)),
                      onTap: _pickEndTime,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.grey, width: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Evento di Formazione'),
                subtitle: const Text('Attiva per i requisiti di compliance'),
                value: _isTraining,
                onChanged: (val) {
                  setState(() {
                    _isTraining = val;
                  });
                },
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isTraining
                    ? Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
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
                      if (_isTraining && (value == null || value.isEmpty)) {
                        return 'Il sommario è obbligatorio per la formazione';
                      }
                      return null;
                    },
                  ),
                )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Totale ore stimato: ${_calculateHours().toStringAsFixed(2)} h',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _calculateHours() > 0 ? Colors.blue : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
