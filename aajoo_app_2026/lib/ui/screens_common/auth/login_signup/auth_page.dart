// Login / Sign-up — re-skinned to the new teal/orange design (scaffold
// login_screen.dart). Visual layer only; ALL auth wiring preserved verbatim:
// AuthController.login() + isHost routing, signup → InfoScreen, forgot password,
// OptionButton guest/host toggle, validators.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/ui/screens_common/auth/basic_info/basic_info_screen.dart';
import 'package:rent_home/widgets/option_button.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/input_sanitizers.dart';
import 'package:rent_home/ui/widgets/password_rules_checklist.dart';
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
    // The canonical policy (password_rules_checklist.dart mirrors the backend
    // schema). A private list here missed the special-character rule, so a
    // signup could pass this form and still be refused by the server.
    return validateAgainstPasswordRules(value);
  }

  final List<String> imagePaths = [
    'assets/home_1.jpg',
    'assets/home_2.jpg',
    'assets/home_3.jpg',
  ];

  // Field decoration in the new design — filled cream, teal focus, no hard border.
  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        prefixIcon: Icon(icon, color: kIndigo, size: 20),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: inter(color: kMuted, fontSize: 14),
        filled: true,
        fillColor: kSand,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kLine)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kIndigo, width: 1.4)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      // SizedBox.expand is load-bearing. A Stack sizes itself to its
      // NON-positioned children, and every child here is Positioned, so
      // without it the Stack collapses to nothing and `bottom: 0` on the form
      // sheet anchors near the top of the screen — the card then extends
      // upward off-screen and the only thing visible is its bottom edge.
      // That was the "blank page after tapping Explore": the login form was
      // rendering, just almost entirely above the top of the display.
      body: SizedBox.expand(
        child: Stack(
        children: [
          // Hero image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CarouselSlider(
              options: CarouselOptions(
                height: 430,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                autoPlayAnimationDuration: const Duration(milliseconds: 300),
                viewportFraction: 1,
                enlargeCenterPage: false,
                scrollPhysics: const NeverScrollableScrollPhysics(),
              ),
              items: imagePaths.map((imagePath) {
                return Image.asset(imagePath,
                    fit: BoxFit.cover, height: 430, width: double.infinity,
                    errorBuilder: (_, __, ___) =>
                        Container(height: 430, color: kSand));
              }).toList(),
            ),
          ),
          // Legibility scrim
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 430,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.18),
                      Colors.transparent,
                      kCream.withOpacity(0.15),
                    ],
                    stops: const [0, 0.4, 1]),
              ),
            ),
          ),
          // Brand
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage('assets/aajoo_new_logo.png')),
                const SizedBox(width: 8),
                Text('aajoo',
                    style: fraunces(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ]),
            ),
            ),
          ),
          // Form sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.72),
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                      color: Color(0x1A0F172A),
                      blurRadius: 20,
                      offset: Offset(0, -6)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLogin ? 'Welcome back' : 'Create your account',
                      style: fraunces(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: kInk),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isLogin
                          ? 'Log in to continue to your stays.'
                          : 'Sign up to explore the best homes across India.',
                      style: inter(fontSize: 14, color: kMuted),
                    ),
                    const SizedBox(height: 22),
                    Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters: AppInputFormatters.email,
                            decoration: _dec('Email', Icons.mail_outline),
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
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: passwordController,
                            obscureText: passwordObscure,
                            decoration: _dec('Password', Icons.lock_outline,
                                suffix: IconButton(
                                  onPressed: () => setState(() =>
                                      passwordObscure = !passwordObscure),
                                  icon: Icon(
                                      passwordObscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: kMuted, size: 20),
                                )),
                            // Strict shape only when CREATING the password.
                            // On login the stored password is whatever it is —
                            // a stricter rule here would lock those users out.
                            validator: (v) => isLogin
                                ? ((v == null || v.isEmpty)
                                    ? 'Please enter your password'
                                    : null)
                                : validatePassword(v),
                            onChanged: isLogin
                                ? null
                                : (_) => setState(() {}),
                          ),
                          if (!isLogin)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              // The list of what the input expects, ticking
                              // live — not a surprise rejection after Submit.
                              child: PasswordRulesChecklist(
                                  password: passwordController.text),
                            ),
                          if (!isLogin)
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: TextFormField(
                                controller: confirmPasswordController,
                                obscureText: confirmPasswordObscure,
                                decoration: _dec(
                                    'Confirm Password', Icons.lock_outline,
                                    suffix: IconButton(
                                      onPressed: () => setState(() =>
                                          confirmPasswordObscure =
                                              !confirmPasswordObscure),
                                      icon: Icon(
                                          confirmPasswordObscure
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: kMuted, size: 20),
                                    )),
                                validator: (value) {
                                  if (value != passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          const SizedBox(height: 6),
                          Visibility(
                            visible: isLogin,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    {Get.toNamed('/forgot-password')},
                                child: Text('Forgot Password?',
                                    style: inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: kIndigo)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Guest / Host toggle (shared widget — picks up teal theme)
                    OptionButton(
                      initialSelection: userType.value,
                      onOptionSelected: (int selectedOption) {
                        userType.value = selectedOption;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Login / Sign-up button — LOGIC PRESERVED VERBATIM
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
                                          final user =
                                              authController.userData.value;
                                          if (authController
                                                  .error.value.isEmpty &&
                                              user != null) {
                                            if (user.isHost) {
                                              Get.offAllNamed('/host/home');
                                            } else {
                                              Get.offAllNamed('/home');
                                            }
                                          }
                                        });
                                        if (authController
                                            .error.value.isEmpty) {}
                                      } else {
                                        await authController
                                            .checkEmailAlreadyExists(
                                                emailController.text);
                                        if (authController
                                            .error.value.isEmpty) {
                                          final emailVal =
                                              emailController.text.trim();
                                          final passVal =
                                              passwordController.text;
                                          final confirmVal =
                                              confirmPasswordController.text;
                                          final hostVal = userType.value == 1;
                                          authController.authEmail.value =
                                              emailVal;
                                          authController.authPassword.value =
                                              passVal;
                                          authController
                                              .authConfirmPassword.value =
                                              confirmVal;
                                          authController.authIsHost.value =
                                              hostVal;
                                          authController.signupData[
                                              'user_email'] = emailVal;
                                          authController.signupData[
                                              'user_password'] = passVal;
                                          authController.signupData[
                                                  'user_confirmPassword'] =
                                              confirmVal;
                                          authController.signupData[
                                              'user_isHost'] = hostVal;
                                          Get.to(() => const InfoScreen());
                                        } else {
                                          print(
                                              'Error: ${authController.error.value}');
                                        }
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kIndigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: authController.isLoading.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(isLogin ? 'Login' : 'Next',
                                    style: inter(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                          )),
                    ),

                    // "Continue with Google" — on BOTH tabs.
                    //
                    // It used to be login-only, on the reasoning that sign-up
                    // collects KYC which Google cannot supply. But the server
                    // already handles exactly that: /user/auth/google CREATES
                    // the account when it does not exist, marks it verified
                    // (Google has proven the address, so our OTP step has
                    // nothing left to establish) and returns the list of
                    // profile gaps to fill in later.
                    //
                    // So Google sign-up worked the whole time — it was simply
                    // unreachable from the tab where someone creating an account
                    // would look for it, which is what "signup with google is
                    // missing when new account create" describes.
                    ...[
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(child: Divider(color: kMuted.withOpacity(.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or',
                              style: inter(fontSize: 12.5, color: kMuted)),
                        ),
                        Expanded(child: Divider(color: kMuted.withOpacity(.3))),
                      ]),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: Obx(() => OutlinedButton.icon(
                              onPressed: authController.isLoading.value
                                  ? null
                                  : () => authController
                                          .loginWithGoogle(userType.value == 1)
                                          .then((_) {
                                        final user =
                                            authController.userData.value;
                                        if (authController.error.value.isEmpty &&
                                            user != null) {
                                          Get.offAllNamed(user.isHost
                                              ? '/host/home'
                                              : '/home');
                                        }
                                      }),
                              // Google requires their own "G" mark on this
                              // button. The asset is not in the repo yet, so
                              // until it is dropped into assets/images/ the
                              // button renders text-only — an arrow icon read
                              // as "generic login" and drawing our own G would
                              // be a poor imitation of someone's trademark.
                              icon: Image.asset('assets/images/google.png',
                                  height: 18,
                                  width: 18,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink()),
                              label: Text(
                                  isLogin
                                      ? 'Continue with Google'
                                      : 'Sign up with Google',
                                  style: inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: kMuted.withOpacity(.35)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            )),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            isLogin = !isLogin;
                            authController.error.value = '';
                          });
                        },
                        child: RichText(
                          text: TextSpan(
                            style: inter(fontSize: 13.5, color: kMuted),
                            children: [
                              TextSpan(
                                  text: isLogin
                                      ? "Don't have an account?  "
                                      : 'Already have an account?  '),
                              TextSpan(
                                  text: isLogin ? 'Sign up' : 'Login',
                                  style: inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: kIndigo)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
