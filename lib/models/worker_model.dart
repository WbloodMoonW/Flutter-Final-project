import 'user_model.dart';
import 'portfolio_item.dart';
import 'pricing_package.dart';
import 'service_model.dart';
import 'working_hours.dart';
import 'review_model.dart';
import 'category_model.dart';

class Worker {
  final String id;
  final User user;
  final String? title;
  final String? bio;
  final String? location;
  final List<String> skills;
  final double ratingAverage;
  final int totalReviews;
  final int totalOrders;
  final double totalEarnings;
  final int completionRate;
  final List<PortfolioItem> portfolio;
  final List<PricingPackage> pricingPackages;
  final List<WorkerService> services;
  final Map<String, WorkingHoursEntry?> workingHours;
  final List<CustomerReview> reviews;
  final bool isCompany;
  final Category? category;

  Worker({
    required this.id,
    required this.user,
    this.title,
    this.bio,
    this.location,
    this.skills = const [],
    this.ratingAverage = 0.0,
    this.totalReviews = 0,
    this.totalOrders = 0,
    this.totalEarnings = 0.0,
    this.completionRate = 0,
    this.portfolio = const [],
    this.pricingPackages = const [],
    this.services = const [],
    this.workingHours = const {},
     this.reviews = const [],
    this.isCompany = false,
    this.category,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    String extractId(dynamic val) {
      if (val == null) return '';
      if (val is String) return val;
      if (val is Map) return val['\$oid']?.toString() ?? val['_id']?.toString() ?? val['id']?.toString() ?? '';
      return val.toString();
    }

    final String workerId = extractId(json['_id'] ?? json['id']);
    final userData = json['userId'] is Map ? json['userId'] : (json['user'] is Map ? json['user'] : json);
    
    final Map<String, WorkingHoursEntry?> wh = {};
    if (json['workingHours'] is List) {
      for (var entry in json['workingHours']) {
        final day = entry['day'];
        if (day != null) {
          wh[day] = entry['enabled'] == false ? null : WorkingHoursEntry.fromMap(entry);
        }
      }
    } else if (json['workingHours'] is Map) {
      json['workingHours'].forEach((day, entry) {
        if (entry is Map<String, dynamic>) {
          wh[day] = WorkingHoursEntry.fromMap(entry);
        }
      });
    }

    String? locStr;
    if (json['location'] is Map) {
      locStr = json['location']['address'] ?? json['location']['city'] ?? json['location']['label'];
    } else if (json['location'] is String && json['location'].toString().isNotEmpty) {
      locStr = json['location'];
    }
    
    // Fallbacks
    locStr ??= json['address']?.toString() ?? 
               json['city']?.toString() ??
               (json['userId'] is Map ? (json['userId']['address']?.toString() ?? json['userId']['location']?.toString()) : null) ??
               (json['user'] is Map ? (json['user']['address']?.toString() ?? json['user']['location']?.toString()) : null);


    return Worker(
      id: workerId,
      user: User.fromJson(userData),
      title: json['title']?.toString() ?? json['profession']?.toString(),
      bio: json['bio']?.toString() ?? json['description']?.toString() ?? json['about']?.toString() ?? 
           (json['userId'] is Map ? (json['userId']['bio']?.toString() ?? json['userId']['description']?.toString()) : null) ??
           (json['user'] is Map ? (json['user']['bio']?.toString() ?? json['user']['description']?.toString()) : null),
      location: locStr,
      skills: json['skills'] is List ? List<String>.from(json['skills'].map((s) => s.toString())) : [],
      ratingAverage: (json['ratingAverage'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      totalOrders: json['completedOrders'] ?? json['totalOrders'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      completionRate: json['completionRate'] ?? 0,
      portfolio: (json['portfolio'] as List?)?.map((p) => PortfolioItem.fromMap(p)).toList() ?? [],
      pricingPackages: (json['pricingPackages'] as List?)?.map((p) => PricingPackage.fromMap(p)).toList() ?? (json['packages'] as List?)?.map((p) => PricingPackage.fromMap(p)).toList() ?? [],
      services: () {
        final List<WorkerService> list = [];
        final rawServices = json['services'] ?? json['serviceList'] ?? json['service'] ?? json['workerServices'];
        if (rawServices is List) {
          for (var item in rawServices) {
            if (item is Map) {
              try {
                list.add(WorkerService.fromMap(Map<String, dynamic>.from(item)));
              } catch (e) {
                // Ignore malformed service but parse others
              }
            }
          }
        }
        return list;
      }(),
      workingHours: wh,
      reviews: (json['reviews'] as List?)?.map((r) => CustomerReview.fromMap(r)).toList() ?? [],
      isCompany: json['isCompany'] ?? false,
      category: json['category'] is Map ? Category.fromJson(json['category']) : (json['categoryId'] is Map ? Category.fromJson(json['categoryId']) : null),
    );
  }

  Worker copyWith({
    String? id,
    User? user,
    String? title,
    String? bio,
    String? location,
    List<String>? skills,
    double? ratingAverage,
    int? totalReviews,
    int? totalOrders,
    double? totalEarnings,
    int? completionRate,
    List<PortfolioItem>? portfolio,
    List<PricingPackage>? pricingPackages,
    List<WorkerService>? services,
    Map<String, WorkingHoursEntry?>? workingHours,
    List<CustomerReview>? reviews,
    bool? isCompany,
    Category? category,
  }) {
    return Worker(
      id: id ?? this.id,
      user: user ?? this.user,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      skills: skills ?? this.skills,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      totalReviews: totalReviews ?? this.totalReviews,
      totalOrders: totalOrders ?? this.totalOrders,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      completionRate: completionRate ?? this.completionRate,
      portfolio: portfolio ?? this.portfolio,
      pricingPackages: pricingPackages ?? this.pricingPackages,
      services: services ?? this.services,
      workingHours: workingHours ?? this.workingHours,
      reviews: reviews ?? this.reviews,
      isCompany: isCompany ?? this.isCompany,
      category: category ?? this.category,
    );
  }
}
