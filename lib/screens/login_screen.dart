import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kira_college_ai/components/space_scaffold.dart';
import 'package:kira_college_ai/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      final auth = context.read<AuthService>();
      
      // Add timeout to prevent infinite loading
      final user = await auth.signInWithEmail(
        _email.text.trim(), 
        _password.text
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Login timed out. Please check your internet connection and try again.');
        },
      );
      
      if (mounted && user != null) {
        Navigator.pushReplacementNamed(context, '/chatScreen');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Login failed. Please try again.';
        
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'No account found with this email. Please check your email or create a new account.';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'Incorrect password. Please try again.';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Please enter a valid email address.';
        } else if (e.toString().contains('user-disabled')) {
          errorMessage = 'This account has been disabled. Please contact support.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Request timed out. Please check your internet connection and try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleGoogle() async {
    setState(() => _loading = true);
    
    try {
      final auth = context.read<AuthService>();
      
      // Add timeout to prevent infinite loading
      final user = await auth.signInWithGoogle(forceAccountPicker: true).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Google sign-in timed out. Please try again.');
        },
      );
      
      if (mounted && user != null) {
        Navigator.pushReplacementNamed(context, '/chatScreen');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in was cancelled or failed. Please try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Google sign-in failed. Please try again.';
        
        if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Google sign-in timed out. Please try again.';
        } else if (e.toString().contains('SHA')) {
          errorMessage = 'Google sign-in configuration error. Please contact support.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleGuest() async {
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    try {
      await auth.signInAsGuest();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/chatScreen');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SpaceScaffold(
      title: 'Welcome to KIRA',
      showBack: false,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final cardWidth = maxW >= 800 ? 500.0 : double.infinity;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Know Your College',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _email,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(color: Colors.white70),
                              ),
                              validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Colors.white70),
                              ),
                              validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters',
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _handleEmailLogin,
                                child: Text(_loading ? 'Loading...' : 'Login'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No account? ', style: TextStyle(color: Colors.white70)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/signup'),
                          child: const Text('Sign up'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _handleGoogle,
                        icon: const Icon(Icons.login, color: Colors.white),
                        label: const Text('Continue with Google', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _loading ? null : _handleGuest,
                        child: const Text('Continue as Guest', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


