part of bit_array;

/// A range-encoded bit counter.
class BitCounter {
  final _bits = <BitArray>[];
  int _length = 0;

  BitCounter(this._length);

  /// The list of bits from LSB to MSB.
  ///
  /// Exposed only for serialization, do NOT call or modify them directly.
  List<BitArray> get bits => _bits;

  /// The maximum number of bits required to store the value of the counter.
  int get bitLength => _bits.length;

  /// The lowest 63-bit integer value at the given [index].
  /// TODO: add BigInt support.
  int operator [](int index) {
    int count = 0;
    for (int i = 0; i < _bits.length && i < 63; i++) {
      if (_bits[i][index]) {
        count |= (1 << i);
      }
    }
    return count;
  }

  /// Sets the lowest 63-bit integer value at the given [index].
  /// TODO: add BigInt support.
  void operator []=(int index, int value) {
    int pos = 0;
    while (value > 0) {
      BitArray array;
      if (_bits.length == pos) {
        array = BitArray(_length);
        _bits.add(array);
      } else {
        array = _bits[pos];
      }
      array[index] = (value & 0x01) != 0;
      value >>= 1;
      pos++;
    }
    while (pos < _bits.length) {
      _bits[pos++].clearBit(index);
    }
  }

  /// Returns the binary string representation of the count at the given [index].
  String toBinaryString(int index) {
    final sb = StringBuffer();
    for (int i = _bits.length - 1; i >= 0; i--) {
      final value = _bits[i][index];
      if (sb.isEmpty && !value) continue;
      sb.write(value ? '1' : '0');
    }
    if (sb.isEmpty) {
      return '0';
    }
    return sb.toString();
  }

  /// Adds a bit [array] to the counter.
  void addBitArray(BitArray array) {
    addBitSet(array);
  }

  /// Adds a [set] to the counter.
  ///
  /// The add starts at the bit position specified by [shiftLeft].
  void addBitSet(BitSet set, {int shiftLeft = 0}) {
    // From last bit index to bit array length: +1
    if (_length < set.length + 1) {
      _length = set.length + 1;
      _bits.forEach((a) => a.length = _length);
    }
    for (int i = _bits.length; i < shiftLeft; i++) {
      _bits.add(BitArray(_length));
    }
    final arrayDataLength = _bufferLength32(_length);
    final iterator = set.asUint32Iterable().iterator;
    for (int i = 0; i < arrayDataLength && iterator.moveNext(); i++) {
      int overflow = iterator.current;

      for (int pos = shiftLeft; overflow != 0; pos++) {
        BitArray counter;
        if (_bits.length == pos) {
          counter = BitArray(_length);
          _bits.add(counter);
        } else {
          counter = _bits[pos];
        }
        final value = counter._data[i];
        final newOverflow = value & overflow;
        counter._data[i] = (value | overflow) & (~newOverflow);
        overflow = newOverflow;
      }
    }
  }

  /// Adds a [counter] to the set.
  ///
  /// The add starts at the bit position specified by [shiftLeft].
  void addBitCounter(BitCounter counter, {int shiftLeft = 0}) {
    for (int i = 0; i < counter.bitLength; i++) {
      addBitSet(counter.bits[i], shiftLeft: shiftLeft + i);
    }
  }

  /// Increments the value at the [index].
  ///
  /// The increment starts at the bit position specified by [shiftLeft].
  void increment(int index, {int shiftLeft = 0}) {
    for (int i = _bits.length; i < shiftLeft; i++) {
      _bits.add(BitArray(_length));
    }
    for (int pos = shiftLeft;; pos++) {
      BitArray counter;
      if (_bits.length == pos) {
        counter = BitArray(_length);
        _bits.add(counter);
      } else {
        counter = _bits[pos];
      }
      final set = counter[index];
      counter[index] = !set;
      if (set) {
        continue;
      } else {
        break;
      }
    }
  }

  /// Multiply this instance with [value] and return the result.
  BitCounter multiply(int value) {
    final result = BitCounter(_length);
    int shiftLeft = 0;
    while (value > 0) {
      final bit = value & 0x01;
      if (bit == 1) {
        result.addBitCounter(this, shiftLeft: shiftLeft);
      }
      value = value >> 1;
      shiftLeft++;
    }
    return result;
  }

  /// Multiply this instance with [counter] and return the result.
  BitCounter multiplyWithCounter(BitCounter counter) {
    final result = BitCounter(math.min(_length, counter._length));
    for (int i = 0; i < bitLength; i++) {
      for (int j = 0; j < counter.bitLength; j++) {
        final ba = _bits[i].clone()..and(counter._bits[j]);
        result.addBitSet(ba, shiftLeft: i + j);
      }
    }
    return result;
  }

  /// Multiply this instance with [value] and return the result.
  BitCounter operator *(/* int | BitCounter */ dynamic value) {
    if (value is int) {
      return multiply(value);
    } else if (value is BitCounter) {
      return multiplyWithCounter(value);
    } else {
      throw Exception('Unknown multiplier type: ${value.runtimeType}');
    }
  }

  /// Add [bits] cleared bits to the lower binary digits.
  void shiftLeft(int bits) {
    if (bits <= 0) return;
    final list = List<BitArray>.generate(bits, (i) => BitArray(_length));
    _bits.insertAll(0, list);
  }

