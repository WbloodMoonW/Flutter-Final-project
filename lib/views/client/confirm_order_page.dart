import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/localization.dart';
import '../../models/worker_model.dart';
import '../../models/service_model.dart';
import '../../models/coupon_model.dart';
import '../../viewmodels/client_viewmodel.dart';
import '../../services/api_service.dart';
import 'map_picker_page.dart';
import 'paymob_checkout_page.dart';

class ConfirmOrderPage extends StatefulWidget {
  final Worker worker;
  final WorkerService service;
  final DateTime? initialDate;

  const ConfirmOrderPage({
    super.key,
    required this.worker,
    required this.service,
    this.initialDate,
  });

  @override
  State<ConfirmOrderPage> createState() => _ConfirmOrderPageState();
}

class _ConfirmOrderPageState extends State<ConfirmOrderPage> {
  final Color primaryTeal = const Color(0xFF006D5B);
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  DateTime? _selectedDateTime;
  String _paymentMethod = 'cod';
  bool _isLoading = false;
  Coupon? _appliedCoupon;
  double _discountAmount = 0.0;
  bool _isValidatingCoupon = false;
  double? _selectedLat;
  double? _selectedLng;

  // Matches backend's resolveServicePrice — for range services we charge the
  // min (the upper bound is just a "may go up to" hint for the customer).
  double get _basePrice {
    if (widget.service.typeofService == 'range' && widget.service.priceRange != null) {
      final min = widget.service.priceRange!['min'];
      if (min != null && min > 0) return min;
    }
    return widget.service.price;
  }

  String _formatServicePrice() {
    final unit = AppLocalization.isArabic ? 'ج.م' : 'EGP';
    if (widget.service.typeofService == 'range' && widget.service.priceRange != null) {
      final min = widget.service.priceRange!['min'] ?? 0;
      final max = widget.service.priceRange!['max'] ?? 0;
      if (min > 0 || max > 0) {
        return '${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)} $unit';
      }
    }
    return '${widget.service.price.toStringAsFixed(0)} $unit';
  }

