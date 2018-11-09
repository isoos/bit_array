import 'package:test/test.dart';

import 'package:bit_array/bit_array.dart';

void main() {
  group('CompositeCounter', () {
    test('simple ops', () {
      final counter = new CompositeCounter();
      counter[100000] = 102;
      expect(counter[100000], 102);
      expect(counter[100001], 0);
      counter.addCompositeSet(new CompositeSet()..[100000] = true);
      expect(counter[100000], 103);
    });
  });
}
