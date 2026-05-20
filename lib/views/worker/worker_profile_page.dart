import 'package:angezny/views/worker/worker_public_profile_page.dart';
import '../client/worker_profile_page.dart' as client_profile;
import '../client/main_wrapper.dart';
import 'worker_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../viewmodels/worker_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'add_service_page.dart';
import '../../core/localization.dart';
import '../../models/portfolio_item.dart';
import '../../models/pricing_package.dart';
import '../../models/working_hours.dart';
import '../../models/order_model.dart';
import '../auth/login_view.dart';
import '../client/map_picker_page.dart';
import 'support_components.dart';

class WorkerProfilePage extends StatefulWidget {
  const WorkerProfilePage({super.key});

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  static const Color primaryColor = Color(0xFF006D5B);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF8E8E93);
  static const Color cardBg = Color(0xFFF9FAFB);

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _skillsCtrl;

  int _activeTab = 0;
  late Map<String, WorkingHoursEntry?> _localHours;
  bool _isAr = AppLocalization.isArabic;
  bool _isInitialized = false;
  TimeOfDay _defaultFrom = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _defaultTo = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    final workerVM = Provider.of<WorkerViewModel>(context, listen: false);
    _nameCtrl = TextEditingController(text: workerVM.name);
    _emailCtrl = TextEditingController(text: workerVM.email);
    _phoneCtrl = TextEditingController(text: workerVM.phone);
    _titleCtrl = TextEditingController(text: workerVM.professionalTitle);
    _bioCtrl = TextEditingController(text: workerVM.bio);
    _locationCtrl = TextEditingController(text: workerVM.location);
    _skillsCtrl = TextEditingController(text: workerVM.skills.join(', '));
    _localHours = Map.from(workerVM.workingHours);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _titleCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo()),
        backgroundColor: success ? primaryColor : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  ImageProvider _getImageProvider(String url) {
    if (url.isEmpty) {
      return const NetworkImage('https://ui-avatars.com/api/?name=Worker&background=006D5B&color=fff');
    }
    if (url.startsWith('http') || url.startsWith('https')) {
      return NetworkImage(url);
    }
    try {
      final base64String = url.contains(',') ? url.split(',').last : url;
      // Remove any whitespace before decoding just in case
      final cleaned = base64String.replaceAll(RegExp(r'\s+'), '');
      return MemoryImage(base64Decode(cleaned));
    } catch (e) {
      return const NetworkImage('https://ui-avatars.com/api/?name=Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final workerVM = Provider.of<WorkerViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    _isAr = AppLocalization.isArabic;

    // Populate controllers if they are not yet initialized and data is available
    if (!_isInitialized && workerVM.worker != null && workerVM.name != "Worker") {
      _nameCtrl.text = workerVM.name;
      _emailCtrl.text = workerVM.email;
      _phoneCtrl.text = workerVM.phone;
      _titleCtrl.text = workerVM.professionalTitle;
      _bioCtrl.text = workerVM.bio;
      _locationCtrl.text = workerVM.location;
      _skillsCtrl.text = workerVM.skills.join(', ');
      const englishToArabicDays = {
        'sat': 'السبت', 'sun': 'الأحد', 'mon': 'الاثنين',
        'tue': 'الثلاثاء', 'wed': 'الأربعاء', 'thu': 'الخميس', 'fri': 'الجمعة',
        'saturday': 'السبت', 'sunday': 'الأحد', 'monday': 'الاثنين',
        'tuesday': 'الثلاثاء', 'wednesday': 'الأربعاء', 'thursday': 'الخميس', 'friday': 'الجمعة',
      };
      _localHours = {};
      workerVM.workingHours.forEach((day, entry) {
        final arabicDay = englishToArabicDays[day.toLowerCase()] ?? day;
        _localHours[arabicDay] = entry;
      });
      _isInitialized = true;
    }

    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() => _isInitialized = false);
              await workerVM.loadWorkerData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(workerVM),
                  const SizedBox(height: 24),
                  _buildStatsGrid(workerVM),
                  const SizedBox(height: 24),
                  _buildSettingsSection(workerVM, authVM),
                  const SizedBox(height: 24),
                  _buildSecondaryActions(workerVM),
                  const SizedBox(height: 32),
                  _buildTabs(workerVM),
                  const SizedBox(height: 16),
                  _buildTabContent(workerVM),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WorkerViewModel workerVM) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor, width: 3),
                image: DecorationImage(
                  image: _getImageProvider(workerVM.avatarUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => workerVM.updateProfileImage(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(workerVM.name, style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
        Text(workerVM.professionalTitle.isEmpty ? (_isAr ? 'لم يتم تحديد مهنة' : 'No title specified') : workerVM.professionalTitle, 
            style: GoogleFonts.cairo(fontSize: 14, color: textMuted)),
      ],
    );
  }

  Widget _buildStatsGrid(WorkerViewModel workerVM) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildStatItem(
            label: _isAr ? 'قيد الانتظار' : 'Pending',
            value: workerVM.pendingOrders.toString(),
            icon: Icons.access_time_rounded,
            color: Colors.orange,
            bgColor: const Color(0xFFFFF8E1),
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            label: _isAr ? 'مكتمل' : 'Completed',
            value: workerVM.completedOrders.toString(),
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green,
            bgColor: const Color(0xFFE8F5E9),
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            label: _isAr ? 'الأرباح' : 'Earnings',
            value: '${workerVM.totalEarnings.toStringAsFixed(0)} ${_isAr ? 'ج.م' : 'EGP'}',
            icon: Icons.payments_outlined,
            color: primaryColor,
            bgColor: const Color(0xFFE0F2F1),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value, required IconData icon, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Text(label, style: GoogleFonts.cairo(fontSize: 16, color: textDark)),
          const Spacer(),
          Text(value, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions(WorkerViewModel workerVM) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddServicePage())),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D5A46),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text(
            _isAr ? '+ إضافة خدمة جديدة' : '+ Add New Service',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(WorkerViewModel workerVM, AuthViewModel authVM) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Text(_isAr ? 'عربي' : 'Arabic', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              const Spacer(),
              Switch(
                value: _isAr,
                onChanged: (val) {
                  setState(() => _isAr = val);
                  AppLocalization.toggleLanguage();
                },
                activeColor: primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Multi-Account Dropdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: authVM.accounts.any((acc) => acc['user']['email'] == authVM.currentUser?.email) ? authVM.currentUser?.email : null,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
                items: [
                  ...(() {
                    final uniqueEmails = <String>{};
                    return authVM.accounts.where((acc) => uniqueEmails.add(acc['user']['email'])).map((acc) {
                      final user = acc['user'];
                      return DropdownMenuItem<String>(
                        value: user['email'],
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: primaryColor.withOpacity(0.1),
                              backgroundImage: _getImageProvider(user['profileImage']?.toString() ?? ''),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "${user['firstName']} ${user['lastName']}",
                                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user['email'] == authVM.currentUser?.email)
                              const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          ],
                        ),
                      );
                    });
                  })(),
                  DropdownMenuItem<String>(
                    value: 'ADD_ACCOUNT',
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline, color: primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          _isAr ? 'إضافة حساب جديد' : 'Add Account',
                          style: GoogleFonts.cairo(fontSize: 14, color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) async {
                  if (val == 'ADD_ACCOUNT') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  } else if (val != null && val != authVM.currentUser?.email) {
                    final index = authVM.accounts.indexWhere((acc) => acc['user']['email'] == val);
                    if (index != -1) {
                      await authVM.switchAccount(index);
                      if (mounted) {
                        final role = authVM.currentUser?.role ?? 'customer';
                        if (role == 'worker') {
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const WorkerDashboardPage()), (r) => false);
                        } else {
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainWrapper()), (r) => false);
                        }
                      }
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActions(WorkerViewModel workerVM) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildOutlineAction(
            label: _isAr ? 'تسجيل الخروج' : 'Logout',
            icon: Icons.logout_rounded,
            color: Colors.redAccent,
            onTap: () async {
              await Provider.of<AuthViewModel>(context, listen: false).logout();
              if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
            },
          ),
          const SizedBox(height: 12),
          _buildOutlineAction(
            label: _isAr ? 'الملف العام' : 'Public Profile',
            icon: Icons.visibility_outlined,
            color: primaryColor,
            onTap: () {
              if (workerVM.worker?.id != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => client_profile.WorkerProfilePage(workerId: workerVM.worker!.id)));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineAction({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: color,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(WorkerViewModel workerVM) {
    final tabs = _isAr 
      ? ['الملف الشخصي', 'الخدمات', 'سجل المهام'] 
      : ['Profile', 'Services', 'Job History'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final isActive = _activeTab == e.key;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = e.key),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2D5A46) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isActive ? Colors.transparent : Colors.grey.shade200),
              ),
              child: Text(
                e.value,
                style: GoogleFonts.cairo(
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(WorkerViewModel workerVM) {
    switch (_activeTab) {
      case 0: return _buildProfileTab(workerVM);
      case 1: return _buildServicesTab(workerVM);
      case 2: return _buildHistoryTab(workerVM);
      default: return const SizedBox();
    }
  }

  Widget _buildProfileTab(WorkerViewModel workerVM) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBronzeBadge(workerVM),
          const SizedBox(height: 24),
          _buildPortfolioSection(workerVM),
          const SizedBox(height: 24),
          _buildWorkingHoursSection(),
          const SizedBox(height: 24),
          _buildPersonalInfoSection(),
          const SizedBox(height: 32),
          _buildSaveButton(workerVM),
        ],
      ),
    );
  }

  Widget _buildBronzeBadge(WorkerViewModel workerVM) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Text(
            _isAr ? 'أنجزت ${workerVM.completedOrders} طلباً مكتملاً' : 'You completed ${workerVM.completedOrders} orders',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.brown),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
            child: Text(_isAr ? 'برونزي' : 'Bronze', style: GoogleFonts.cairo(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection(WorkerViewModel workerVM) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.grid_view_rounded, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(_isAr ? 'معرض الأعمال' : 'Portfolio', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: () async {
                final imageUrl = await workerVM.pickAndUploadImage();
                if (imageUrl != null && mounted) {
                  String title = '';
                  String desc = '';
                  await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(_isAr ? 'إضافة عمل' : 'Add Work', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            decoration: InputDecoration(labelText: _isAr ? 'العنوان' : 'Title'),
                            onChanged: (val) => title = val,
                          ),
                          TextField(
                            decoration: InputDecoration(labelText: _isAr ? 'الوصف' : 'Description'),
                            onChanged: (val) => desc = val,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_isAr ? 'إلغاء' : 'Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            workerVM.addPortfolioItem(PortfolioItem(title: title, description: desc, imageUrl: imageUrl));
                            Navigator.pop(ctx);
                          },
                          child: Text(_isAr ? 'إضافة' : 'Add'),
                        ),
                      ],
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text(_isAr ? 'إضافة عمل' : 'Add Work', style: GoogleFonts.cairo(fontSize: 12)),
              style: TextButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (workerVM.portfolio.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                _isAr ? 'لا توجد أعمال بعد. أضف أول عمل لك.' : 'No portfolio items yet. Add your first work.',
                style: GoogleFonts.cairo(color: textMuted, fontSize: 13),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: workerVM.portfolio.length,
            itemBuilder: (context, index) => Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(image: _getImageProvider(workerVM.portfolio[index].imageUrl ?? ''), fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        debugPrint('--- Tapped delete button for portfolio item index: $index');
                        workerVM.deletePortfolioItem(index);
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWorkingHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time_filled_rounded, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(_isAr ? 'ساعات العمل' : 'Working Hours', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTimePickerField(_isAr ? 'من' : 'From', _defaultFrom, true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTimePickerField(_isAr ? 'إلى' : 'To', _defaultTo, false)),
          ],
        ),
        const SizedBox(height: 16),
        Text(_isAr ? 'أيام الإجازة' : 'Days Off', style: GoogleFonts.cairo(fontSize: 14, color: textMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'].map((day) {
            final isOff = _localHours[day] == null;
            return GestureDetector(
              onTap: () => setState(() => _localHours[day] = isOff ? WorkingHoursEntry(from: _defaultFrom, to: _defaultTo) : null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isOff ? const Color(0xFFF3F4F6) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isOff ? Colors.transparent : primaryColor.withOpacity(0.3)),
                ),
                child: Text(day, style: GoogleFonts.cairo(fontSize: 12, color: isOff ? textMuted : primaryColor)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimePickerField(String label, TimeOfDay time, bool isFrom) {
    final timeStr = time.format(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 12, color: textDark, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(context: context, initialTime: time);
            if (picked != null) {
              setState(() {
                if (isFrom) _defaultFrom = picked; else _defaultTo = picked;
                _localHours.forEach((key, val) {
                  if (val != null) _localHours[key] = WorkingHoursEntry(from: _defaultFrom, to: _defaultTo);
                });
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: textMuted),
                const SizedBox(width: 8),
                Text(timeStr, style: GoogleFonts.cairo(color: textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      children: [
        LabeledFormField(label: _isAr ? 'العنوان المهني' : 'Professional Title', hint: '', controller: _titleCtrl),
        const SizedBox(height: 16),
        LabeledFormField(label: _isAr ? 'نبذة عنك' : 'Bio', hint: '', controller: _bioCtrl, maxLines: 4),
        const SizedBox(height: 16),
        LabeledFormField(
          label: _isAr ? 'الموقع' : 'Location', 
          hint: _isAr ? 'اضغط لتحديد الموقع' : 'Tap to select location', 
          controller: _locationCtrl,
          readOnly: true,
          suffixIcon: const Icon(Icons.map_outlined, color: primaryColor),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapPickerPage()),
            );
            if (result != null && result is Map) {
              setState(() {
                _locationCtrl.text = result['address'] ?? "";
              });
            }
          },
        ),
        const SizedBox(height: 16),
        LabeledFormField(label: _isAr ? 'المهارات (افصل بفاصلة)' : 'Skills (comma separated)', hint: '', controller: _skillsCtrl),
      ],
    );
  }

  Widget _buildSaveButton(WorkerViewModel workerVM) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          final skills = _skillsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          final success = await workerVM.updateProfileFull(
            fullName: _nameCtrl.text,
            bioText: _bioCtrl.text,
            title: _titleCtrl.text,
            loc: _locationCtrl.text,
            skillsList: skills,
            hours: _localHours,
          );
          if (success) {
            _showSnack(_isAr ? 'تم حفظ البيانات بنجاح' : 'Profile updated successfully');
          } else {
            _showSnack(workerVM.errorMessage ?? (_isAr ? 'فشل حفظ البيانات' : 'Failed to update profile'), success: false);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(_isAr ? 'حفظ التعديلات' : 'Save Changes', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildServicesTab(WorkerViewModel workerVM) {
    return Column(
      children: [
        _buildPrimaryActions(workerVM),
        const SizedBox(height: 20),
        if (workerVM.services.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.miscellaneous_services_rounded, size: 64, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text(_isAr ? 'لا توجد خدمات مضافة' : 'No services added', style: GoogleFonts.cairo(color: textMuted)),
                ],
              ),
            ),
          )
        else
          ...workerVM.services.asMap().entries.map((entry) {
        final index = entry.key;
        final s = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.description,
                      style: GoogleFonts.cairo(fontSize: 14, color: textMuted),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${s.price.toStringAsFixed(0)} ${_isAr ? 'ج.م' : 'EGP'}',
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Switch(
                    value: s.isActive,
                    activeColor: primaryColor,
                    onChanged: (val) => workerVM.toggleServiceStatus(index),
                  ),
                  Text(
                    s.isActive ? (_isAr ? 'نشط' : 'Active') : (_isAr ? 'غير نشط' : 'Inactive'),
                    style: GoogleFonts.cairo(fontSize: 10, color: s.isActive ? primaryColor : textMuted),
                  ),
                ],
              ),
            ],
          ),
        );
        }),
      ],
    );
  }

  Widget _buildActiveJobsTab(WorkerViewModel workerVM) {
    final active = workerVM.orders.where((o) => o.status != 'completed' && o.status != 'cancelled' && o.status != 'rejected').toList();
    if (active.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(_isAr ? 'لا توجد مهام جارية' : 'No active jobs', style: GoogleFonts.cairo(color: textMuted)),
        ),
      );
    }
    return Column(children: active.map((o) => _buildOrderCard(o)).toList());
  }

  Widget _buildHistoryTab(WorkerViewModel workerVM) {
    final history = workerVM.historyOrders;
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(_isAr ? 'لا توجد مشاريع مكتملة' : 'No completed projects', style: GoogleFonts.cairo(color: textMuted)),
        ),
      );
    }
    return Column(children: history.map((o) => _buildOrderCard(o)).toList());
  }

  Widget _buildOrderCard(Order o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.assignment_outlined, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.serviceTitle ?? (_isAr ? 'خدمة' : 'Service'), style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(o.customer?.fullName ?? (_isAr ? 'عميل' : 'Customer'), style: GoogleFonts.cairo(fontSize: 12, color: textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${o.price.toStringAsFixed(0)} ${_isAr ? 'ج.م' : 'EGP'}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(o.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _translateStatus(o.status),
                  style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(o.status)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'completed': return Colors.green;
      case 'cancelled':
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _translateStatus(String status) {
    final s = status.toLowerCase();
    if (!_isAr) return s.replaceAll('_', ' ');
    switch (s) {
      case 'pending': return 'قيد الانتظار';
      case 'accepted': return 'مقبول';
      case 'in_progress': return 'قيد التنفيذ';
      case 'completed': return 'مكتمل';
      case 'cancelled': return 'ملغي';
      case 'rejected': return 'مرفوض';
      default: return status;
    }
  }
}
