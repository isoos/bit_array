import 'package:test/test.dart';

import 'package:bit_array/bit_array.dart';

void main() {
  group('BitCounter', () {
    test('set and get values', () {
      final counter = new BitCounter(128);
      for (int c = 0; c < 128; c++) {
        expect(counter[c], 0);
        for (int i = 0; i < 1024; i++) {
          counter[c] = i;
          expect(counter[c], i);
        }
        for (int i = 1024; i >= 0; i--) {
          counter[c] = i;
          expect(counter[c], i);
        }
      }
      expect(counter.bitLength, 11);
    });

    test('increment value', () {
      final counter = new BitCounter(128);
      for (int c = 0; c < 128; c++) {
        for (int i = 1; i < 1024; i++) {
          counter.increment(c);
          expect(counter[c], i);
        }
        counter[c] = 0;
        for (int i = 1; i < 1024; i++) {
          counter.increment(c);
          expect(counter[c], i);
        }
      }
      expect(counter.bitLength, 10);
    });

    test('simple bit arrays', () {
      final counter = new BitCounter(128);
      counter.addBitArray(new BitArray(128)..setBits([0, 3]));
      counter.addBitArray(new BitArray(128)..setBits([0, 2]));
      counter.addBitArray(new BitArray(128)..setBits([0, 1, 3]));
      counter.addBitArray(new BitArray(128)..setBits([63]));
      expect(counter[0], 3);
      expect(counter[1], 1);
      expect(counter[2], 1);
      expect(counter[3], 2);
      expect(counter[4], 0);
      expect(counter[63], 1);
      expect(counter.bitLength, 2);
      expect(counter.toBinaryString(3), '10');
    });

    test('complex bit arrays', () {
      final counter = new BitCounter(1024);
      for (int i = 1; i < 1024; i++) {
        final array = new BitArray(1024)..setBit(i);
        for (int j = 0; j < i; j++) {
          counter.addBitArray(array);
        }
      }
      expect(counter.bitLength, 10);
      for (int i = 0; i < 1024; i++) {
        expect(counter[i], i);
      }
    });

    test('bit sets', () {
      final counter = new BitCounter(0);
      counter.addBitSet(new ListSet.fromSorted([0, 2, 5, 2000]));
      expect(counter[2000], 1);
      counter.addBitSet(new ListSet.fromSorted([2, 2000]));
      counter.addBitSet(new RangeSet.fromSortedRangeLength([0, 2, 1999, 1]));
      expect(counter[0], 2);
      expect(counter[1], 1);
      expect(counter[2], 3);
      expect(counter[3], 0);
      expect(counter[4], 0);
      expect(counter[5], 1);
      expect(counter[6], 0);
      expect(counter[1998], 0);
      expect(counter[1999], 1);
      expect(counter[2000], 3);
      expect(counter[2001], 0);
    });
  });
}
