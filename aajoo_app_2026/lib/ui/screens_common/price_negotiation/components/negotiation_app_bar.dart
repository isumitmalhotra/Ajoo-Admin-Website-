import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/ui/screens_common/price_negotiation/negotiation_controller.dart';
import 'package:rent_home/utils/money.dart';

class NegotiationAppBar extends StatelessWidget {
  final Property property;
  final NegotiationController negotiationController;

  const NegotiationAppBar({
    super.key,
    required this.property,
    required this.negotiationController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: theme.primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          negotiationController.disconnectSocket();
          Navigator.pop(context);
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          property.propertyName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    property.coverImage != null
                        ? property.coverImage.toString()
                        : '',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: kLine,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.broken_image,
                        size: 60,
                        color: kMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        property.propertyAddress,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Base: ${rupees(double.parse(property.propertyPrice))}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        property.propertyDesc,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
