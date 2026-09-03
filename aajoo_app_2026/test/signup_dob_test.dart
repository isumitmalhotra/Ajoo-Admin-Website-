// The signup date-of-birth wheel must not offer an age signup will reject.
//
// The bug (APP #2): the wheel opened on TODAY, and the value is only recorded
// when the wheel is scrolled. Tapping Done without touching it therefore
// submitted today as the date of birth — an age of 0 — and signup failed with
// "You must be at least 18 years old". The second attempt worked only because
// the wheel had been moved by then, which is exactly the "fails on the first
// attempt" the tester reported.
//
// This drives the real screen rather than a copy of the rule, so it fails if
// someone changes the picker's seed or its bound.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/controller/common_controller.dart';
import 'package:rent_home/ui/screens_common/auth/basic_info/basic_info_screen.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(AuthController());
    Get.put(CommonController());
  });

  tearDown(Get.reset);

  testWidgets('the date-of-birth wheel opens on the youngest allowed birthday',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: InfoScreen()));
    await tester.pumpAndSettle();

    // Open the wheel from the DOB field.
    // Find it by the label the host actually sees.
    final dob = find.byWidgetPredicate((w) =>
        w is InputDecorator &&
        ((w.decoration.labelText ?? w.decoration.hintText) ?? '')
            .toLowerCase()
            .contains('birth'));
    expect(dob, findsWidgets, reason: 'the signup form should have a DOB field');
    await tester.tap(dob.first, warnIfMissed: false);
    await tester.pumpAndSettle();

    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );

    final now = DateTime.now();
    final youngest = DateTime(now.year - 18, now.month, now.day);

    // Opens on the youngest allowed birthday, so Done-without-scrolling — the
    // exact gesture that used to fail — submits a valid date.
    expect(picker.initialDateTime, youngest);

    // And cannot be scrolled past it, so an under-age date cannot be chosen
    // at all rather than being rejected after the fact.
    expect(picker.maximumDate, youngest);
  });
}
