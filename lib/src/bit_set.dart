part of bit_array;

/// An integer-indexed collection to test membership status.
abstract class BitSet {
  /// Whether the value specified by the [index] is member of the collection.
  bool operator [](int index);

  /// The largest addressable or contained member of the [BitSet]:
  /// - Immutable sets should return the largest contained member.
  /// - Fixed-memory sets should return the maximum addressable value.
  int get length;

  /// The number of members.
  int get cardinality;

  /// Creates a copy of the current [BitSet].
  BitSet clone();

  /// Returns an iterable wrapper that returns the content of the [BitSet] as
  /// 64-bit int blocks. Members are iterated from a zero-based index and each
  /// block contains 64 values as a bit index.
  Iterable<int> asUint64Iterable();

  /// Returns an iterable wrapper of the [BitSet] that iterates over the index
  /// members that are set to true.
  Iterable<int> asIntIterable();
}

/// Memory-efficient empty [BitSet].
class EmptySet implements BitSet {
  const EmptySet();

  @override
  bool operator [](int index) => false;

  @override
  int get length => 0;

  @override
  int get cardinality => 0;

  @override
  BitSet clone() => this;

  @override
  Iterable<int> asIntIterable() => const Iterable<int>.empty();

  @override
  Iterable<int> asUint64Iterable() => const Iterable<int>.empty();
}

/// Memory-efficient empty [BitSet] instance.
const emptyBitSet = const EmptySet();

/// A list-based [BitSet] implementation.
class ListSet implements BitSet {
  final List<int> _list;

  ListSet.fromSorted(this._list);

  @override
  bool operator [](int index) {
    int left = 0;
    int right = _list.length - 1;
    while (left <= right) {
      final mid = (left + right) >> 1;
      final value = _list[mid];
      if (value < index) {
        left = mid + 1;
      } else if (value > index) {
        right = mid - 1;
      } else {
        return true;
      }
    }
    return false;
  }

  @override
  int get length => _list.isEmpty ? 0 : _list.last;

  @override
  int get cardinality {
    return _list.length;
  }

  @override
  BitSet clone() {
    return new ListSet.fromSorted(_cloneList(_list));
  }

  @override
  Iterable<int> asUint64Iterable() => _toUint64Iterable(asIntIterable());

  @override
  Iterable<int> asIntIterable() => _list;
}

/// A range-based [BitSet] implementation.
class RangeSet implements BitSet {
  final List<int> _list;

  RangeSet.fromSortedRangeLength(this._list);

  @override
  bool operator [](int index) {
    int left = 0;
    int right = (_list.length >> 1) - 1;
    while (left <= right) {
      final mid = (left + right) >> 1;
      final midIndex = mid << 1;
      final start = _list[midIndex];
      final end = start + _list[midIndex + 1];
      if (end < index) {
        left = mid + 1;
      } else if (start > index) {
        right = mid - 1;
      } else {
        return true;
      }
    }
    return false;
  }

  @override
  int get length {
    if (_list.isEmpty) return 0;
    final lastIndex = _list.length - 2;
    return _list[lastIndex] + _list[lastIndex + 1];
  }

  @override
  int get cardinality {
    int value = _list.length >> 1;
    for (int i = 1; i < _list.length; i += 2) {
      value += _list[i];
    }
    return value;
  }

  @override
  BitSet clone() {
    return new ListSet.fromSorted(_cloneList(_list));
  }

  @override
  Iterable<int> asUint64Iterable() => _toUint64Iterable(asIntIterable());

  @override
  Iterable<int> asIntIterable() sync* {
    for (int i = 0; i < _list.length; i += 2) {
      int value = _list[i];
      for (int j = _list[i + 1]; j >= 0; j--) {
        yield value;
        value++;
      }
    }
  }
}

Iterable<int> _toUint64Iterable(Iterable<int> values) sync* {
  final iter = values.iterator;
  int blockOffset = 0;
  int blockLast = 63;
  int block = 0;
  bool hasCurrent = iter.moveNext();
  while (hasCurrent) {
    if (block == 0 && iter.current > blockLast) {
      yield 0;
      blockOffset += 64;
      blockLast += 64;
      continue;
    } else if (iter.current <= blockLast) {
      final offset = iter.current - blockOffset;
      block |= _bitMask[offset];
      hasCurrent = iter.moveNext();
      continue;
    } else {
      yield block;
      block = 0;
      blockOffset += 64;
      blockLast += 64;
    }
  }
  if (block != 0) {
    yield block;
  }
}

List<int> _cloneList(List<int> list) {
  if (list is Uint16List) {
    final clone = new Uint16List(list.length);
    clone.setRange(0, list.length, list);
    return clone;
  } else if (list is Uint8List) {
    final clone = new Uint8List(list.length);
    clone.setRange(0, list.length, list);
    return clone;
  } else if (list is Uint32List) {
    final clone = new Uint32List(list.length);
    clone.setRange(0, list.length, list);
    return clone;
  } else if (list is Uint64List) {
    final clone = new Uint64List(list.length);
    clone.setRange(0, list.length, list);
    return clone;
  } else {
    return new List<int>.from(list);
  }
}