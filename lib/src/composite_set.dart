part of bit_array;

/// Optimizes the [BitArray] into a representation that takes less memory.
/// May return the same [array] instance or null to indicate that there is no
/// optimized version for it.
typedef BitSet BitArrayOptimizer(BitArray array);

/// A container for offset-based [BitSet].
class BitSetChunk {
  final int offset;
  BitSet _set;

  BitSetChunk(this.offset, this._set);

  /// The bit set.
  BitSet get bitSet => _set;

  /// Returns the [bitSet] as [BitArray], and converts it if needed.
  BitArray asBitArray(int length) {
    if (_set is! BitArray) {
      _set = BitArray.fromBitSet(_set, length: length);
    }
    return _set as BitArray;
  }
}

/// A composite [BitSet] using multiple chunks of [BitSet] objects with offsets.
///
/// By default, each chunk is using a maximum cardinality of 2^16 entries,
/// following the RoaringBitmap pattern.
class CompositeSet extends BitSet {
  /// The bits used for each chunk.
  final int chunkBits;

  /// The list of chunks.
  ///
  /// Exposed only for serialization, do NOT call or modify them directly.
  final List<BitSetChunk> chunks;

  final int _chunkLength;
  final int _indexMask;
  final int _offsetMask;

  CompositeSet({this.chunkBits = 16, List<BitSetChunk>? chunks})
      : _chunkLength = (1 << chunkBits),
        _indexMask = (1 << chunkBits) - 1,
        _offsetMask = ~((1 << chunkBits) - 1),
        chunks = chunks ?? <BitSetChunk>[];

  @override
  bool operator [](int index) {
    final chunkOffset = index & _offsetMask;
    final c = _getChunk(chunkOffset);
    if (c == null) {
      return false;
    } else {
      return c.bitSet[index & _indexMask];
    }
  }

  /// Sets the bit specified by the [index] to the [value].
  void operator []=(int index, bool value) {
    final chunkOffset = index & _offsetMask;
    final c = _getChunk(chunkOffset, true)!;
    c.asBitArray(_chunkLength)[index & _indexMask] = value;
  }

  @override
  int get length =>
      chunks.isEmpty ? 0 : chunks.last.offset + chunks.last.bitSet.length;

  @override
  int get cardinality =>
      chunks.fold<int>(0, (sum, c) => sum + c.bitSet.cardinality);

  void and(CompositeSet set) {
    int i = 0;
    int j = 0;
    while (i < chunks.length && j < set.chunks.length) {
      final a = chunks[i];
      final b = set.chunks[j];
      if (a.offset < b.offset) {
        a._set = emptyBitSet;
        i++;
      } else if (a.offset > b.offset) {
        j++;
      } else if (a.bitSet == emptyBitSet || b.bitSet == emptyBitSet) {
        a._set = emptyBitSet;
        i++;
        j++;
      } else {
        a.asBitArray(_chunkLength).and(b.bitSet);
        i++;
        j++;
      }
    }
    while (i < chunks.length) {
      chunks.removeLast();
    }
  }

  void or(CompositeSet set) {
    int i = 0;
    int j = 0;
    while (i < chunks.length && j < set.chunks.length) {
      final a = chunks[i];
      final b = set.chunks[j];
      if (a.offset < b.offset) {
        i++;
      } else if (a.offset > b.offset) {
        final c = BitSetChunk(b.offset, b.bitSet.clone());
        chunks.insert(i, c);
        i++;
        j++;
      } else if (a.bitSet == emptyBitSet) {
        a._set = b.bitSet.clone();
        i++;
        j++;
      } else if (b.bitSet == emptyBitSet) {
        i++;
        j++;
      } else {
        a.asBitArray(_chunkLength).or(b.bitSet);
        i++;
        j++;
      }
    }
    while (j < set.chunks.length) {
      final b = chunks[j++];
      chunks.add(BitSetChunk(b.offset, b.bitSet.clone()));
    }
  }

  /// Optimize the containers.
  void optimize({BitArrayOptimizer? optimizer, int removeThreshold = 0}) {
    optimizer ??= chunkBits == 16 ? _optimizeBitArray16 : _simpleOptimizer;
    int removeCount = 0;
    for (BitSetChunk c in chunks) {
      if (c._set is BitArray) {
        final bitSet = optimizer(c._set as BitArray);
        if (bitSet is! BitArray) {
          c._set = bitSet;
        }
      }
      if (c.bitSet == emptyBitSet) removeCount++;
    }
    if (removeCount > removeThreshold) {
      chunks.removeWhere((c) => c.bitSet == emptyBitSet);
    }
  }

  @override
  CompositeSet clone() {
    return CompositeSet(
      chunkBits: chunkBits,
      chunks: chunks
          .map((bsc) => BitSetChunk(bsc.offset, bsc.bitSet.clone()))
          .toList(),
    );
  }

  @override
  Iterable<int> asUint32Iterable() => _toUint32Iterable(asIntIterable());

  @override
  Iterable<int> asIntIterable() sync* {
    for (int i = 0; i < chunks.length; i++) {
      final c = chunks[i];
      yield* c.bitSet.asIntIterable().map((i) => i + c.offset);
    }
  }

  BitSetChunk? _getChunk(int offset, [bool forInsert = false]) {
    int left = 0;
    int right = chunks.length - 1;
    while (left <= right) {
      final mid = (left + right) >> 1;
      final value = chunks[mid];
      if (value.offset < offset) {
        left = mid + 1;
      } else if (value.offset > offset) {
        right = mid - 1;
      } else {
        return chunks[mid];
      }
    }
    if (forInsert) {
      final c = BitSetChunk(offset, BitArray(_chunkLength));
      if (left == chunks.length) {
        chunks.add(c);
      } else {
        chunks.insert(left, c);
      }
      return c;
    } else {
      return null;
    }
  }
}

BitSet _simpleOptimizer(BitArray array) {
  final cardinality = array.cardinality;
  if (cardinality == 0) {
    return emptyBitSet;
  }
  if (cardinality < (array.length >> 12)) {
    return ListSet.fromSorted(array.asIntIterable().toList());
  }
  return array;
}

BitSet _optimizeBitArray16(BitArray array) {
  final cardinality = array.cardinality;
  if (cardinality == 0) {
    return emptyBitSet;
  }
  if (cardinality < 1024) {
    final list = Uint16List(cardinality);
    list.setRange(0, cardinality, array.asIntIterable());
    return ListSet.fromSorted(list);
  }
  return array;
}
