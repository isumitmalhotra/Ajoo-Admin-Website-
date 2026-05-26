import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:iconsax/iconsax.dart';
import 'auth_controller.dart';

class CreateAccountLoadingScreen extends StatefulWidget {
  final String email;
  final String password;
  final String confirmPassword;
  final bool isHost;

  const CreateAccountLoadingScreen({
    Key? key,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.isHost,
  }) : super(key: key);

  @override
  _CreateAccountLoadingScreenState createState() =>
      _CreateAccountLoadingScreenState();
}

class _CreateAccountLoadingScreenState
    extends State<CreateAccountLoadingScreen> {
  final AuthController authController = Get.find<AuthController>();

  final List<String> _messages = [
    "Creating your account...",
    "Setting up your profile...",
    "Almost there...",
    "Preparing verification..."
  ];

  int _currentIndex = 0;
  bool _isSubmitting = false;
  bool _canNavigate = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    // Listen to error changes
    ever(authController.error, (error) {
      if (error.isNotEmpty && mounted && !_hasError) {
        setState(() {
          _hasError = true;
          _isSubmitting = false;
        });
      }
    });

    // Start signup process
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _submitSignup();
    });
  }

  Future<void> _submitSignup() async {
    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
      _hasError = false;
    });

    _startMessageRotation();

    try {
      final response = await authController.submitSignup(
        email: widget.email,
        password: widget.password,
        confirmPassword: widget.confirmPassword,
        isHost: widget.isHost,
      );

      if (!mounted || !_canNavigate) return;

      if (response.success) {
        // Success - wait for animation then navigate
        await Future.delayed(const Duration(seconds: 1));

        if (mounted && _canNavigate) {
          Get.offNamed(
            '/verify',
            arguments: {'userId': response.data.userId, 'email': widget.email},
          );
        }
      } else {
        // Error occurred
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      // Exception occurred
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _hasError = true;
        });
      }
    }
  }

  void _startMessageRotation() {
    if (!_isSubmitting || _hasError) return;

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || !_isSubmitting || _hasError) return;

      if (_currentIndex < _messages.length - 1) {
        setState(() {
          _currentIndex++;
        });
        _startMessageRotation();
      }
    });
  }

  void _handleRetry() {
    // Only clear the error, DON'T clear signup data
    authController.error.value = '';
    // Go back to the previous screen (InfoScreen)
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async => !_isSubmitting,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Obx(() {
            final hasError = authController.error.value.isNotEmpty;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animation or Error Icon
                  if (!hasError) ...[
                    Center(
                      child: Lottie.asset(
                        'assets/Animation - 1729069558573.json',
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.close_circle,
                        size: 60,
                        color: Colors.red[600],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Message
                  Text(
                    hasError
                        ? 'Account Creation Failed'
                        : _messages[_currentIndex],
                    style: TextStyle(
                      fontSize: 20,
                      color: hasError ? Colors.red[700] : theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Error message or subtitle
                  if (hasError) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.info_circle,
                            color: Colors.red[700],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authController.error.value,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Retry Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleRetry,
                        icon: const Icon(Iconsax.refresh, size: 20),
                        label: const Text('Go Back & Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Please wait while we set up your account',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _canNavigate = false;
    _isSubmitting = false;
    super.dispose();
  }
}
