import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/static_page_controller.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class HostSupportScreen extends StatelessWidget {
  const HostSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcontentColor,
      appBar: AppBar(
        title: Text('Host Support'),
        backgroundColor: kprimaryColor,
        foregroundColor: kscaffoldColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HostContactInfoSection(),
              const SizedBox(height: 10),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: Text('Host Frequently Asked Questions',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600)),
              ),
              HostFAQSection()
            ],
          ),
        ),
      ),
    );
  }
}

class HostContactInfoSection extends StatelessWidget {
  const HostContactInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Host Dedicated Support
        GestureDetector(
          onTap: () {
            final Uri phoneUri = Uri(scheme: 'tel', path: '+919625236254');
            launchUrl(phoneUri);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 3),
                  )
                ],
                color: kscaffoldColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ContactRow(
                  icon: Icons.support_agent,
                  label: 'Host Dedicated Support Team',
                  contactInfo: '+91 96252 36254',
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  _circleActionButton(
                    icon: Image.asset(
                      'assets/whatsapp.png',
                      width: 22,
                      height: 22,
                    ),
                    bgColor: kprimaryColor.withOpacity(0.1),
                    onTap: () {
                      DeviceService.launchWhatsapp(
                        phoneNumber: "7973918722",
                        message: "hello, i need assistance",
                      );
                    },
                  ),

                  const SizedBox(width: 12),
                  // Support Agent Button
                  _circleActionButton(
                    icon: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    bgColor: kprimaryColor,
                    onTap: () {
                      Get.toNamed(
                        '/webview',
                        arguments: {
                          'url':
                              'https://window-2.botpenguin.com/69803a093817049868bf064f/696f4cdf88f4a8046c67188e',
                          'title': 'Support Chat',
                        },
                      );
                    },
                  ),
                ])
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Property Management Email
        GestureDetector(
          onTap: () {
            final Uri emailUri =
                Uri(scheme: 'mailto', path: 'aajoolive@gmail.com');
            launchUrl(emailUri);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 3),
                  )
                ],
                color: kscaffoldColor),
            child: const ContactRow(
              icon: Icons.email,
              label: 'Property Management Support',
              contactInfo: 'aajoolive@gmail.com',
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Emergency Support
        GestureDetector(
          onTap: () {
            final Uri phoneUri = Uri(scheme: 'tel', path: '+919317236254');
            launchUrl(phoneUri);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 3),
                  )
                ],
                color: Colors.red.shade50),
            child: const ContactRow(
              icon: Icons.emergency,
              label: 'Emergency Property Support',
              contactInfo: '+91 93172 36254',
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Host Portal Website
        GestureDetector(
          onTap: () {
            final Uri websiteUri = Uri.parse('https://aajoohomes.com/host');
            launchUrl(websiteUri);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 3),
                  )
                ],
                color: kscaffoldColor),
            child: const ContactRow(
              icon: Icons.dashboard,
              label: 'Visit Host Portal for analytics',
              contactInfo: 'aajoohomes.com/host',
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleActionButton({
    required Widget icon,
    required VoidCallback onTap,
    required Color bgColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
        ),
        child: icon,
      ),
    );
  }
}

class ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String contactInfo;

  const ContactRow({
    required this.icon,
    required this.label,
    required this.contactInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: kcontentColor,
          radius: 25,
          child: Icon(icon, color: kprimaryColor),
        ),
        const SizedBox(width: 15),

        /// 👇 THIS IS IMPORTANT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                contactInfo,
                maxLines: 2, // 👈 allows 2 lines
                overflow:
                    TextOverflow.ellipsis, // 👈 prevents overflow after 2 lines
                softWrap: true,
                style: const TextStyle(
                  color: kprimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HostFAQSection extends StatefulWidget {
  @override
  State<HostFAQSection> createState() => _HostFAQSectionState();
}

class _HostFAQSectionState extends State<HostFAQSection> {
  late StaticPageController _staticPageController;

  // Host-specific FAQ data
  final List<Map<String, String>> hostFAQs = [
    {
      'question': 'How do I list my property on Aajoo Homes?',
      'answer':
          'To list your property, go to the "Add Property" section in your host dashboard. Fill in all required details including property photos, amenities, pricing, and availability. Our team will review and approve your listing within 24-48 hours.'
    },
    {
      'question': 'What commission does Aajoo Homes charge?',
      'answer':
          'Aajoo Homes charges a competitive commission rate of 15-20% depending on your property type and location. This includes marketing, customer support, payment processing, and platform maintenance.'
    },
    {
      'question': 'How do I manage bookings and check-ins?',
      'answer':
          'Use the host dashboard to view all bookings, manage availability, and communicate with guests. You can update booking status, handle check-ins/check-outs, and resolve any issues through the platform.'
    },
    {
      'question': 'When do I receive payments for bookings?',
      'answer':
          'Payments are processed within 24-48 hours after successful guest check-in. Funds are transferred to your registered bank account. You can track all transactions in the "Earnings" section of your dashboard.'
    },
    {
      'question': 'How do I handle cancellations?',
      'answer':
          'Cancellation policies are set when you list your property. The platform automatically handles cancellations according to your policy. You will be notified of any cancellations and refunds will be processed accordingly.'
    },
    {
      'question': 'What support is available for property maintenance issues?',
      'answer':
          'Contact our emergency support line for urgent property issues. For regular maintenance, you can schedule services through our partner network or handle them independently and update the property status accordingly.'
    },
    {
      'question': 'How do I update my property details or pricing?',
      'answer':
          'Log into your host dashboard and navigate to "My Properties". Select the property you want to edit and update details, photos, pricing, or availability. Changes are reflected immediately on the platform.'
    },
    {
      'question': 'What happens if there are issues with guests?',
      'answer':
          'Report any guest-related issues through the support system. Our team mediates between hosts and guests to resolve conflicts. For serious violations, we may take action including guest account suspension.'
    }
  ];

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<StaticPageController>()) {
      _staticPageController = Get.put(StaticPageController());
    } else {
      _staticPageController = Get.find<StaticPageController>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 3),
            )
          ],
          color: kscaffoldColor),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: hostFAQs.length,
        itemBuilder: (context, index) {
          final faq = hostFAQs[index];
          return HostFAQTile(
            question: faq['question']!,
            answer: faq['answer']!,
          );
        },
      ),
    );
  }
}

class HostFAQTile extends StatefulWidget {
  final String question;
  final String answer;

  const HostFAQTile({super.key, required this.question, required this.answer});

  @override
  State<HostFAQTile> createState() => _HostFAQTileState();
}

class _HostFAQTileState extends State<HostFAQTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        widget.question,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
      trailing: Icon(
        isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
        color: kprimaryColor,
      ),
      collapsedTextColor: Colors.grey.shade800,
      onExpansionChanged: (value) {
        setState(() {
          isExpanded = value;
        });
      },
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            widget.answer,
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
