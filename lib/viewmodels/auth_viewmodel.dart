import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel() {
    checkAuthStatus();
  }
  List<Map<String, dynamic>> _accounts = [];
  User? _currentUser;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get accounts => _accounts;
  User? get currentUser => _currentUser;
  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final result = await ApiService.signin(email, password);
      if (result != null && result['user'] != null) {
        _currentUser = User.fromJson(result['user']);
        await checkAuthStatus();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> googleLogin(String idToken) async {
    _setLoading(true);
    try {
      final result = await ApiService.googleSignin(idToken);
      if (result != null && result['user'] != null) {
        _currentUser = User.fromJson(result['user']);
        await checkAuthStatus();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signup(Map<String, dynamic> data) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final result = await ApiService.signup(
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
        email: data['email'],
        phone: data['phone'],
        password: data['password'],
        role: data['role'],
        idFront: data['idFront'],
        idBack: data['idBack'],
      );
      if (result != null && result['user'] != null) {
        _currentUser = User.fromJson(result['user']);
        await checkAuthStatus();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchNotifications() async {
    try {
      _notifications = await ApiService.getNotifications();
      notifyListeners();
    } catch (e) {}
  }

  Future<void> markAllRead() async {
    await ApiService.markNotificationsRead();
    await fetchNotifications();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      if (_currentUser?.role == 'worker') {
        await ApiService.updateWorkerProfile(data);
      } else {
        await ApiService.updateCustomerProfile(data);
      }
      await checkAuthStatus();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> switchAccount(int index) async {
    if (index < 0 || index >= _accounts.length) return;
    final account = _accounts[index];
    await StorageService.saveToken(account['token']);
    await checkAuthStatus();
  }

  Future<void> logout() async {
    await StorageService.clearAll();
    _currentUser = null;
    _notifications = [];
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _currentUser = await ApiService.getMe();
    _accounts = await StorageService.getAccounts();
    if (_currentUser != null) {
      fetchNotifications();
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
