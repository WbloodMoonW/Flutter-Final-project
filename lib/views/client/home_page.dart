import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/localization.dart';
import '../../viewmodels/client_viewmodel.dart';
import 'worker_profile_page.dart';
import 'main_wrapper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryTeal = const Color(0xFF006D5B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final clientVM = Provider.of<ClientViewModel>(context, listen: false);
    await clientVM.fetchCategories();
    await clientVM.fetchWorkers();
  }

  @override
  Widget build(BuildContext context) {
    final clientVM = Provider.of<ClientViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          AppLocalization.translate('app_name'),
          style: GoogleFonts.cairo(
            color: primaryTeal,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Directionality(
        textDirection: AppLocalization.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: clientVM.isLoading && clientVM.categories.isEmpty
            ? Center(child: CircularProgressIndicator(color: primaryTeal))
            : RefreshIndicator(
                onRefresh: _fetchData,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 30),
                      _buildCategoriesSection(clientVM),
                      const SizedBox(height: 30),
                      _buildFeaturedSection(clientVM),
                      const SizedBox(height: 16),
                      _buildOfferCard(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: primaryTeal,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalization.isArabic ? 'ابحث عن أفضل\nالمحترفين في مصر' : 'Search for the best\nprofessionals in Egypt',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalization.translate('tagline'),
                style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 150, left: 24, right: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TextField(
              textAlign: AppLocalization.isArabic ? TextAlign.right : TextAlign.left,
              decoration: InputDecoration(
                hintText: AppLocalization.translate('search_hint'),
                hintStyle: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      elevation: 0,
                    ),
                    child: Text(
                      AppLocalization.translate('search_btn'),
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(ClientViewModel clientVM) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalization.translate('categories'),
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              GestureDetector(
                onTap: () {
                  // Find the MainWrapperState and change the index
                  final mainWrapper = context.findAncestorStateOfType<MainWrapperState>();
                  if (mainWrapper != null) {
                    mainWrapper.updateIndex(1); // 1 is the ServicesPage tab
                  }
                },
                child: Text(
                  AppLocalization.translate('view_all'),
                  style: GoogleFonts.cairo(fontSize: 14, color: primaryTeal, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: clientVM.categories.length,
            itemBuilder: (context, index) {
              final cat = clientVM.categories[index];
              return _buildCategoryItem(
                cat.name,
                Icons.home_repair_service,
                imageUrl: cat.icon,
                onTap: () async {
                  await clientVM.fetchWorkers(categoryId: cat.id);
                  if (mounted) {
                    final mainWrapper = context.findAncestorStateOfType<MainWrapperState>();
                    if (mainWrapper != null) {
                      mainWrapper.updateIndex(1); // Switch to Services tab
                    }
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSection(ClientViewModel clientVM) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            AppLocalization.translate('featured_pros'),
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: clientVM.workers.length > 3 ? 3 : clientVM.workers.length,
          itemBuilder: (context, index) {
            final worker = clientVM.workers[index];
            return _buildProfessionalCard(
              worker.id,
              worker.user.fullName,
              worker.user.isVerified ? (AppLocalization.isArabic ? 'موثق' : 'Verified') : (AppLocalization.isArabic ? 'جديد' : 'New'),
              worker.ratingAverage,
              imageUrl: worker.user.profileImage,
            );
          },
        ),
      ],
    );
  }

  Widget _buildOfferCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(30)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalization.isArabic ? 'عرض خاص' : 'Special Offer', style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(AppLocalization.isArabic ? 'خصم 20% على أول خدمة لك' : '20% OFF your first service', style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF86EFAC), foregroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 24), elevation: 0),
                    child: Text(AppLocalization.translate('book_now'), style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.stars_rounded, color: Colors.white, size: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String label, IconData icon, {String? imageUrl, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                image: imageUrl != null && imageUrl.isNotEmpty 
                  ? DecorationImage(
                      image: imageUrl.startsWith('data:image') 
                        ? MemoryImage(base64Decode(imageUrl.split(',').last)) 
                        : (imageUrl.startsWith('http') 
                            ? NetworkImage(imageUrl) 
                            : NetworkImage('https://angezny.onrender.com$imageUrl')) as ImageProvider, 
                      fit: BoxFit.cover) 
                  : null,
              ),
              child: imageUrl == null || imageUrl.isEmpty ? Icon(icon, color: primaryTeal, size: 28) : null,
            ),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalCard(String id, String name, String role, double rating, {String? imageUrl}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkerProfilePage(workerId: id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(name, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                      Row(children: [const Icon(Icons.star_rounded, color: Colors.orange, size: 16), const SizedBox(width: 4), Text(rating.toStringAsFixed(1), style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold))]),
                    ],
                  ),
                  Text(role, style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[500]), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(AppLocalization.isArabic ? 'متوفر الآن' : 'Available Now', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                      const Spacer(),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)), child: Text(AppLocalization.isArabic ? 'رائد' : 'Top Rated', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600]))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                image: imageUrl != null && imageUrl.isNotEmpty 
                  ? DecorationImage(
                      image: imageUrl.startsWith('data:image') 
                        ? MemoryImage(base64Decode(imageUrl.split(',').last)) 
                        : (imageUrl.startsWith('http') 
                            ? NetworkImage(imageUrl) 
                            : NetworkImage('https://angezny.onrender.com$imageUrl')) as ImageProvider, 
                      fit: BoxFit.cover) 
                  : null,
              ),
              child: imageUrl == null || imageUrl.isEmpty ? Icon(Icons.person, color: Colors.grey[400], size: 30) : null,
            ),
          ],
        ),
      ),
    );
  }
}
