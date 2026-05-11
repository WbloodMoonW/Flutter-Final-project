import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/localization.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  static const Color primary = Color(0xFF006D5B);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF8E8E93);

  bool _loading = true;
  Map<String, dynamic> _wallet = {};
  List<dynamic> _transactions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiService.getWorkerWallet();
      if (resp != null) {
        setState(() {
          _wallet = Map<String, dynamic>.from(resp['wallet'] ?? {});
          _transactions = List<dynamic>.from(resp['transactions'] ?? []);
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalization.isArabic;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(isAr ? 'المحفظة' : 'Wallet', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: textDark)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!, style: GoogleFonts.cairo(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _fetch, child: Text(isAr ? 'إعادة المحاولة' : 'Retry', style: GoogleFonts.cairo())),
                ]))
              : RefreshIndicator(
                  onRefresh: _fetch,
                  color: primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildBalanceCard(isAr),
                        const SizedBox(height: 20),
                        _buildStatsRow(isAr),
                        const SizedBox(height: 24),
                        _buildTransactionsList(isAr),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBalanceCard(bool isAr) {
    final balance = (_wallet['balance'] ?? 0).toDouble();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF006D5B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(isAr ? 'الرصيد الحالي' : 'Current Balance', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${balance.toStringAsFixed(2)} ${isAr ? 'ج.م' : 'EGP'}',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isAr ? 'المحفظة غير قابلة للسحب الآن' : 'Wallet is not withdrawable yet',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isAr) {
    final lifetime = (_wallet['lifetimeEarnings'] ?? 0).toDouble();
    final withdrawn = (_wallet['lifetimeWithdrawn'] ?? 0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF4CAF50),
            iconBg: const Color(0xFFE8F5E9),
            label: isAr ? 'إجمالي الأرباح' : 'Total Earnings',
            value: '${lifetime.toStringAsFixed(0)} ${isAr ? 'ج.م' : 'EGP'}',
          )),
          const SizedBox(width: 14),
          Expanded(child: _buildStatCard(
            icon: Icons.call_made_rounded,
            iconColor: const Color(0xFFE91E63),
            iconBg: const Color(0xFFFCE4EC),
            label: isAr ? 'إجمالي السحوبات' : 'Total Withdrawn',
            value: '${withdrawn.toStringAsFixed(0)} ${isAr ? 'ج.م' : 'EGP'}',
          )),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.cairo(color: textMuted, fontSize: 11), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.cairo(color: textDark, fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(isAr ? 'سجل المعاملات' : 'Transactions History', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 14),
          if (_transactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(children: [
                  Icon(Icons.receipt_long_outlined, size: 56, color: textMuted.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text(isAr ? 'لا توجد معاملات بعد' : 'No transactions yet', style: GoogleFonts.cairo(color: textMuted)),
                ]),
              ),
            )
          else
            ...(_transactions.map((tx) => _buildTxItem(tx, isAr)).toList()),
        ],
      ),
    );
  }

  Widget _buildTxItem(dynamic tx, bool isAr) {
    final type = tx['type'] ?? 'credit';
    final amount = (tx['amount'] ?? 0).toDouble();
    final isCredit = type == 'credit' || amount >= 0;
    final date = DateTime.tryParse(tx['createdAt'] ?? '');
    final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? Icons.call_received_rounded : Icons.call_made_rounded,
              color: isCredit ? const Color(0xFF4CAF50) : const Color(0xFFE91E63),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['description'] ?? (isCredit ? (isAr ? 'إيداع' : 'Credit') : (isAr ? 'سحب' : 'Debit')),
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: textDark, fontSize: 14),
                ),
                if (dateStr.isNotEmpty)
                  Text(dateStr, style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}${amount.abs().toStringAsFixed(2)} ${isAr ? 'ج.م' : 'EGP'}',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isCredit ? const Color(0xFF4CAF50) : const Color(0xFFE91E63),
            ),
          ),
        ],
      ),
    );
  }
}
