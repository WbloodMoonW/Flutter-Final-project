import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/category_model.dart';
import '../models/worker_model.dart';
import '../models/order_model.dart';
import '../models/address_model.dart';
import '../models/coupon_model.dart';
import '../models/review_model.dart';

class ClientViewModel extends ChangeNotifier {
  List<Category> _categories = [];
  List<Worker> _workers = [];
  Coupon? _featuredCoupon;
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
  Coupon? get featuredCoupon => _featuredCoupon;
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

  Future<void> fetchFeaturedCoupon() async {
    try {
      _featuredCoupon = await ApiService.getFeaturedCoupon();
      notifyListeners();
    } catch (_) {
      _featuredCoupon = null;
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
      
      if (_searchQuery.isNotEmpty) {
        searchWorkers(_searchQuery);
      } else {
        _filteredWorkers = List.from(_workers);
      }
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
      final user = await ApiService.getCustomerProfile();
      debugPrint('>>> fetchMyOrders: CURRENT USER ID = ${user?['_id'] ?? user?['id']}');
      
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

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void searchWorkers(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredWorkers = List.from(_workers);
    } else {
      final lowercaseQuery = query.toLowerCase().trim();
      
      bool matchesKeyword(String? fieldText) {
        if (fieldText == null || fieldText.isEmpty) return false;
        final f = fieldText.toLowerCase();
        
        // Direct match
        if (f.contains(lowercaseQuery)) return true;
        
        // Translation/synonym groups
        final groups = [
          {'plumber', 'plumbing', 'سباك', 'سباكة'},
          {'electrician', 'electricity', 'electrification', 'كهربائي', 'كهرباء'},
          {'carpenter', 'carpentry', 'نجار', 'نجارة'},
          {'painter', 'painting', 'نقاش', 'دهان', 'نقاشة', 'دهانات'},
          {'ac', 'air conditioner', 'air conditioning', 'تكييف', 'فني تكييف'},
          {'cleaning', 'cleaner', 'housekeeping', 'تنظيف', 'منظف', 'خادمة'},
          {'blacksmith', 'حداد', 'حدادة', 'حدادين'}
        ];
        
        for (var group in groups) {
          final queryMatch = group.any((word) => lowercaseQuery.contains(word) || word.contains(lowercaseQuery));
          if (queryMatch) {
            final fieldMatch = group.any((word) => f.contains(word));
            if (fieldMatch) return true;
          }
        }
        
        return false;
      }

      _filteredWorkers = _workers.where((w) {
        if (w.user.fullName.toLowerCase().contains(lowercaseQuery)) return true;
        if (matchesKeyword(w.title)) return true;
        if (matchesKeyword(w.category?.name)) return true;
        if (w.skills.any((skill) => matchesKeyword(skill))) return true;
        if (matchesKeyword(w.location)) return true;
        if (w.services.any((service) => matchesKeyword(service.name) || matchesKeyword(service.description))) return true;
        return false;
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

  Future<List<CustomerReview>> getWorkerReviews(String id) async {
    _setLoading(true);
    try {
      final reviews = await ApiService.getWorkerReviews(id);
      return reviews;
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Returns the order map on success (so callers can chain a card-checkout
  // step), or null on failure.
  Future<Map<String, dynamic>?> createBooking({
    required String serviceId,
    String? locationAddress,
    DateTime? scheduledFor,
    String? couponCode,
    String paymentMode = 'cash_on_delivery',
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final order = await ApiService.createBooking(
        serviceId: serviceId,
        locationAddress: locationAddress,
        scheduledFor: scheduledFor,
        couponCode: couponCode,
        paymentMode: paymentMode,
      );
      await fetchMyOrders();
      return order;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, String>> createPaymobCheckout(String orderId) {
    return ApiService.createPaymobCheckout(orderId);
  }

  Future<String> getPaymentStatus(String paymentId) {
    return ApiService.getPaymentStatus(paymentId);
  }

  Future<Coupon?> validateCoupon(String code, {double? amount, String? categoryId}) async {
    return await ApiService.validateCoupon(code, amount: amount, categoryId: categoryId);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