  /// Remove [bits] lower binary digits.
  void shiftRight(int bits) {
    if (bits <= 0) return;
    final end = math.min(bits, bitLength);
    if (end > 0) {
      _bits.removeRange(0, end);
    }
  }

  /// Returns a [BitArray] which is true for every position where the current
  /// [BitCounter] has a value larger or equal to [minValue].
  BitArray toMask({int minValue = 1}) {
    if (minValue < 1) {
      throw ArgumentError('minValue must be at least 1.');
    }
    if (bitLength == 0) return BitArray(0);
    if (minValue == 1) {
      final r = _bits[0].clone();
      for (int i = 1; i < bitLength; i++) {
        r.or(_bits[i]);
      }
      return r;
    } else {
      final other = <int>[];
      minValue--;
      while (minValue > 0) {
        final bit = minValue & 0x01;
        other.add(bit == 0 ? 0 : ~0);
        minValue >>= 1;
      }
      final r = BitArray(_length);
      final bl = math.max(bitLength, other.length);
      final dataLength = _bits[0]._data.length;
      for (int i = 0; i < dataLength; i++) {
        int ub = -1;
        for (int j = 0; j < bl; j++) {
          final av = j >= bitLength ? 0 : bits[j]._data[i];
          final bv = j >= other.length ? 0 : other[j];

          final ag = av & (~bv);
          final bg = bv & (~av);
          ub = bg | (ub & (~ag));
        }
        r._data[i] = ~ub;
      }
      return r;
    }
  }

  /// Updates the values to the maximum of the pairwise values with [other].
  void max(BitCounter other) {
    if (_length != other._length) {
      throw ArgumentError(
          'Length does not match: $_length != ${other._length}');
    }
    if (bitLength == 0) {
      _bits.addAll(other._bits.map((a) => a.clone()));
      return;
    } else if (other.bitLength == 0) {
      return;
    }
    while (bitLength < other.bitLength) {
      _bits.add(BitArray(_length));
    }
    final dataLength = _bits[0]._data.length;
    for (int i = 0; i < dataLength; i++) {
      int ua = -1;
      for (int j = 0; j < bitLength; j++) {
        final av = bits[j]._data[i];
        final bv = j >= other.bitLength ? 0 : other.bits[j]._data[i];

        final ag = av & (~bv);
        final bg = bv & (~av);
        ua = ag | (ua & (~bg));
      }
      for (int j = 0; j < bitLength; j++) {
        final av = bits[j]._data[i];
        final bv = j >= other.bitLength ? 0 : other.bits[j]._data[i];
        _bits[j]._data[i] = (ua & av) | ((~ua) & bv);
      }
    }
  }

  /// Updates the values to the minimum of the pairwise values with [other].
  ///
  /// The most significant bits will be removed if they are all-zero.
  void min(BitCounter other) {
    if (_length != other._length) {
      throw ArgumentError(
          'Length does not match: $_length != ${other._length}');
    }
    if (bitLength == 0) {
      return;
    } else if (other.bitLength == 0) {
      _bits.clear();
      return;
    }
    final mbl = math.max(bitLength, other.bitLength);
    final dataLength = _bits[0]._data.length;
    for (int i = 0; i < dataLength; i++) {
      int ub = -1;
      for (int j = 0; j < mbl; j++) {
        final av = j >= bitLength ? 0 : bits[j]._data[i];
        final bv = j >= other.bitLength ? 0 : other.bits[j]._data[i];

        final ag = av & (~bv);
        final bg = bv & (~av);
        ub = ag | (ub & (~bg));
      }
      for (int j = 0; j < bitLength; j++) {
        final av = bits[j]._data[i];
        final bv = j >= other.bitLength ? 0 : other.bits[j]._data[i];
        _bits[j]._data[i] = (ub & bv) | ((~ub) & av);
      }
    }
    while (bitLength > 0 && _bits.last.isEmpty) {
      _bits.removeLast();
    }
  }

  /// Update the current [BitCounter] using a logical AND operation with the
  /// corresponding elements in the specified [set].
  ///
  /// Excess size of the [set] is ignored.
  ///
  /// The most significant bits will be removed if they are all-zero.
  void applyMask(BitSet set) {
    if (bitLength == 0) return;
    final dataLength = _bits.first._data.length;
    final iter = set.asUint32Iterable().iterator;
    int i = 0;
    for (; i < dataLength && iter.moveNext(); i++) {
      final cv = iter.current;
      for (int j = 0; j < _bits.length; j++) {
        _bits[j]._data[i] &= cv;
      }
    }
    for (; i < dataLength; i++) {
      for (int j = 0; j < _bits.length; j++) {
        _bits[j]._data[i] = 0;
      }
    }
    while (bitLength > 0 && _bits.last.isEmpty) {
      _bits.removeLast();
    }
  }

  /// Creates a copy of the current [BitCounter].
  ///
  /// The cloned instance starts at the bit position specified by [shiftRight].
  BitCounter clone({int shiftRight = 0}) {
    final c = BitCounter(_length);
    for (int i = shiftRight; i < bitLength; i++) {
      c._bits.add(_bits[i].clone());
    }
    return c;
  }
}
