import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/worker_viewmodel.dart';
import '../../models/service_model.dart';
import '../../core/localization.dart';

class AddServicePage extends StatefulWidget {
  const AddServicePage({super.key});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryColor = const Color(0xFF006D5B);
  
  String _name = '';
  String _description = '';
  double _price = 0.0;
  double _minPrice = 0.0;
  double _maxPrice = 0.0;
  String _type = 'fixed';
  String _categoryId = '';
  
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalization.isArabic;
    final workerVM = Provider.of<WorkerViewModel>(context);
    
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            isAr ? 'إضافة خدمة جديدة' : 'Add New Service',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E)),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(isAr ? 'اسم الخدمة' : 'Service Name'),
                _buildTextField(
                  hint: isAr ? 'مثال: سباكة حمامات' : 'e.g. Bathroom Plumbing',
                  onSaved: (v) => _name = v ?? '',
                  validator: (v) {
                    if (v == null || v.isEmpty) return (isAr ? 'مطلوب' : 'Required');
                    if (v.length < 2) return (isAr ? 'الاسم قصير جداً' : 'Name too short');
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildLabel(isAr ? 'القسم' : 'Category'),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration(isAr ? 'اختر القسم' : 'Select Category'),
                  items: workerVM.categories.map((c) => DropdownMenuItem(
                    value: c['id'].toString(),
                    child: Text(c['name']?.toString() ?? '', style: GoogleFonts.cairo()),
                  )).toList(),
                  onChanged: (v) => setState(() => _categoryId = v ?? ''),
                  validator: (v) => (v == null || v.isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
                ),
                const SizedBox(height: 20),

                _buildLabel(isAr ? 'نوع التسعير' : 'Price Type'),
                Row(
                  children: [
                    _buildTypeOption('fixed', isAr ? 'ثابت' : 'Fixed'),
                    const SizedBox(width: 8),
                    _buildTypeOption('hourly', isAr ? 'ساعة' : 'Hourly'),
                    const SizedBox(width: 8),
                    _buildTypeOption('range', isAr ? 'نطاق' : 'Range'),
                  ],
                ),
                const SizedBox(height: 20),

                if (_type != 'range') ...[
                  _buildLabel(isAr ? 'السعر (ج.م)' : 'Price (EGP)'),
                  _buildTextField(
                    hint: '0.00',
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _price = double.tryParse(v ?? '0') ?? 0.0,
                    validator: (v) => (v == null || v.isEmpty || (double.tryParse(v) ?? 0) <= 0) 
                        ? (isAr ? 'أدخل سعر صحيح' : 'Enter valid price') : null,
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(isAr ? 'من' : 'Min'),
                            _buildTextField(
                              hint: '0.00',
                              keyboardType: TextInputType.number,
                              onSaved: (v) => _minPrice = double.tryParse(v ?? '0') ?? 0.0,
                              validator: (v) => (v == null || v.isEmpty || (double.tryParse(v) ?? 0) <= 0) 
                                  ? (isAr ? 'مطلوب' : 'Req') : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(isAr ? 'إلى' : 'Max'),
                            _buildTextField(
                              hint: '0.00',
                              keyboardType: TextInputType.number,
                              onSaved: (v) => _maxPrice = double.tryParse(v ?? '0') ?? 0.0,
                              validator: (v) {
                                final val = double.tryParse(v ?? '0') ?? 0;
                                if (val <= 0) return (isAr ? 'مطلوب' : 'Req');
                                // Note: _minPrice might not be saved yet during validation, 
                                // but we'll check it in the submit method for better accuracy.
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),

                _buildLabel(isAr ? 'وصف الخدمة' : 'Description'),
                _buildTextField(
                  hint: isAr ? 'اشرح تفاصيل الخدمة...' : 'Explain service details...',
                  maxLines: 4,
                  onSaved: (v) => _description = v ?? '',
                  validator: (v) => (v != null && v.length > 1000) ? (isAr ? 'الوصف طويل جداً' : 'Description too long') : null,
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isAr ? 'إضافة الخدمة' : 'Add Service',
                          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      child: Text(
        text,
        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1A1A2E)),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hint),
      style: GoogleFonts.cairo(),
      onSaved: onSaved,
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  Widget _buildTypeOption(String id, String label) {
    final isSelected = _type == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = id),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200),
          ),
          child: Text(
            label,
            style: GoogleFonts.cairo(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_type == 'range' && _minPrice > _maxPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalization.isArabic ? 'السعر الأقصى يجب أن يكون أكبر من الأدنى' : 'Max price must be > Min')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final workerVM = Provider.of<WorkerViewModel>(context, listen: false);
      final newService = WorkerService(
        name: _name,
        categoryId: _categoryId,
        description: _description,
        price: _type == 'range' ? 0 : _price,
        typeofService: _type,
        priceRange: _type == 'range' ? {'min': _minPrice, 'max': _maxPrice} : null,
        isActive: true,
      );

      await workerVM.addService(newService);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalization.isArabic ? 'تم إضافة الخدمة بنجاح' : 'Service added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
