import 'package:flutter_test/flutter_test.dart';
import 'package:tripreceipt/config/theme.dart';

void main() {
  test('theme builds', () {
    expect(AppTheme.theme.colorScheme.primary.toARGB32(), isNonZero);
  });
}
