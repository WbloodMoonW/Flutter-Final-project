import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/localization.dart';
import '../../viewmodels/client_viewmodel.dart';
import 'worker_profile_page.dart';
import 'map_picker_page.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final Color primaryTeal = const Color(0xFF006D5B);
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWorkers();
    });
  }

  Future<void> _fetchWorkers() async {
    final clientVM = Provider.of<ClientViewModel>(context, listen: false);
    await clientVM.fetchWorkers();
  }

  @override
  Widget build(BuildContext context) {
    final clientVM = Provider.of<ClientViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(AppLocalization.translate('app_name'), style: GoogleFonts.cairo(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: Directionality(
        textDirection: AppLocalization.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => clientVM.searchWorkers(value),
                        textAlign: AppLocalization.isArabic ? TextAlign.right : TextAlign.left,
                        decoration: InputDecoration(
                          hintText: AppLocalization.translate('search_provider_hint'),
                          hintStyle: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 14),
                          suffixIcon: Icon(Icons.search, color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () => _showFilterSheet(clientVM),
                      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchWorkers,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocalization.translate('available_providers'), style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text('${clientVM.filteredWorkers.length} ${AppLocalization.translate('results_count')}', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[500])),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (clientVM.isLoading && clientVM.workers.isEmpty)
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: const Center(child: CircularProgressIndicator(color: Color(0xFF006D5B))),
                      )
                    else if (clientVM.filteredWorkers.isEmpty)
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalization.isArabic ? 'لا يوجد مقدمي خدمة حالياً' : 'No providers found',
                                style: GoogleFonts.cairo(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...clientVM.filteredWorkers.map((worker) => _buildProviderCard(
                            id: worker.id,
                            name: worker.user.fullName,
                            role: worker.user.isVerified ? (AppLocalization.isArabic ? 'موثق' : 'Verified') : (AppLocalization.isArabic ? 'مزود خدمة' : 'Service Provider'),
                            rating: worker.ratingAverage,
                            price: '',
                            imageUrl: worker.user.profileImage,
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(ClientViewModel clientVM) {
    String? tempPostcode = clientVM.selectedPostcode;
    String? tempAddress = clientVM.selectedAddress;
    double? tempLat = clientVM.selectedLat;
    double? tempLng = clientVM.selectedLng;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalization.isArabic ? 'تصفية النتائج' : 'Filter Results', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (tempAddress != null)
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              tempAddress = null;
                              tempLat = null;
                              tempLng = null;
                            });
                          },
                          child: Text(AppLocalization.isArabic ? 'مسح' : 'Clear', style: GoogleFonts.cairo(color: Colors.red)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(AppLocalization.translate('categories'), style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: clientVM.categories.length + 1,
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final cat = isAll ? null : clientVM.categories[index - 1];
                        final label = isAll ? (AppLocalization.isArabic ? 'الكل' : 'All') : cat!.name;
                        
                        return GestureDetector(
                          onTap: () {
                            clientVM.fetchWorkers(
                              categoryId: cat?.id,
                              lat: tempLat,
                              lng: tempLng,
                              postcode: tempPostcode,
                              address: tempAddress,
                            );
                            Navigator.pop(context);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(child: Text(label, style: GoogleFonts.cairo(fontSize: 14))),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(AppLocalization.isArabic ? 'البحث في منطقة محددة' : 'Search in specific area', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPickerPage()));
                      if (result != null && result is Map) {
                        setSheetState(() {
                          tempAddress = result['address'];
                          tempPostcode = result['postcode'];
                          tempLat = result['lat'];
                          tempLng = result['lng'];
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: primaryTeal),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tempAddress ?? (AppLocalization.isArabic ? 'اضغط لتحديد الموقع' : 'Tap to select location'),
                              style: GoogleFonts.cairo(fontSize: 14, color: tempAddress == null ? Colors.grey : Colors.black),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (tempPostcode != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocalization.isArabic ? 'الرمز البريدي' : 'Postcode', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(tempPostcode!, style: GoogleFonts.cairo(color: primaryTeal, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        clientVM.fetchWorkers(
                          lat: tempLat,
                          lng: tempLng,
                          postcode: tempPostcode,
                          address: tempAddress,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: Text(AppLocalization.isArabic ? 'تطبيق الفلتر' : 'Apply Filter', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProviderCard({required String id, required String name, required String role, required double rating, required String price, String? imageUrl}) {
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
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
                      Row(children: [const Icon(Icons.star_rounded, color: Colors.orange, size: 18), const SizedBox(width: 4), Text(rating.toStringAsFixed(1), style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold))]),
                    ],
                  ),
                  Text(role, style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[500]), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(price, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTeal)),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WorkerProfilePage(workerId: id),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                        child: Text(AppLocalization.translate('book_now'), style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
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
              child: imageUrl == null || imageUrl.isEmpty ? Icon(Icons.person, color: Colors.grey[400], size: 40) : null,
            ),
          ],
        ),
      ),
    );
  }
}
