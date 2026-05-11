import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../viewmodels/worker_viewmodel.dart';
import '../../core/localization.dart';
import 'support_components.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  
  String? _selectedReportType;
  dynamic _selectedOrder;
  bool _isSubmitting = false;
  int _activeTab = 0;

  final List<Map<String, dynamic>> _reportTypes = [
    {'id': 'service', 'title': 'مشكلة في خدمة', 'desc': 'مشكلة متعلقة بخدمة حجزتها', 'icon': Icons.work_outline_rounded},
    {'id': 'user', 'title': 'بلاغ عن مستخدم', 'desc': 'سلوك غير لائق أو إساءة', 'icon': Icons.person_off_outlined},
    {'id': 'technical', 'title': 'مشكلة تقنية', 'desc': 'الموقع لا يعمل كما يجب', 'icon': Icons.build_outlined},
    {'id': 'payment', 'title': 'مشكلة في الدفع', 'desc': 'دفعة مفقودة أو خطأ مالي', 'icon': Icons.credit_card_outlined},
    {'id': 'other', 'title': 'أخرى', 'desc': 'أي موضوع آخر', 'icon': Icons.help_outline_rounded},
  ];

  static const Color primaryColor = Color(0xFF009688);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF8E8E93);

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReportType == null) {
      _showSnack('يرجى اختيار نوع البلاغ أولاً', success: false);
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        // Placeholder for real API call
        await Future.delayed(const Duration(seconds: 1));
        _showSnack('تم إرسال البلاغ بنجاح');
        Navigator.pop(context);
      } catch (e) {
        _showSnack('فشل إرسال البلاغ', success: false);
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnack(String msg, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo()),
      backgroundColor: success ? primaryColor : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalization.isArabic;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: Text(isAr ? 'الدعم والمساعدة' : 'Support', style: GoogleFonts.cairo(color: textDark, fontWeight: FontWeight.bold)),
      ),
      body: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SupportHeader(
                title: 'الدعم والمساعدة',
                subtitle: 'أرسل بلاغاً للإدارة عن أي مشكلة في الخدمات، المستخدمين، الدفع، أو أي مشكلة تقنية.',
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  SupportTabButton(label: isAr ? 'إرسال بلاغ جديد' : 'New Report', icon: Icons.add_circle_outline_rounded, isActive: _activeTab == 0, onTap: () => setState(() => _activeTab = 0)),
                  const SizedBox(width: 16),
                  SupportTabButton(label: isAr ? 'بلاغاتي' : 'My Reports', icon: Icons.history_rounded, isActive: _activeTab == 1, onTap: () => setState(() => _activeTab = 1)),
                ],
              ),
              const SizedBox(height: 32),
              if (_activeTab == 0) _buildNewReportForm(isAr) else _buildMyReportsList(isAr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewReportForm(bool isAr) {
    final workerVM = Provider.of<WorkerViewModel>(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isAr ? 'ما نوع البلاغ؟' : 'Report Type', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.2),
            itemCount: _reportTypes.length,
            itemBuilder: (context, index) {
              final type = _reportTypes[index];
              return SupportTypeCard(title: type['title'], description: type['desc'], icon: type['icon'], isSelected: _selectedReportType == type['id'], onTap: () => setState(() => _selectedReportType = type['id']));
            },
          ),
          const SizedBox(height: 32),
          LabeledFormField(label: isAr ? 'عنوان البلاغ' : 'Title', hint: '', controller: _titleController),
          const SizedBox(height: 24),
          LabeledFormField(label: isAr ? 'تفاصيل البلاغ' : 'Details', hint: '', controller: _detailsController, maxLines: 5),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005F54), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : Text(isAr ? 'إرسال البلاغ' : 'Send Report', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMyReportsList(bool isAr) {
    return Column(children: [
      const SizedBox(height: 40),
      Icon(Icons.description_outlined, size: 64, color: textMuted.withOpacity(0.3)),
      const SizedBox(height: 16),
      Text(isAr ? 'لا توجد بلاغات سابقة' : 'No reports yet', style: GoogleFonts.cairo(color: textMuted, fontSize: 16)),
    ]);
  }
}
