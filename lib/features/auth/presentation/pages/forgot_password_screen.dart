// lib/features/auth/presentation/pages/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/auth_request.dart';
import '../presentation/providers/auth_providers.dart';
import '../presentation/utils/auth_validators.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late TextEditingController _emailController;
  late GlobalKey<FormState> _formKey;
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final request = ResetPasswordRequest(
      email: _emailController.text.trim(),
    );

    await ref.read(authStateProvider.notifier).resetPassword(request);

    if (mounted) {
      final authState = ref.read(authStateProvider);
      if (authState is AuthUnauthenticated || authState is AuthError) {
        setState(() => _emailSent = true);
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final errorMessage = authState is AuthError ? authState.message : null;
    final successMessage = authState is AuthUnauthenticated ? authState.message : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _emailSent || successMessage != null
            ? _buildSuccessView(successMessage)
            : _buildResetForm(errorMessage),
      ),
    );
  }

  Widget _buildResetForm(String? errorMessage) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_reset,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          Text(
            'Forgot Password?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'user@example.com',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: AuthValidators.validateEmail,
          ),
          const SizedBox(height: 16),
          if (errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                errorMessage,
                style: TextStyle(color: Colors.red[900]),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Send Reset Link'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back to Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(String? message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        Text(
          'Check Your Email',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          message ?? 'We have sent a password reset link to your email.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Return to Sign In'),
          ),
        ),
      ],
    );
  }
}