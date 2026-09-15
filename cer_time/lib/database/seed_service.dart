import 'package:sqflite/sqflite.dart';

class SeedService {
  static Future<void> seed(Database db) async {
    final now = DateTime.now();

    DateTime day(int offsetDays) =>
        now.add(Duration(days: offsetDays));
    DateTime at(int offsetDays, int hour, [int minute = 0]) {
      final d = day(offsetDays);
      return DateTime(d.year, d.month, d.day, hour, minute);
    }

    // ---------------- Users ----------------
    final managerId = await db.insert('users', {
      'name': 'Mario Rossi',
      'role': 'manager',
      'manager_id': null,
      'avatar_color': '#1A5F7A',
    });

    final marcoId = await db.insert('users', {
      'name': 'Marco Bianchi', 'role': 'employee',
      'manager_id': managerId, 'avatar_color': '#2E7D32',
    });
    final elenaId = await db.insert('users', {
      'name': 'Elena Verdi', 'role': 'employee',
      'manager_id': managerId, 'avatar_color': '#EF6C00',
    });
    final lucaId = await db.insert('users', {
      'name': 'Luca Neri', 'role': 'employee',
      'manager_id': managerId, 'avatar_color': '#C62828',
    });
    final saraId = await db.insert('users', {
      'name': 'Sara Conti', 'role': 'employee',
      'manager_id': managerId, 'avatar_color': '#6A1B9A',
    });
    final giuliaId = await db.insert('users', {
      'name': 'Giulia Ferrari', 'role': 'employee',
      'manager_id': managerId, 'avatar_color': '#00838F',
    });

    // ---------------- Training Courses ----------------
    final antincendioId = await db.insert('training_courses', {
      'title': 'Corso Antincendio',
      'description': 'Aggiornamento normativo obbligatorio sicurezza antincendio.',
      'scheduled_date': day(-10).toIso8601String(),
      'duration_hours': 4.0,
      'created_by': managerId,
    });
    final privacyId = await db.insert('training_courses', {
      'title': 'Corso Privacy GDPR',
      'description': 'Formazione obbligatoria su trattamento dati personali e GDPR.',
      'scheduled_date': day(-15).toIso8601String(),
      'duration_hours': 3.0,
      'created_by': managerId,
    });
    final ergonomiaId = await db.insert('training_courses', {
      'title': 'Ergonomia Postazione Lavoro',
      'description': 'Corso su corretta postura e prevenzione disturbi muscolo-scheletrici.',
      'scheduled_date': day(-2).toIso8601String(),
      'duration_hours': 2.0,
      'created_by': managerId,
    });
    final sicurezzaId = await db.insert('training_courses', {
      'title': 'Sicurezza in Cantiere',
      'description': 'Corso pratico su DPI e procedure di cantiere.',
      'scheduled_date': day(5).toIso8601String(),
      'duration_hours': 6.0,
      'created_by': managerId,
    });
    final primoSoccorsoId = await db.insert('training_courses', {
      'title': 'Primo Soccorso Aziendale',
      'description': 'Nozioni base BLS-D per addetti al primo soccorso.',
      'scheduled_date': day(20).toIso8601String(),
      'duration_hours': 8.0,
      'created_by': managerId,
    });
    final dpiId = await db.insert('training_courses', {
      'title': 'Uso DPI Avanzato',
      'description': 'Corso avanzato sull\'utilizzo dei dispositivi di protezione individuale.',
      'scheduled_date': day(30).toIso8601String(),
      'duration_hours': 5.0,
      'created_by': managerId,
    });

    Future<int> insertEvent({
      required int userId,
      int? courseId,
      required String title,
      required DateTime start,
      required double hours,
      required bool isTraining,
      String? summary,
    }) {
      final end = start.add(Duration(minutes: (hours * 60).round()));
      return db.insert('events', {
        'user_id': userId,
        'course_id': courseId,
        'title': title,
        'start_time': start.toIso8601String(),
        'end_time': end.toIso8601String(),
        'hours': hours,
        'is_training': isTraining ? 1 : 0,
        'summary': isTraining ? summary : null,
        'created_at': now.toIso8601String(),
      });
    }

    Future<void> completeCourse({
      required int userId,
      required int courseId,
      required String title,
      required DateTime start,
      required double hours,
      required String summary,
    }) async {
      final eventId = await insertEvent(
        userId: userId, courseId: courseId, title: title,
        start: start, hours: hours, isTraining: true, summary: summary,
      );
      await db.insert('course_assignments', {
        'course_id': courseId,
        'user_id': userId,
        'status': 'completed',
        'completed_event_id': eventId,
      });
    }

    Future<void> assignPending(int userId, int courseId) {
      return db.insert('course_assignments', {
        'course_id': courseId,
        'user_id': userId,
        'status': 'pending',
      });
    }

    await completeCourse(
      userId: marcoId, courseId: antincendioId, title: 'Corso Antincendio',
      start: at(-10, 9), hours: 4.0,
      summary: 'Ripasso procedure di evacuazione ed estintori portatili.',
    );
    await completeCourse(
      userId: marcoId, courseId: privacyId, title: 'Corso Privacy GDPR',
      start: at(-15, 9), hours: 3.0,
      summary: 'Approfondimento su trattamento dati e data breach.',
    );
    await insertEvent(
      userId: marcoId, title: 'Formazione periodica tecnica',
      start: at(-30, 14), hours: 6.0, isTraining: true,
      summary: 'Aggiornamento su strumenti diagnostici aziendali.',
    );
    await insertEvent(
      userId: marcoId, title: 'Formazione periodica tecnica',
      start: at(-60, 14), hours: 6.0, isTraining: true,
      summary: 'Sessione pratica su nuovi protocolli di collaudo.',
    );
    await insertEvent(
      userId: marcoId, title: 'Formazione periodica tecnica',
      start: at(-90, 14), hours: 6.0, isTraining: true,
      summary: 'Corso di aggiornamento su normative di settore.',
    );
    await insertEvent(
      userId: marcoId, title: 'Allineamento Team',
      start: at(-3, 10), hours: 1.0, isTraining: false,
    );
    await insertEvent(
      userId: marcoId, title: 'Ripasso rapido procedure',
      start: at(-1, 9), hours: 2.0, isTraining: true,
      summary: 'Ripasso rapido delle procedure di sicurezza apprese di recente.',
    );
    await assignPending(marcoId, ergonomiaId); // scaduto (-2gg) -> demoable
    await assignPending(marcoId, sicurezzaId); // futuro (+5gg) -> locked
    await assignPending(marcoId, dpiId); // futuro (+30gg) -> locked

    await completeCourse(
      userId: elenaId, courseId: antincendioId, title: 'Corso Antincendio',
      start: at(-10, 11), hours: 4.0,
      summary: 'Corso seguito con attenzione, materiale chiaro.',
    );
    await insertEvent(
      userId: elenaId, title: 'Formazione avanzata processi',
      start: at(-20, 9), hours: 8.0, isTraining: true,
      summary: 'Workshop su ottimizzazione dei processi interni.',
    );
    await insertEvent(
      userId: elenaId, title: 'Formazione avanzata processi',
      start: at(-50, 9), hours: 8.0, isTraining: true,
      summary: 'Sessione su gestione qualità e miglioramento continuo.',
    );
    await insertEvent(
      userId: elenaId, title: 'Formazione avanzata processi',
      start: at(-80, 9), hours: 8.0, isTraining: true,
      summary: 'Corso su reportistica e KPI di reparto.',
    );
    await insertEvent(
      userId: elenaId, title: 'Formazione avanzata processi',
      start: at(-110, 9), hours: 8.0, isTraining: true,
      summary: 'Aggiornamento su procedure di controllo qualità.',
    );
    await insertEvent(
      userId: elenaId, title: 'Formazione avanzata processi',
      start: at(-140, 9), hours: 8.0, isTraining: true,
      summary: 'Corso su gestione documentale e tracciabilità.',
    );
    await insertEvent(
      userId: elenaId, title: 'Retrospettiva sprint',
      start: at(-4, 15), hours: 1.0, isTraining: false,
    );
    await insertEvent(
      userId: elenaId, title: 'Aggiornamento rapido normativo',
      start: at(-2, 9), hours: 3.0, isTraining: true,
      summary: 'Sessione di aggiornamento su normativa recente.',
    );
    await assignPending(elenaId, ergonomiaId); // scaduto -> demoable
    await assignPending(elenaId, sicurezzaId); // futuro -> locked
    await assignPending(elenaId, primoSoccorsoId); // futuro -> locked

    await insertEvent(
      userId: lucaId, title: 'Formazione base sicurezza',
      start: at(-20, 9), hours: 5.0, isTraining: true,
      summary: 'Introduzione alle procedure di sicurezza di reparto.',
    );
    await insertEvent(
      userId: lucaId, title: 'Formazione base sicurezza',
      start: at(-45, 9), hours: 5.0, isTraining: true,
      summary: 'Approfondimento su segnaletica e vie di fuga.',
    );
    await insertEvent(
      userId: lucaId, title: 'Riunione operativa',
      start: at(-5, 10), hours: 2.0, isTraining: false,
    );
    await insertEvent(
      userId: lucaId, title: 'Sessione di ripasso sicurezza',
      start: at(-1, 9), hours: 2.0, isTraining: true,
      summary: 'Ripasso rapido delle procedure di sicurezza di reparto.',
    );
    await assignPending(lucaId, antincendioId); // scaduto (-10gg) -> demoable
    await assignPending(lucaId, privacyId); // scaduto (-15gg) -> demoable
    await assignPending(lucaId, sicurezzaId); // futuro -> locked

    await insertEvent(
      userId: saraId, title: 'Formazione amministrativa',
      start: at(-25, 9), hours: 6.0, isTraining: true,
      summary: 'Corso su gestione pratiche e archiviazione documenti.',
    );
    await insertEvent(
      userId: saraId, title: 'Kickoff progetto',
      start: at(-7, 11), hours: 1.5, isTraining: false,
    );
    await insertEvent(
      userId: saraId, title: 'Aggiornamento pratiche amministrative',
      start: at(-2, 9), hours: 1.5, isTraining: true,
      summary: 'Aggiornamento rapido su nuove procedure di archiviazione.',
    );
    await assignPending(saraId, ergonomiaId); // scaduto -> demoable
    await assignPending(saraId, primoSoccorsoId); // futuro -> locked
    await assignPending(saraId, dpiId); // futuro -> locked

    await completeCourse(
      userId: giuliaId, courseId: privacyId, title: 'Corso Privacy GDPR',
      start: at(-15, 10), hours: 3.0,
      summary: 'Prima formazione aziendale su trattamento dati personali.',
    );
    await insertEvent(
      userId: giuliaId, title: 'Onboarding aziendale',
      start: at(-1, 9), hours: 1.0, isTraining: false,
    );
    await insertEvent(
      userId: giuliaId, title: 'Ripasso onboarding',
      start: at(-1, 9), hours: 1.0, isTraining: true,
      summary: 'Ripasso rapido dei materiali di onboarding aziendale.',
    );
    await assignPending(giuliaId, antincendioId); // scaduto -> demoable
    await assignPending(giuliaId, dpiId); // futuro -> locked
  }
}
