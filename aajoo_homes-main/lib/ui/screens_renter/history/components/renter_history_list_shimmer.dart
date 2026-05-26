import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class RenterHistoryListShimmerView extends StatelessWidget {
  const RenterHistoryListShimmerView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ));
      },
      itemCount: 5,
    );
  }
}
