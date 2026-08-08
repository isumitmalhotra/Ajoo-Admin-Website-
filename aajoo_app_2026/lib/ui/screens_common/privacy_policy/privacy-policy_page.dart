import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/controller/static_page_controller.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final AuthController authController = Get.find<AuthController>();
  final StaticPageController staticController =
      Get.put<StaticPageController>(StaticPageController());
  bool isHost = false;

  @override
  void initState() {
    super.initState();
    isHost = authController.userData.value?.isHost ?? false;
    staticController.getPrivacyPolicyData(isHost);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Privacy & Policies'),
        backgroundColor: kprimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        // Check if data is loading
        if (staticController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: kprimaryColor,
            ),
          );
        }
        // Check if privacy policy data is null
        if (staticController.privacyPolicy.value == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.warning_2, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No policy data available',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        // Get the privacy policy data
        final privacyPolicy = staticController.privacyPolicy.value!['data']
                ['privacyPolicy'] as Map<String, dynamic>? ??
            {};

        // Static placeholder data for new sections
        final Map<String, dynamic> additionalPolicies = {
          'Static Booking Policy': [
            'Static bookings require a minimum stay of 30 days.',
            'Full payment is required upfront.',
            'Cancellations must be made 14 days prior to check-in for a full refund.',
          ],
          'Weekly Booking Policy': [
            'Weekly bookings require a minimum stay of 7 days.',
            'A 50% deposit is required at booking.',
            'Cancellations within 48 hours of booking are fully refundable.',
          ],
          'Check-in/Check-out Policies': [
            'Check-in time is after 3:00 PM.',
            'Check-out time is before 11:00 AM.',
            'Early check-in or late check-out may incur additional fees.',
          ],
        };
        privacyPolicy.remove("footer");

        // Combine privacy policy and additional policies
        final allPolicies = {...privacyPolicy, ...additionalPolicies};

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: allPolicies.entries.map<Widget>((entry) {
            final heading = entry.key;
            final value = entry.value;

            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading with icon
                    Visibility(
                      visible: heading != "Header",
                      child: Row(
                        children: [
                          Icon(
                            _getSectionIcon(heading),
                            color: kprimaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              heading,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Content (string or list of strings)
                    if (value is String)
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: heading == "Header"
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      )
                    else if (value is List<dynamic>)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: value.map<Widget>((item) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Iconsax.arrow_right_3,
                                  size: 16,
                                  color: kprimaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  // Helper method to assign icons based on section heading
  IconData _getSectionIcon(String heading) {
    switch (heading.toLowerCase()) {
      case 'introduction':
        return Iconsax.document_text;
      case 'information we collect':
        return Iconsax.info_circle;
      case 'how we use your information':
        return Iconsax.cpu;
      case 'sharing your information':
        return Iconsax.share;
      case 'security':
        return Iconsax.shield_tick;
      case 'your rights':
        return Iconsax.user;
      case 'static booking policy':
        return Iconsax.calendar;
      case 'weekly booking policy':
        return Iconsax.calendar_1;
      case 'check-in/check-out policies':
        return Iconsax.clock;
      default:
        return Iconsax.note;
    }
  }
}
