import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../services/settings_service.dart';
import '../services/session_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  void initState() {
    super.initState();
    SettingsService.instance.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  Future<void>  _confirmResetDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset database'),
        content: const Text(
          'Questa azione eliminerà TUTTI gli eventi registrati in modo permanente. '
              'L\'azione non è reversibile. Continuare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ELIMINA TUTTO'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DbHelper().resetDatabase(SessionService.instance.currentUserId!);
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content : Text('Database resettato con successo')),
      );
    }
  }

  @override
  Widget build(BuildContext context)  {
    final settings = SettingsService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Tema scuro'),
            subtitle: const Text('Attiva la modalità'),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (value) => settings.setDarkMode(value),
          ),
          const Divider(),
          RadioListTile<TimeFormatMode>(
            title: const Text('formato decimale'),
            subtitle: const Text('Es. 1.50h'),
            value: TimeFormatMode.decimal,
            groupValue: settings.timeFormat,
            onChanged: (value) => settings.setTimeFormat(value!),
          ),
          RadioListTile<TimeFormatMode>(
            title: const Text('Formato ore e minuti'),
            subtitle: const Text('Es. 1h 30m'),
            value: TimeFormatMode.hhmm,
            groupValue: settings.timeFormat,
            onChanged: (value) => settings.setTimeFormat(value!),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cambia utente'),
            subtitle: Text('Sessione: ${SessionService.instance.currentUser?.name ?? "-"}'),
            onTap: () async {
              await SessionService.instance.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset Database', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Elimina permanentemente tutti gli eventi'),
            onTap: _confirmResetDatabase,
          ),
        ],
      ),
    );
  }

}