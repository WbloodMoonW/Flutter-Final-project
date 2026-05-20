import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../core/localization.dart';
import '../models/user_model.dart';
import '../models/worker_model.dart';
import '../models/service_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../models/notification_model.dart';
import '../models/chat_models.dart';
import '../models/coupon_model.dart';
import '../models/review_model.dart';
import 'storage_service.dart';
import 'socket_service.dart';

class ApiService {
  static const String _baseUrl = 'https://angezny.onrender.com/api';

  static String _handleError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('SocketException') || 
        errorStr.contains('Connection failed') || 
        errorStr.contains('HandshakeException') || 
        errorStr.contains('Unexpected character') ||
        errorStr.contains('FormatException')) {
      return AppLocalization.translate('server_offline');
    }
    return errorStr.replaceAll('Exception: ', '');
  }

  // ============================================================
  // AUTHENTICATION
  // ============================================================

  static Future<Map<String, dynamic>?> signin(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 100));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await StorageService.saveToken(data['token']);
          final accounts = await StorageService.getAccounts();
          final user = data['user'];
          accounts.removeWhere((acc) => acc['user']['email'] == user['email']);
          accounts.add({'token': data['token'], 'user': user});
          await StorageService.saveAccounts(accounts);
        }
        return data; 
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<Map<String, dynamic>?> googleSignin(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': idToken}),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        if (data['token'] != null) await StorageService.saveToken(data['token']);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Google login failed');
      }
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<Map<String, dynamic>?> facebookSignin(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/facebook'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'accessToken': accessToken}),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        if (data['token'] != null) await StorageService.saveToken(data['token']);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Facebook login failed');
      }
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'newPassword': newPassword}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<List<AppNotification>> getNotifications() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['notifications'] as List).map((n) => AppNotification.fromJson(n)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> markNotificationsRead() async {
    try {
      final token = await StorageService.getToken();
      await http.put(
        Uri.parse('$_baseUrl/auth/notifications/read-all'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
    } catch (e) {}
  }

  static Future<Map<String, dynamic>?> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? idFront,
    String? idBack,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
          'password': password,
          'confirmPassword': password,
          'role': role,
          if (idFront != null) 'idFront': idFront,
          if (idBack != null) 'idBack': idBack,
        }),
      ).timeout(const Duration(seconds: 100));

      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        if (data['token'] != null) {
          await StorageService.saveToken(data['token']);
        }
        return data;
      } else {
        throw Exception(data['message'] ?? 'Signup failed');
      }
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<User?> getMe() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['user'] ?? data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // WORKER DATA
  // ============================================================

  static Future<Map<String, dynamic>?> getWorkerDashboard() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/worker/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error in getWorkerDashboard: $e');
      return null;
    }
  }

  static Future<List<Order>> getWorkerOrders() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$_baseUrl/worker/orders'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> ordersData = [];
        if (data is List) {
          ordersData = data;
        } else if (data is Map) {
          ordersData = (data['orders'] ?? data['data'] ?? data['items'] ?? []) as List;
        }
        final List<Order> list = [];
        for (var o in ordersData) {
          try {
            list.add(Order.fromJson(o));
          } catch (err) {
            debugPrint('Skipping malformed worker order: $err, JSON: $o');
          }
        }
        return list;
      }
    } catch (e) {
      debugPrint('Error in getWorkerOrders: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getWorkerWallet() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/worker/wallet'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) {}
    return null;
  }



  // GET /worker/licenses does not exist; extract from dashboard profile instead.
  static Future<List<String>> getWorkerLicenses() async {
    try {
      final dashboard = await getWorkerDashboard();
      if (dashboard == null) return [];
      final actualData = dashboard['data'] ?? dashboard;
      final profileData = actualData['profile'] ?? actualData['worker'] ?? actualData;
      final rawLicenses = profileData['licenses'] as List? ?? [];
      return rawLicenses
          .map((l) => (l as Map<String, dynamic>)['fileUrl']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {}
    return [];
  }

  static Future<void> addLicense(Map<String, dynamic> licenseData) async {
    try {
      final token = await StorageService.getToken();
      await http.post(
        Uri.parse('$_baseUrl/worker/licenses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(licenseData),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // ============================================================
  // SEARCH & CHAT
  // ============================================================

  static Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/search/suggest?q=$query'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['suggestions'] ?? []);
      }
    } catch (e) {}
    return [];
  }

  static Future<List<Conversation>> getConversations() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/conversations'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['conversations'] as List).map((c) => Conversation.fromJson(c)).toList();
      }
    } catch (e) {}
    return [];
  }

  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/conversations/$conversationId/messages'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['messages'] as List).map((m) => ChatMessage.fromJson(m)).toList();
      }
    } catch (e) {}
    return [];
  }

  static Future<Conversation?> findOrCreateConversation(String userId) async {
    try {
      final token = await StorageService.getToken();
      debugPrint('>>> FIND/CREATE CONV WITH USER: $userId');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'userId': userId}),
      ).timeout(const Duration(seconds: 15));

      debugPrint('>>> CONV RESPONSE STATUS: ${response.statusCode}');
      debugPrint('>>> CONV RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Conversation.fromJson(data['conversation'] ?? data['data'] ?? data);
      }
    } catch (e) {
      debugPrint('>>> CONV ERROR: $e');
    }
    return null;
  }

  static Future<void> sendMessage(String conversationId, String message, String senderId) async {
    try {
      final socket = await SocketService.connect();
      socket.emit('chat:send', {
        'conversationId': conversationId,
        'message': message,
        'messageType': 'text',
      });
    } catch (e) {
      debugPrint('>>> SEND MESSAGE ERROR: $e');
    }
  }

  static Future<List<WorkerService>> getWorkerServices() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$_baseUrl/worker/services'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List servicesData = (data is List) ? data : (data['services'] ?? []);
        return servicesData.map((s) => WorkerService.fromMap(s)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> updateWorkerProfile(Map<String, dynamic> data) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await http.put(
        Uri.parse('$_baseUrl/worker/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update worker profile');
      }
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // ============================================================
  // CLIENT DATA
  // ============================================================

  static Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories'))
          .timeout(const Duration(seconds: 100));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['categories'] as List).map((c) => Category.fromJson(c)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Category?> getCategoryById(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories/$id'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Category.fromJson(data['category'] ?? data);
      }
    } catch (e) {}
    return null;
  }

  static Future<List<Worker>> getWorkers({int? limit = 100, String? category, String? search, double? lat, double? lng, String? postcode}) async {
    try {
      String url = '$_baseUrl/workers?limit=$limit';
      if (category != null && category.isNotEmpty) url += '&category=$category';
      if (search != null && search.isNotEmpty) url += '&search=$search';
      if (lat != null) url += '&lat=$lat';
      if (lng != null) url += '&lng=$lng';
      if (postcode != null && postcode.isNotEmpty) url += '&postcode=$postcode';

      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 100));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List workersList = data['workers'] ?? [];
        
        final List<Worker> workers = [];
        for (var w in workersList) {
          try {
            workers.add(Worker.fromJson(w));
          } catch (e) {
            debugPrint('Error parsing worker data: $e');
            debugPrint('Malformed worker data: $w');
          }
        }
        return workers;
      }
    } catch (e) {
      debugPrint('Error in getWorkers: $e');
    }
    return [];
  }

  static Future<void> updateMyLocation(double lat, double lng, String address) async {
    try {
      final token = await StorageService.getToken();
      await http.put(
        Uri.parse('$_baseUrl/workers/me/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'lat': lat, 'lng': lng, 'address': address}),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<WorkerService?> getServiceById(String serviceId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/workers/service/$serviceId'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WorkerService.fromMap(data['service'] ?? data);
      }
    } catch (e) {}
    return null;
  }

  static Future<Worker?> getWorkerById(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/workers/$id'))
          .timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Worker.fromJson(data['worker'] ?? data);
      }
    } catch (e) {}
    return null;
  }

  static Future<List<CustomerReview>> getWorkerReviews(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/workers/$id/reviews'))
          .timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List reviewsData = (data['reviews'] ?? data) as List;
        return reviewsData.map((r) => CustomerReview.fromMap(r)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching worker reviews: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getCustomerProfile() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/customer/profile'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) {}
    return null;
  }

  static Future<void> updateCustomerProfile(Map<String, dynamic> data) async {
    try {
      final token = await StorageService.getToken();
      await http.put(
        Uri.parse('$_baseUrl/customer/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<List<Order>> getCustomerOrders() async {
    try {
      final token = await StorageService.getToken();
      debugPrint('>>> getCustomerOrders: token=${token != null ? "present" : "NULL"}');
      final response = await http.get(
        //https://angezny.onrender.com/api/customer/orders?status=history&page=1&limit=10
        Uri.parse('$_baseUrl/customer/orders?status=history'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      debugPrint('>>> getCustomerOrders: statusCode=${response.statusCode}');
      debugPrint('>>> getCustomerOrders: body=${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> ordersData = [];
        if (data is List) {
          ordersData = data;
        } else if (data is Map) {
          ordersData = (data['orders'] ?? data['data'] ?? data['item'] ?? []) as List;
        }
        debugPrint('>>> getCustomerOrders: found ${ordersData.length} raw orders');
        final List<Order> list = [];
        for (var o in ordersData) {
          try {
            final order = Order.fromJson(o);
            debugPrint('>>> Parsed order id=${order.id}, status="${order.status}"');
            list.add(order);
          } catch (err) {
            debugPrint('Skipping malformed customer order: $err, JSON: $o');
          }
        }
        debugPrint('>>> getCustomerOrders: returning ${list.length} orders');
        return list;
      }
    } catch (e) {
      debugPrint('Error in getCustomerOrders: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> addAddress(Map<String, dynamic> addressData) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/customer/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(addressData),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to add address');
      }
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // Returns the created order's id (and the raw map for callers that need
  // more fields). Throws on non-2xx.
  static Future<Map<String, dynamic>> createBooking({
    required String serviceId,
    String? locationAddress,
    DateTime? scheduledFor,
    String? couponCode,
    String paymentMode = 'cash_on_delivery',
  }) async {
    try {
      final token = await StorageService.getToken();
      final String formattedDate = scheduledFor!.toUtc().toIso8601String().split('.')[0] + 'Z';

      final body = <String, dynamic>{
        'serviceId': serviceId,
        'address': locationAddress ?? '',
        'scheduledDate': formattedDate,
        'paymentMode': paymentMode,
        if (couponCode != null) 'couponCode': couponCode,
      };

      debugPrint('>>> ORDER BODY: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/customer/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      debugPrint('>>> ORDER RESPONSE STATUS: ${response.statusCode}');
      debugPrint('>>> ORDER RESPONSE BODY: ${response.body}');

      final data = json.decode(response.body);
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Failed to create order');
      }
      return Map<String, dynamic>.from(data['order'] ?? data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // Starts a Paymob hosted-checkout session for an order. Returns
  // { paymentId, checkoutUrl } that the mobile UI uses to open a WebView.
  static Future<Map<String, String>> createPaymobCheckout(String orderId) async {
    final token = await StorageService.getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/payments/checkout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'orderId': orderId}),
    ).timeout(const Duration(seconds: 20));
    final data = json.decode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Failed to start checkout');
    }
    return {
      'paymentId': (data['paymentId'] ?? '').toString(),
      'checkoutUrl': (data['checkoutUrl'] ?? '').toString(),
    };
  }

  // Polled by the WebView screen while the customer is paying — the webhook
  // is authoritative server-side, this is just a way to surface the latest
  // status to the UI.
  static Future<String> getPaymentStatus(String paymentId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/$paymentId/status'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['payment']?['status'] ?? 'pending').toString();
      }
    } catch (_) {}
    return 'pending';
  }

  // ============================================================
  // OTHER
  // ============================================================

  static Future<void> verifyEmail(String email, String code) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'email': email, 'code': code}),
      ).timeout(const Duration(seconds: 100));

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Verification failed');
      }
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<void> resendVerificationCode() async {
    try {
      final token = await StorageService.getToken();
      await http.post(
        Uri.parse('$_baseUrl/auth/resend-verification-code'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 100));
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // The backend has no role-switching endpoint. To change roles, the user must
  // create a new account with the desired role.
  static Future<void> switchRole(String newRole) async {
    throw Exception(
      AppLocalization.isArabic
          ? 'لا يمكن تغيير الدور. يرجى إنشاء حساب جديد بالدور المطلوب.'
          : 'Role switching is not supported. Please create a new account with the desired role.',
    );
  }

  static Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      ).timeout(const Duration(seconds: 100));

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to send reset email');
      }
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<void> updateOrderStatus(String orderId, String status, {Map<String, dynamic>? completionReport, String? reason}) async {
    try {
      final token = await StorageService.getToken();
      final body = {
        'status': status,
        if (completionReport != null) 'completionReport': completionReport,
        if (reason != null) 'reason': reason,
        if (reason != null) 'rejectionReason': reason,
      };
      await http.put(
        Uri.parse('$_baseUrl/worker/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<Coupon?> getFeaturedCoupon() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/coupons/featured'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        final raw = data['coupon'] ?? data;
        if (raw == null || (raw is Map && raw.isEmpty)) return null;
        return Coupon.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (e) {}
    return null;
  }

  static Future<Coupon?> validateCoupon(String code, {double? amount, String? categoryId}) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/coupons/validate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'code': code,
          if (amount != null) 'amount': amount,
          if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend returns { valid: false, message } for invalid codes — bail.
        if (data is Map && data['valid'] == false) return null;
        return Coupon.fromJson(data['coupon'] ?? data);
      }
    } catch (e) {}
    return null;
  }
  static Future<WorkerService> createService(WorkerService service) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/worker/services'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(service.toMap()),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return WorkerService.fromMap(data['service']);
      } else {
        throw Exception(data['message'] ?? 'Failed to create service');
      }
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<void> updateService(String serviceId, Map<String, dynamic> data) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/worker/services/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update service');
      }
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<void> deleteService(String serviceId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/worker/services/$serviceId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete service');
      }
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }
}