  @override
  void initState() {
    super.initState();
    // Force a default date if none provided to avoid null issues
    _selectedDateTime = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
    // Pre-populate with a default address so validation doesn't block the user
    _addressController.text = AppLocalization.isArabic ? 'القاهرة، مصر' : 'Cairo, Egypt';
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primaryTeal)),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primaryTeal)),
          child: child!,
        ),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _confirmOrder() async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalization.isArabic ? 'يرجى إدخال العنوان' : 'Please enter the address')),
      );
      return;
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalization.isArabic ? 'يرجى تحديد موعد الخدمة' : 'Please select service date')),
      );
      return;
    }

    final serviceId = widget.service.id;
    if (serviceId == null || serviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalization.isArabic ? 'يرجى تحديد الخدمة' : 'Please select a service')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final clientVM = Provider.of<ClientViewModel>(context, listen: false);

    debugPrint('>>> ORDER: workerId=${widget.worker.id}, serviceId=$serviceId, location=${_addressController.text}, scheduledFor=$_selectedDateTime');

    final order = await clientVM.createBooking(
      serviceId: serviceId,
      locationAddress: _addressController.text,
      scheduledFor: _selectedDateTime,
      couponCode: _appliedCoupon?.code,
      paymentMode: _paymentMethod == 'card' ? 'card' : 'cash_on_delivery',
    );

    if (order == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(clientVM.errorMessage ?? 'Failed to confirm order')),
        );
      }
      return;
    }

    // COD: order is live, worker has been notified — done.
    if (_paymentMethod != 'card') {
      setState(() => _isLoading = false);
      if (mounted) _showSuccessPopup();
      return;
    }

    // Card: pull the order id out of the response and start Paymob checkout.
    final orderId = (order['_id'] ?? order['id'] ?? '').toString();
    if (orderId.isEmpty) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.isArabic ? 'تعذّر بدء الدفع' : 'Could not start payment')),
        );
      }
      return;
    }

    try {
      final session = await clientVM.createPaymobCheckout(orderId);
      setState(() => _isLoading = false);
      if (!mounted) return;
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => PaymobCheckoutPage(
            paymentId: session['paymentId'] ?? '',
            checkoutUrl: session['checkoutUrl'] ?? '',
          ),
        ),
      );

      if (!mounted) return;
      if (result == 'completed') {
        _showSuccessPopup();
      } else if (result == 'failed') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.isArabic ? 'فشلت عملية الدفع' : 'Payment failed'), backgroundColor: Colors.red),
        );
      } else {
        // 'pending' (webhook hasn't landed yet) or 'cancelled' — the order
        // exists, customer can retry payment from the bookings tab.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.isArabic ? 'لم يكتمل الدفع — يمكنك إعادة المحاولة من تبويب الحجوزات' : 'Payment not completed — you can retry from the Bookings tab')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            Text(
              AppLocalization.isArabic ? 'تم تأكيد طلبك!' : 'Order Confirmed!',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalization.isArabic 
                ? 'تم إرسال طلبك للمحترف بنجاح. يمكنك متابعة الحالة من تبويب الحجوزات.' 
                : 'Your order has been sent to the professional. Track status in the Bookings tab.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to profile
                  Navigator.pop(context); // Go back to services/home
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: Text(AppLocalization.isArabic ? 'حسناً' : 'Great', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text(
          AppLocalization.isArabic ? 'تأكيد طلبك' : 'Confirm your order',
          style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceSummary(),
            const SizedBox(height: 24),
            _buildAppointmentDetails(),
            const SizedBox(height: 24),
            _buildNotesSection(),
            const SizedBox(height: 24),
            _buildPaymentMethod(),
            const SizedBox(height: 24),
            _buildCouponSection(),
            const SizedBox(height: 24),
            _buildPriceBreakdown(),
            const SizedBox(height: 30),
            _buildConfirmButton(),
            const SizedBox(height: 20),
            _buildFooterText(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.handyman_rounded, color: Color(0xFF006D5B), size: 35),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.service.name, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(widget.worker.user.fullName, style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppLocalization.isArabic ? 'السعر' : 'Price', style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 11)),
              Text(_formatServicePrice(), style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentDetails() {
    return _buildSectionContainer(
      icon: Icons.calendar_today_rounded,
      title: AppLocalization.isArabic ? 'تفاصيل الموعد' : 'Appointment details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalization.isArabic ? 'تاريخ الخدمة *' : 'Service date *', style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[700])),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDateTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Text(
                    _selectedDateTime != null 
                      ? '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year}  ${TimeOfDay.fromDateTime(_selectedDateTime!).format(context)}'
                      : 'mm/dd/yyyy --:-- --',
                    style: GoogleFonts.cairo(color: _selectedDateTime != null ? Colors.black : Colors.grey[500]),
                  ),
                  const Spacer(),
                  Icon(Icons.calendar_month, color: Colors.grey[600], size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(AppLocalization.isArabic ? 'عنوان الخدمة *' : 'Service address *', style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[700])),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: AppLocalization.isArabic ? 'مثال: المعادي، شارع 9، عمارة 12، الدور 3' : 'Example: Maadi, Street 9, Building 12, 3rd floor',
              hintStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[400]),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          _buildMapSelector(),
        ],
      ),
    );
  }

  Widget _buildMapSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Color(0xFF006D5B), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalization.isArabic ? 'تحديد الموقع من البحث' : 'Set location from search',
              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: _showLocationPicker,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              AppLocalization.isArabic ? 'بحث عن عنوان' : 'Search address',
              style: GoogleFonts.cairo(fontSize: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapPickerPage(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _addressController.text = result['address'] as String? ?? _addressController.text;
        _selectedLat = (result['lat'] as num?)?.toDouble();
        _selectedLng = (result['lng'] as num?)?.toDouble();
      });
      // Confirm to user that location was set
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.isArabic ? 'تم تحديد الموقع بنجاح ✓' : 'Location set successfully ✓'),
          backgroundColor: const Color(0xFF006D5B),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildNotesSection() {
    return _buildSectionContainer(
      icon: Icons.note_alt_outlined,
      title: AppLocalization.isArabic ? 'ملاحظات للمحترف (اختياري)' : 'Notes for the worker (optional)',
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: AppLocalization.isArabic ? 'أي تفاصيل إضافية تساعد المحترف - مقاسات، أدوات مطلوبة، تعليمات الدخول...' : 'Any extra detail that will help the worker — sizes, tools needed, access instructions...',
          hintStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[400]),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return _buildSectionContainer(
      icon: Icons.payment_rounded,
      title: AppLocalization.isArabic ? 'طريقة الدفع' : 'Payment method',
      child: Column(
        children: [
          _buildPaymentOption(
            id: 'cod',
            title: AppLocalization.isArabic ? 'دفع عند الاستلام' : 'Cash on delivery',
            subtitle: AppLocalization.isArabic ? 'ادفع للمحترف نقداً بعد الانتهاء من الخدمة.' : 'Pay the worker in cash after the service is done.',
            icon: Icons.payments_outlined,
            selected: _paymentMethod == 'cod',
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            id: 'card',
            title: AppLocalization.isArabic ? 'دفع بالبطاقة (Visa / Mastercard)' : 'Card payment (Visa / Mastercard)',
            subtitle: AppLocalization.isArabic ? 'دفع آمن عبر Paymob. سيتم تحويلك لإتمام الدفع.' : 'Secure online payment via Paymob. You will be redirected to complete the payment.',
            icon: Icons.credit_card_rounded,
            selected: _paymentMethod == 'card',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({required String id, required String title, required String subtitle, required IconData icon, bool selected = false, bool isComingSoon = false}) {
    return GestureDetector(
      onTap: isComingSoon ? null : () => setState(() => _paymentMethod = id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? primaryTeal.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: selected ? primaryTeal : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? primaryTeal : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Icon(icon, color: Colors.grey[600], size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (isComingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text(AppLocalization.isArabic ? 'قريباً' : 'Coming soon', style: GoogleFonts.cairo(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isValidatingCoupon = true);
    final clientVM = Provider.of<ClientViewModel>(context, listen: false);
    final coupon = await clientVM.validateCoupon(
      code,
      amount: widget.service.price,
      categoryId: widget.service.categoryId,
    );
    setState(() => _isValidatingCoupon = false);

    if (coupon != null && coupon.isActive) {
      setState(() {
        _appliedCoupon = coupon;
        if (coupon.type == 'fixed') {
          _discountAmount = coupon.value;
        } else {
          _discountAmount = (_basePrice * coupon.value) / 100;
        }
        if (_discountAmount > _basePrice) {
          _discountAmount = _basePrice;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              coupon.type == 'fixed'
                ? (AppLocalization.isArabic ? 'تم تطبيق خصم ${coupon.value} ج.م!' : 'Discount of ${coupon.value} EGP applied!')
                : (AppLocalization.isArabic ? 'تم تطبيق خصم ${coupon.value}%!' : 'Discount of ${coupon.value}% applied!'),
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: primaryTeal,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.isArabic ? 'كود غير صالح' : 'Invalid coupon code',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCouponSection() {
    return _buildSectionContainer(
      icon: Icons.local_offer_outlined,
      title: AppLocalization.isArabic ? 'كود الخصم (اختياري)' : 'Coupon code (optional)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  decoration: InputDecoration(
                    hintText: AppLocalization.isArabic ? 'أدخل كود الخصم' : 'Enter coupon code',
                    hintStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isValidatingCoupon ? null : _applyCoupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _appliedCoupon != null ? primaryTeal : const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  elevation: 0,
                ),
                child: _isValidatingCoupon 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      AppLocalization.isArabic ? 'تطبيق' : 'Apply',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
              ),
            ],
          ),
          if (_appliedCoupon != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                _appliedCoupon!.type == 'fixed'
                  ? (AppLocalization.isArabic ? 'تم تفعيل خصم ${_appliedCoupon!.value} ج.م' : '${_appliedCoupon!.value} EGP discount applied!')
                  : (AppLocalization.isArabic ? 'تم تفعيل خصم ${_appliedCoupon!.value}%' : '${_appliedCoupon!.value}% discount applied!'),
                style: GoogleFonts.cairo(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    final double total = (_basePrice - _discountAmount).clamp(0, double.infinity).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalization.isArabic ? 'سعر الخدمة' : 'Service price', style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 14)),
              Text(_formatServicePrice(), style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          if (widget.service.typeofService == 'range') ...[
            const SizedBox(height: 4),
            Align(
              alignment: AppLocalization.isArabic ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                AppLocalization.isArabic
                  ? 'يبدأ الإجمالي من الحد الأدنى وقد يزيد حسب الاتفاق'
                  : 'Total starts at the minimum and may rise per agreement',
                style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 11),
              ),
            ),
          ],
          if (_discountAmount > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalization.isArabic ? 'الخصم' : 'Discount', style: GoogleFonts.cairo(color: Colors.red[400], fontSize: 14)),
                Text('-${_discountAmount.toStringAsFixed(0)} EGP', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: Colors.red[400], fontSize: 14)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalization.isArabic ? 'الإجمالي' : 'Total', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${total.toStringAsFixed(0)} EGP', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _confirmOrder,
        style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  AppLocalization.isArabic ? 'تأكيد الطلب' : 'Confirm order',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildFooterText() {
    return Text(
      AppLocalization.isArabic 
        ? 'بالضغط على "تأكيد الطلب" سنقوم بتوجيه تفاصيلك للمحترف وتنبيهه فوراً. سيقوم المحترف بقبول أو رفض الطلب من لوحة التحكم الخاصة به.'
        : 'By tapping "Confirm order" we\'ll forward your details to the worker and notify them immediately. The worker will accept or reject the order from their dashboard.',
      textAlign: TextAlign.center,
      style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 11),
    );
  }

  Widget _buildSectionContainer({required IconData icon, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryTeal, size: 20),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Container(width: 4, height: 20, decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(2))),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

