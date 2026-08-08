import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/static_page_controller.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:rent_home/widgets/social_row.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcontentColor,
      appBar: AppBar(
        title: const Text('Contact Support'),
        backgroundColor: kprimaryColor,
        foregroundColor: kscaffoldColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ContactInfoSection(),
            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Text('Frequently asked Questions',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600)),
            ),
            const Expanded(child: FAQSection()),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const SocialRow(
              rowAlignment: MainAxisAlignment.spaceEvenly,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class ContactInfoSection extends StatelessWidget {
  const ContactInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            // Handle tap on customer service
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
            child: Row(
              children: [
                const ContactRow(
                  icon: Icons.phone,
                  label: 'Our 24x7 Customer Service',
                  contactInfo: '+91 96252 36254',
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    DeviceService.launchWhatsapp(
                        phoneNumber: "9317236254",
                        message:
                            "Hello Aajoo Homes, I need assistance regarding the Aajoo Homes app.");
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kprimaryColor.withOpacity(0.1),
                    ),
                    child: Image.asset(
                      'assets/whatsapp.png',
                      width: 25,
                      height: 25,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            // Handle tap on email
            final Uri emailUri =
                Uri(scheme: 'mailto', path: 'naaajoolive@gmail.com');
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
              label: 'Write us at',
              contactInfo: 'aajoolive@gmail.com',
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            // Handle tap on website
            final Uri websiteUri = Uri.parse('https://aajoohomes.com/');
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
              icon: Icons.web_rounded,
              label: 'Visit our website for more information.',
              contactInfo: 'aajoohomes.com',
            ),
          ),
        ),
      ],
    );
  }
}

class ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String contactInfo;

  const ContactRow({super.key, 
    required this.icon,
    required this.label,
    required this.contactInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: kcontentColor,
          radius: 25,
          child: Icon(icon, color: kprimaryColor),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w400, fontSize: 13)),
            const SizedBox(height: 2),
            Text(contactInfo,
                style: const TextStyle(
                    color: kprimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
          ],
        ),
      ],
    );
  }
}

class FAQSection extends StatefulWidget {
  const FAQSection({super.key});

  @override
  State<FAQSection> createState() => _FAQSectionState();
}

class _FAQSectionState extends State<FAQSection> {
  late StaticPageController _staticPageController;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<StaticPageController>()) {
      _staticPageController = Get.put(StaticPageController());
    } else {
      _staticPageController = Get.find<StaticPageController>();
    }
    _staticPageController.getFaqData();
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
      child: Obx(() {
        if (_staticPageController.isLoading.value) {
          //shimmer
          return Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade200,
              child: ListView.builder(
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      height: 50,
                      width: double.infinity,
                      color: Colors.white,
                    );
                  }));
        }
        final faqData = _staticPageController.faqData.value?.data.faqData;
        if (faqData == null) {
          return const Center(child: Text("No data available"));
        }
        return ListView.builder(
          itemCount: faqData.length,
          itemBuilder: (context, index) {
            final faq = faqData[index];
            return FAQTile(question: faq.title, answer: faq.description);
          },
        );
      }),
    );
  }
}

class FAQTile extends StatefulWidget {
  final String question;
  final String answer;

  const FAQTile({super.key, required this.question, required this.answer});

  @override
  State<FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<FAQTile> {
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
            ),
          ),
        ),
      ],
    );
  }
}
