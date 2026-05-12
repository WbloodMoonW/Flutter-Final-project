import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization.dart';
import '../../viewmodels/client_viewmodel.dart';

// Paymob checkout runs in the device's external browser (works on every
// platform without a native WebView plugin). While the user is paying we
// poll the backend for the authoritative status — webhook updates it the
// moment Paymob confirms the transaction.
class PaymobCheckoutPage extends StatefulWidget {
  final String paymentId;
  final String checkoutUrl;

  const PaymobCheckoutPage({
    super.key,
    required this.paymentId,
    required this.checkoutUrl,
  });

  @override
  State<PaymobCheckoutPage> createState() => _PaymobCheckoutPageState();
}

class _PaymobCheckoutPageState extends State<PaymobCheckoutPage> {
  static const Color _teal = Color(0xFF006D5B);

  Timer? _pollTimer;
  String _status = 'pending';
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openCheckout());
    // Poll every 3s. Webhook lands within seconds in normal conditions.
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  Future<void> _openCheckout() async {
    if (_opened) return;
    _opened = true;
    final uri = Uri.tryParse(widget.checkoutUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    final vm = Provider.of<ClientViewModel>(context, listen: false);
    final status = await vm.getPaymentStatus(widget.paymentId);
    if (!mounted) return;
    if (status != _status) setState(() => _status = status);
    if (status == 'completed' || status == 'failed') {
      _pollTimer?.cancel();
      Navigator.of(context).pop(status);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = AppLocalization.isArabic;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: Text(
          ar ? 'الدفع بالبطاقة' : 'Card payment',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.credit_card_rounded, size: 80, color: _teal),
            const SizedBox(height: 24),
            Text(
              ar ? 'تم فتح صفحة الدفع في المتصفح' : 'Checkout opened in your browser',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              ar
                  ? 'أكمل عملية الدفع في المتصفح ثم عُد إلى التطبيق. سنحدّث الحالة تلقائياً.'
                  : 'Complete the payment in your browser, then return here. We will update the status automatically.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
                ),
                const SizedBox(width: 12),
                Text(
                  ar ? 'في انتظار تأكيد الدفع...' : 'Waiting for payment confirmation...',
                  style: GoogleFonts.cairo(color: Colors.grey[700]),
                ),
              ],
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _openCheckout.call,
              icon: const Icon(Icons.open_in_new),
              label: Text(
                ar ? 'إعادة فتح صفحة الدفع' : 'Reopen checkout page',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _teal,
                side: const BorderSide(color: _teal),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancelled'),
              child: Text(
                ar ? 'إلغاء والعودة لاحقاً' : 'Cancel and finish later',
                style: GoogleFonts.cairo(color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
