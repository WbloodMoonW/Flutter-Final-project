import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/category_model.dart';
import '../models/worker_model.dart';
import '../models/order_model.dart';
import '../models/address_model.dart';
import '../models/coupon_model.dart';

class ClientViewModel extends ChangeNotifier {
  List<Category> _categories = [];
  List<Worker> _workers = [];
  List<Worker> _filteredWorkers = [];
  List<Order> _myOrders = [];
  List<Address> _myAddresses = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get categories => _categories;
  List<Worker> get workers => _workers;
  List<Worker> get filteredWorkers => _filteredWorkers;
  List<Order> get myOrders => _myOrders;
  List<Address> get myAddresses => _myAddresses;
  List<String> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCategories() async {
    _setLoading(true);
    try {
      _categories = await ApiService.getCategories();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchWorkers({String? categoryId, String? search}) async {
    _setLoading(true);
    try {
      _workers = await ApiService.getWorkers(category: categoryId, search: search);
      _filteredWorkers = List.from(_workers);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMyOrders() async {
    _setLoading(true);
    try {
      _myOrders = await ApiService.getCustomerOrders();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMyAddresses() async {
    try {
      final profile = await ApiService.getCustomerProfile();
      if (profile != null && profile['addresses'] != null) {
        _myAddresses = (profile['addresses'] as List).map((a) => Address.fromJson(a)).toList();
      }
      notifyListeners();
    } catch (e) {}
  }

  Future<void> updateSuggestions(String query) async {
    if (query.length < 2) {
      _suggestions = [];
      notifyListeners();
      return;
    }
    _suggestions = await ApiService.getSearchSuggestions(query);
    notifyListeners();
  }

  void searchWorkers(String query) {
    if (query.isEmpty) {
      _filteredWorkers = List.from(_workers);
    } else {
      _filteredWorkers = _workers.where((w) {
        return w.user.fullName.toLowerCase().contains(query.toLowerCase()) ||
               (w.title?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  Future<Worker?> getWorkerById(String id) async {
    _setLoading(true);
    try {
      final worker = await ApiService.getWorkerById(id);
      return worker;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createBooking(String workerId, {String? serviceId, String? locationAddress, DateTime? scheduledFor, String? couponCode}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await ApiService.createBooking(workerId, serviceId: serviceId, locationAddress: locationAddress, scheduledFor: scheduledFor, couponCode: couponCode);
      await fetchMyOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Coupon?> validateCoupon(String code) async {
    return await ApiService.validateCoupon(code);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
