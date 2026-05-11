import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalization {
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('ar'));

  static bool get isArabic => localeNotifier.value.languageCode == 'ar';

  /// Loads the saved language preference from local storage.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      localeNotifier.value = Locale(languageCode);
    }
  }

  static void setLocale(Locale locale) async {
    localeNotifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  static void toggleLanguage() async {
    if (isArabic) {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('ar'));
    }
  }

  static String translate(String key) {
    return isArabic ? _arabic[key] ?? key : _english[key] ?? key;
  }

  static final Map<String, String> _arabic = {
    'app_name': 'أنجزني',
    'tagline': 'بوابة الخدمات العصرية في مصر',
    'login': 'تسجيل الدخول',
    'signup': 'إنشاء حساب',
    'full_name': 'الاسم بالكامل',
    'enter_full_name': 'أدخل اسمك بالكامل',
    'email': 'البريد الإلكتروني',
    'phone': 'رقم الهاتف',
    'password': 'كلمة المرور',
    'create_account': 'إنشاء الحساب',
    'or_continue_with': 'أو المتابعة عبر',
    'google': 'جوجل',
    'facebook': 'فيسبوك',
    'basic_subscription': 'الاشتراك الأساسي',
    'subscription_desc': 'احصل على وصول كامل لكل خدماتنا الآن',
    'price_99': '٩٩ ج.م',
    'monthly': '/ شهرياً',
    'terms': 'الشروط والأحكام',
    'privacy': 'سياسة الخصوصية',
    'language': 'اللغة العربية',
    'search_hint': 'بص بتدور على إيه؟ مثلاً: سباك، كهربائي..',
    'search_btn': 'بحث',
    'categories': 'التصنيفات',
    'view_all': 'عرض الكل',
    'featured_pros': 'محترفين مميزين',
    'home': 'الرئيسية',
    'services': 'الخدمات',
    'bookings': 'الحجوزات',
    'providers': 'المزودين',
    'profile': 'الملف الشخصي',
    'available_providers': 'مقدمي الخدمات المتاحين',
    'results_count': 'نتيجة',
    'book_now': 'حجز الآن',
    'view_profile': 'عرض الملف الشخصي',
    'verified': 'موثق',
    'provider_recruitment': 'هل أنت مقدم خدمة؟',
    'recruitment_desc': 'انضم إلى أكبر شبكة من الحرفيين في مصر وابدأ في زيادة دخلك الآن.',
    'register_now': 'سجل الآن',
    'search_provider_hint': 'ابحث عن مقدم خدمة...',
    'all': 'الكل',
    'server_offline': 'الخادم غير متصل بالإنترنت في الوقت الحالي، يرجى المحاولة لاحقاً.',
    'user_type': 'نوع الحساب',
    'customer': 'عميل (أبحث عن خدمات)',
    'contractor': 'صنايعي / مقاول (أقدم خدمات)',
    'dashboard': 'لوحة التحكم',
    'my_jobs': 'مهامي',
    'earnings': 'الأرباح',
    'wallet': 'المحفظة',
    'settings': 'الإعدادات',
    'active_tasks': 'المهام النشطة',
    'completed_tasks': 'المهام المكتملة',
    'total_earnings': 'إجمالي الأرباح',
    'withdraw': 'سحب الأرباح',
    'job_details': 'تفاصيل المهمة',
    'accept_job': 'قبول المهمة',
    'decline_job': 'رفض المهمة',
    'stats': 'الإحصائيات',
    'recent_activity': 'النشاط الأخير',
  };

  static final Map<String, String> _english = {
    'app_name': 'Angezny',
    'tagline': 'Gateway to modern services in Egypt',
    'login': 'Login',
    'signup': 'Sign Up',
    'full_name': 'Full Name',
    'enter_full_name': 'Enter your full name',
    'email': 'Email Address',
    'phone': 'Phone Number',
    'password': 'Password',
    'create_account': 'Create Account',
    'or_continue_with': 'Or continue with',
    'google': 'Google',
    'facebook': 'Facebook',
    'basic_subscription': 'Basic Subscription',
    'subscription_desc': 'Get full access to all services now',
    'price_99': '99 EGP',
    'monthly': '/ Month',
    'terms': 'Terms & Conditions',
    'privacy': 'Privacy Policy',
    'language': 'English',
    'search_hint': 'What are you looking for? e.g. Plumber..',
    'search_btn': 'Search',
    'categories': 'Categories',
    'view_all': 'View All',
    'featured_pros': 'Featured Professionals',
    'home': 'Home',
    'services': 'Services',
    'bookings': 'Bookings',
    'providers': 'Providers',
    'profile': 'Profile',
    'available_providers': 'Available Providers',
    'results_count': 'Results',
    'book_now': 'Book Now',
    'view_profile': 'View Profile',
    'verified': 'Verified',
    'provider_recruitment': 'Are you a provider?',
    'recruitment_desc': 'Join the largest network of craftsmen in Egypt and start earning now.',
    'register_now': 'Register Now',
    'search_provider_hint': 'Search for a provider...',
    'all': 'All',
    'server_offline': 'The server is offline for the time being, please try again later.',
    'user_type': 'Account Type',
    'customer': 'Client (I need services)',
    'contractor': 'Contractor (I provide services)',
    'dashboard': 'Dashboard',
    'my_jobs': 'My Jobs',
    'earnings': 'Earnings',
    'wallet': 'Wallet',
    'settings': 'Settings',
    'active_tasks': 'Active Tasks',
    'completed_tasks': 'Completed Tasks',
    'total_earnings': 'Total Earnings',
    'withdraw': 'Withdraw',
    'job_details': 'Job Details',
    'accept_job': 'Accept Job',
    'decline_job': 'Decline Job',
    'stats': 'Statistics',
    'recent_activity': 'Recent Activity',
  };
}
