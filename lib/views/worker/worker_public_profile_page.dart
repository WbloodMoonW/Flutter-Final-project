import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/worker_viewmodel.dart';
import '../../core/localization.dart';
import '../../models/portfolio_item.dart';
import '../../models/pricing_package.dart';

class WorkerPublicProfilePage extends StatefulWidget {
  const WorkerPublicProfilePage({super.key});

  @override
  State<WorkerPublicProfilePage> createState() => _WorkerPublicProfilePageState();
}

class _WorkerPublicProfilePageState extends State<WorkerPublicProfilePage> {
  static const Color primaryColor = Color(0xFF2D6A4F);
  static const Color bgColor = Color(0xFFF0F4F3);
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF8E8E93);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerViewModel>(context, listen: false).fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalization.isArabic;
    return Consumer<WorkerViewModel>(
      builder: (context, workerVM, _) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: bgColor,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroHeader(workerVM, isAr),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBookingCard(workerVM, isAr),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildAboutSection(workerVM, isAr),
                            const SizedBox(height: 16),
                            if (workerVM.pricingPackages.isNotEmpty) ...[
                              _buildPricingSection(workerVM, isAr),
                              const SizedBox(height: 16),
                            ],
                            if (workerVM.portfolio.isNotEmpty) ...[
                              _buildPortfolioSection(workerVM, isAr),
                              const SizedBox(height: 16),
                            ],
                            _buildReviewsSection(workerVM, isAr),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(WorkerViewModel workerVM, bool isAr) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E40), Color(0xFF2D6A4F)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(workerVM.name, style: GoogleFonts.cairo(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CAF50))),
                    ],
                  ),
                  Text('"${workerVM.professionalTitle}"', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13)),
                ],
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 35,
                backgroundColor: const Color(0xFF3D8B6E),
                backgroundImage: workerVM.avatarUrl.isNotEmpty ? NetworkImage(workerVM.avatarUrl) : null,
                child: workerVM.avatarUrl.isEmpty ? const Icon(Icons.person_rounded, color: Colors.white, size: 38) : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildMetaChip(Icons.star_rounded, '${workerVM.rating} (${workerVM.reviewCount} ${isAr ? 'تقييم' : 'reviews'})', color: const Color(0xFFFFC107)),
              const SizedBox(width: 12),
              if (workerVM.location.isNotEmpty) _buildMetaChip(Icons.location_on_outlined, workerVM.location),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Text(text, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        Icon(icon, size: 14, color: color ?? Colors.white70),
      ],
    );
  }

  Widget _buildBookingCard(WorkerViewModel workerVM, bool isAr) {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(isAr ? 'السعر المبدئي' : 'Starting Price', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 11, color: textMuted)),
                const SizedBox(height: 4),
                Text(
                  workerVM.pricingPackages.isNotEmpty ? '${workerVM.pricingPackages.first.price} ${isAr ? 'ج.م' : 'EGP'}' : (isAr ? 'تواصل' : 'Contact'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(isAr ? 'احجز الآن' : 'Book Now', style: GoogleFonts.cairo()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(WorkerViewModel workerVM, bool isAr) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildSectionHeader(Icons.person_outline_rounded, isAr ? 'نبذة عني' : 'About Me'),
          const SizedBox(height: 10),
          Text(workerVM.bio, textAlign: TextAlign.right, style: GoogleFonts.cairo(color: textMuted, fontSize: 13, height: 1.6)),
          const SizedBox(height: 16),
          _buildSkillsWrap(workerVM.skills),
        ],
      ),
    );
  }

  Widget _buildSkillsWrap(List<String> skills) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: skills.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFE8F0EE), borderRadius: BorderRadius.circular(20)),
        child: Text(s, style: GoogleFonts.cairo(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w600)),
      )).toList(),
    );
  }

  Widget _buildPricingSection(WorkerViewModel workerVM, bool isAr) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildSectionHeader(Icons.local_offer_outlined, isAr ? 'باقات الأسعار' : 'Pricing Packages'),
          const SizedBox(height: 12),
          Column(children: workerVM.pricingPackages.map((pkg) => ListTile(title: Text(pkg.title, style: GoogleFonts.cairo()), subtitle: Text('${pkg.price} ${isAr ? 'ج.م' : 'EGP'}', style: GoogleFonts.cairo()))).toList()),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection(WorkerViewModel workerVM, bool isAr) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildSectionHeader(Icons.photo_library_outlined, isAr ? 'معرض الأعمال' : 'Portfolio'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.2),
            itemCount: workerVM.portfolio.length,
            itemBuilder: (ctx, i) => Container(decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(WorkerViewModel workerVM, bool isAr) {
    return _buildCard(child: Center(child: Text(isAr ? 'التقييمات قريباً' : 'Reviews coming soon', style: GoogleFonts.cairo(color: textMuted))));
  }

  Widget _buildCard({required Widget child}) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]), child: child);
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(title, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: textDark)),
      const SizedBox(width: 8),
      Icon(icon, size: 20, color: primaryColor),
    ]);
  }
}
