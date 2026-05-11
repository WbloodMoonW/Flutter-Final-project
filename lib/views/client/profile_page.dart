// ignore_for_file: duplicate_ignore, deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../core/localization.dart';
import '../auth/login_view.dart';
import '../auth/verification_view.dart';
import '../worker/worker_dashboard_page.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'main_wrapper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color primaryTeal = const Color(0xFF006D5B);
  final Color textDark = const Color(0xFF1A1A2E);
  final Color textMuted = const Color(0xFF8E8E93);
  bool isEditing = false;
  File? _pickedImage;
  String? _base64Image;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFields();
    });
  }

  void _initFields() {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    if (authVM.currentUser != null) {
      _firstNameController.text = authVM.currentUser!.firstName;
      _lastNameController.text = authVM.currentUser!.lastName;
      _phoneController.text = authVM.currentUser!.phone;
      _emailController.text = authVM.currentUser!.email;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImage = File(image.path);
        _base64Image = "data:image/png;base64,${base64Encode(bytes)}";
      });
    }
  }

  Future<void> _updateProfile() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authVM.updateProfile({
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'profileImage': _base64Image,
    });

    if (success) {
      if (mounted) {
        setState(() {
          isEditing = false;
          _pickedImage = null;
          _base64Image = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.isArabic ? 'تم تحديث الملف الشخصي' : 'Profile updated successfully')),
        );
      }
    } else if (authVM.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authVM.errorMessage!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    if (authVM.isLoading && authVM.currentUser == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: primaryTeal)));
    }

    return Directionality(
      textDirection: AppLocalization.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(authVM),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (isEditing) _buildEditForm() else _buildProfileView(authVM),
                    const SizedBox(height: 30),
                    _buildActionButtons(authVM),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthViewModel authVM) {
    final user = authVM.currentUser;
    final String fullName = user != null ? "${user.firstName} ${user.lastName}" : "";
    final String? profileImage = user?.profileImage;
    
    ImageProvider? imageProvider;
    if (_pickedImage != null) {
      imageProvider = FileImage(_pickedImage!);
    } else if (profileImage != null && profileImage.startsWith('data:image')) {
      final base64String = profileImage.split(',').last;
      imageProvider = MemoryImage(base64Decode(base64String));
    } else if (profileImage != null && profileImage.isNotEmpty) {
      imageProvider = NetworkImage(profileImage);
    }

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryTeal,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: isEditing ? _pickImage : null,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      image: imageProvider != null 
                        ? DecorationImage(image: imageProvider, fit: BoxFit.cover) 
                        : null,
                    ),
                    child: imageProvider == null 
                      ? Icon(Icons.person, color: primaryTeal, size: 60) 
                      : null,
                  ),
                  if (isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  fullName.isNotEmpty ? fullName : (AppLocalization.isArabic ? 'مستخدم' : 'User'),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  user?.email ?? '',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(AuthViewModel authVM) {
    final user = authVM.currentUser;
    final bool isVerified = user?.isVerified ?? true;
    return Column(
      children: [
        if (!isVerified) _buildVerificationCard(user?.email ?? ''),
        _buildProfileItem(Icons.person_outline, AppLocalization.isArabic ? 'الاسم الأول' : 'First Name', user?.firstName ?? ''),
        _buildProfileItem(Icons.person_outline, AppLocalization.isArabic ? 'الاسم الأخير' : 'Last Name', user?.lastName ?? ''),
        _buildProfileItem(Icons.phone_android_rounded, AppLocalization.translate('phone'), user?.phone ?? ''),
        _buildProfileItem(Icons.email_outlined, AppLocalization.translate('email'), user?.email ?? ''),
      ],
    );
  }

  Widget _buildVerificationCard(String email) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalization.isArabic ? 'حسابك غير مفعل' : 'Account not verified',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  AppLocalization.isArabic ? 'اضغط لتفعيل حسابك الآن' : 'Tap to verify your account now',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.resendVerificationCode();
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerificationPage(email: email),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(AppLocalization.isArabic ? 'تفعيل' : 'Verify'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        _buildTextField(AppLocalization.isArabic ? 'الاسم الأول' : 'First Name', _firstNameController),
        const SizedBox(height: 16),
        _buildTextField(AppLocalization.isArabic ? 'الاسم الأخير' : 'Last Name', _lastNameController),
        const SizedBox(height: 16),
        _buildTextField(AppLocalization.translate('email'), _emailController),
        const SizedBox(height: 16),
        _buildTextField(AppLocalization.translate('phone'), _phoneController),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: primaryTeal, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 12)),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    value,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AuthViewModel authVM) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              if (isEditing) {
                _updateProfile();
              } else {
                setState(() => isEditing = true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              isEditing 
                ? (AppLocalization.isArabic ? 'حفظ التغييرات' : 'Save Changes')
                : (AppLocalization.isArabic ? 'تعديل الملف الشخصي' : 'Edit Profile'),
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        if (isEditing)
          TextButton(
            onPressed: () => setState(() => isEditing = false),
            child: Text(
              AppLocalization.isArabic ? 'إلغاء' : 'Cancel',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ),
        const SizedBox(height: 12),
        
        // Multi-Account Dropdown
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: authVM.accounts.any((acc) => acc['user']['email'] == authVM.currentUser?.email) ? authVM.currentUser?.email : null,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryTeal),
              items: [
                ...(() {
                  final uniqueEmails = <String>{};
                  return authVM.accounts.where((acc) => uniqueEmails.add(acc['user']['email'])).map((acc) {
                    final user = acc['user'];
                    return DropdownMenuItem<String>(
                      value: user['email'],
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: primaryTeal.withOpacity(0.1),
                            backgroundImage: user['profileImage'] != null && user['profileImage'].isNotEmpty 
                              ? (user['profileImage'].startsWith('data:image') 
                                  ? MemoryImage(base64Decode(user['profileImage'].split(',').last)) 
                                  : NetworkImage(user['profileImage']) as ImageProvider) 
                              : null,
                            child: user['profileImage'] == null || user['profileImage'].isEmpty 
                              ? Text(user['firstName'][0], style: TextStyle(fontSize: 12, color: primaryTeal)) 
                              : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "${user['firstName']} ${user['lastName']}",
                              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user['email'] == authVM.currentUser?.email)
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        ],
                      ),
                    );
                  });
                })(),
                DropdownMenuItem<String>(
                  value: 'ADD_ACCOUNT',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: primaryTeal, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalization.isArabic ? 'إضافة حساب جديد' : 'Add Account',
                        style: GoogleFonts.cairo(fontSize: 14, color: primaryTeal, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (val) async {
                if (val == 'ADD_ACCOUNT') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                } else if (val != null && val != authVM.currentUser?.email) {
                  final index = authVM.accounts.indexWhere((acc) => acc['user']['email'] == val);
                  if (index != -1) {
                    await authVM.switchAccount(index);
                    if (mounted) {
                      final role = authVM.currentUser?.role ?? 'customer';
                      if (role == 'worker') {
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const WorkerDashboardPage()), (r) => false);
                      } else {
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainWrapper()), (r) => false);
                      }
                    }
                  }
                }
              },
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              await authVM.logout();
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              AppLocalization.isArabic ? 'تسجيل الخروج' : 'Logout',
              style: GoogleFonts.cairo(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.language, size: 20, color: primaryTeal),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalization.translate('language'),
                    style: GoogleFonts.cairo(
                      color: textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Switch(
                value: AppLocalization.isArabic,
                onChanged: (val) {
                  AppLocalization.setLocale(val ? const Locale('ar') : const Locale('en'));
                },
                activeThumbColor: primaryTeal,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
