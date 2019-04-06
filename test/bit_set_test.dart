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

    test('uint64', () {
      _testUint64(set, [
        '0000000000000000',
        '0000000100000000',
        '0000000000000100',
        '0000000000000000',
        '0000000000000010',
        '0000000000000000',
        '0010011100000000',
        '0000000000000000',
      ]);
    });

    test('values around 200', () {
      expect(ListSet.fromSorted([199]).asUint64Iterable().toList(),
          [0, 0, 0, 128]);
      expect(ListSet.fromSorted([200]).asUint64Iterable().toList(),
          [0, 0, 0, 256]);
      expect(ListSet.fromSorted([201]).asUint64Iterable().toList(),
          [0, 0, 0, 512]);
      expect(ListSet.fromSorted([2, 199]).asUint64Iterable().toList(),
          [4, 0, 0, 128]);
      expect(ListSet.fromSorted([2, 200]).asUint64Iterable().toList(),
          [4, 0, 0, 256]);
      expect(ListSet.fromSorted([2, 201]).asUint64Iterable().toList(),
          [4, 0, 0, 512]);
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

    test('uint64', () {
      _testUint64(set, [
        '0010001111000001',
        '1100011111000000',
        '0000000000000000',
        '0000000000000000',
      ]);
    });
  });
}

String _rev(String s) => String.fromCharCodes(s.codeUnits.reversed);

void _testUint64(BitSet set, List<String> expected) {
  final list = set
      .asUint64Iterable()
      .map((i) => i.toRadixString(2).padLeft(64, '0'))
      .map(_rev)
      .expand((s) => [
            s.substring(0, 16),
            s.substring(16, 32),
            s.substring(32, 48),
            s.substring(48)
          ])
      .toList();
  expect(list, expected);
}
