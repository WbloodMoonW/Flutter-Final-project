import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/worker_viewmodel.dart';
import '../../models/order_model.dart';
import '../../core/localization.dart';

class ServiceRequestsPage extends StatefulWidget {
  const ServiceRequestsPage({super.key});

  @override
  State<ServiceRequestsPage> createState() => _ServiceRequestsPageState();
}

class _ServiceRequestsPageState extends State<ServiceRequestsPage> {
  final Color primaryColor = const Color(0xFF006D5B);
  final Color textDark = const Color(0xFF1A1A2E);
  final Color textMuted = const Color(0xFF8E8E93);

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

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          isAr ? 'طلبات الخدمات' : 'Service Requests',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<WorkerViewModel>(
        builder: (context, workerVM, _) {
          final requests = workerVM.orders;

          if (workerVM.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (requests.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => workerVM.fetchData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 150,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_late_outlined,
                          size: 64,
                          color: textMuted.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isAr ? 'لا توجد طلبات حالياً' : 'No requests yet',
                          style: GoogleFonts.cairo(color: textMuted, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => workerVM.fetchData(),
            color: primaryColor,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final r = requests[index];
                return _buildRequestCard(r, isAr, workerVM);
              },
            ),
          );
        },
      ),
    );
  }

  // ── Request Card ──────────────────────────────────────────────────────────
  Widget _buildRequestCard(Order r, bool isAr, WorkerViewModel workerVM) {
    final date = r.scheduledFor ?? r.createdAt;
    final dateStr = '${date.day}/${date.month}/${date.year}  '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header: status badge + service title ───────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                _buildStatusBadge(r.status, isAr),
                const Spacer(),
                Flexible(
                  child: Text(
                    r.serviceTitle ?? (isAr ? 'خدمة' : 'Service'),
                    textAlign: TextAlign.end,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Customer name
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${r.customer?.firstName ?? (isAr ? 'عميل' : 'Customer')} ${r.customer?.lastName ?? ''}',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.person_outline,
                        size: 18, color: Color(0xFF006D5B)),
                  ],
                ),
                const SizedBox(height: 6),

                // Date / time
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      dateStr,
                      style: GoogleFonts.cairo(fontSize: 12, color: textMuted),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 6),

                // Location
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      r.address ?? (isAr ? 'غير محدد' : 'Not specified'),
                      style: GoogleFonts.cairo(fontSize: 12, color: textMuted),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // ── Price + action buttons ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Action buttons
                    Row(
                      children: [
                        if (r.status == 'pending') ...[
                          _buildActionButton(
                            label: isAr ? 'رفض' : 'Reject',
                            color: Colors.redAccent,
                            onTap: () async {
                              final ok = await workerVM.updateOrderStatus(r.id, 'cancelled');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(ok ? (isAr ? 'تم رفض الطلب' : 'Rejected') : (isAr ? 'فشل الرفض' : 'Failed')),
                                  backgroundColor: ok ? Colors.green : Colors.red,
                                ));
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            label: isAr ? 'قبول' : 'Accept',
                            color: primaryColor,
                            onTap: () async {
                              final ok = await workerVM.updateOrderStatus(r.id, 'accepted');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(ok ? (isAr ? 'تم قبول الطلب' : 'Accepted') : (isAr ? 'فشل القبول' : 'Failed')),
                                  backgroundColor: ok ? Colors.green : Colors.red,
                                ));
                              }
                            },
                          ),
                        ],

                        if (r.status == 'accepted')
                          _buildActionButton(
                            label: isAr ? 'بدء التنفيذ' : 'Start Work',
                            color: const Color(0xFFF9A825),
                            onTap: () async {
                              final ok = await workerVM.updateOrderStatus(r.id, 'in_progress');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(ok ? (isAr ? 'تم بدء التنفيذ' : 'Work started') : (isAr ? 'فشل التحديث' : 'Failed')),
                                  backgroundColor: ok ? Colors.green : Colors.red,
                                ));
                              }
                            },
                          ),

                        if (r.status == 'in_progress')
                          _buildActionButton(
                            label: isAr ? 'إتمام' : 'Complete',
                            color: const Color(0xFF4CAF50),
                            onTap: () async {
                              final ok = await workerVM.updateOrderStatus(r.id, 'completed');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(ok ? (isAr ? 'تم إتمام الطلب' : 'Completed!') : (isAr ? 'فشل التحديث' : 'Failed')),
                                  backgroundColor: ok ? Colors.green : Colors.red,
                                ));
                              }
                            },
                          ),
                      ],
                    ),

                    // Price
                    Text(
                      '${r.price} ${isAr ? 'ج.م' : 'EGP'}',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Status badge ──────────────────────────────────────────────────────────
  Widget _buildStatusBadge(String status, bool isAr) {
    Color color;
    Color bg;
    String label;

    switch (status) {
      case 'completed':
        color = const Color(0xFF4CAF50);
        bg = const Color(0xFFE8F5E9);
        label = isAr ? 'مكتمل' : 'Completed';
        break;
      case 'in_progress':
        color = const Color(0xFFF9A825);
        bg = const Color(0xFFFFF8E1);
        label = isAr ? 'قيد التنفيذ' : 'In Progress';
        break;
      case 'accepted':
        color = const Color(0xFF006D5B);
        bg = const Color(0xFFE0F2F1);
        label = isAr ? 'تم القبول' : 'Accepted';
        break;
      case 'cancelled':
      case 'rejected':
        color = Colors.redAccent;
        bg = const Color(0xFFFFEBEE);
        label = isAr ? 'ملغي' : 'Cancelled';
        break;
      case 'pending':
      default:
        color = const Color(0xFF5C6BC0);
        bg = const Color(0xFFE8EAF6);
        label = isAr ? 'طلب جديد' : 'New Request';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Action button ─────────────────────────────────────────────────────────
  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
