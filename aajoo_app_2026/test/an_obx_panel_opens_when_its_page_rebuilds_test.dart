// The listing's booking panel is built inside an Obx (it watches
// bookingController.isLoading) and opens when the page's own setState flips
// isExpanded — "Negotiate & Reserve" calls _toggleExpanded. That is the main
// conversion path, so the GetX 4.6.6 -> 4.7.3 bump (D5, snackbars) must not
// change how an Obx rebuilds when its parent does.
//
// This pins it with a real tap in the test, the same shape as the page: a
// StatefulWidget whose setState flips a plain field, read inside an Obx that
// also reads an observable. (On the Simulator the panel was driven through
// the VM service, whose setState lands outside a tap's frame timing — this is
// the instrument-free version.)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Booking extends GetxController {
  final isLoading = false.obs;
}

class _Page extends StatefulWidget {
  const _Page();
  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  final booking = _Booking();
  bool isExpanded = false;

  void _toggleExpanded() => setState(() => isExpanded = !isExpanded);

  Widget _buildBottomSheet() => isExpanded
      ? const Text('View Details')
      : ElevatedButton(
          onPressed: _toggleExpanded, child: const Text('Negotiate & Reserve'));

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(() => booking.isLoading.value
                ? const CircularProgressIndicator()
                : _buildBottomSheet()),
          ),
        ]),
      );
}

void main() {
  testWidgets('a tap on Negotiate & Reserve opens the panel inside the Obx',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: _Page()));
    expect(find.text('Negotiate & Reserve'), findsOneWidget);

    await tester.tap(find.text('Negotiate & Reserve'));
    await tester.pump();

    expect(find.text('View Details'), findsOneWidget,
        reason: 'the Obx must rebuild when its parent calls setState');
  });

  testWidgets('and still follows its own observable afterwards', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: _Page()));
    final state = tester.state<_PageState>(find.byType(_Page));
    state.booking.isLoading.value = true;
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    state.booking.isLoading.value = false;
    await tester.pump();
    expect(find.text('Negotiate & Reserve'), findsOneWidget);
  });
}
