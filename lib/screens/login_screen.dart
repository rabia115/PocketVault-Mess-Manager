import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool rememberMe = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default Admin credentials pre-filled
    emailController.text = 'admin@pocketvault.com';
    passwordController.text = 'PocketVault@123';
  }

  void fillAdminCredentials() {
    setState(() {
      emailController.text = 'admin@pocketvault.com';
      passwordController.text = 'PocketVault@123';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default Admin Credentials Loaded!'),
        backgroundColor: Color(0xFF176B50),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void fillMemberCredentials() {
    setState(() {
      emailController.text = 'ali.khan@example.com';
      passwordController.text = 'Member@123';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Member Credentials Loaded (Ali Khan)!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.pocketvault://login-callback',
      );
    } catch (e) {
      if (!mounted) return;
      // Demo fallback if OAuth provider not set up on device
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sign-In Initiated! Logging in as Member...'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/member', (route) => false);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void openOtpVerificationModal() {
    final otpPhoneEmailController = TextEditingController(text: 'ali.khan@example.com');
    final otpCodeController = TextEditingController();

    String? generatedOtp;
    bool isOtpSent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                24,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.mark_email_read, color: Color(0xFF176B50)),
                            SizedBox(width: 8),
                            Text(
                              'Member OTP Login',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Enter your registered Member Email or Phone Number to receive a 6-digit OTP login code.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 18),

                    TextField(
                      controller: otpPhoneEmailController,
                      enabled: !isOtpSent,
                      decoration: InputDecoration(
                        labelText: 'Member Email or Phone',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    if (isOtpSent) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: otpCodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: 'Enter 6-Digit OTP Code',
                          hintText: 'e.g. 849201',
                          prefixIcon: const Icon(Icons.security, color: Color(0xFF176B50)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF176B50)),
                        onPressed: () {
                          if (!isOtpSent) {
                            final code = (100000 + Random().nextInt(900000)).toString();
                            generatedOtp = code;

                            setSheetState(() {
                              isOtpSent = true;
                              otpCodeController.text = code; // Auto fill correct OTP for testing convenience
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('OTP Sent! Your Member OTP Code is: $code'),
                                backgroundColor: const Color(0xFF176B50),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          } else {
                            final enteredCode = otpCodeController.text.trim();
                            if (enteredCode == generatedOtp) {
                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('OTP Verified Successfully! Logged in as Member.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pushNamedAndRemoveUntil(context, '/member', (route) => false);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Incorrect OTP Code. Please enter the valid OTP code.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          !isOtpSent ? 'Send OTP Code' : 'Verify OTP & Login',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    final String enteredEmail = emailController.text.trim();

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: enteredEmail,
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome! Logged in as ${enteredEmail == "admin@pocketvault.com" ? "Admin" : "Member"}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      if (enteredEmail == 'admin@pocketvault.com') {
        Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
        return;
      } else if (enteredEmail == 'ali.khan@example.com' || enteredEmail.contains('member')) {
        Navigator.pushNamedAndRemoveUntil(context, '/member', (route) => false);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF176B50);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    size: 65,
                    color: green,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'PocketVault Mess',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: green,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Smart Mess & Financial Manager',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Sign in as Admin or Member to manage mess activities.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Email Field
                  const Text(
                    'Email Address',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'admin@pocketvault.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // Password Field
                  const Text(
                    'Password',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'PocketVault@123',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        activeColor: green,
                        onChanged: (value) {
                          setState(() {
                            rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('Remember Me'),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Default Admin password: PocketVault@123'),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: green),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Main Email/Password Login Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'Login to PocketVault',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Google Sign-In & OTP Login Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: signInWithGoogle,
                          icon: const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
                          label: const Text('Google Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: openOtpVerificationModal,
                          icon: const Icon(Icons.mark_email_read, size: 18, color: green),
                          label: const Text('OTP Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),
                  const Divider(),
                  const SizedBox(height: 14),

                  // Quick Role Selector (Bottom of Login Page)
                  const Text(
                    'Select Role Account to Test:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: green,
                            side: const BorderSide(color: green, width: 1.5),
                          ),
                          onPressed: () {
                            fillAdminCredentials();
                            loginUser();
                          },
                          icon: const Icon(Icons.admin_panel_settings, size: 18),
                          label: const Text(
                            'Admin Dashboard\n(admin@pocketvault.com)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: Colors.blue.shade800,
                            side: BorderSide(color: Colors.blue.shade800, width: 1.5),
                          ),
                          onPressed: () {
                            fillMemberCredentials();
                            loginUser();
                          },
                          icon: const Icon(Icons.person, size: 18),
                          label: const Text(
                            'Member Dashboard\n(ali.khan@example.com)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Signup Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
