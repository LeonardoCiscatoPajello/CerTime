import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';


class SessionService extends ChangeNotifier{
  static final SessionService instance = SessionService._internal();
  SessionService._internal();

  static const _keyUserId = 'session_user_id';

  AppUser? _currentUser;
  bool _initialized = false;

  AppUser? get currentUser => _currentUser;
  int? get currentUserId => _currentUser?.id;
  bool get isLoggedIn => _currentUser != null;
  bool get isManager => _currentUser?.isManager ?? false;

  Future<void> init() async {
    if(_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final storeId = prefs.getInt(_keyUserId);
    if(storeId != null){
      _currentUser = await DbHelper().getUserById(storeId);
    }
    _initialized = true;
  }

  Future<void> login(AppUser user) async {
    _currentUser = user;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, user.id);
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }
}