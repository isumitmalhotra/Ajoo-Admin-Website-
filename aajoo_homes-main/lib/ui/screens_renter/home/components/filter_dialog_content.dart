import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/common_controller.dart';

class FilterDialogContent extends StatefulWidget {
  final Function(int selectedCategory, double selectedRadius,
      double? weeklyPrice, double? monthlyPrice) onApply;

  const FilterDialogContent({super.key, required this.onApply});

  @override
  State<FilterDialogContent> createState() => _FilterDialogContentState();
}

class _FilterDialogContentState extends State<FilterDialogContent> {
  String? selectedCategory;
  double selectedRadius = 1.0;
  double weeklyPrice = 500.0; // Default weekly price
  double monthlyPrice = 2000.0; // Default monthly price
  bool weeklyAny = false;
  bool monthlyAny = false;

  final CommonController commonController = Get.put(CommonController());

  @override
  void initState() {
    super.initState();
    commonController.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Obx(() {
        // Handle loading state
        if (commonController.cats.value == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: kprimaryColor,
            ),
          );
        }

        // Handle empty categories
        if (commonController.cats.value!.data.categories.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No categories available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // Initialize selectedCategory if not set
        selectedCategory ??=
            commonController.cats.value!.data.categories[0].catTitle;

        return Container(
          padding: const EdgeInsets.all(20.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Filter Properties',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),

              // Category Dropdown
              // _buildSectionTitle('Property Category'),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 12),
              //   decoration: BoxDecoration(
              //     border:
              //         Border.all(color: theme.primaryColor.withOpacity(0.3)),
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   child: DropdownButton<String>(
              //     isExpanded: true,
              //     focusColor: Colors.transparent,
              //     value: selectedCategory,
              //     icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
              //     iconSize: 24,
              //     underline: const SizedBox(),
              //     onChanged: (String? newValue) {
              //       setState(() {
              //         selectedCategory = newValue!;
              //       });
              //     },
              //     items: commonController.cats.value!.data.categories
              //         .map<DropdownMenuItem<String>>((category) {
              //       return DropdownMenuItem<String>(
              //         value: category.catTitle,
              //         child: Text(
              //           category.catTitle.capitalizeFirst!,
              //           style: TextStyle(
              //             fontSize: 16,
              //             color: theme.primaryColor,
              //           ),
              //         ),
              //       );
              //     }).toList(),
              //   ),
              // ),
              const SizedBox(height: 20),

              // Radius Slider
              _buildSectionTitle('Search Radius (km)'),
              _buildSlider(
                value: selectedRadius,
                min: 1,
                max: 15,
                divisions: 14,
                label: '${selectedRadius.round()} km',
                onChanged: (double newValue) {
                  setState(() {
                    selectedRadius = newValue;
                  });
                },
              ),

              // Weekly Price Slider
              _buildSectionTitle('Weekly Price (₹)'),
              _buildSlider(
                value: weeklyAny ? 500.0 : weeklyPrice,
                min: 100,
                max: 5000,
                divisions: 49,
                label: weeklyAny ? 'Any' : '₹${weeklyPrice.round()}',
                onChanged: (double newValue) {
                  setState(() {
                    weeklyPrice = newValue;
                  });
                },
                allowAny: true,
                onAnyToggle: (bool isAny) {
                  setState(() {
                    weeklyAny = isAny;
                  });
                },
                anyChecked: weeklyAny,
              ),

              // Monthly Price Slider
              _buildSectionTitle('Monthly Price (₹)'),
              _buildSlider(
                value: monthlyAny ? 2000.0 : monthlyPrice,
                min: 500,
                max: 20000,
                divisions: 39,
                label: monthlyAny ? 'Any' : '₹${monthlyPrice.round()}',
                onChanged: (double newValue) {
                  setState(() {
                    monthlyPrice = newValue;
                  });
                },
                allowAny: true,
                onAnyToggle: (bool isAny) {
                  setState(() {
                    monthlyAny = isAny;
                  });
                },
                anyChecked: monthlyAny,
              ),

              const SizedBox(height: 20),

              // Buttons
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: theme.primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      int selectedCategoryId = commonController
                          .cats.value!.data.categories
                          .firstWhere((category) =>
                              category.catTitle == selectedCategory)
                          .catId;

                      widget.onApply(
                        selectedCategoryId,
                        selectedRadius,
                        weeklyAny ? null : weeklyPrice,
                        monthlyAny ? null : monthlyPrice,
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Apply',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      side: BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Cancel',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required Function(double) onChanged,
    bool allowAny = false,
    Function(bool)? onAnyToggle,
    bool anyChecked = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            if (allowAny)
              Row(
                children: [
                  const Text(
                    'Any',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  Checkbox(
                    value: anyChecked,
                    onChanged: (bool? isChecked) {
                      onAnyToggle?.call(isChecked ?? false);
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          onChanged: (double newValue) {
            onChanged(newValue);
          },
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ],
    );
  }
}
