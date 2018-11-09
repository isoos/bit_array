import 'package:test/test.dart';

import 'package:bit_array/bit_array.dart';

void main() {
  group('CompositeSet', () {
    test('chunk boundaries', () {
      final set = new CompositeSet();
      set[65535] = true;
      expect(set.chunks, hasLength(1));
      expect(set.chunks.single.offset, 0);
      expect(set.chunks.single.bitSet.asIntIterable().toList(), [65535]);

      set[65536] = true;
      set[65537] = true;
      expect(set.chunks, hasLength(2));
      expect(set.chunks.last.offset, 65536);
      expect(set.chunks.last.bitSet.asIntIterable().toList(), [0, 1]);

      expect(set.asIntIterable().toList(), [65535, 65536, 65537]);
    });

    test('optimize empty set', () {
      final set = new CompositeSet();
      set[1] = false;
      expect(set.chunks, hasLength(1));
      set.optimize();
      expect(set.chunks, isEmpty);
    });

    test('optimize to single list', () {
      final set = new CompositeSet();
      set[1] = false;
      set[65537] = true;
      expect(set.chunks, hasLength(2));
      set.optimize();
      expect(set.chunks, hasLength(1));
      expect(set.chunks.single.bitSet, const TypeMatcher<ListSet>());
      expect(set.asIntIterable().toList(), [65537]);
    });
  });
}
