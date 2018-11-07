part of bit_array;

/// A range-encoded bit counter.
class BitCounter {
  final _bits = <BitArray>[];
  int _length = 0;

  BitCounter(this._length);

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
        array = new BitArray(_length);
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
    final sb = new StringBuffer();
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
    if (_length < array.length) {
      _length = array.length;
      _bits.forEach((a) => a.length = _length);
    }
    final arrayDataLength = _length >> 6;
    final iterator = array.asUint64Iterable().iterator;
    for (int i = 0; i < arrayDataLength && iterator.moveNext(); i++) {
      int overflow = iterator.current;

      for (int pos = 0; overflow != 0; pos++) {
        BitArray counter;
        if (_bits.length == pos) {
          counter = new BitArray(_length);
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

  /// Increments the value at the [index].
  void increment(int index) {
    for (int pos = 0;; pos++) {
      BitArray counter;
      if (_bits.length == pos) {
        counter = new BitArray(_length);
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
}
