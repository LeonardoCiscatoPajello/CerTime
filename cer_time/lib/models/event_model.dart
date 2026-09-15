class Event {
  final int? id;
  final int userId;
  final int? courseId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final double hours;
  final bool isTraining;
  final String? summary;

  Event({
    this.id,
    required this.userId,
    this.courseId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.hours,
    required this.isTraining,
    this.summary,
  });

  // Converte un record SQLite Map in un oggetto Evento Dart
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      userId: map['user_id'],
      courseId: map['course_id'],
      title: map['title'],
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
      hours: map['hours'],
      isTraining: map['is_training'] == 1,
      summary: map['summary'],
    );
  }

  // Converte l'oggetto Evento in un Map per l'inserimento nel DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'course_id': courseId,
      'title': title,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'hours': hours,
      'is_training': isTraining ? 1 : 0,
      'summary': isTraining ? summary : null,
    };
  }
}
