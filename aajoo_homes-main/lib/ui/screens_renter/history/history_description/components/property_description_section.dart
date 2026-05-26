import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class PropertyDescriptionSection extends StatelessWidget {
  const PropertyDescriptionSection({
    super.key,
    required this.isLoading,
    required this.propertyName,
    required this.propertyAddress,
    required this.bookingDataWidget,
  });

  final RxBool isLoading;
  final String? propertyName;
  final String? propertyAddress;
  final Widget bookingDataWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Obx(() {
        if (isLoading.value) {
          return const PropertyDescriptionShimmer();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _PropertyTitle(),
            SizedBox(height: 6),
            _PropertyAddress(),
            SizedBox(height: 14),
            Divider(thickness: 0.8),
            SizedBox(height: 8),
            _BookingSection(),
            SizedBox(height: 8),
            Divider(thickness: 0.8),
          ],
        );
      }),
    );
  }
}

class _PropertyTitle extends StatelessWidget {
  const _PropertyTitle();

  @override
  Widget build(BuildContext context) {
    final title = context
        .findAncestorWidgetOfExactType<PropertyDescriptionSection>()
        ?.propertyName;

    if (title == null || title.isEmpty) return const SizedBox.shrink();

    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
    );
  }
}

class _PropertyAddress extends StatelessWidget {
  const _PropertyAddress();

  @override
  Widget build(BuildContext context) {
    final address = context
        .findAncestorWidgetOfExactType<PropertyDescriptionSection>()
        ?.propertyAddress;

    if (address == null || address.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 18,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            address,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}

class _BookingSection extends StatelessWidget {
  const _BookingSection();

  @override
  Widget build(BuildContext context) {
    final bookingWidget = context
        .findAncestorWidgetOfExactType<PropertyDescriptionSection>()
        ?.bookingDataWidget;

    return bookingWidget ?? const SizedBox.shrink();
  }
}

class PropertyDescriptionShimmer extends StatelessWidget {
  const PropertyDescriptionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷️ Property Title
          _shimmerLine(height: 22, width: 200),
          const SizedBox(height: 8),

          // 📍 Address
          _shimmerLine(height: 14, width: double.infinity),
          const SizedBox(height: 6),
          _shimmerLine(height: 14, width: 260),

          const SizedBox(height: 14),
          _softDivider(),

          const SizedBox(height: 10),

          // 📦 Booking info rows
          _bookingRow(),
          const SizedBox(height: 8),
          _bookingRow(),

          const SizedBox(height: 12),
          _softDivider(),
        ],
      ),
    );
  }

  Widget _shimmerLine({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _bookingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _shimmerLine(height: 13, width: 110),
        _shimmerLine(height: 13, width: 70),
      ],
    );
  }

  Widget _softDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      color: Colors.grey.shade300,
    );
  }
}
