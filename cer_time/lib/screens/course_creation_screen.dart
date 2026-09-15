import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import '../services/session_service.dart';

class CourseCreationScreen extends StatefulWidget {
  const CourseCreationScreen({super.key});

  @override
  State<CourseCreationScreen> createState() => _CourseCreationScreenState();
}

class _CourseCreationScreenState extends State<CourseCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 7));
  late Future<List<AppUser>> _employeesFuture;
  final Set<int> _selectedEmployeeIds = {};

  @override
  void initState() {
    super.initState();
    _employeesFuture = DbHelper().getEmployeesForManager(SessionService.instance.currentUserId!);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2030),
    );
    if(picked != null) setState(() => _scheduledDate = picked);
  }
  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno un dipendente')),
      );
      return;
    }

    final duration = double.tryParse(_durationController.text.replaceAll(',', '.'));
    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci una durata valida')),
      );
      return;
    }

    final courseId = await DbHelper().createCourse(
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      scheduledDate: _scheduledDate,
      durationHours: duration,
      createdBy: SessionService.instance.currentUserId!,
    );

    await DbHelper().assignCoursesToUsers(courseId, _selectedEmployeeIds.toList());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Corso assegnato a ${_selectedEmployeeIds.length} dipendenti')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo Corso'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titolo Corso', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Inserisci un titolo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrizione (opzionale)', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Data pianificata'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_scheduledDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey, width: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Durata prevista (ore)', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Inserisci la durata' : null,
              ),
              const SizedBox(height: 24),
              Text('Assegna a', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),


              FutureBuilder<List<AppUser>>(
                future: _employeesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final employees = snapshot.data ?? [];
                  if (employees.isEmpty) {
                    return const Text('Nessun dipendente associato a questo account');
                  }
                  final allSelected = _selectedEmployeeIds.length == employees.length;
                  return Column(
                    children: [
                      CheckboxListTile(
                        title: const Text('Seleziona tutti', style: TextStyle(fontWeight: FontWeight.bold)),
                        value: allSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedEmployeeIds.addAll(employees.map((e) => e.id));
                            } else {
                              _selectedEmployeeIds.clear();
                            }
                          });
                        },
                      ),
                      const Divider(height: 1),
                      ...employees.map((emp) {
                        return CheckboxListTile(
                          title: Text(emp.name),
                          value: _selectedEmployeeIds.contains(emp.id),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedEmployeeIds.add(emp.id);
                              } else {
                                _selectedEmployeeIds.remove(emp.id);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}