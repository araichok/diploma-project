import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController  = TextEditingController();
  final _lastNameController   = TextEditingController();
  final _emailController      = TextEditingController();
  final _phoneController      = TextEditingController();
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final parts = user.name.split(' ');
    _firstNameController.text = parts.first;
    if (parts.length > 1) _lastNameController.text = parts.skip(1).join(' ');
    _emailController.text = user.email;

    // Phone is stored locally — load it from SharedPreferences
    final phone = await ApiService().getLocalPhone();
    if (mounted) {
      setState(() {
        _phoneController.text = phone.isNotEmpty ? phone : (user.phoneNumber.isNotEmpty ? user.phoneNumber : '');
        _profileLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final phone = _phoneController.text.trim();
      await ApiService().saveLocalPhone(phone);

      await auth.updateProfile(
        firstName:   _firstNameController.text.trim(),
        lastName:    _lastNameController.text.trim(),
        email:       _emailController.text.trim(),
        phoneNumber: phone,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth  = Provider.of<AuthProvider>(context);
    final user  = auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    final isAdmin = auth.isAdmin;
    final accent  = isAdmin ? Colors.red.shade700 : Colors.blue.shade700;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Profile' : 'My Profile'),
        backgroundColor: isAdmin ? Colors.red.shade700 : Colors.white,
        foregroundColor: isAdmin ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: auth.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Avatar ────────────────────────────────────────────────
                  Center(
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: isAdmin ? Colors.red.shade100 : Colors.blue.shade100,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: isAdmin ? Colors.red.shade100 : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        isAdmin ? '👑 Administrator' : '🧳 Traveler',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Email (read-only) ─────────────────────────────────────
                  _buildField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    readOnly: true,
                    enabled: false,
                  ),
                  const SizedBox(height: 14),

                  // ── First name ────────────────────────────────────────────
                  _buildField(
                    controller: _firstNameController,
                    label: 'First Name',
                    icon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your first name' : null,
                  ),
                  const SizedBox(height: 14),

                  // ── Last name ─────────────────────────────────────────────
                  _buildField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),

                  _buildField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    hint: '+7 777 777 7777',
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '* Phone is saved on this device only',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
                  const SizedBox(height: 22),

                  ElevatedButton.icon(
                    onPressed: auth.isLoading ? null : () => _saveProfile(auth),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  OutlinedButton.icon(
                    onPressed: () => _showChangePasswordDialog(context, auth),
                    icon: const Icon(Icons.lock_reset_outlined),
                    label: const Text('Change Password'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  OutlinedButton.icon(
                    onPressed: () async {
                      await auth.logout();
                      if (mounted) Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.logout_outlined),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    bool enabled = true,
    TextInputType? keyboardType,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext scaffoldCtx, AuthProvider auth) {
    final oldCtrl     = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureOld     = true;
    bool obscureNew     = true;
    bool obscureConfirm = true;
    bool isLoading      = false;

    showDialog(
      context: scaffoldCtx,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDS) {
          Future<void> submit() async {
            final oldPass     = oldCtrl.text.trim();
            final newPass     = newCtrl.text.trim();
            final confirmPass = confirmCtrl.text.trim();

            if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
              ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
                const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.orange),
              );
              return;
            }
            if (newPass != confirmPass) {
              ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
                const SnackBar(content: Text('New passwords do not match'), backgroundColor: Colors.red),
              );
              return;
            }
            if (newPass.length < 8) {
              ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
                const SnackBar(content: Text('New password must be at least 8 characters'), backgroundColor: Colors.orange),
              );
              return;
            }

            setDS(() => isLoading = true);
            try {
              await auth.changePassword(oldPass, newPass);
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              if (scaffoldCtx.mounted) {
                ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Password changed successfully!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } catch (e) {
              setDS(() => isLoading = false);
              if (scaffoldCtx.mounted) {
                final msg = e.toString().replaceAll('Exception: ', '');
                ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
                  SnackBar(content: Text('Error: $msg'), backgroundColor: Colors.red),
                );
              }
            }
          }

          return AlertDialog(
            title: const Text('Change Password'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _pwField('Current Password', oldCtrl, obscureOld, Icons.lock_outline,
                      () => setDS(() => obscureOld = !obscureOld)),
                  const SizedBox(height: 12),
                  _pwField('New Password', newCtrl, obscureNew, Icons.lock,
                      () => setDS(() => obscureNew = !obscureNew)),
                  const SizedBox(height: 12),
                  _pwField('Confirm New Password', confirmCtrl, obscureConfirm, Icons.lock_clock,
                      () => setDS(() => obscureConfirm = !obscureConfirm)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Change'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pwField(String label, TextEditingController ctrl,
      bool obscure, IconData icon, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
      ),
    );
  }
}
