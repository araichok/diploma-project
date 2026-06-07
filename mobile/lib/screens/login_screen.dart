import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

enum PasswordStrength { weak, medium, strong }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;

  String? _emailError;
  String? _passwordError;
  String? _nameError;
  String? _phoneError;

  PasswordStrength _passwordStrength = PasswordStrength.weak;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ----- Обновлённая валидация email -----
  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email (e.g., name@example.com)';
    }
    return null;
  }

  // ----- Новая валидация имени (требует имя и фамилию, каждое не менее 2 символов) -----
  String? _validateName(String name) {
    if (name.isEmpty) return 'Full name is required';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return 'Enter first name and last name';
    }
    if (parts.any((p) => p.length < 2)) {
      return 'First name and last name must be at least 2 characters each';
    }
    return null;
  }

  // ----- Новая валидация телефона (требует + и 10-15 цифр) -----
  String? _validatePhone(String phone) {
    if (phone.isEmpty) return 'Phone number is required';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Enter 10-15 digits (international format with +)';
    }
    if (!phone.startsWith('+')) {
      return 'Phone number should start with + (e.g., +77777777777)';
    }
    return null;
  }

  // ----- Остальные методы валидации пароля (без изменений) -----
  PasswordStrength _checkPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (score >= 5) return PasswordStrength.strong;
    if (score >= 3) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    List<String> errors = [];
    if (!password.contains(RegExp(r'[0-9]'))) errors.add('one number');
    if (!password.contains(RegExp(r'[a-z]'))) errors.add('one lowercase letter');
    if (!password.contains(RegExp(r'[A-Z]'))) errors.add('one uppercase letter');
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('one special character (!@#\$%^&*)');
    }
    if (errors.isNotEmpty) {
      return 'Password must contain ${errors.join(", ")}';
    }
    return null;
  }

  Color _getStrengthColor() {
    switch (_passwordStrength) {
      case PasswordStrength.weak: return Colors.red;
      case PasswordStrength.medium: return Colors.orange;
      case PasswordStrength.strong: return Colors.green;
    }
  }

  String _getStrengthText() {
    switch (_passwordStrength) {
      case PasswordStrength.weak: return 'Weak';
      case PasswordStrength.medium: return 'Medium';
      case PasswordStrength.strong: return 'Strong';
    }
  }

  bool _validateRegistration() {
    bool isValid = true;
    setState(() {
      _nameError = _validateName(_nameController.text);
      if (_nameError != null) isValid = false;
      _phoneError = _validatePhone(_phoneController.text);
      if (_phoneError != null) isValid = false;
      _emailError = _validateEmail(_emailController.text);
      if (_emailError != null) isValid = false;
      _passwordError = _validatePassword(_passwordController.text);
      if (_passwordError != null) isValid = false;
    });
    return isValid;
  }

  bool _validateLogin() {
    bool isValid = true;
    setState(() {
      _emailError = _validateEmail(_emailController.text);
      if (_emailError != null) isValid = false;
      if (_passwordController.text.isEmpty) {
        _passwordError = 'Password is required';
        isValid = false;
      } else {
        _passwordError = null;
      }
    });
    return isValid;
  }

  void _clearErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _nameError = null;
      _phoneError = null;
      _passwordStrength = PasswordStrength.weak;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.travel_explore, size: 80, color: Colors.blue.shade700),
                      const SizedBox(height: 16),
                      Text(
                        _isLogin ? 'Welcome Back!' : 'Create Account',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Sign in to continue' : 'Register to start your journey',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 32),

                      if (!_isLogin) ...[
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.person),
                            errorText: _nameError,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            hintText: 'Ivan Ivanov',
                          ),
                          onChanged: (value) => setState(() => _nameError = _validateName(value)),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: const Icon(Icons.phone),
                            errorText: _phoneError,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            hintText: '+7 777 777 77 77',
                          ),
                          onChanged: (value) => setState(() => _phoneError = _validatePhone(value)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          errorText: _emailError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          hintText: 'user@example.com',
                        ),
                        onChanged: (value) => setState(() => _emailError = _validateEmail(value)),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          errorText: _passwordError,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (!_isLogin) {
                              _passwordStrength = _checkPasswordStrength(value);
                              _passwordError = _validatePassword(value);
                            } else if (value.isEmpty) {
                              _passwordError = 'Password is required';
                            } else {
                              _passwordError = null;
                            }
                          });
                        },
                      ),

                      if (!_isLogin && _passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: _passwordStrength == PasswordStrength.weak ? 0.33 :
                                       _passwordStrength == PasswordStrength.medium ? 0.66 : 1.0,
                                backgroundColor: Colors.grey.shade200,
                                color: _getStrengthColor(),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_getStrengthText(), style: TextStyle(color: _getStrengthColor(), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use 8+ chars with numbers, uppercase & special chars (!@#\$%^&*)',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ],

                      const SizedBox(height: 24),

                      if (_isLogin) ...[
                        ElevatedButton(
                          onPressed: authProvider.isLoading ? null : () async {
                            if (_validateLogin()) {
                              final success = await authProvider.login(
                                _emailController.text,
                                _passwordController.text,
                                _nameController.text,
                              );
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Login successful!'), backgroundColor: Colors.green),
                                );
                                // Admins go to admin panel, users go to emotion screen first
                                if (authProvider.isAdmin) {
                                  Navigator.pushReplacementNamed(context, '/');
                                } else {
                                  Navigator.pushReplacementNamed(context, '/emotion');
                                }
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(authProvider.lastError ?? 'Invalid email or password'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: authProvider.isLoading ? const CircularProgressIndicator() : const Text('Login'),
                        ),
                      ] else ...[
                        ElevatedButton(
                          onPressed: authProvider.isLoading ? null : () async {
                            if (_validateRegistration()) {
                              // ----- Автоматическое добавление + к телефону, если его нет -----
                              String rawPhone = _phoneController.text.trim();
                              String formattedPhone = rawPhone.startsWith('+') ? rawPhone : '+$rawPhone';
                              final success = await authProvider.register(
                                _emailController.text,
                                _nameController.text,
                                formattedPhone,
                                _passwordController.text,
                              );
                              if (success && mounted) {
                                final savedEmail = _emailController.text;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Registration successful! Please login.'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                setState(() {
                                  _isLogin = true;
                                  _nameController.clear();
                                  _phoneController.clear();
                                  _passwordController.clear();
                                  _emailController.text = savedEmail;
                                  _passwordError = null;
                                  _nameError = null;
                                  _phoneError = null;
                                  _emailError = null;
                                  _passwordStrength = PasswordStrength.weak;
                                });
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(authProvider.lastError ?? 'Registration failed'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: authProvider.isLoading ? const CircularProgressIndicator() : const Text('Register'),
                        ),
                      ],

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _clearErrors();
                          });
                        },
                        child: Text(_isLogin ? "Don't have an account? Register" : "Already have an account? Login"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
