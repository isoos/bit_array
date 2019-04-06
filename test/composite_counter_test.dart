import 'package:test/test.dart';

import 'package:bit_array/bit_array.dart';

void main() {
  group('CompositeCounter', () {
    test('simple ops', () {
      final counter = CompositeCounter();
      counter[100000] = 102;
      expect(counter[100000], 102);
      expect(counter[100001], 0);
      counter.addCompositeSet(CompositeSet()..[100000] = true);
      expect(counter[100000], 103);
    });

    test('counter add', () {
      final counter = CompositeCounter()
        ..[2] = 100
        ..[3] = 2
        ..addCompositeCounter(CompositeCounter()..[2] = 3, shiftLeft: 2)
        ..addCompositeCounter(CompositeCounter()..[3] = 1);
      expect(counter[2], 112);
      expect(counter[3], 3);
    });

    test('multiplyWithCounter', () {
      final c1 = CompositeCounter()
        ..[2] = 2
        ..[1000000] = 17;
      final c3 = c1.multiply(5);
      expect(c3.chunks.length, 2);
      expect(c3.chunks.last.offset, 983040);
      expect(c3[2], 10);
      expect(c3[1000000], 17 * 5);
    });

    test('multiplyWithCounter', () {
      final c1 = CompositeCounter()
        ..[2] = 2
        ..[1000000] = 17;
      final c2 = CompositeCounter()..[1000000] = 13;
      final c3 = c1.multiplyWithCounter(c2);
      expect(c3.chunks.length, 1);
      expect(c3.chunks.single.offset, 983040);
      expect(c3[2], 0);
      expect(c3[1000000], 221);
    });
  });
}
