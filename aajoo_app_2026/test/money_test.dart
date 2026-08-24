import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/money.dart';

void main() {
  test('Indian grouping: last three, then pairs', () {
    expect(rupeeDigits(0), '0');
    expect(rupeeDigits(999), '999');
    expect(rupeeDigits(1000), '1,000');
    expect(rupeeDigits(3200), '3,200');
    expect(rupeeDigits(99999), '99,999');
    expect(rupeeDigits(100000), '1,00,000');
    expect(rupeeDigits(1234567), '12,34,567');
    expect(rupeeDigits(120000000), '12,00,00,000');
  });

  test('rounds to whole rupees — paise are never shown', () {
    expect(rupeeDigits(3200.00), '3,200');
    expect(rupeeDigits(2099.6), '2,100');
    expect(rupees(19000), '₹19,000');
  });

  test('negatives keep their sign', () {
    expect(rupeeDigits(-2500), '-2,500');
  });

  test('parses whatever the API sent', () {
    expect(rupeesFrom('3200.00'), '₹3,200');
    expect(rupeesFrom('₹3,200'), '₹3,200');
    expect(rupeesFrom(2100), '₹2,100');
    expect(rupeesFrom(null), '');
    // Not a number at all — return it rather than rendering a blank price.
    expect(rupeesFrom('On request'), 'On request');
  });
}
