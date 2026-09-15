class TrainingCourse{
  final int id;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final double durationHours;
  final int createdBy;

  TrainingCourse({
    required this.id,
    required this.title,
    this.description,
    required this.scheduledDate,
    required this.durationHours,
    required this.createdBy,
  });

  factory TrainingCourse.fromMap(Map<String, dynamic> map) {
    return TrainingCourse(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      scheduledDate: DateTime.parse(map['scheduled_date']),
      durationHours: map['duration_hours'],
      createdBy: map['created_by'],
    );
  }
}