import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../client/main_wrapper.dart';
import 'sign_up_view.dart';
import '../../core/localization.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../worker/worker_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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

  Future<void> _handleLogin() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError(AppLocalization.isArabic ? 'يرجى ملء جميع الحقول' : 'Please fill all fields');
      return;
    }

    final success = await authVM.login(email, password);
    if (success) {
      if (mounted) {
        final role = authVM.currentUser?.role ?? 'customer';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => role == 'worker' 
                ? const WorkerDashboardPage() 
                : const MainWrapper()
          ),
        );
      }
    } else if (authVM.errorMessage != null) {
      if (mounted) {
        _showError(authVM.errorMessage!.replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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
                        child: _buildTab(AppLocalization.translate('login'), true),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUpPage()),
                            );
                          },
                          child: _buildTab(AppLocalization.translate('signup'), false),
                        ),
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
                        label: AppLocalization.translate('email'),
                        hint: 'example@gmail.com',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(controller: _passwordController),
                      const SizedBox(height: 12),
                      Align(
                        alignment: AppLocalization.isArabic ? Alignment.centerLeft : Alignment.centerRight,
                        child: Text(
                          AppLocalization.isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
                          style: GoogleFonts.cairo(
                            color: primaryTeal,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: authVM.isLoading ? null : _handleLogin,
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
                                AppLocalization.translate('login'),
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
                const SizedBox(height: 30),

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
        color: isActive ? primaryTeal : Colors.transparent,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.cairo(
            color: isActive ? Colors.white : Colors.grey[400],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required String label, required String hint, required IconData icon, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF374151)),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({TextEditingController? controller}) {
    bool _isPasswordVisibleLocal = false; 
    return StatefulBuilder(
      builder: (context, setStateLocal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalization.translate('password'),
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              obscureText: !_isPasswordVisibleLocal,
              textAlign: AppLocalization.isArabic ? TextAlign.right : TextAlign.left,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400], size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisibleLocal ? Icons.visibility : Icons.visibility_off, color: Colors.grey[400], size: 20),
                  onPressed: () => setStateLocal(() => _isPasswordVisibleLocal = !_isPasswordVisibleLocal),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        );
      }
    );
  }
}