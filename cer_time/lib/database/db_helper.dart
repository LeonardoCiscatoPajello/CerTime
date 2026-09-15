import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/pending_course_model.dart';
import '../models/training_course_model.dart';
import 'events_notifier.dart';
import 'seed_service.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  static Database? _database;

  factory DbHelper() => _instance;

  DbHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'certime.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if(oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS events');
      await db.execute('DROP TABLE IF EXISTS course_assignments');
      await db.execute('DROP TABLE IF EXISTS training_courses');
      await db.execute('DROP TABLE IF EXISTS users');
      await _onCreate(db, newVersion);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        manager_id INTEGER,
        avatar_color TEXT NOT NULL,
        FOREIGN KEY (manager_id) REFERENCES users (id)
    )
  ''');

    await db.execute('''
    CREATE TABLE training_courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        scheduled_date TEXT NOT NULL,
        duration_hours REAL NOT NULL,
        created_by INTEGER NOT NULL,
        FOREIGN KEY (created_by) REFERENCES users (id)
    )
  ''');

    await db.execute('''
    CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        course_id INTEGER,
        title TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        hours REAL NOT NULL,
        is_training INTEGER NOT NULL,
        summary TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (course_id) REFERENCES training_courses (id)
    )
  ''');

    await db.execute('''
    CREATE TABLE course_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        completed_event_id INTEGER,
        FOREIGN KEY (course_id) REFERENCES training_courses (id),
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (completed_event_id) REFERENCES events (id)
    )
  ''');

    await SeedService.seed(db);
  }

// Users

  Future<List<AppUser>> getUsers() async {
    Database db = await database;
    final maps = await db.query('users', orderBy: 'role DESC, name ASC');
    return List.generate(maps.length, (i) => AppUser.fromMap(maps[i]));
  }

  Future<AppUser?> getUserById(int id) async {
    Database db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if(maps.isEmpty) return null;
    return AppUser.fromMap(maps.first);
  }

// Events

  Future<int> insertEvent(Event event) async {
    Database db = await database;
    final id =  await db.insert('events', {
      ...event.toMap(),
      'created_at': DateTime.now().toIso8601String(),
    });
    EventsNotifier.instance.notifyEventsChanged();
    return id;
  }

  Future<List<Event>> getEventsForUser(int userId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'start_time DESC',
    );
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<int> deleteEvent(int id) async {
    Database db = await database;
    final result = await db.transaction((txn) async {
      await txn.update(
        'course_assignments',
        {'status': 'pending', 'completed_event_id': null},
        where: 'completed_event_id = ?',
        whereArgs: [id],
      );
      return await txn.delete('events', where: 'id = ?', whereArgs: [id]);
    });
    EventsNotifier.instance.notifyEventsChanged();
    return result;
  }

  Future<int> updateEvent(Event event) async {
    Database db = await database;
    final result = await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
    EventsNotifier.instance.notifyEventsChanged();
    return result;
  }

  Future<void> resetDatabase(int userId) async {
    Database db = await database;
    await db.transaction((txn) async {
      final ids = await txn.query('events', columns: ['id'], where: 'user_id = ?', whereArgs: [userId]);
      final eventIds = ids.map((e) => e['id'] as int).toList();
      if (eventIds.isNotEmpty) {
        final placeholders = List.filled(eventIds.length, '?').join(',');
        await txn.update(
          'course_assignments',
          {'status': 'pending', 'completed_event_id': null},
          where: 'completed_event_id IN ($placeholders)',
          whereArgs: eventIds,
        );
      }
      await txn.delete('events', where: 'user_id = ?', whereArgs: [userId]);
    });
    EventsNotifier.instance.notifyEventsChanged();
  }

  Future<List<PendingCourse>> getPendingCoursesForUser(int userId) async {
    Database db = await database;
    final maps = await db.rawQuery('''
    SELECT ca.id as assignment_id, tc.id as course_id, tc.title, tc.description,
           tc.scheduled_date, tc.duration_hours
    FROM course_assignments ca
    JOIN training_courses tc ON ca.course_id = tc.id
    WHERE ca.user_id = ? AND ca.status = 'pending'
    ORDER BY tc.scheduled_date ASC
  ''', [userId]);
    return List.generate(maps.length, (i) => PendingCourse.fromMap(maps[i]));
  }

  Future<void> completeCourseAssignment({
    required int assignmentId,
    required Event event,
  }) async {
    Database db = await database;

    final rows = await db.rawQuery('''
      SELECT tc.scheduled_date FROM course_assignments ca
      JOIN training_courses tc ON ca.course_id = tc.id
      WHERE ca.id = ?
    ''', [assignmentId]);

    if(rows.isEmpty) {
      throw StateError('Assegnazione corso non trovata.');
    }

    final scheduledDate = DateTime.parse(rows.first['scheduled_date'] as String);
    if(scheduledDate.isAfter(DateTime.now())) {
      throw StateError(
        'Non è possibile registrare la presenza per un corso non ancora svolto '
            '(pianificato per il ${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}).',
      );
    }
    await db.transaction((txn) async {
      final eventId = await txn.insert('events', {
        ...event.toMap(),
        'created_at': DateTime.now().toIso8601String(),
      });
      await txn.update(
        'course_assignments',
        {'status': 'completed', 'completed_event_id': eventId},
        where: 'id = ?',
        whereArgs: [assignmentId],
      );
    });
    EventsNotifier.instance.notifyEventsChanged();
  }

// Manager

  Future<List<AppUser>> getEmployeesForManager(int managerId) async {
    Database db = await database;
    final maps = await db.query(
      'users',
      where: 'manager_id = ?',
      whereArgs: [managerId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => AppUser.fromMap(maps[i]));
  }

  Future<int> createCourse({
    required String title,
    String? description,
    required DateTime scheduledDate,
    required double durationHours,
    required int createdBy,
  }) async {
    Database db = await database;
    return await db.insert('training_courses', {
      'title': title,
      'description': description,
      'scheduled_date': scheduledDate.toIso8601String(),
      'duration_hours': durationHours,
      'created_by': createdBy,
    });
  }

  Future<void> assignCoursesToUsers(int courseId, List<int> userIds) async {
    Database db = await database;
    await db.transaction((txn) async{
      for (final userId in userIds){
        await txn.insert('course_assignments', {
          'course_id': courseId,
          'user_id': userId,
          'status' : 'pending',
        });
      }
    });
    EventsNotifier.instance.notifyEventsChanged();
  }

  Future<List<Map<String, dynamic>>> getCoursesCreatedBy(int managerId) async {
    Database db = await database;
    final courses = await db.query(
      'training_courses',
      where: 'created_by = ?',
      whereArgs: [managerId],
      orderBy: 'scheduled_date DESC',
    );
    final List<Map<String, dynamic>> result = [];
    for (final c in courses) {
      final assignments = await db.rawQuery('''
        SELECT ca.status, u.name FROM course_assignments ca
        JOIN users u ON ca.user_id = u.id
        WHERE ca.course_id = ?
      ''', [c['id']]);
      result.add({'course': TrainingCourse.fromMap(c), 'assignments': assignments});
    }
    return result;
  }

  Future<List<Event>> getEventsForManagedUser(int managerId, int employeeId) async {
    Database db = await database;
    final owner = await db.query(
      'users',
      where: 'id = ? AND manager_id = ?',
      whereArgs: [employeeId, managerId],
    );
    if (owner.isEmpty) return [];
    return getEventsForUser(employeeId);
  }

  Future<List<Map<String, dynamic>>> getTeamComplianceSummary(int managerId) async {
    final now = DateTime.now();
    final employees = await getEmployeesForManager(managerId);
    final List<Map<String, dynamic>> result = [];
    for (final emp in employees) {
      final events = await getEventsForUser(emp.id);
      final training = events.where((e) => e.isTraining);
      final annual = training
          .where((e) => e.startTime.year == now.year)
          .fold(0.0, (sum, e) => sum + e.hours);
      final pending = await getPendingCoursesForUser(emp.id);
      result.add(
          {'user': emp, 'annualHours': annual, 'pendingCount': pending.length});
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getAggregatedEventsForManager(int managerId) async{
    Database db = await database;
    return await db.rawQuery('''
      SELECT e.*, u.name as employee_name
      FROM events e
      JOIN users u ON e.user_id = u.id
      WHERE u.manager_id = ?
      ORDER BY u.name ASC, e.start_time DESC
    ''', [managerId]);
  }
}
