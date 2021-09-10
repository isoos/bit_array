import 'dart:typed_data';

import 'package:bit_array/bit_array.dart';
import 'package:test/test.dart';

void main() {
  group('BitArray', () {
    test('simple values', () {
      final array = BitArray(1024);
      for (var i = 0; i < 1024; i++) {
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
      final array = BitArray(1000000);
      expect(array.cardinality, 0);
      expect(array.asIntIterable().toList(), []);

      array.setBit(3);
      expect(array[3], isTrue);
      expect(array.cardinality, 1);

      array.setBit(333);
      expect(array[333], isTrue);
      expect(array.cardinality, 2);
      expect(array.asIntIterable().toList(), [3, 333]);

      for (var i = 0; i < 1000000; i++) {
        if (i % 3 == 0) {
          array.setBit(i);
        }
      }
      expect(array[15], isTrue);
      expect(array.cardinality, 333334);
      expect(array.asIntIterable().length, 333334);

      for (var i = 0; i < 1000000; i++) {
        if (i % 5 == 0) {
          array.invertBit(i);
        }
      }
      expect(array[5], isTrue);
      expect(array[15], isFalse);
      expect(array.cardinality, 400000);
      expect(array.asIntIterable().length, 400000);

      for (var i = 0; i < 1000000; i++) {
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

    test('packing and unpacking', () {
      final bitsAmount = 10000;
      final accumulator = BitArray(0);
      for (var i = 0; i < bitsAmount; i++) {
        accumulator.length = i + 1;
        if (i % 2 == 0) {
          accumulator.setBit(i);
        } else {
          accumulator.clearBit(i);
        }
      }
      final packed = accumulator.byteBuffer;
      final deccumulator = BitArray.fromByteBuffer(packed);
      for (var i = 0; i < bitsAmount; i++) {
        expect(deccumulator[i], accumulator[i]);
      }
    });

    test('fromUint8list', () {
      var list = Uint8List.fromList(<int>[0xAA, 0x55, 0x1b, 0x1a]);
      var bitArray = BitArray.fromUint8List(list);

      for (var w = 0; w < 2; w++) {
        var word = 0;
        for (var b = 7; b >= 0; b--) {
          word <<= 1;
          word |= (bitArray[b + w * 8] ? 1 : 0);
        }
        expect(word, list[w]);
      }
    });

    test('fromString', () {
      void testBitString(String bitString) {
        var reversedBitString = bitString.split('').reversed.join();
        var bitArray = BitArray.parseBinary(bitString);
        for (var i = 0; i < bitString.length; i++) {
          expect(bitArray[i], reversedBitString[i] == '1');
        }
      }

      testBitString('111010');
      testBitString('101010010101001001000100101110');
      testBitString('10101001011101110101110011101010110101011111110110');
    });

    test('array ops', () {
      final oooo = BitArray(32);
      expect(oooo.toBinaryString().substring(0, 4), '0000');
      expect(oooo.asIntIterable(false).take(4).toList(), [0, 1, 2, 3]);

      final oioi = BitArray(32)..setBits([1, 3]);
      expect(oioi.toBinaryString().substring(0, 4), '0101');

      final ioio = BitArray(32)..setBits([0, 2]);
      expect(ioio.toBinaryString().substring(0, 4), '1010');

      final iiii = BitArray(32)..setBits([0, 1, 2, 3]);
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

  group('BitArray equals and hashCode', () {
    final oiii = BitArray(32)..setBits([1, 2, 3]);
    final oioi = BitArray(32)..setBits([1, 3]);
    final ooio = BitArray(32)..setBits([2]);

    test('equals', () {
      expect(oiii ^ oioi, equals(ooio));
    });

    test('not equals', () {
      expect(oiii, isNot(ooio));
    });

    test('hashCode', () {
      expect((oiii ^ oioi).hashCode, equals(ooio.hashCode));
    });
  });

  group('BitArray + BitSet', () {
    final array = BitArray(128)..setBits([13, 113]);
    final list = ListSet.fromSorted([13, 33]);
    final range = RangeSet.fromSortedRangeLength([110, 3]);

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
