part of bit_array;

/// A container for offset-based [BitSet].
class BitCounterChunk {
  final int offset;
  final BitCounter bitCounter;

  BitCounterChunk(this.offset, this.bitCounter);
}

/// A composite counter similar to [BitCounter] using multiple chunks of
/// [BitCounter] objects with offsets.
///
/// By default, each chunk is using a maximum cardinality of 2^16 entries,
/// following the RoaringBitmap pattern.
class CompositeCounter {
  /// The bits used for each chunk.
  final int chunkBits;

  /// The list of chunks.
  ///
  /// Exposed only for serialization, do NOT call or modify them directly.
  final List<BitCounterChunk> chunks;

  final int _chunkLength;
  final int _indexMask;
  final int _offsetMask;

  CompositeCounter({this.chunkBits: 16, List<BitCounterChunk> chunks})
      : _chunkLength = (1 << chunkBits),
        _indexMask = (1 << chunkBits) - 1,
        _offsetMask = ~((1 << chunkBits) - 1),
        chunks = chunks ?? <BitCounterChunk>[];

  /// The maximum number of bits required to store the value of the counter.
  int get bitLength =>
      chunks.fold<int>(0, (m, c) => math.max(m, c.bitCounter.bitLength));

  /// The lowest 63-bit integer value at the given [index].
  /// TODO: add BigInt support.
  int operator [](int index) {
    final chunkOffset = index & _offsetMask;
    final c = _getChunk(chunkOffset);
    if (c == null) {
      return 0;
    } else {
      return c.bitCounter[index & _indexMask];
    }
  }

  /// Sets the lowest 63-bit integer value at the given [index].
  /// TODO: add BigInt support.
  void operator []=(int index, int value) {
    final chunkOffset = index & _offsetMask;
    final c = _getChunk(chunkOffset, true);
    c.bitCounter[index & _indexMask] = value;
  }

  /// Increments the current counter the given composite set.
  void addCompositeSet(CompositeSet set) {
    if (set.chunkBits != chunkBits) {
      throw new StateError('Only sets with the same chunkBits can be added');
    }
    for (BitSetChunk bsc in set.chunks) {
      final c = _getChunk(bsc.offset, true);
      c.bitCounter.addBitSet(bsc.bitSet);
    }
  }

  /// Increments the value at the [index].
  void increment(int index) {
    final chunkOffset = index & _offsetMask;
    final c = _getChunk(chunkOffset, true);
    c.bitCounter.increment(index & _indexMask);
  }

  BitCounterChunk _getChunk(int offset, [bool forInsert = false]) {
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
      final c = new BitCounterChunk(offset, new BitCounter(_chunkLength));
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
