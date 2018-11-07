import 'package:test/test.dart';

import 'package:bit_array/bit_array.dart';

void main() {
  group('BitArray', () {
    test('simple values', () {
      final array = new BitArray(1024);
      for (int i = 0; i < 1024; i++) {
        expect(array[i], isFalse);
        expect(array.cardinality, 0);
        array[i] = true;
        expect(array[i], isTrue);
        expect(array.cardinality, 1);
        array[i] = false;
        expect(array[i], isFalse);
        expect(array.cardinality, 0);
      }
    });

    test('large patterns', () {
      final array = new BitArray(1000000);
      expect(array.cardinality, 0);
      expect(array.asIntIterable().toList(), []);

      array.setBit(3);
      expect(array[3], isTrue);
      expect(array.cardinality, 1);

      array.setBit(333);
      expect(array[333], isTrue);
      expect(array.cardinality, 2);
      expect(array.asIntIterable().toList(), [3, 333]);

      for (int i = 0; i < 1000000; i++) {
        if (i % 3 == 0) {
          array.setBit(i);
        }
      }
      expect(array[15], isTrue);
      expect(array.cardinality, 333334);
      expect(array.asIntIterable().length, 333334);

      for (int i = 0; i < 1000000; i++) {
        if (i % 5 == 0) {
          array.invertBit(i);
        }
      }
      expect(array[5], isTrue);
      expect(array[15], isFalse);
      expect(array.cardinality, 400000);
      expect(array.asIntIterable().length, 400000);

      for (int i = 0; i < 1000000; i++) {
        if (i % 5 == 0) {
          array.clearBit(i);
        }
      }
      expect(array[5], isFalse);
      expect(array[15], isFalse);
      expect(array.cardinality, 266667);
      expect(array.asIntIterable().length, 266667);
      expect(array.asIntIterable().where((i) => i < 40).toList(),
          [3, 6, 9, 12, 18, 21, 24, 27, 33, 36, 39]);
    });

    test('array ops', () {
      final oooo = new BitArray(64);
      expect(oooo.toBinaryString().substring(0, 4), '0000');
      expect(oooo.asIntIterable(false).take(4).toList(), [0, 1, 2, 3]);

      final oioi = new BitArray(64)..setBits([1, 3]);
      expect(oioi.toBinaryString().substring(0, 4), '0101');

      final ioio = new BitArray(64)..setBits([0, 2]);
      expect(ioio.toBinaryString().substring(0, 4), '1010');

      final iiii = new BitArray(64)..setBits([0, 1, 2, 3]);
      expect(iiii.toBinaryString().substring(0, 4), '1111');

      expect((oioi & iiii).toBinaryString().substring(0, 4), '0101');
      expect((oioi & ioio).toBinaryString().substring(0, 4), '0000');
      expect((oioi ^ iiii).toBinaryString().substring(0, 4), '1010');
      expect((oioi % iiii).toBinaryString().substring(0, 4), '0000');
      expect((oioi % oooo).toBinaryString().substring(0, 4), '0101');
      expect((oioi ^ oooo).toBinaryString().substring(0, 4), '0101');
      expect((oioi ^ ioio).toBinaryString().substring(0, 4), '1111');
    });
  });

  group('BitArray + BitSet', () {
    final array = new BitArray(128)..setBits([13, 113]);
    final list = new ListSet.fromSorted([13, 33]);
    final range = new RangeSet.fromSortedRangeLength([110, 3]);

    test('and', () {
      expect(
          (array & list).toBinaryString(),
          '0000000000000100000000000000000000000000000000000000000000000000'
          '0000000000000000000000000000000000000000000000000000000000000000');
      expect(
          (array & range).toBinaryString(),
          '0000000000000000000000000000000000000000000000000000000000000000'
          '0000000000000000000000000000000000000000000000000100000000000000');
    });

    test('andNot', () {
      expect(
          (array % list).toBinaryString(),
          '0000000000000000000000000000000000000000000000000000000000000000'
          '0000000000000000000000000000000000000000000000000100000000000000');
      expect(
          (array % range).toBinaryString(),
          '0000000000000100000000000000000000000000000000000000000000000000'
          '0000000000000000000000000000000000000000000000000000000000000000');
    });

    test('or', () {
      expect(
          (array | list).toBinaryString(),
          '0000000000000100000000000000000001000000000000000000000000000000'
          '0000000000000000000000000000000000000000000000000100000000000000');
      expect(
          (array | range).toBinaryString(),
          '0000000000000100000000000000000000000000000000000000000000000000'
          '0000000000000000000000000000000000000000000000111100000000000000');
    });

    test('xor', () {
      expect(
          (array ^ list).toBinaryString(),
          '0000000000000000000000000000000001000000000000000000000000000000'
          '0000000000000000000000000000000000000000000000000100000000000000');
      expect(
          (array ^ range).toBinaryString(),
          '0000000000000100000000000000000000000000000000000000000000000000'
          '0000000000000000000000000000000000000000000000111000000000000000');
    });
  });
}
