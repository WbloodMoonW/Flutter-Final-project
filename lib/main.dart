import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/localization.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/client_viewmodel.dart';
import 'viewmodels/worker_viewmodel.dart';
import 'views/auth/login_view.dart';
import 'views/auth/verification_view.dart';
import 'views/client/main_wrapper.dart';
import 'views/worker/worker_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocalization.init();
  
  final String? token = await StorageService.getToken();
  String role = 'customer';
  String? userEmail;
  bool isVerified = true;
  bool forceVerify = false;

  if (token != null) {
    final user = await ApiService.getMe();
    if (user != null) {
      role = user.role;
      userEmail = user.email;
      isVerified = user.isVerified;
      
      if (role == 'worker' && !isVerified) {
        forceVerify = true;
      }
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ClientViewModel()),
        ChangeNotifierProvider(create: (_) => WorkerViewModel()),
      ],
      child: MyApp(
        isLoggedIn: token != null,
        isVerified: isVerified,
        email: userEmail,
        forceVerify: forceVerify,
        role: role,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isVerified;
  final String? email;
  final bool forceVerify;
  final String role;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.isVerified,
    required this.forceVerify,
    required this.role,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    Widget initialHome;
    if (!isLoggedIn) {
      initialHome = const LoginPage();
    } else if (forceVerify && email != null) {
      initialHome = VerificationPage(email: email!);
    } else {
      initialHome = (role == 'worker') ? const WorkerDashboardPage() : const MainWrapper();
    }

    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocalization.localeNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          title: 'Angezny',
          debugShowCheckedModeBanner: false,
          locale: locale,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006D5B)),
            useMaterial3: true,
          ),
          home: initialHome,
        );
      },
    );
  }
}
