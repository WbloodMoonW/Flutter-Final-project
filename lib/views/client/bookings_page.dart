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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientViewModel>(context, listen: false).fetchMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientVM = Provider.of<ClientViewModel>(context);

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
              child: clientVM.myOrders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: clientVM.myOrders.length,
                      itemBuilder: (context, index) {
                        final order = clientVM.myOrders[index];
                        return _buildBookingCard(order);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            AppLocalization.isArabic ? 'لا توجد حجوزات حالياً' : 'No bookings yet',
            style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Order order) {
    Color statusColor;
    String statusText;

    switch (order.status.toLowerCase()) {
      case 'accepted':
      case 'completed':
        statusColor = Colors.green;
        statusText = AppLocalization.isArabic ? 'مقبول' : 'Accepted';
        break;
      case 'rejected':
      case 'cancelled':
        statusColor = Colors.red;
        statusText = AppLocalization.isArabic ? 'مرفوض' : 'Rejected';
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
        ],
      ),
    );
  }
}
