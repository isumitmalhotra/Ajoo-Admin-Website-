import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/ui/screens_common/auth/basic_info/basic_info_screen.dart';
import 'package:rent_home/widgets/option_button.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../auth_controller.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final AuthController authController = Get.find<AuthController>();
  bool isLogin = true;
  bool passwordObscure = true;
  bool confirmPasswordObscure = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final userType = 0.obs;
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letters';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain lowercase letters';
    }
    return null;
  }

  final List<String> imagePaths = [
    'assets/home_1.jpg',
    'assets/home_2.jpg',
    'assets/home_3.jpg',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Background Image Stack
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 450,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 3),
                  autoPlayAnimationDuration: const Duration(milliseconds: 300),
                  viewportFraction: 1,
                  enlargeCenterPage: false,
                  scrollPhysics:
                      const NeverScrollableScrollPhysics(), // Disable sliding
                ),
                items: imagePaths.map((imagePath) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        height: 450,
                        width: double.infinity,
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            // White Opacity Layer
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 450,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            AssetImage("assets/aajoo_new_logo.png"),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Aajoo",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            // Bottom Rounded Container for Form
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40.0),
                    topRight: Radius.circular(40.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLogin ? "Login to Your Account" : "Create Your Account",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isLogin
                          ? "Welcome back! Please enter your credentials to log in."
                          : "Sign up to explore the best homes.",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              prefixIcon:
                                  Icon(Icons.email, color: theme.primaryColor),
                              hintText: "Email",
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegex =
                                  RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passwordController,
                            obscureText: passwordObscure,
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    passwordObscure = !passwordObscure;
                                  });
                                },
                                icon: Icon(
                                  passwordObscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              prefixIcon:
                                  Icon(Icons.lock, color: theme.primaryColor),
                              hintText: "Password",
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: validatePassword,
                          ),
                          if (!isLogin)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: TextFormField(
                                controller: confirmPasswordController,
                                obscureText: confirmPasswordObscure,
                                decoration: InputDecoration(
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        confirmPasswordObscure =
                                            !confirmPasswordObscure;
                                      });
                                    },
                                    icon: Icon(
                                      confirmPasswordObscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                  prefixIcon: Icon(Icons.lock,
                                      color: theme.primaryColor),
                                  hintText: "Confirm Password",
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value != passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          const SizedBox(
                            height: 10,
                          ),
                          Visibility(
                              visible: isLogin,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                      onPressed: () =>
                                          {Get.toNamed('/forgot-password')},
                                      child: const Text(
                                        "Forgot Password",
                                        style: TextStyle(
                                            fontSize: 13,
                                            decoration:
                                                TextDecoration.underline),
                                      ))
                                ],
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    ...[
                      OptionButton(
                        onOptionSelected: (int selectedOption) {
                          // Handle the selected option here
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              userType.value = selectedOption;
                            });
                          });
                          // userType.value = selectedOption;
                        },
                      ),
                      const SizedBox(height: 30),
                    ],

                    // Login/Signup Button
                    SizedBox(
                      width: double.infinity,
                      child: Obx(() => ElevatedButton(
                            onPressed: authController.isLoading.value
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      if (isLogin) {
                                        await authController
                                            .login(
                                          emailController.text,
                                          passwordController.text,
                                          userType.value == 1,
                                        )
                                            .then((_) {
                                          if (authController
                                              .error.value.isEmpty) {
                                            final user =
                                                authController.userData.value;
                                            if (user!.isHost) {
                                              Get.offAllNamed('/host/home');
                                            } else {
                                              Get.offAllNamed('/home');
                                            }
                                          } else {
                                            // Handle error message here
                                            print(
                                                'Error: ${authController.error.value}');
                                          }
                                        });
                                        if (authController.error.value.isEmpty)
                                          ;
                                      } else {
                                        await authController
                                            .checkEmailAlreadyExists(
                                                emailController.text);
                                        if (authController
                                            .error.value.isEmpty) {
                                          authController.signupData({
                                            'user_email': emailController.text,
                                            'user_password':
                                                passwordController.text,
                                            'user_confirmPassword':
                                                confirmPasswordController.text,
                                            'user_isHost': userType.value == 1,
                                          });
                                          print(
                                              'User Type: ${userType.value} ${authController.signupData.value}');
                                          Get.to(() => const InfoScreen());
                                        } else {
                                          // Handle error message here
                                          print(
                                              'Error: ${authController.error.value}');
                                        }
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const StadiumBorder(),
                            ),
                            child: authController.isLoading.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isLogin ? "Login" : "Next",
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          )),
                    ),

                    // Toggle Login/Signup
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            isLogin = !isLogin;
                            authController.error.value = ''; // Clear any errors
                          });
                        },
                        child: Text(
                          isLogin
                              ? "Don't have an account? Sign up"
                              : "Already have an account? Login",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
