import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import 'services_page.dart';
import 'bookings_page.dart';
import '../../core/localization.dart';
import 'profile_page.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/client_viewmodel.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => MainWrapperState();
}


class MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  final Color primaryTeal = const Color(0xFF006D5B);

  @override
  void initState() {
    super.initState();
    AppLocalization.localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    AppLocalization.localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) {
      Provider.of<ClientViewModel>(context, listen: false).fetchAll();
    }
  }

  void updateIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocalization.localeNotifier,
      builder: (context, locale, child) {
        final List<Widget> pages = [
          HomePage(key: ValueKey('home_${locale.languageCode}')),
          ServicesPage(key: ValueKey('services_${locale.languageCode}')),
          BookingsPage(key: ValueKey('bookings_${locale.languageCode}')),
          ProfilePage(key: ValueKey('profile_${locale.languageCode}')),
        ];

        return Scaffold(
          body: pages[_selectedIndex],
          bottomNavigationBar: Directionality(
            textDirection: AppLocalization.isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                debugPrint("Tapped index: $index");
                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: primaryTeal,
              unselectedItemColor: Colors.grey[400],
              selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.home_filled), label: AppLocalization.translate('home')),
                BottomNavigationBarItem(icon: const Icon(Icons.grid_view_rounded), label: AppLocalization.translate('services')),
                BottomNavigationBarItem(icon: const Icon(Icons.calendar_month_outlined), label: AppLocalization.translate('bookings')),
                BottomNavigationBarItem(icon: const Icon(Icons.person_outline_rounded), label: AppLocalization.translate('profile')),
              ],
            ),
          ),
        );
      },
    );
  }
}
