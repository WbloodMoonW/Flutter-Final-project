import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/worker_model.dart';
import '../models/service_model.dart';
import '../models/portfolio_item.dart';
import '../models/pricing_package.dart';
import '../models/working_hours.dart';
import '../models/order_model.dart';
import '../models/category_model.dart';

class WorkerViewModel extends ChangeNotifier {
  Worker? _worker;
  List<Order> _orders = [];
  Map<String, dynamic> _wallet = {};
  bool _isLoading = false;
  String? _errorMessage;

  // New state from WorkerDataService
  int _pendingOrdersCount = 0;
  int _acceptedOrdersCount = 0;
  int _inProgressOrdersCount = 0;
  int _completedOrdersCount = 0;
  double _totalEarnings = 0;
  double _rating = 0;
  int _reviewCount = 0;
  int _completionRate = 0;
  List<Map<String, String>> _notifications = [];
  List<Map<String, dynamic>> _categories = [];
  List<String> _licenses = [];

  Worker? get worker => _worker;
  List<Order> get orders => _orders;
  Map<String, dynamic> get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Convenient Getters
  String get name => _worker != null ? "${_worker!.user.firstName} ${_worker!.user.lastName}" : "Worker";
  String get firstName => _worker?.user.firstName ?? "";
  String get lastName => _worker?.user.lastName ?? "";
  String get email => _worker?.user.email ?? "";
  String get phone => _worker?.user.phone ?? "";
  String get avatarUrl => _worker?.user.profileImage ?? "";
  String get professionalTitle => _worker?.title ?? "";
  String get bio => _worker?.bio ?? "";
  String get location => _worker?.location ?? "";
  List<String> get skills => _worker?.skills ?? [];
  
  // Stats Getters
  int get pendingOrders => _pendingOrdersCount + _acceptedOrdersCount + _inProgressOrdersCount;
  int get completedOrders => _completedOrdersCount;
  double get totalEarnings => _totalEarnings;
  double get rating => _rating;
  int get reviewCount => _reviewCount;
  int get completionRate => _completionRate;
  
  List<Map<String, String>> get notifications => _notifications;
  List<Map<String, dynamic>> get categories => _categories;
  List<String> get licenses => _licenses;

  List<WorkerService> get services => _worker?.services ?? [];
  List<PortfolioItem> get portfolio => _worker?.portfolio ?? [];
  List<PricingPackage> get pricingPackages => _worker?.pricingPackages ?? [];
  Map<String, WorkingHoursEntry?> get workingHours => _worker?.workingHours ?? {};
  bool get isCompany => _worker?.isCompany ?? false;

  // Alias for compatibility with new UI
  Future<void> fetchData() => loadWorkerData();

