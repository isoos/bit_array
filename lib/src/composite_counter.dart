part of '../bit_array.dart';

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

  CompositeCounter({this.chunkBits = 16, List<BitCounterChunk>? chunks})
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
    final c = _getChunk(chunkOffset, true)!;
    c.bitCounter[index & _indexMask] = value;
  }

  /// Increments the current counter the given composite set.
  ///
  /// The add starts at the bit position specified by [shiftLeft].
  void addCompositeSet(CompositeSet set, {int shiftLeft = 0}) {
    if (set.chunkBits != chunkBits) {
      throw StateError('Only sets with the same chunkBits can be added');
    }
    for (var bsc in set.chunks) {
      final c = _getChunk(bsc.offset, true)!;
      c.bitCounter.addBitSet(bsc.bitSet, shiftLeft: shiftLeft);
    }
  }

  /// Adds a [counter] to the set.
  ///
  /// The add starts at the bit position specified by [shiftLeft].
  void addCompositeCounter(CompositeCounter counter, {int shiftLeft = 0}) {
    if (counter.chunkBits != chunkBits) {
      throw StateError('Only counters with the same chunkBits can be added');
    }
    for (var bcc in counter.chunks) {
      final c = _getChunk(bcc.offset, true)!;
      c.bitCounter.addBitCounter(bcc.bitCounter, shiftLeft: shiftLeft);
    }
  }

  /// Multiply this instance with [value] and return the result.
  CompositeCounter multiply(int value) {
    return CompositeCounter(
      chunkBits: chunkBits,
      chunks: chunks
          .map((c) => BitCounterChunk(c.offset, c.bitCounter * value))
          .toList(),
    );
  }

  /// Multiply this instance with [counter] and return the result.
  CompositeCounter multiplyWithCounter(CompositeCounter counter) {
    if (counter.chunkBits != chunkBits) {
      throw StateError(
          'Only counters with the same chunkBits can be multiplied');
    }
    final result = CompositeCounter(chunkBits: counter.chunkBits);
    for (var bcc in counter.chunks) {
      final c = _getChunk(bcc.offset);
      if (c == null) continue;
      final m = c.bitCounter * bcc.bitCounter;
      if (m.bitLength == 0) continue;
      if (m.bitLength == 1 && m._bits[0].cardinality == 0) continue;
      result.chunks.add(BitCounterChunk(bcc.offset, m));
    }
    return result;
  }

  /// Multiply this instance with [value] and return the result.
  CompositeCounter operator *(/* int | CompositeCounter */ dynamic value) {
    if (value is int) {
      return multiply(value);
    } else if (value is CompositeCounter) {
      return multiplyWithCounter(value);
    } else {
      throw Exception('Unknown multiplier type: ${value.runtimeType}');
    }
  }

  /// Increments the value at the [index].
  ///
  /// The increment starts at the bit position specified by [shiftLeft].
  void increment(int index, {int shiftLeft = 0}) {
    final chunkOffset = index & _offsetMask;
    final c = _getChunk(chunkOffset, true)!;
    c.bitCounter.increment(index & _indexMask, shiftLeft: shiftLeft);
  }

  /// Add [bits] cleared bits to the lower binary digits.
  void shiftLeft(int bits) {
    if (bits <= 0) return;
    for (final c in chunks) {
      c.bitCounter.shiftLeft(bits);
    }
  }

  /// Remove [bits] lower binary digits.
  void shiftRight(int bits) {
    if (bits <= 0) return;
    for (final c in chunks) {
      c.bitCounter.shiftRight(bits);
    }
  }

  /// Returns a [CompositeSet] which is true for every position where the
  /// current [CompositeCounter()] has a value larger or equal to [minValue].
  CompositeSet toMask({int minValue = 1}) {
    return CompositeSet(
        chunkBits: chunkBits,
        chunks: chunks.expand<BitSetChunk>((c) {
          final set = c.bitCounter.toMask(minValue: minValue);
          if (set.isEmpty) return [];
          return [BitSetChunk(c.offset, set)];
        }).toList());
  }

  /// Updates the values to the maximum of the pairwise values with [other].
  void max(CompositeCounter other) {
    if (chunkBits != other.chunkBits) {
      throw Exception('chunkBits must match: $chunkBits != ${other.chunkBits}');
    }
    for (var oc in other.chunks) {
      final c = _getChunk(oc.offset, true)!;
      if (c.bitCounter.bitLength == 0) {
        c.bitCounter._bits.addAll(oc.bitCounter._bits.map((a) => a.clone()));
      } else {
        c.bitCounter.max(oc.bitCounter);
      }
    }
  }

  /// Updates the values to the minimum of the pairwise values with [other].
  ///
  /// The most significant bits will be removed if they are all-zero.
  void min(CompositeCounter other) {
    if (chunkBits != other.chunkBits) {
      throw Exception('chunkBits must match: $chunkBits != ${other.chunkBits}');
    }
    final lastOffset = other.chunks.isEmpty ? -1 : other.chunks.last.offset;
    while (chunks.isNotEmpty && chunks.last.offset > lastOffset) {
      chunks.removeLast();
    }
    final newChunks = <BitCounterChunk>[];
    for (var oc in other.chunks) {
      final c = _getChunk(oc.offset, false);
      if (c == null) continue;
      c.bitCounter.min(oc.bitCounter);
      if (c.bitCounter.bitLength > 0) {
        newChunks.add(c);
      }
    }
    chunks.replaceRange(0, chunks.length, newChunks);
  }

  /// Update the current [CompositeCounter] using a logical AND operation with
  /// the corresponding elements in the specified [set].
  ///
  /// Excess size of the [set] is ignored.
  ///
  /// The most significant bits will be removed if they are all-zero.
  void applyMask(CompositeSet set) {
    if (chunkBits != set.chunkBits) {
      throw Exception('chunkBits must match: $chunkBits != ${set.chunkBits}');
    }
    final lastOffset = set.chunks.isEmpty ? -1 : set.chunks.last.offset;
    while (chunks.isNotEmpty && chunks.last.offset > lastOffset) {
      chunks.removeLast();
    }
    final newChunks = <BitCounterChunk>[];
    for (var oc in set.chunks) {
      final c = _getChunk(oc.offset, false);
      if (c == null) continue;
      c.bitCounter.applyMask(oc.bitSet);
      if (c.bitCounter.bitLength > 0) {
        newChunks.add(c);
      }
    }
    chunks.replaceRange(0, chunks.length, newChunks);
  }

  /// Creates a copy of the current [CompositeCounter].
  ///
  /// The cloned instance starts at the bit position specified by [shiftRight].
  CompositeCounter clone({int shiftRight = 0}) {
    return CompositeCounter(
      chunkBits: chunkBits,
      chunks: chunks
          .map((c) => BitCounterChunk(
              c.offset, c.bitCounter.clone(shiftRight: shiftRight)))
          .toList(),
    );
  }

  BitCounterChunk? _getChunk(int offset, [bool forInsert = false]) {
    var left = 0;
    var right = chunks.length - 1;
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
      final c = BitCounterChunk(offset, BitCounter(_chunkLength));
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
