import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/static_page_controller.dart';
import 'package:shimmer/shimmer.dart';

class AboutPage extends StatefulWidget {
  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late StaticPageController _staticPageController;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<StaticPageController>()) {
      _staticPageController = Get.put(StaticPageController());
    } else {
      _staticPageController = Get.find<StaticPageController>();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _staticPageController.getAboutUsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: kcontentColor,
      appBar: AppBar(
        title: const Text("About Aajoo"),
        centerTitle: true,
        backgroundColor: kprimaryColor,
        foregroundColor: kscaffoldColor,
      ),
      body: Obx(() {
        if (_staticPageController.isLoading.value) {
          return _buildShimmerLoading();
        }
        final aboutUsData =
            _staticPageController.aboutUsData.value?.data.aboutData;
        if (aboutUsData == null) {
          return Center(child: Text("No data available"));
        }
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
                      const AssetImage("assets/aajoo_new_logo.png"),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text(
                      "Aajoo",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      aboutUsData.quote.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Section(
                  title: "About Us", content: aboutUsData.aboutUs.toString()),
              Section(
                  title: "Our Mission",
                  content: aboutUsData.ourMission.toString()),
              Section(
                  title: "Our Vision",
                  content: aboutUsData.ourVision.toString()),
              Text(
                "Key Features",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              FeatureTile(
                icon: Icons.location_on,
                title: "Walking Distance Optimization",
                description: aboutUsData
                    .whatMakesUsDifferent!.walkingDistanceOptimization
                    .toString(),
              ),
              FeatureTile(
                icon: Icons.attach_money,
                title: "Price Negotiation",
                description: aboutUsData.whatMakesUsDifferent!.priceNegotiation
                    .toString(),
              ),
              FeatureTile(
                icon: Icons.hotel,
                title: "Luxurious Options",
                description: aboutUsData.whatMakesUsDifferent!.luxuriousOptions
                    .toString(),
              ),
              FeatureTile(
                icon: Icons.security,
                title: "Safety and Trust",
                description:
                    aboutUsData.whatMakesUsDifferent!.safetyAndTrust.toString(),
              ),
              FeatureTile(
                icon: Icons.feedback,
                title: "Feedback-Driven",
                description:
                    aboutUsData.whatMakesUsDifferent!.feedbackDriven.toString(),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: CircleAvatar(radius: 60),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16.0),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 20,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ],
                ));
          },
        ),
      ]),
    );
  }
}

class Section extends StatelessWidget {
  final String title;
  final String content;

  const Section({
    Key? key,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