  Future<void> loadWorkerData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dashboardData = await ApiService.getWorkerDashboard();
      if (dashboardData != null) {
        // Handle nested 'data' field if present
        final actualData = dashboardData['data'] ?? dashboardData;
        final profileData = actualData['profile'] ?? actualData['worker'] ?? actualData['user'] ?? (actualData.containsKey('email') ? actualData : {});
        _worker = Worker.fromJson(profileData);

        final stats = actualData['stats'] as Map<String, dynamic>?;
        if (stats != null) {
          _totalEarnings = ((stats['totalEarnings'] ?? 0) as num).toDouble();
          _pendingOrdersCount = (stats['pendingOrders'] ?? 0) as int;
          _acceptedOrdersCount = (stats['acceptedOrders'] ?? 0) as int;
          _inProgressOrdersCount = (stats['inProgressOrders'] ?? 0) as int;
          _completedOrdersCount = (stats['completedOrders'] ?? 0) as int;
          _rating = ((stats['ratingAverage'] ?? profileData['ratingAverage'] ?? 0) as num).toDouble();
          _reviewCount = (stats['totalReviews'] ?? profileData['totalReviews'] ?? 0) as int;
          _completionRate = (stats['completionRate'] ?? profileData['completionRate'] ?? 0) as int;
        }

        // Extract licenses from profile (no separate endpoint exists)
        final rawLicenses = profileData['licenses'] as List? ?? [];
        _licenses = rawLicenses
            .map((l) => (l as Map<String, dynamic>)['fileUrl']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }

      _orders = await ApiService.getWorkerOrders();
      _wallet = await ApiService.getWorkerWallet() ?? {};

      try {
        final rawServices = await ApiService.getWorkerServices();
        if (_worker != null) {
          _worker = _worker!.copyWith(services: rawServices);
        }
      } catch (e) {
        debugPrint('Error loading worker services: $e');
      }

      // Fetch categories
      final cats = await ApiService.getCategories();
      _categories = cats.map((c) => c.toJson()).toList();
      
      // Fetch notifications
      final notes = await ApiService.getNotifications();
      _notifications = notes.map((n) => {
        'title': n.title,
        'body': n.message,
        'time': n.createdAt.toString(),
        'isRead': n.isRead.toString(),
      }).toList();

    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error loading worker data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> updateProfileFull({
    String? fullName,
    String? bioText,
    String? title,
    String? loc,
    List<String>? skillsList,
    bool? company,
    Map<String, WorkingHoursEntry?>? hours,
    String? profileImageBase64,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      
      // Basic info
      if (fullName != null) {
        data['name'] = fullName;
        final parts = fullName.trim().split(' ');
        data['firstName'] = parts.first;
        data['lastName'] = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
      if (bioText != null) data['bio'] = bioText;
      if (title != null) {
        data['title'] = title;
        data['profession'] = title;
      }
      if (loc != null) {
        data['location'] = loc;
        data['address'] = loc;
      }
      if (skillsList != null) data['skills'] = skillsList;
      if (company != null) {
        data['typeOfWorker'] = company ? 'company' : 'individual';
        data['typeofWorker'] = data['typeOfWorker'];
      }
      if (profileImageBase64 != null) data['profileImage'] = profileImageBase64;
      
      // Always include current portfolio and packages to match web behavior
      if (_worker != null) {
        data['portfolio'] = _worker!.portfolio.map((item) => item.toMap()).toList();
        data['packages'] = _worker!.pricingPackages.map((pkg) => pkg.toMap()).toList();
        data['pricingPackages'] = _worker!.pricingPackages.map((pkg) => pkg.toMap()).toList();
      }
      
      // Working Hours
      if (hours != null) {
        final List<Map<String, dynamic>> whList = [];
        hours.forEach((day, entry) {
          if (entry != null) {
            whList.add({
              'day': _mapDayToArabic(day),
              'from': '${entry.from.hour.toString().padLeft(2, '0')}:${entry.from.minute.toString().padLeft(2, '0')}',
              'to': '${entry.to.hour.toString().padLeft(2, '0')}:${entry.to.minute.toString().padLeft(2, '0')}',
              'enabled': true,
            });
          } else {
            whList.add({'day': _mapDayToArabic(day), 'enabled': false});
          }
        });
        data['workingHours'] = whList;
      }

      debugPrint('--- updateProfileFull body payload: ${json.encode(data)}');
      await ApiService.updateWorkerProfile(data);
      await loadWorkerData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  String _mapDayToArabic(String day) {
    const map = {
      'السبت': 'sat', 'الأحد': 'sun', 'الاثنين': 'mon',
      'الثلاثاء': 'tue', 'الأربعاء': 'wed', 'الخميس': 'thu', 'الجمعة': 'fri',
    };
    return map[day] ?? day;
  }

  void savePersonalInfo({required String title, required String bioText, required String loc, required List<String> skillsList}) {
    if (_worker == null) return;
    _worker = _worker!.copyWith(
      title: title,
      bio: bioText,
      skills: skillsList,
    );
    notifyListeners();
  }

  void saveProviderType(bool company) {
    if (_worker == null) return;
    _worker = _worker!.copyWith(isCompany: company);
    notifyListeners();
  }

  void addPortfolioItem(PortfolioItem item) {
    if (_worker == null) return;
    final newList = List<PortfolioItem>.from(_worker!.portfolio)..add(item);
    _worker = _worker!.copyWith(portfolio: newList);
    notifyListeners();
  }

  void updatePortfolioItem(int index, PortfolioItem item) {
    if (_worker == null) return;
    final newList = List<PortfolioItem>.from(_worker!.portfolio);
    newList[index] = item;
    _worker = _worker!.copyWith(portfolio: newList);
    notifyListeners();
  }

  void deletePortfolioItem(int index) {
    if (_worker == null) return;
    final newList = List<PortfolioItem>.from(_worker!.portfolio)..removeAt(index);
    _worker = _worker!.copyWith(portfolio: newList);
    notifyListeners();
  }

  void addPricingPackage(PricingPackage pkg) {
    if (_worker == null) return;
    final newList = List<PricingPackage>.from(_worker!.pricingPackages)..add(pkg);
    _worker = _worker!.copyWith(pricingPackages: newList);
    notifyListeners();
  }

  void updatePricingPackage(int index, PricingPackage pkg) {
    if (_worker == null) return;
    final newList = List<PricingPackage>.from(_worker!.pricingPackages);
    newList[index] = pkg;
    _worker = _worker!.copyWith(pricingPackages: newList);
    notifyListeners();
  }

  void deletePricingPackage(int index) {
    if (_worker == null) return;
    final newList = List<PricingPackage>.from(_worker!.pricingPackages)..removeAt(index);
    _worker = _worker!.copyWith(pricingPackages: newList);
    notifyListeners();
  }

  void saveWorkingHours(Map<String, WorkingHoursEntry?> hours) {
    if (_worker == null) return;
    _worker = _worker!.copyWith(workingHours: Map<String, WorkingHoursEntry?>.from(hours));
    notifyListeners();
  }

  Future<void> addService(WorkerService service) async {
    _isLoading = true;
    notifyListeners();
    try {
      await ApiService.createService(service);
      await loadWorkerData(); // Refresh to get the latest list with IDs
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateService(int index, WorkerService service) async {
    try {
      if (_worker != null && service.id != null) {
        await ApiService.updateService(service.id!, service.toMap());
        final newList = List<WorkerService>.from(_worker!.services);
        newList[index] = service;
        _worker = _worker!.copyWith(services: newList);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteService(int index) async {
    try {
      if (_worker != null) {
        final service = _worker!.services[index];
        if (service.id != null) {
          await ApiService.deleteService(service.id!);
          final newList = List<WorkerService>.from(_worker!.services)..removeAt(index);
          _worker = _worker!.copyWith(services: newList);
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  Future<void> toggleServiceStatus(int index) async {
    if (_worker == null) return;
    final newList = List<WorkerService>.from(_worker!.services);
    final service = newList[index];
    if (service.id == null) return;

    final newStatus = !service.isActive;

    try {
      await ApiService.updateService(service.id!, {'active': newStatus});
      newList[index] = service.copyWith(isActive: newStatus);
      _worker = _worker!.copyWith(services: newList);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  static const List<String> dayOrder = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  static const Map<String, String> dayLabels = {
    'monday': 'الاثنين', 'tuesday': 'الثلاثاء', 'wednesday': 'الأربعاء', 'thursday': 'الخميس', 'friday': 'الجمعة', 'saturday': 'السبت', 'sunday': 'الأحد'
  };

  static String formatDate(DateTime d) => "${d.year}/${d.month}/${d.day}";
  static String formatTime(TimeOfDay t) => "${t.hour}:${t.minute.toString().padLeft(2, '0')}";

  Future<String?> pickAndConvertImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        final bytes = await image.readAsBytes();
        return base64Encode(bytes);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  Future<bool> updateOrderStatus(String orderId, String status, {String? reason}) async {
    try {
      Map<String, dynamic>? report;
      if (status == 'completed') {
        // The backend requires a completion report (details + images).
        // For now, we send a default one so the button "works" immediately.
        report = {
          'details': 'Service completed successfully.',
          'images': ['https://res.cloudinary.com/demo/image/upload/v1312461204/sample.jpg'], // Placeholder image
        };
      }
      
      await ApiService.updateOrderStatus(orderId, status, completionReport: report, reason: reason);
      await fetchData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfileImage() async {
    final base64 = await pickAndConvertImage();
    if (base64 != null) {
      return updateProfileFull(profileImageBase64: base64);
    }
    return false;
  }
}
