import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/localization.dart';
import '../../models/worker_model.dart';
import '../../models/working_hours.dart';
import '../../viewmodels/client_viewmodel.dart';
import 'chat_page.dart';
import 'confirm_order_page.dart';

class WorkerProfilePage extends StatefulWidget {
  final String workerId;
  const WorkerProfilePage({super.key, required this.workerId});

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  final Color primaryTeal = const Color(0xFF006D5B);
  Worker? worker;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWorkerDetails();
    });
  }

  Future<void> _fetchWorkerDetails() async {
    final clientVM = Provider.of<ClientViewModel>(context, listen: false);
    final data = await clientVM.getWorkerById(widget.workerId);
    if (mounted) {
      setState(() {
        worker = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryTeal))
          : worker == null
              ? const Center(child: Text('Worker not found'))
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoSection(),
                            const SizedBox(height: 30),
                            _buildBioSection(),
                            const SizedBox(height: 30),
                            _buildServicesSection(),
                            const SizedBox(height: 30),
                            _buildSkillsSection(),
                            const SizedBox(height: 30),
                            _buildWorkingHoursSection(),
                            const SizedBox(height: 30),
                            _buildStatsSection(),
                            const SizedBox(height: 40),
                            _buildContactButton(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSliverAppBar() {
    final user = worker!.user;
    final String name = user.fullName;
    final String? profileImage = user.profileImage;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: primaryTeal,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (profileImage != null && profileImage.isNotEmpty)
              Image(
                image: profileImage.startsWith('data:image') 
                  ? MemoryImage(base64Decode(profileImage.split(',').last)) 
                  : (profileImage.startsWith('http') 
                      ? NetworkImage(profileImage) 
                      : NetworkImage('https://angezny.onrender.com$profileImage')) as ImageProvider,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: primaryTeal.withOpacity(0.1),
                  child: Icon(Icons.person, size: 100, color: primaryTeal),
                ),
              )
            else
              Container(
                color: primaryTeal.withOpacity(0.1),
                child: Icon(Icons.person, size: 100, color: primaryTeal),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
        title: Text(
          name,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        centerTitle: false,
      ),
    );
  }

  Widget _buildInfoSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                worker!.title ?? (AppLocalization.isArabic ? 'محترف' : 'Professional'),
                style: GoogleFonts.cairo(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${worker!.ratingAverage}',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    ' (${worker!.totalReviews} ${AppLocalization.isArabic ? 'تقييم' : 'reviews'})',
                    style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            AppLocalization.isArabic ? 'متوفر' : 'Available',
            style: GoogleFonts.cairo(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalization.isArabic ? 'عن المحترف' : 'About Professional',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Text(
          worker!.bio ?? (AppLocalization.isArabic ? 'لا يوجد وصف متاح حالياً.' : 'No description available.'),
          style: GoogleFonts.cairo(color: Colors.grey[700], height: 1.6),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    final services = worker!.services.where((s) => s.isActive).toList();
    if (services.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalization.isArabic ? 'الخدمات المتوفرة' : 'Available Services',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return _buildServiceCard(service);
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(dynamic service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  service.name,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Text(
                '${service.price.toStringAsFixed(0)} ${AppLocalization.isArabic ? "ج.م" : "EGP"}',
                style: GoogleFonts.cairo(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            service.description,
            style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleBooking(service.id, service.name),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                AppLocalization.translate('book_now'),
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBooking(String? serviceId, String serviceName) {
    final service = worker!.services.firstWhere((s) => s.id == serviceId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmOrderPage(
          worker: worker!,
          service: service,
        ),
      ),
    );
  }

  Widget _buildSkillsSection() {
    final List<String> skills = worker!.skills;
    if (skills.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalization.isArabic ? 'المهارات' : 'Skills',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                skill,
                style: GoogleFonts.cairo(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWorkingHoursSection() {
    final Map<String, WorkingHoursEntry?> hours = worker!.workingHours;
    final entries = hours.entries.where((e) => e.value != null).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalization.isArabic ? 'ساعات العمل' : 'Working Hours',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: entries.map((e) => _buildWorkingHourRow(e.key, e.value!)).toList(),
          ),
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay t) => "${t.hour}:${t.minute.toString().padLeft(2, '0')}";

  Widget _buildWorkingHourRow(String day, WorkingHoursEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          Text(
            '${_formatTime(entry.from)} - ${_formatTime(entry.to)}',
            style: GoogleFonts.cairo(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          AppLocalization.isArabic ? 'الطلبات' : 'Orders',
          '${worker!.totalOrders}',
          Icons.shopping_bag_outlined,
        ),
        _buildStatItem(
          AppLocalization.isArabic ? 'التقييم' : 'Rating',
          worker!.ratingAverage.toStringAsFixed(1),
          Icons.star_rounded,
        ),
        _buildStatItem(
          AppLocalization.isArabic ? 'المنطقة' : 'Area',
          worker!.location ?? (AppLocalization.isArabic ? 'القاهرة' : 'Cairo'),
          Icons.location_on_outlined,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryTeal, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }

  Widget _buildContactButton() {
    final String name = worker!.user.fullName;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      receiverId: worker!.user.id,
                      receiverName: name.isNotEmpty ? name : (AppLocalization.isArabic ? 'محترف' : 'Professional'),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: Text(
                AppLocalization.isArabic ? 'تحدث مع المحترف' : 'Chat with Professional',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

