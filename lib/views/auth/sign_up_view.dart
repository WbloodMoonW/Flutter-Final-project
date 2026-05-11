// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'login_view.dart';
import '../client/main_wrapper.dart';
import '../../core/localization.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'verification_view.dart';
import '../worker/worker_dashboard_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'customer';
  final Color primaryTeal = const Color(0xFF006D5B);
  final Color bgColor = const Color(0xFFF9FAFB);

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSignUp() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showError(AppLocalization.isArabic ? 'يرجى ملء جميع الحقول' : 'Please fill all fields');
      return;
    }

    final success = await authVM.signup({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'password': password,
      'role': _selectedRole,
    });

    if (success) {
      if (mounted) {
        // Assume verification logic or redirect based on authVM state
        final isVerified = authVM.currentUser?.isVerified ?? false;
        if (!isVerified && _selectedRole == 'worker') {
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationPage(email: email),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => _selectedRole == 'worker' 
                  ? const WorkerDashboardPage() 
                  : const MainWrapper()
            ),
          );
        }
      }
    } else if (authVM.errorMessage != null) {
      if (mounted) {
        _showError(authVM.errorMessage!.replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: AppLocalization.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryTeal,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Image.asset(
                    'assets/toolbox (1).png',
                    width: 60,
                    height: 60,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalization.translate('app_name'),
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  AppLocalization.translate('tagline'),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 40),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: AppLocalization.translate('user_type'),
                      labelStyle: GoogleFonts.cairo(color: Colors.grey[600]),
                    ),
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryTeal),
                    items: [
                      DropdownMenuItem(
                        value: 'customer',
                        child: Text(AppLocalization.translate('customer'), style: GoogleFonts.cairo()),
                      ),
                      DropdownMenuItem(
                        value: 'worker',
                        child: Text(AppLocalization.translate('contractor'), style: GoogleFonts.cairo()),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          child: _buildTab(AppLocalization.translate('login'), false),
                        ),
                      ),
                      Expanded(
                        child: _buildTab(AppLocalization.translate('signup'), true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField(
                        label: AppLocalization.isArabic ? 'الاسم الأول' : 'First Name',
                        hint: AppLocalization.isArabic ? 'أدخل اسمك الأول' : 'Enter your first name',
                        icon: Icons.person_outline,
                        controller: _firstNameController,
                      ),
                      const SizedBox(height: 15),
                      _buildInputField(
                        label: AppLocalization.isArabic ? 'الاسم الأخير' : 'Last Name',
                        hint: AppLocalization.isArabic ? 'أدخل اسمك الأخير' : 'Enter your last name',
                        icon: Icons.person_outline,
                        controller: _lastNameController,
                      ),
                      const SizedBox(height: 15),
                      _buildInputField(
                        label: AppLocalization.translate('email'),
                        hint: 'example@gmail.com',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                      ),
                      const SizedBox(height: 20),
                      _buildPhoneInputField(controller: _phoneController),
                      const SizedBox(height: 20),
                      _buildPasswordField(controller: _passwordController),
                      
                      const SizedBox(height: 30),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: authVM.isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: authVM.isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                AppLocalization.translate('create_account'),
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                InkWell(
                  onTap: () {
                    setState(() {
                      AppLocalization.toggleLanguage();
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.language, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalization.translate('language'),
                        style: GoogleFonts.cairo(
                          color: Colors.grey[400],
                          fontSize: 14,
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

  Widget _buildTab(String title, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.cairo(
            color: isActive ? primaryTeal : Colors.grey[400],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textAlign: AppLocalization.isArabic ? TextAlign.right : TextAlign.left,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(color: Colors.grey[300], fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInputField({TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalization.translate('phone'),
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          textAlign: TextAlign.left,
          decoration: InputDecoration(
            hintText: '10XXXXXXXX',
            hintStyle: GoogleFonts.cairo(color: Colors.grey[300], fontSize: 14),
            prefixIcon: Container(
              width: 90,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇪🇬', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text(
                    '+20',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const VerticalDivider(indent: 12, endIndent: 12),
                ],
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({TextEditingController? controller}) {
    bool isPasswordVisibleLocal = false;
    return StatefulBuilder(
      builder: (context, setStateLocal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalization.translate('password'),
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              obscureText: !isPasswordVisibleLocal,
              textAlign: AppLocalization.isArabic ? TextAlign.right : TextAlign.left,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400], size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisibleLocal ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () {
                    setStateLocal(() {
                      isPasswordVisibleLocal = !isPasswordVisibleLocal;
                    });
                  },
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        );
      }
    );
  }
}
