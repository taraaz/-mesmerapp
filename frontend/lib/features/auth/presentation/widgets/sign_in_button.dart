import 'package:flutter/material.dart';

class SignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const SignInButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.login, size: 20),
        label: Text(isLoading ? 'Logging in...' : 'Log In'),
      ),
    );
  }
}
