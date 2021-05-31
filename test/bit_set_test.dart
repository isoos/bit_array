import 'package:test/test.dart';

import 'package:bit_array/bit_array.dart';

void main() {
  group('ListSet', () {
    final set = ListSet.fromSorted([23, 45, 78, 98, 101, 102, 103]);

    test('simple values', () {
      expect(set.length, 103);
      expect(set.cardinality, 7);
      expect(set[22], isFalse);
      expect(set[23], isTrue);
      expect(set[24], isFalse);
      expect(set[44], isFalse);
      expect(set[45], isTrue);
      expect(set[46], isFalse);
      expect(set[77], isFalse);
      expect(set[78], isTrue);
      expect(set[79], isFalse);
      expect(set[97], isFalse);
      expect(set[98], isTrue);
      expect(set[99], isFalse);
      expect(set[100], isFalse);
      expect(set[101], isTrue);
      expect(set[102], isTrue);
      expect(set[103], isTrue);
      expect(set[104], isFalse);
    });

    test('uint32', () {
      _testUint8(set, [
        '00000000',
        '00000000',
        '00000001',
        '00000000',
        '00000000',
        '00000100',
        '00000000',
        '00000000',
        '00000000',
        '00000010',
        '00000000',
        '00000000',
        '00100111',
      ]);
    });

    test('values around 200', () {
      expect(ListSet.fromSorted([199]).asUint8Iterable().toList(), [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        128
      ]);
      expect(ListSet.fromSorted([200]).asUint8Iterable().toList(), [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1
      ]);
      expect(ListSet.fromSorted([201]).asUint8Iterable().toList(), [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        2
      ]);
      expect(ListSet.fromSorted([2, 199]).asUint8Iterable().toList(), [
        4,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        128
      ]);
      expect(ListSet.fromSorted([2, 200]).asUint8Iterable().toList(), [
        4,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1
      ]);
      expect(ListSet.fromSorted([2, 201]).asUint8Iterable().toList(), [
        4,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        2
      ]);
    });
  });

  group('ListSet equals and hashCode', () {
    test('equals', () {
      expect(ListSet.fromSorted([1, 3]), equals(ListSet.fromSorted([1, 3])));
    });

    test('not equals', () {
      expect(ListSet.fromSorted([1, 3]), isNot(ListSet.fromSorted([1, 2])));
    });

    test('hashCode', () {
      expect(ListSet.fromSorted([1, 3]).hashCode,
          equals(ListSet.fromSorted([1, 3]).hashCode));
    });
  });

  group('RangeSet', () {
    final set = RangeSet.fromSortedRangeLength([2, 0, 6, 3, 15, 2, 21, 4]);

    test('simple values', () {
      expect(set.length, 25);
      expect(set.cardinality, 13);
      expect(set[1], isFalse);
      expect(set[2], isTrue);
      expect(set[3], isFalse);
      expect(set[5], isFalse);
      expect(set[6], isTrue);
      expect(set[7], isTrue);
      expect(set[8], isTrue);
      expect(set[9], isTrue);
      expect(set[10], isFalse);
      expect(set[14], isFalse);
      expect(set[15], isTrue);
      expect(set[16], isTrue);
      expect(set[17], isTrue);
      expect(set[18], isFalse);
      expect(set[19], isFalse);
      expect(set[20], isFalse);
      expect(set[21], isTrue);
      expect(set[22], isTrue);
      expect(set[23], isTrue);
      expect(set[24], isTrue);
      expect(set[25], isTrue);
      expect(set[26], isFalse);
    });

    test('uint32', () {
      _testUint8(set, [
        '00100011',
        '11000001',
        '11000111',
        '11000000',
      ]);
    });
  });

  group('RangeSet equals and hashCode', () {
    test('equals', () {
      expect(RangeSet.fromSortedRangeLength([1, 3]),
          equals(RangeSet.fromSortedRangeLength([1, 2, 4, 0])));
    });

    test('not equals', () {
      expect(RangeSet.fromSortedRangeLength([1, 3]),
          isNot(RangeSet.fromSortedRangeLength([1, 2])));
    });

    test('hashCode', () {
      expect(RangeSet.fromSortedRangeLength([1, 3]).hashCode,
          equals(RangeSet.fromSortedRangeLength([1, 2, 4, 0]).hashCode));
    });
  });
}

String _rev(String s) => String.fromCharCodes(s.codeUnits.reversed);

void _testUint8(BitSet set, List<String> expected) {
  final list = set
      .asUint8Iterable()
      .map((i) => i.toRadixString(2).padLeft(8, '0'))
      .map(_rev)
      .toList();
  expect(list, expected);
}
