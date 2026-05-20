import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/localization.dart';
import '../../viewmodels/client_viewmodel.dart';
import '../../models/order_model.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final Color primaryTeal = const Color(0xFF006D5B);
  int _activeSubTab = 0; // 0 for Pending Bookings, 1 for Booking History

  @override
  void initState() {
    super.initState();
    debugPrint(">>> BookingsPage initState called");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(">>> BookingsPage post-frame callback running fetchMyOrders");
      Provider.of<ClientViewModel>(context, listen: false).fetchMyOrders();
    });
  }

  Widget _buildTabBar() {
    final isAr = AppLocalization.isArabic;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _activeSubTab = 0);
                Provider.of<ClientViewModel>(context, listen: false).fetchMyOrders();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeSubTab == 0 ? primaryTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    isAr ? 'حجوزات معلقة' : 'Pending Bookings',
                    style: GoogleFonts.cairo(
                      color: _activeSubTab == 0 ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _activeSubTab = 1);
                Provider.of<ClientViewModel>(context, listen: false).fetchMyOrders();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeSubTab == 1 ? primaryTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    isAr ? 'سجل الحجوزات' : 'Booking History',
                    style: GoogleFonts.cairo(
                      color: _activeSubTab == 1 ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientVM = Provider.of<ClientViewModel>(context);
    final filteredOrders = clientVM.myOrders.where((order) {
  final status = order.status.toLowerCase().trim(); // <-- add .trim()
  
  // Temporary debug
  debugPrint('Order status: "$status", tab: $_activeSubTab');
  
  if (_activeSubTab == 1) {
    return status == 'completed' || status == 'rejected' || status == 'cancelled';
  } else {
    return status == 'pending' || status == 'accepted' || status == 'in_progress';
  }
}).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppLocalization.isArabic ? 'حجوزاتي' : 'My Bookings',
          style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: clientVM.isLoading && clientVM.myOrders.isEmpty
          ? Center(child: CircularProgressIndicator(color: primaryTeal))
          : RefreshIndicator(
              onRefresh: () => clientVM.fetchMyOrders(),
              color: primaryTeal,
              child: Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: filteredOrders.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              return _buildBookingCard(order);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    final isAr = AppLocalization.isArabic;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 20),
              Text(
                _activeSubTab == 0
                    ? (isAr ? 'لا توجد حجوزات معلقة حالياً' : 'No pending bookings currently')
                    : (isAr ? 'سجل الحجوزات فارغ' : 'Booking history is empty'),
                style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Order order) {
    Color statusColor;
    String statusText;

    switch (order.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusText = AppLocalization.isArabic ? 'مكتمل' : 'Completed';
        break;
      case 'accepted':
        statusColor = Colors.teal;
        statusText = AppLocalization.isArabic ? 'مقبول' : 'Accepted';
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusText = AppLocalization.isArabic ? 'قيد التنفيذ' : 'In Progress';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = AppLocalization.isArabic ? 'مرفوض' : 'Rejected';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = AppLocalization.isArabic ? 'ملغي' : 'Cancelled';
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusText = AppLocalization.isArabic ? 'قيد الانتظار' : 'Pending';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.serviceTitle ?? (AppLocalization.isArabic ? 'خدمة' : 'Service'),
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.cairo(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                order.scheduledFor != null 
                  ? '${order.scheduledFor!.day}/${order.scheduledFor!.month}/${order.scheduledFor!.year}' 
                  : (AppLocalization.isArabic ? 'غير محدد' : 'Not specified'),
                style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(width: 20),
              Icon(Icons.access_time_rounded, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                order.scheduledFor != null 
                  ? '${order.scheduledFor!.hour}:${order.scheduledFor!.minute.toString().padLeft(2, '0')}' 
                  : '--:--',
                style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalization.isArabic ? 'السعر المتوقع' : 'Expected Price',
                style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 14),
              ),
              Text(
                '${order.price.toStringAsFixed(0)} ${AppLocalization.isArabic ? "ج.م" : "EGP"}',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 16),
              ),
            ],
          ),
          if (order.status.toLowerCase() == 'completed' && 
              !order.hasReviewed &&
              !Provider.of<ClientViewModel>(context, listen: false).reviewedOrderIds.contains(order.id)) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showReviewDialog(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalization.isArabic ? 'أترك تقييم' : 'Leave Review',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReviewDialog(Order order) {
    final isAr = AppLocalization.isArabic;
    int rating = 5;
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isAr ? 'تقييم الخدمة' : 'Rate Service',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: isAr ? 'اكتب رأيك هنا (اختياري)' : 'Write your review here (optional)',
                      hintStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(isAr ? 'إلغاء' : 'Cancel', style: GoogleFonts.cairo(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await Provider.of<ClientViewModel>(this.context, listen: false).submitReview(
                      order.id,
                      rating,
                      commentController.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                        content: Text(
                          success 
                            ? (isAr ? 'تم إرسال التقييم بنجاح' : 'Review submitted successfully')
                            : (isAr ? 'فشل إرسال التقييم' : 'Failed to submit review'),
                          style: GoogleFonts.cairo(),
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isAr ? 'إرسال' : 'Submit', style: GoogleFonts.cairo(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
