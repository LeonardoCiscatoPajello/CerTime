import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/event_model.dart';

class ExportService {
  // Gen CSV From events and share panel
  static Future<void> exportAndShare(List<Event> events) async {
    final scvContent = _buildCsv(events);
    final file = await _writeToTempFile(scvContent);
    await SharePlus.instance.share(
      ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: 'Export CerTime'
      ),
    );
  }

  static String _buildCsv(List<Event> events) {
    final buffer = StringBuffer();
    buffer.writeln('Titolo,Data,Ora Inizio,Ora Fine,Ore,Tipo,Sommario');

    for (final e in events) {
      final date = '${e.startTime.year}-${_pad(e.startTime.month)}-${_pad(e.startTime.day)}';
      final start = '${_pad(e.startTime.hour)}:${_pad(e.startTime.minute)}';
      final end = '${_pad(e.endTime.hour)}:${_pad(e.endTime.minute)}';
      final type = e.isTraining ? 'Formazione' : 'Meeting';
      final summary = _escapeCsvField(e.summary ?? '');
      final title = _escapeCsvField(e.title);

      buffer.writeln('$title,$date,$start,$end,${e.hours.toStringAsFixed(2)},$type,$summary');
    }
    return buffer.toString();
  }

  static String _escapeCsvField(String field) {
    if(field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');

  static Future<File> _writeToTempFile(String content) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/certime_export_$timestamp.csv');
    return file.writeAsString(content);
  }

  static Future<void> exportAggregatedAndShare(List<Map<String, dynamic>> rows) async {
    final buffer = StringBuffer();
    buffer.writeln('Dipendente,Titolo,Data,Ora Inizio,Ora Fine,Ore,Tipo,Sommario');

    for (final r in rows) {
      final start = DateTime.parse(r['start_time']);
      final end = DateTime.parse(r['end_time']);
      final date = '${start.year}-${_pad(start.month)}-${_pad(start.day)}';
      final startStr = '${_pad(start.hour)}:${_pad(start.minute)}';
      final endStr = '${_pad(end.hour)}:${_pad(end.minute)}';
      final type = (r['is_training'] == 1) ? 'Formazione' : 'Meeting';
      final summary = _escapeCsvField(r['summary'] ?? '');
      final title = _escapeCsvField(r['title']);
      final employee = _escapeCsvField(r['employee_name']);

      buffer.writeln('$employee,$title,$date,$startStr,$endStr,'
          '${(r['hours'] as num).toStringAsFixed(2)},$type,$summary');
    }

    final file = await _writeToTempFile(buffer.toString());
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Export Team CerTime',
      ),
    );
  }
}
