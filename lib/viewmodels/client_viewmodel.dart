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
  
  // Location Filter State
  double? _selectedLat;
  double? _selectedLng;
  String? _selectedPostcode;
  String? _selectedAddress;

  List<Category> get categories => _categories;
  List<Worker> get workers => _workers;
  List<Worker> get filteredWorkers => _filteredWorkers;
  List<Order> get myOrders => _myOrders;
  List<Address> get myAddresses => _myAddresses;
  List<String> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double? get selectedLat => _selectedLat;
  double? get selectedLng => _selectedLng;
  String? get selectedPostcode => _selectedPostcode;
  String? get selectedAddress => _selectedAddress;
  
  Future<void> fetchAll() async {
    await fetchCategories();
    await fetchWorkers();
    await fetchMyOrders();
  }

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

  Future<void> fetchWorkers({
    String? categoryId, 
    String? search, 
    double? lat, 
    double? lng, 
    String? postcode,
    String? address,
  }) async {
    _setLoading(true);
    try {
      _selectedLat = lat;
      _selectedLng = lng;
      _selectedPostcode = postcode;
      _selectedAddress = address;
      
      String? finalSearch = search;
      if (postcode != null && postcode.isNotEmpty) {
        finalSearch = (finalSearch != null && finalSearch.isNotEmpty) 
          ? '$finalSearch $postcode' 
          : postcode;
      }
      
      _workers = await ApiService.getWorkers(
        category: categoryId, 
        search: finalSearch,
        lat: lat,
        lng: lng,
        postcode: postcode,
      );
      _filteredWorkers = List.from(_workers);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void clearLocationFilter() {
    _selectedLat = null;
    _selectedLng = null;
    _selectedPostcode = null;
    _selectedAddress = null;
    fetchWorkers();
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
      final lowercaseQuery = query.toLowerCase();
      _filteredWorkers = _workers.where((w) {
        return w.user.fullName.toLowerCase().contains(lowercaseQuery) ||
               (w.title?.toLowerCase().contains(lowercaseQuery) ?? false) ||
               (w.location?.toLowerCase().contains(lowercaseQuery) ?? false);
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
