import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../database/events_notifier.dart';
import '../models/event_model.dart';
import '../services/export_service.dart';
import '../services/session_service.dart';
import 'form_screen.dart';
import '../utils/hours_format.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum HistoryFilter { all, week, month, year, custom }

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter _currentFilter = HistoryFilter.all;
  DateTimeRange? _customRange;
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _refreshEvents();
    EventsNotifier.instance.addListener(_refreshEvents);
  }

  @override
  void dispose() {
    EventsNotifier.instance.removeListener(_refreshEvents);
    super.dispose();
  }

  void _refreshEvents() {
    setState(() {
      _eventsFuture = DbHelper().getEventsForUser(SessionService.instance.currentUserId!);;
    });
  }

  void _openEditForm(Event event){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormScreen(event: event)),
    );
  }

  Future<void> _pickCustomRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if(picked != null){
      setState(() {
        _customRange = picked;
        _currentFilter = HistoryFilter.custom;
      });
    }
  }

  List<Event> _filterEvents(List<Event> events) {
    final now = DateTime.now();
    switch (_currentFilter) {
      case HistoryFilter.week:
        final lastWeek = now.subtract(const Duration(days: 7));
        return events.where((e) => e.startTime.isAfter(lastWeek)).toList();
      case HistoryFilter.month:
        return events.where((e) => e.startTime.month == now.month && e.startTime.year == now.year).toList();
      case HistoryFilter.year:
        return events.where((e) => e.startTime.year == now.year).toList();
      case HistoryFilter.custom:
        if (_customRange == null) return events;
        final start = _customRange!.start;
        final end = DateTime(_customRange!.end.year, _customRange!.end.month, _customRange!.end.day, 23, 59, 59);
        return events.where((e) => e.startTime.isAfter(start.subtract(const Duration(seconds: 1))) && e.startTime.isBefore(end)).toList();
      case HistoryFilter.all:
      default:
        return events;
    }
  }

  Future<void> _confirmDelete(Event event) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text('Sei sicuro di voler eliminare "${event.title}"? L\'azione non è reversibile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ELIMINA'),
          ),
        ],
      ),
    );

    if (confirm == true && event.id != null) {
      final deletedEvent = event;
      await DbHelper().deleteEvent(event.id!);
      _refreshEvents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Evento Eliminato'),
          action: SnackBarAction(
            label: 'Annulla',
            onPressed: () async {
              await DbHelper().insertEvent(deletedEvent);
            },
          ),
        ),
      );
    }
  }

  Future<void> _exportCurrentView() async {
    final allEvents = await _eventsFuture;
    final filtered = _filterEvents(allEvents);

    if(filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun evento da esportare per il filtro corrente')),
      );
      return;
    }

    try {
      await ExportService.exportAndShare(filtered);
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante l\'esportazione: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storico Attività'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Esporta CSV',
            onPressed: _exportCurrentView,
          ),
          PopupMenuButton<HistoryFilter>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              if(filter == HistoryFilter.custom){
                _pickCustomRange();
              } else {
                setState(() {
                  _currentFilter = filter;
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: HistoryFilter.all, child: Text('Tutti')),
              const PopupMenuItem(value: HistoryFilter.week, child: Text('Ultima settimana')),
              const PopupMenuItem(value: HistoryFilter.month, child: Text('Mese corrente')),
              const PopupMenuItem(value: HistoryFilter.year, child: Text('Anno corrente')),
              const PopupMenuItem(value: HistoryFilter.custom, child: Text('Intervallo personalizzato')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_currentFilter != HistoryFilter.all)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text('Filtro attivo: ${_getFilterName(_currentFilter)}'),
                onDeleted: () {
                  setState(() {
                    _currentFilter = HistoryFilter.all;
                    _customRange = null;
                  });
                },
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Event>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Errore: ${snapshot.error}'));
                }

                final allEvents = snapshot.data ?? [];
                final filteredEvents = _filterEvents(allEvents);

                if (filteredEvents.isEmpty) {
                  return const Center(
                    child: Text('Nessun evento trovato per questo periodo'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredEvents.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return _buildEventCard(event);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterName(HistoryFilter filter) {
    switch (filter) {
      case HistoryFilter.week: return 'Settimana';
      case HistoryFilter.month: return 'Mese';
      case HistoryFilter.year: return 'Anno';
      case HistoryFilter.custom:
        if(_customRange == null) return 'Personalizzato';
        final fmt = DateFormat('dd/MM/yy');
        return '${fmt.format(_customRange!.start)} - ${fmt.format(_customRange!.end)}';
      default: return 'Tutti';
    }
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => _openEditForm(event),
        title: Row(
          children: [
            Expanded(
              child: Text(
                event.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: event.isTraining ? Colors.green.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                event.isTraining ? 'FORMAZIONE' : 'RIUNIONE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: event.isTraining ? Colors.green.shade800 : Colors.blue.shade800,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(DateFormat('dd MMM yyyy').format(event.startTime)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Durata: ${HoursFormatter.format(event.hours)}',
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
            ),
            if (event.isTraining && event.summary != null) ...[
              const Divider(),
              const Text(
                'Sommario:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                event.summary!,
                style: const TextStyle(fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDelete(event),
        ),
      ),
    );
  }
}