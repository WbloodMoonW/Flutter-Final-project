import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/worker_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/localization.dart';
import '../../services/api_service.dart';
import '../auth/login_view.dart';
import 'worker_profile_page.dart';
import 'service_requests_page.dart';
import 'wallet_page.dart';
import 'worker_public_profile_page.dart';
import 'report_page.dart';
import '../../models/chat_models.dart';
import '../client/chat_page.dart';

class WorkerDashboardPage extends StatefulWidget {
  const WorkerDashboardPage({super.key});

  @override
  State<WorkerDashboardPage> createState() => _WorkerDashboardPageState();
}

class _WorkerDashboardPageState extends State<WorkerDashboardPage>
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  String _searchQuery = '';
  String _selectedFilter = 'الكل';

  int _messagesRefreshKey = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // ── Design Colors ──
  static const Color primaryColor = Color(0xFF006D5B);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF8E8E93);
  static const Color cardWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();

    // Initial data fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerViewModel>(context, listen: false).fetchData();
    });
    AppLocalization.localeNotifier.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (mounted) {
      Provider.of<WorkerViewModel>(context, listen: false).fetchData();
    }
  }

  @override
  void dispose() {
    AppLocalization.localeNotifier.removeListener(_onLocaleChanged);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocalization.localeNotifier,
      builder: (context, locale, child) {
        final isAr = AppLocalization.isArabic;
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            drawer: _buildDrawer(isAr),
            appBar: (_currentNavIndex == 2 || _currentNavIndex == 3)
                ? null
                : AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    centerTitle: false,
                    title: const Text(
                      'Angezny',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: IndexedStack(
                index: _currentNavIndex,
                children: [
                  // 0 - Home
                  _buildHomeTab(isAr),
                  // 1 - Requests
                  ServiceRequestsPage(key: ValueKey('requests_${locale.languageCode}')),
                  // 2 - Messages
                  _buildMessagesTab(isAr),
                  // 3 - Profile
                  WorkerProfilePage(key: ValueKey('profile_${locale.languageCode}')),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNav(isAr),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────
  //  Home Tab
  // ──────────────────────────────────────────
  Widget _buildHomeTab(bool isAr) {
    return Consumer<WorkerViewModel>(
      builder: (context, workerVM, _) {
        return RefreshIndicator(
          onRefresh: () => workerVM.fetchData(),
          color: primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _buildSearchBar(isAr),
                if (_searchQuery.isEmpty) ...[
                  _buildWelcomeSection(workerVM),
                  _buildEarningsCard(workerVM, isAr),
                  const SizedBox(height: 18),
                  _buildStatsRow(workerVM, isAr),
                  const SizedBox(height: 24),
                  _buildQuickActions(isAr),
                  const SizedBox(height: 24),
                  _buildCurrentJobs(workerVM, isAr),
                ] else ...[
                  _buildSearchResults(isAr),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────
  //  Messages Tab
  // ──────────────────────────────────────────
  Widget _buildMessagesTab(bool isAr) {
    final authVM = Provider.of<AuthViewModel>(context);
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _messagesRefreshKey++;
        });
      },
      child: FutureBuilder<List<Conversation>>(
        key: ValueKey(_messagesRefreshKey),
        future: ApiService.getConversations(),
        builder: (context, snapshot) {
          final conversations = snapshot.data ?? [];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'محادثاتي' : 'My Messages',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  )
                else if (conversations.isEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 250,
                        child: Center(
                          child: Text(
                            isAr ? 'لا توجد محادثات حالياً' : 'No conversations yet',
                            style: GoogleFonts.cairo(),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final chat = conversations[index] as Conversation;
                        final otherUser = chat.participants.firstWhere(
                          (p) => p.id != authVM.currentUser?.id,
                          orElse: () => chat.participants.first,
                        );
                        final lastMsg = chat.lastMessage?.text ?? (isAr ? 'بدء المحادثة' : 'Start conversation');

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  receiverId: otherUser.id,
                                  receiverName: otherUser.fullName,
                                  conversationId: chat.id,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardWhite,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: primaryColor.withOpacity(0.1),
                                  child: Text(
                                    (otherUser.firstName.isNotEmpty ? otherUser.firstName : 'U').substring(0, 1),
                                    style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            otherUser.fullName,
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: textDark,
                                            ),
                                          ),
                                          Text(
                                            isAr ? 'الآن' : 'Now',
                                            style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              color: textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lastMsg,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          color: textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          textAlign: isAr ? TextAlign.right : TextAlign.left,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
          },
          decoration: InputDecoration(
            hintText: isAr
                ? 'ابحث عن عملاء أو كلمات مفتاحية...'
                : 'Search for customers or keywords...',
            hintStyle: GoogleFonts.cairo(color: textMuted, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: textMuted),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isAr) {
    // Placeholder logic for search results
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(isAr ? 'لا توجد نتائج بحث' : 'No search results', style: GoogleFonts.cairo(color: textMuted)),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(WorkerViewModel workerVM) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppLocalization.isArabic ? 'مرحباً بك مجدداً' : 'Welcome back',
            style: GoogleFonts.cairo(fontSize: 15, color: textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            workerVM.name,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(WorkerViewModel workerVM, bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D6A4F), Color(0xFF1B5E40)],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              isAr ? 'إجمالي الأرباح' : 'Total Earnings',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  isAr ? 'ج.م' : 'EGP',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  workerVM.totalEarnings.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '+${workerVM.completionRate}% ${isAr ? 'إنجاز' : 'Completion'}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(WorkerViewModel workerVM, bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.pending_actions_rounded,
              iconBg: const Color(0xFFFFF8E1),
              iconColor: const Color(0xFFF9A825),
              label: isAr ? 'طلبات معلقة' : 'Pending',
              value: workerVM.pendingOrders.toString(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_outline_rounded,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF4CAF50),
              label: isAr ? 'مكتملة' : 'Completed',
              value: workerVM.completedOrders.toString(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildStatCard(
              icon: Icons.star_rounded,
              iconBg: const Color(0xFFFFF8E1),
              iconColor: const Color(0xFFFFC107),
              label: isAr ? 'التقييم' : 'Rating',
              value: workerVM.rating.toStringAsFixed(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.cairo(fontSize: 10, color: textMuted), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isAr ? 'إجراءات سريعة' : 'Quick Actions', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.history_rounded,
                  iconBg: const Color(0xFFFFF3E0),
                  iconColor: const Color(0xFFFF9800),
                  label: isAr ? 'السجل' : 'History',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceRequestsPage())),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.account_balance_wallet_outlined,
                  iconBg: const Color(0xFFFCE4EC),
                  iconColor: const Color(0xFFE91E63),
                  label: isAr ? 'المحفظة' : 'Wallet',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage())),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.public_rounded,
                  iconBg: const Color(0xFFE8EAF6),
                  iconColor: const Color(0xFF5C6BC0),
                  label: isAr ? 'الملف العام' : 'Public',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerPublicProfilePage())),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.person_outline_rounded,
                  iconBg: const Color(0xFFE0F2F1),
                  iconColor: primaryColor,
                  label: isAr ? 'ملفي' : 'Profile',
                  onTap: () => setState(() => _currentNavIndex = 3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.cairo(fontSize: 11, color: textDark, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentJobs(WorkerViewModel workerVM, bool isAr) {
    final requests = workerVM.orders.where((o) => o.status != 'completed' && o.status != 'cancelled').toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceRequestsPage())),
                child: Text(isAr ? 'عرض الكل' : 'View All', style: GoogleFonts.cairo(fontSize: 13, color: primaryColor, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Text(isAr ? 'الوظائف الحالية' : 'Current Jobs', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
            ],
          ),
        ),
        if (requests.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text(isAr ? 'لا توجد وظائف حالية' : 'No current jobs', style: GoogleFonts.cairo()))
        else
          ...requests.take(3).map((r) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: _buildJobCard(
                  title: r.serviceTitle ?? (isAr ? 'خدمة' : 'Service'),
                  location: r.address ?? (isAr ? 'غير محدد' : 'Not specified'),
                  budget: '${r.price} ${isAr ? 'ج.م' : 'EGP'}',
                  statusLabel: _getStatusLabel(r.status, isAr),
                  statusColor: _getStatusColor(r.status),
                  statusBg: _getStatusColor(r.status).withOpacity(0.1),
                  isAr: isAr,
                ),
              )),
      ],
    );
  }

  String _getStatusLabel(String status, bool isAr) {
    switch (status) {
      case 'completed': return isAr ? 'مكتمل' : 'Completed';
      case 'in_progress': return isAr ? 'قيد التنفيذ' : 'In Progress';
      case 'accepted': return isAr ? 'تم القبول' : 'Accepted';
      default: return isAr ? 'قيد الانتظار' : 'Pending';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return const Color(0xFF4CAF50);
      case 'in_progress': return const Color(0xFFF9A825);
      case 'accepted': return const Color(0xFF006D5B);
      default: return const Color(0xFF8E8E93);
    }
  }

  Widget _buildJobCard({
    required String title,
    required String location,
    required String budget,
    required String statusLabel,
    required Color statusColor,
    required Color statusBg,
    required bool isAr,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(statusLabel, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ),
              const Spacer(),
              Text(title, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(location, style: GoogleFonts.cairo(fontSize: 12, color: textMuted)),
              const SizedBox(width: 6),
              const Icon(Icons.location_on_outlined, size: 16, color: textMuted),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(budget, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor)),
              const Spacer(),
              Text(isAr ? 'الميزانية' : 'Budget', style: GoogleFonts.cairo(fontSize: 12, color: textMuted)),
              const SizedBox(width: 6),
              const Icon(Icons.payments_outlined, size: 16, color: textMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isAr) {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (index) => setState(() => _currentNavIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey[400],
      showUnselectedLabels: true,
      selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.grid_view), label: isAr ? 'الرئيسية' : 'Home'),
        BottomNavigationBarItem(icon: const Icon(Icons.assignment_outlined), label: isAr ? 'الطلبات' : 'Requests'),
        BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline), label: isAr ? 'الرسائل' : 'Messages'),
        BottomNavigationBarItem(icon: const Icon(Icons.person), label: isAr ? 'حسابي' : 'Profile'),
      ],
    );
  }

  Widget _buildDrawer(bool isAr) {
    return Consumer<WorkerViewModel>(
      builder: (context, workerVM, _) {
        return Drawer(
          child: Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              children: [
                // ── Premium Header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: workerVM.avatarUrl.isNotEmpty ? NetworkImage(workerVM.avatarUrl) : null,
                          child: workerVM.avatarUrl.isEmpty ? const Icon(Icons.person, size: 40, color: primaryColor) : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        workerVM.name,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Drawer Items ──
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildDrawerItem(
                        icon: Icons.person_outline,
                        label: isAr ? 'الملف الشخصي' : 'Profile',
                        onTap: () { Navigator.pop(context); setState(() => _currentNavIndex = 3); },
                      ),
                      _buildDrawerItem(
                        icon: Icons.assignment_outlined,
                        label: isAr ? 'طلبات الخدمات' : 'Service Requests',
                        onTap: () { Navigator.pop(context); setState(() => _currentNavIndex = 1); },
                      ),
                      _buildDrawerItem(
                        icon: Icons.chat_bubble_outline,
                        label: isAr ? 'المحادثات' : 'Chats',
                        onTap: () { Navigator.pop(context); setState(() => _currentNavIndex = 2); },
                      ),
                      _buildDrawerItem(
                        icon: Icons.settings_outlined,
                        label: isAr ? 'الإعدادات' : 'Settings',
                        onTap: () { Navigator.pop(context); }, // Placeholder
                      ),
                      const Divider(),
                      _buildDrawerItem(
                        icon: Icons.help_outline,
                        label: isAr ? 'الدعم والمساعدة' : 'Support & Help',
                        onTap: () { Navigator.pop(context); }, // Placeholder
                      ),
                      const SizedBox(height: 20),
                      _buildDrawerItem(
                        icon: Icons.logout,
                        label: isAr ? 'تسجيل الخروج' : 'Logout',
                        color: Colors.redAccent,
                        onTap: () async {
                          await Provider.of<AuthViewModel>(context, listen: false).logout();
                          if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? textDark.withOpacity(0.7)),
      title: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color ?? textDark,
        ),
      ),
      onTap: onTap,
    );
  }
}
