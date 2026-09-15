import '../services/settings_service.dart';

class HoursFormatter{
  static String format(double hours) {
    if(SettingsService.instance.timeFormat == TimeFormatMode.hhmm) {
      final totalMinutes = (hours * 60).round();
      final h = totalMinutes ~/60;
      final m = totalMinutes % 60;
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${hours.toStringAsFixed(1)} h';
  }
}