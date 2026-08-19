import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/static_page_controller.dart';
// import 'package:rent_home/controllers/static_page_controller.dart';

class TermsPage extends StatefulWidget {
  /// When true, fetches the host-specific terms (`common/term-condition-host`)
  /// instead of the renter terms. Defaults to renter terms so existing callers
  /// are unaffected.
  final bool isHost;

  const TermsPage({super.key, this.isHost = false});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  final StaticPageController _controller = Get.put(StaticPageController());

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.getTermsData(isHost: widget.isHost);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isHost ? "Host Terms & Conditions" : "Terms & Conditions"),
        centerTitle: true,
        backgroundColor: kSand,
        foregroundColor: kInk,
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return Center(
              child: CircularProgressIndicator(
            color: theme.primaryColor,
          ));
        } else if (_controller.terms.value == null) {
          return const Center(child: Text("No data available"));
        }

        final termsData = _controller.terms.value!;
        final sections = termsData.data?.termsAndCondion ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      AssetImage("assets/aajoo_new_logo.png"),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text(
                      widget.isHost
                          ? "Host Terms & Conditions"
                          : "Terms & Conditions",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please read these terms carefully before using our platform.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              for (var section in sections.entries)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.key,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (var term in section.value)
                      TermsConditionItem(
                        title: term,
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
            ],
          ),
        );
      }),
    );
  }
}

class TermsConditionItem extends StatelessWidget {
  final String title;

  const TermsConditionItem({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Iconsax.paperclip4, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
