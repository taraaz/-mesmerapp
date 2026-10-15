import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../projects/presentation/pages/projects_page.dart';
import '../../application/auth_provider.dart';
import '../widgets/login_card.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController =
      TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController();

  bool _isRestoringSession = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final restored =
        await ref.read(authProvider.notifier).tryRestoreSession();

    if (!mounted) {
      return;
    }

    if (restored) {
      _goToDashboard();
      return;
    }

    setState(() {
      _isRestoringSession = false;
    });
  }

  void _goToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const ProjectsPage(),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email and password.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final error =
        await ref.read(authProvider.notifier).login(email, password);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorMessage = error;
    });

    if (error == null) {
      _goToDashboard();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: _isRestoringSession
              ? const CircularProgressIndicator()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: LoginCard(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    isLoading: _isSubmitting,
                    errorMessage: _errorMessage,
                    onSubmit: _submit,
                  ),
                ),
        ),
      ),
    );
  }
}
