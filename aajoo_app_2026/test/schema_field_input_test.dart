// A schema field has to survive being typed into.
//
// The bug (APP #9): the field's widget key contained its own value, so every
// keystroke changed the widget's identity. Flutter disposed the State, its
// controller and its focus, and built a replacement. The character landed —
// the replacement was seeded with it — and every character after it was
// swallowed, because there was no longer a focused field to receive one.
// Measured on device: tap Built-up Area, type "1500", the field holds "1".
//
// The key was there for a real reason (a draft loading over an empty form),
// so these tests pin BOTH behaviours: typing must not disturb the field, and
// a value arriving from outside must still be adopted.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/listing_schema.dart';
import 'package:rent_home/ui/screens_host/listing/widgets/schema_field_input.dart';

const _field = SchemaField(
  key: 'builtup_area',
  label: 'Built-up Area',
  type: FieldType.number,
);

/// The wizard's actual shape: the parent owns the value and rebuilds the field
/// on every change, which is what used to destroy it.
class _Host extends StatefulWidget {
  const _Host({this.initial = '', this.onChanged});
  final String initial;
  final ValueChanged<String>? onChanged;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String value = widget.initial;

  /// Push a value in from outside, the way loading a draft does.
  void loadFromOutside(String v) => setState(() => value = v);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SchemaFieldInput(
          field: _field,
          value: value,
          onChanged: (_, v) {
            setState(() => value = (v ?? '').toString());
            widget.onChanged?.call(value);
          },
        ),
      ),
    );
  }
}

void main() {
  group('a schema text field being typed into', () {
    testWidgets('keeps every character, not just the first', (tester) async {
      await tester.pumpWidget(const _Host());
      await tester.enterText(find.byType(TextField), '1');
      await tester.pump();
      await tester.enterText(find.byType(TextField), '15');
      await tester.pump();
      await tester.enterText(find.byType(TextField), '1500');
      await tester.pump();

      expect(find.text('1500'), findsOneWidget);
    });

    testWidgets('keeps its focus across the rebuild each keystroke causes',
        (tester) async {
      await tester.pumpWidget(const _Host());
      await tester.tap(find.byType(TextField));
      await tester.pump();

      final focused = () =>
          tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus;
      expect(focused(), isTrue, reason: 'tapping should focus the field');

      await tester.enterText(find.byType(TextField), '7');
      await tester.pump();
      // This is the whole bug: focus used to be gone by here, and every
      // keystroke after it went nowhere.
      expect(focused(), isTrue, reason: 'typing must not steal its own focus');
    });

    testWidgets('reports each change upward', (tester) async {
      final seen = <String>[];
      await tester.pumpWidget(_Host(onChanged: seen.add));
      await tester.enterText(find.byType(TextField), '2');
      await tester.pump();
      await tester.enterText(find.byType(TextField), '20');
      await tester.pump();
      expect(seen, ['2', '20']);
    });
  });

  group('a value arriving from outside', () {
    testWidgets('is adopted when the host is not typing — a draft loading',
        (tester) async {
      await tester.pumpWidget(const _Host());
      expect(find.text('1200'), findsNothing);

      tester.state<_HostState>(find.byType(_Host)).loadFromOutside('1200');
      await tester.pump();

      expect(find.text('1200'), findsOneWidget,
          reason: 'this is what the old value-in-key was there to do');
    });

    testWidgets('does not fight the host mid-word', (tester) async {
      await tester.pumpWidget(const _Host());
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '45');
      await tester.pump();

      // The echo of their own keystroke must not reset the cursor.
      final controller =
          tester.widget<TextField>(find.byType(TextField)).controller!;
      expect(controller.text, '45');
      expect(controller.selection.baseOffset, 2,
          reason: 'the caret belongs after what they typed, not at the start');
    });
  });
}
