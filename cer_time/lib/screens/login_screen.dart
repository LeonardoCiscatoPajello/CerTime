import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import '../services/session_service.dart';
import 'main_navigation.dart';

class LoginScreen extends StatefulWidget{
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>{
  late Future<List<AppUser>> _usersFuture;

  @override
  void initState(){
    super.initState();
    _usersFuture = DbHelper().getUsers();
  }
  
  Color _parseColor(String hex){
    final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
    return Color(0xFF000000 | value);
  }
  
  Future<void> _login(AppUser user) async {
    await SessionService.instance.login(user);
    if(!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Seleziona Utente')),
      body: FutureBuilder<List<AppUser>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data ?? [];
          return Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.amber.shade700,
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'DEMO: login simulato, nessuna password richiesta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _parseColor(user.avatarColor),
                          child: Text(user.name.substring(0, 1)),
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.isManager ? 'Responsabile' : 'Dipendente'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _login(user),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}