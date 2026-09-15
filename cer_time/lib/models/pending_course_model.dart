class PendingCourse {
  final int assignmentId;
  final int courseId;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final double durationHours;

  PendingCourse({
    required this.assignmentId,
    required this.courseId,
    required this.title,
   this.description,
    required this.scheduledDate,
    required this.durationHours,
});

  factory PendingCourse.fromMap(Map<String, dynamic> map){
    return PendingCourse(
      assignmentId: map['assignment_id'],
      courseId: map['course_id'],
      title: map['title'],
      description: map['description'],
      scheduledDate: DateTime.parse(map['scheduled_date']),
      durationHours: map['duration_hours'],
    );
  }
}

