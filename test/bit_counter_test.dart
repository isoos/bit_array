import 'package:test/test.dart';

import 'package:bit_array/bit_array.dart';

void main() {
  group('BitCounter', () {
    test('set and get values', () {
      final counter = BitCounter(128);
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
      final counter = BitCounter(128);
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

    test('increment value with shift', () {
      final counter = BitCounter(128);
      counter.increment(10, shiftLeft: 3);
      counter.increment(10, shiftLeft: 2);
      expect(counter[10], 12);
      counter.increment(10);
      expect(counter[10], 13);
      counter.increment(10, shiftLeft: 2);
      expect(counter[10], 17);
      expect(counter.bitLength, 5);
    });

    test('simple bit arrays', () {
      final counter = BitCounter(128);
      counter.addBitArray(BitArray(128)..setBits([0, 3]));
      counter.addBitArray(BitArray(128)..setBits([0, 2]));
      counter.addBitArray(BitArray(128)..setBits([0, 1, 3]));
      counter.addBitArray(BitArray(128)..setBits([63]));
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
      final counter = BitCounter(1024);
      for (int i = 1; i < 1024; i++) {
        final array = BitArray(1024)..setBit(i);
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
      final counter = BitCounter(0);
      counter.addBitSet(ListSet.fromSorted([0, 2, 5, 2000]));
      expect(counter[2000], 1);
      counter.addBitSet(ListSet.fromSorted([2, 2000]));
      counter.addBitSet(RangeSet.fromSortedRangeLength([0, 2, 1999, 1]));
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

    test('bit set with shift', () {
      final counter = BitCounter(128);
      counter.addBitSet(ListSet.fromSorted([0, 2, 5]), shiftLeft: 3);
      expect(counter[2], 8);
      counter.addBitSet(ListSet.fromSorted([2, 2000]), shiftLeft: 2);
      expect(counter[2], 12);
      expect(counter[2000], 4);
    });

    test('multiply', () {
      final c1 = BitCounter(128);
      for (int i = 0; i < 128; i++) {
        c1[i] = i;
      }
      final c3 = c1.multiply(5);
      expect(c3[0], 0);
      expect(c3[10], 50);
      expect(c3[98], 490);
      for (int i = 0; i < 128; i++) {
        final exp = i * 5;
        expect('$i-${c3[i]}', '$i-$exp');
      }
      expect(c1.bitLength, 7);
      expect(c3.bitLength, 10);
    });

    test('multiplyWithCounter', () {
      final c1 = BitCounter(128);
      final c2 = BitCounter(128);
      for (int i = 0; i < 128; i++) {
        c1[i] = i;
        c2[i] = (i % 17) + (i % 3);
      }
      final c3 = c1.multiplyWithCounter(c2);
      expect(c3[0], 0);
      expect(c3[10], 110);
      expect(c3[98], 1470);
      for (int i = 0; i < 128; i++) {
        final exp = i * ((i % 17) + (i % 3));
        expect('$i-${c3[i]}', '$i-$exp');
      }
      expect(c1.bitLength, 7);
      expect(c2.bitLength, 5);
      expect(c3.bitLength, 11);
    });
  });
}
